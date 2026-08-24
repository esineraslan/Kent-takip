import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:kent_takip_application/kent_takip_application.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:kent_takip_persistence/kent_takip_persistence.dart';

final class SnapshotController extends ChangeNotifier {
  SnapshotController({
    required this.gateway,
    required this.drafts,
    required this.stagingMediaStore,
    required this.deleteStagingAfterCommit,
  });

  final DemoDataGateway gateway;
  final OfflineDraftQueue drafts;
  final MediaStore stagingMediaStore;
  final bool deleteStagingAfterCommit;
  AppSnapshotDto? _snapshot;
  Object? _error;
  Object? _revisionError;
  CommandConflict? _conflict;
  StreamSubscription<int>? _revisionSubscription;
  bool _busy = false;
  bool _online = false;

  AppSnapshotDto? get snapshot => _snapshot;
  Object? get error => _error;
  Object? get revisionError => _revisionError;
  CommandConflict? get conflict => _conflict;
  bool get busy => _busy;
  bool get online => _online;
  bool get staffReadOnly => !_online;
  OfflineStateDecision get offlineState => OfflineStatePolicy.decide(
    hasSnapshot: _snapshot != null,
    online: _online,
    refreshing: _busy,
    recoverableFailure: _error != null,
  );

  Future<void> initialize() async {
    _revisionSubscription = gateway.watchRevisions().listen(
      (revision) {
        _revisionError = null;
        if (revision != _snapshot?.revision) unawaited(refresh());
      },
      // WebSocket yalnızca bir hızlandırmadır; REST snapshot başarılıyken
      // revision kanalının kesilmesi uygulamayı çevrimdışı yapmamalıdır.
      onError: (Object error) {
        _revisionError = error;
        notifyListeners();
      },
    );
    await refresh();
  }

  Future<void> refresh() async {
    try {
      _snapshot = await gateway.fetchSnapshot();
      _online = !gateway.lastReadWasOfflineCache;
      _error = _online ? null : _error;
    } on Object catch (error) {
      _online = false;
      _error = error;
    }
    notifyListeners();
  }

  Future<MutationResult?> createReport({
    required String actorId,
    required String clientMutationId,
    required String category,
    required String description,
    required double latitude,
    required double longitude,
    PreparedMedia? preparedMedia,
    AiAnalysisDto? analysis,
    bool manualReviewRequired = false,
    RiskLevel riskLevel = RiskLevel.unknown,
  }) async {
    final current = _snapshot ?? await gateway.fetchSnapshot();
    final command = CreateReportCommand(
      actorId: actorId,
      clientMutationId: clientMutationId,
      expectedRevision: current.revision,
      category: category,
      description: description,
      latitude: latitude,
      longitude: longitude,
      media: [if (preparedMedia != null) preparedMedia.reference],
      analysis: analysis,
      manualReviewRequired: manualReviewRequired,
      riskLevel: riskLevel,
    );
    try {
      if (preparedMedia != null) await _stage(preparedMedia);
      await drafts.save(command);
    } on DomainFailure catch (error) {
      _error = error;
      notifyListeners();
      return null;
    } on Object catch (error) {
      _error = error;
      notifyListeners();
      return null;
    }
    _setBusy(true);
    try {
      await _upload(command);
      final result = await gateway.createReport(command);
      await drafts.clear(actorId);
      await _clearStaging(command);
      _snapshot = result.snapshot;
      _online = true;
      _error = null;
      return result;
    } on CommandConflict catch (error) {
      _snapshot = error.current;
      _conflict = error;
      _error = error;
      return null;
    } on DomainFailure catch (error) {
      _online = true;
      _error = error;
      return null;
    } on Object catch (error) {
      _online = false;
      _error = error;
      return null;
    } finally {
      _setBusy(false);
    }
  }

  Future<MutationResult?> submitSavedDraft(String actorId) async {
    final draft = await drafts.load(actorId);
    if (draft == null) return null;
    final current = _snapshot ?? await gateway.fetchSnapshot();
    final refreshed = CreateReportCommand(
      actorId: draft.actorId,
      clientMutationId: draft.clientMutationId,
      expectedRevision: current.revision,
      category: draft.category,
      description: draft.description,
      latitude: draft.latitude,
      longitude: draft.longitude,
      media: draft.media,
      analysis: draft.analysis,
      manualReviewRequired: draft.manualReviewRequired,
      riskLevel: draft.riskLevel,
    );
    _setBusy(true);
    try {
      await _upload(refreshed);
      final result = await gateway.createReport(refreshed);
      await drafts.clear(actorId);
      await _clearStaging(refreshed);
      _snapshot = result.snapshot;
      _online = true;
      _error = null;
      return result;
    } on CommandConflict catch (error) {
      _snapshot = error.current;
      _conflict = error;
      _error = error;
      return null;
    } on DomainFailure catch (error) {
      _online = true;
      _error = error;
      return null;
    } on Object catch (error) {
      _online = false;
      _error = error;
      return null;
    } finally {
      _setBusy(false);
    }
  }

  Future<MutationResult?> verifyReport({
    required String actorId,
    required String clientMutationId,
    required String reportId,
    required String category,
    required String unitId,
    required String reason,
    String? aiOverrideReason,
    bool publicPreviewApproved = false,
  }) async {
    if (staffReadOnly) return null;
    final current = _snapshot ?? await gateway.fetchSnapshot();
    _setBusy(true);
    try {
      final result = await gateway.verifyReport(
        VerifyReportCommand(
          actorId: actorId,
          clientMutationId: clientMutationId,
          expectedRevision: current.revision,
          reportId: reportId,
          category: category,
          unitId: unitId,
          reason: reason,
          publicPreviewApproved: publicPreviewApproved,
          aiOverrideReason: aiOverrideReason,
        ),
      );
      _snapshot = result.snapshot;
      _online = true;
      _error = null;
      _conflict = null;
      return result;
    } on CommandConflict catch (error) {
      _snapshot = error.current;
      _conflict = error;
      _error = error;
      return null;
    } on DomainFailure catch (error) {
      _online = true;
      _error = error;
      return null;
    } on Object catch (error) {
      _online = false;
      _error = error;
      return null;
    } finally {
      _setBusy(false);
    }
  }


  Future<MutationResult?> reviewLease({
    required String actorId,
    required String reportId,
    required ReviewLeaseAction action,
    String? reason,
  }) async {
    if (staffReadOnly) return null;
    final current = _snapshot ?? await gateway.fetchSnapshot();
    _setBusy(true);
    try {
      final result = await gateway.reviewLease(
        ReviewLeaseCommand(
          actorId: actorId,
          clientMutationId:
              'lease_${actorId}_${reportId}_${action.name}_${DateTime.now().toUtc().microsecondsSinceEpoch}',
          expectedRevision: current.revision,
          reportId: reportId,
          action: action,
          reason: reason,
        ),
      );
      _snapshot = result.snapshot;
      _online = true;
      _error = null;
      _conflict = null;
      return result;
    } on CommandConflict catch (error) {
      _snapshot = error.current;
      _conflict = error;
      _error = error;
      return null;
    } on DomainFailure catch (error) {
      _online = true;
      _error = error;
      return null;
    } on Object catch (error) {
      _online = false;
      _error = error;
      return null;
    } finally {
      _setBusy(false);
    }
  }

  Future<MutationResult?> staffDecision({
    required String actorId,
    required String reportId,
    required StaffDecisionAction action,
    required String reason,
    String? reasonCode,
    String? targetId,
    String? targetReportId,
    String? message,
    String? aiOverrideReason,
    bool confirmCritical = false,
  }) async {
    if (staffReadOnly) return null;
    final current = _snapshot ?? await gateway.fetchSnapshot();
    _setBusy(true);
    try {
      final result = await gateway.staffDecision(
        StaffDecisionCommand(
          actorId: actorId,
          clientMutationId:
              'staff_decision_${actorId}_${DateTime.now().toUtc().microsecondsSinceEpoch}',
          expectedRevision: current.revision,
          reportId: reportId,
          action: action,
          reason: reason,
          reasonCode: reasonCode,
          targetId: targetId,
          targetReportId: targetReportId,
          message: message,
          aiOverrideReason: aiOverrideReason,
          confirmCritical: confirmCritical,
        ),
      );
      _snapshot = result.snapshot;
      _online = true;
      _error = null;
      _conflict = null;
      return result;
    } on CommandConflict catch (error) {
      _snapshot = error.current;
      _conflict = error;
      _error = error;
      return null;
    } on DomainFailure catch (error) {
      _online = true;
      _error = error;
      return null;
    } on Object catch (error) {
      _online = false;
      _error = error;
      return null;
    } finally {
      _setBusy(false);
    }
  }

  Future<MutationResult?> fieldOperation({
    required String actorId,
    required String incidentId,
    required FieldOperationAction action,
    required String reason,
    String? assigneeId,
    String? fieldTeamId,
    String? delayReason,
    int? reestimateMinMinutes,
    int? reestimateMaxMinutes,
    String? resolutionExplanation,
    String? resolutionMediaId,
  }) async {
    if (staffReadOnly) return null;
    final current = _snapshot ?? await gateway.fetchSnapshot();
    _setBusy(true);
    try {
      final result = await gateway.fieldOperation(
        FieldOperationCommand(
          actorId: actorId,
          clientMutationId:
              'field_${actorId}_${DateTime.now().toUtc().microsecondsSinceEpoch}',
          expectedRevision: current.revision,
          incidentId: incidentId,
          action: action,
          reason: reason,
          assigneeId: assigneeId,
          fieldTeamId: fieldTeamId,
          delayReason: delayReason,
          reestimateMinMinutes: reestimateMinMinutes,
          reestimateMaxMinutes: reestimateMaxMinutes,
          resolutionExplanation: resolutionExplanation,
          resolutionMediaId: resolutionMediaId,
        ),
      );
      _snapshot = result.snapshot;
      _online = true;
      _error = null;
      _conflict = null;
      return result;
    } on CommandConflict catch (error) {
      _snapshot = error.current;
      _conflict = error;
      _error = error;
      return null;
    } on DomainFailure catch (error) {
      _online = true;
      _error = error;
      return null;
    } on Object catch (error) {
      _online = false;
      _error = error;
      return null;
    } finally {
      _setBusy(false);
    }
  }

  Future<MutationResult?> municipalWork({
    required String actorId,
    required MunicipalWorkAction action,
    String? workId,
    String? category,
    double? latitude,
    double? longitude,
    DateTime? startsAt,
    DateTime? expectedEndsAt,
    String? responsibleUnitId,
    String? explanation,
    int areaRadiusMeters = 120,
    String? publicInformationText,
    bool publicPreviewApproved = false,
    String? reason,
  }) async {
    if (staffReadOnly) return null;
    final current = _snapshot ?? await gateway.fetchSnapshot();
    _setBusy(true);
    try {
      final result = await gateway.municipalWork(
        MunicipalWorkCommand(
          actorId: actorId,
          clientMutationId:
              'work_${actorId}_${action.name}_${DateTime.now().toUtc().microsecondsSinceEpoch}',
          expectedRevision: current.revision,
          action: action,
          workId: workId,
          category: category,
          latitude: latitude,
          longitude: longitude,
          startsAt: startsAt,
          expectedEndsAt: expectedEndsAt,
          responsibleUnitId: responsibleUnitId,
          explanation: explanation,
          areaRadiusMeters: areaRadiusMeters,
          publicInformationText: publicInformationText,
          publicPreviewApproved: publicPreviewApproved,
          reason: reason,
        ),
      );
      _snapshot = result.snapshot;
      _online = true;
      _error = null;
      _conflict = null;
      return result;
    } on CommandConflict catch (error) {
      _snapshot = error.current;
      _conflict = error;
      _error = error;
      return null;
    } on DomainFailure catch (error) {
      _online = true;
      _error = error;
      return null;
    } on Object catch (error) {
      _online = false;
      _error = error;
      return null;
    } finally {
      _setBusy(false);
    }
  }

  Future<MutationResult?> citizenAction({
    required String actorId,
    required CitizenActionKind kind,
    required String resourceId,
    JsonMap payload = const {},
  }) async {
    final current = _snapshot ?? await gateway.fetchSnapshot();
    _setBusy(true);
    try {
      final result = await gateway.citizenAction(
        CitizenActionCommand(
          actorId: actorId,
          clientMutationId:
              'citizen_action_${actorId}_${DateTime.now().toUtc().microsecondsSinceEpoch}',
          expectedRevision: current.revision,
          kind: kind,
          resourceId: resourceId,
          payload: payload,
        ),
      );
      _snapshot = result.snapshot;
      _online = true;
      _error = null;
      _conflict = null;
      return result;
    } on CommandConflict catch (error) {
      _snapshot = error.current;
      _conflict = error;
      _error = error;
      return null;
    } on DomainFailure catch (error) {
      _online = true;
      _error = error;
      return null;
    } on Object catch (error) {
      _online = false;
      _error = error;
      return null;
    } finally {
      _setBusy(false);
    }
  }

  Future<MutationResult?> sourceOperation({
    required String actorId,
    required SourceOperationAction action,
    JsonMap payload = const {},
  }) async {
    if (staffReadOnly) return null;
    final current = _snapshot ?? await gateway.fetchSnapshot();
    _setBusy(true);
    try {
      final result = await gateway.sourceOperation(
        SourceOperationCommand(
          actorId: actorId,
          clientMutationId: 'source_${actorId}_${action.name}_${DateTime.now().toUtc().microsecondsSinceEpoch}',
          expectedRevision: current.revision,
          action: action,
          payload: payload,
        ),
      );
      _snapshot = result.snapshot;
      _online = true;
      _error = null;
      _conflict = null;
      return result;
    } on CommandConflict catch (error) {
      _snapshot = error.current;
      _conflict = error;
      _error = error;
      return null;
    } on DomainFailure catch (error) {
      _online = true;
      _error = error;
      return null;
    } on Object catch (error) {
      _online = false;
      _error = error;
      return null;
    } finally {
      _setBusy(false);
    }
  }

  Future<MutationResult?> administration({
    required String actorId,
    required AdministrationAction action,
    JsonMap payload = const {},
  }) async {
    final current = _snapshot ?? await gateway.fetchSnapshot();
    _setBusy(true);
    try {
      final result = await gateway.administration(
        AdministrationCommand(
          actorId: actorId,
          clientMutationId: 'admin_${actorId}_${action.name}_${DateTime.now().toUtc().microsecondsSinceEpoch}',
          expectedRevision: current.revision,
          action: action,
          payload: payload,
        ),
      );
      _snapshot = result.snapshot;
      _online = true;
      _error = null;
      _conflict = null;
      return result;
    } on CommandConflict catch (error) {
      _snapshot = error.current;
      _conflict = error;
      _error = error;
      return null;
    } on DomainFailure catch (error) {
      _online = true;
      _error = error;
      return null;
    } on Object catch (error) {
      _online = false;
      _error = error;
      return null;
    } finally {
      _setBusy(false);
    }
  }

  Future<Uint8List?> viewOriginalMedia({
    required String actorId,
    required String mediaRef,
    required String reason,
  }) async {
    if (reason.trim().length < 8) {
      fail(FailureCode.validation, 'Orijinal medya erişim gerekçesi en az 8 karakter olmalıdır.');
    }
    final bytes = await gateway.getMedia(
      _mediaId(mediaRef),
      reason: reason.trim(),
      actorId: actorId,
    );
    await refresh();
    return bytes;
  }

  void clearConflict() {
    _conflict = null;
    _error = null;
    notifyListeners();
  }

  Future<void> resetClientState(Iterable<String> citizenIds) async {
    for (final citizenId in citizenIds) {
      final draft = await drafts.load(citizenId);
      if (draft != null) {
        for (final media in draft.media) {
          for (final ref in [media.originalRef, media.publicRef]) {
            if (ref != null) await stagingMediaStore.delete(_mediaId(ref));
          }
        }
      }
      await drafts.clear(citizenId);
    }
    _conflict = null;
    _revisionError = null;
    await refresh();
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }

  Future<void> _stage(PreparedMedia media) async {
    await stagingMediaStore.put(media.originalId, media.originalBytes);
    if (media.publicId != null && media.publicBytes != null) {
      await stagingMediaStore.put(media.publicId!, media.publicBytes!);
    }
  }

  Future<void> _upload(CreateReportCommand command) async {
    for (final media in command.media) {
      for (final ref in [media.originalRef, media.publicRef]) {
        if (ref == null) continue;
        final id = _mediaId(ref);
        final bytes = await stagingMediaStore.get(id);
        if (bytes == null) {
          fail(FailureCode.corruption, 'Taslak medya verisi bulunamadı.');
        }
        await gateway.putMedia(id, bytes);
      }
    }
  }

  Future<void> _clearStaging(CreateReportCommand command) async {
    if (!deleteStagingAfterCommit) return;
    for (final media in command.media) {
      for (final ref in [media.originalRef, media.publicRef]) {
        if (ref != null) await stagingMediaStore.delete(_mediaId(ref));
      }
    }
  }

  String _mediaId(String ref) {
    if (!ref.startsWith('media://')) {
      fail(FailureCode.validation, 'Medya referansı geçersiz.');
    }
    return ref.substring('media://'.length);
  }

  @override
  void dispose() {
    unawaited(_revisionSubscription?.cancel());
    unawaited(gateway.close());
    super.dispose();
  }
}
