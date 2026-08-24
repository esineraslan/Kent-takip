import 'dart:math' as math;

import 'package:kent_takip_application/src/commands.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';

enum MunicipalWorkAction {
  saveDraft,
  analyzeImpact,
  markReviewReady,
  publish,
  reconcileClock,
  cancel,
}

final class MunicipalWorkCommand {
  MunicipalWorkCommand({
    required this.actorId,
    required this.clientMutationId,
    required this.expectedRevision,
    required this.action,
    this.workId,
    this.category,
    this.latitude,
    this.longitude,
    this.startsAt,
    this.expectedEndsAt,
    this.responsibleUnitId,
    this.explanation,
    this.areaRadiusMeters = 120,
    this.publicInformationText,
    this.publicPreviewApproved = false,
    this.reason,
  }) {
    requireText(actorId, 'actorId');
    requireText(clientMutationId, 'clientMutationId');
    if (expectedRevision < 0) {
      fail(FailureCode.validation, 'expectedRevision negatif olamaz.');
    }
    switch (action) {
      case MunicipalWorkAction.saveDraft:
        requireText(category ?? '', 'category');
        GeoPoint(latitude: latitude ?? double.nan, longitude: longitude ?? double.nan);
        final start = startsAt;
        final end = expectedEndsAt;
        if (start == null || end == null) {
          fail(FailureCode.validation, 'Başlangıç ve tahmini bitiş zorunludur.');
        }
        requireUtc(start, 'startsAt');
        requireUtc(end, 'expectedEndsAt');
        if (!end.isAfter(start)) {
          fail(FailureCode.validation, 'Tahmini bitiş başlangıçtan sonra olmalıdır.');
        }
        requireText(responsibleUnitId ?? '', 'responsibleUnitId');
        requireText(explanation ?? '', 'explanation');
        if (areaRadiusMeters < 25 || areaRadiusMeters > 5000) {
          fail(FailureCode.validation, 'Etki alanı yarıçapı 25–5000 metre olmalıdır.');
        }
        break;
      case MunicipalWorkAction.publish:
        requireText(publicInformationText ?? '', 'publicInformationText');
        if (!publicPreviewApproved) {
          fail(FailureCode.validation, 'Yayın için personel public preview onayı zorunludur.');
        }
        requireText(workId ?? '', 'workId');
        break;
      case MunicipalWorkAction.analyzeImpact:
      case MunicipalWorkAction.markReviewReady:
      case MunicipalWorkAction.reconcileClock:
      case MunicipalWorkAction.cancel:
        if (action != MunicipalWorkAction.reconcileClock) {
          requireText(workId ?? '', 'workId');
        }
        if (action == MunicipalWorkAction.cancel) requireText(reason ?? '', 'reason');
        break;
    }
  }

  factory MunicipalWorkCommand.fromJson(JsonMap json) => MunicipalWorkCommand(
        actorId: expectString(json['actorId'], 'actorId'),
        clientMutationId: expectString(json['clientMutationId'], 'clientMutationId'),
        expectedRevision: expectInt(json['expectedRevision'], 'expectedRevision'),
        action: expectEnum(json['action'], 'action', enumValues(MunicipalWorkAction.values)),
        workId: expectNullableString(json['workId'], 'workId'),
        category: expectNullableString(json['category'], 'category'),
        latitude: _nullableNumber(json['latitude'], 'latitude'),
        longitude: _nullableNumber(json['longitude'], 'longitude'),
        startsAt: json['startsAt'] == null ? null : expectUtcDate(json['startsAt'], 'startsAt'),
        expectedEndsAt: json['expectedEndsAt'] == null
            ? null
            : expectUtcDate(json['expectedEndsAt'], 'expectedEndsAt'),
        responsibleUnitId: expectNullableString(json['responsibleUnitId'], 'responsibleUnitId'),
        explanation: expectNullableString(json['explanation'], 'explanation'),
        areaRadiusMeters: json['areaRadiusMeters'] == null
            ? 120
            : expectInt(json['areaRadiusMeters'], 'areaRadiusMeters'),
        publicInformationText: expectNullableString(
          json['publicInformationText'],
          'publicInformationText',
        ),
        publicPreviewApproved: json['publicPreviewApproved'] == null
            ? false
            : expectBool(json['publicPreviewApproved'], 'publicPreviewApproved'),
        reason: expectNullableString(json['reason'], 'reason'),
      );

  final String actorId;
  final String clientMutationId;
  final int expectedRevision;
  final MunicipalWorkAction action;
  final String? workId;
  final String? category;
  final double? latitude;
  final double? longitude;
  final DateTime? startsAt;
  final DateTime? expectedEndsAt;
  final String? responsibleUnitId;
  final String? explanation;
  final int areaRadiusMeters;
  final String? publicInformationText;
  final bool publicPreviewApproved;
  final String? reason;

  JsonMap toJson() => {
        'actorId': actorId,
        'clientMutationId': clientMutationId,
        'expectedRevision': expectedRevision,
        'action': enumWire(action),
        'workId': workId,
        'category': category,
        'latitude': latitude,
        'longitude': longitude,
        'startsAt': startsAt?.toIso8601String(),
        'expectedEndsAt': expectedEndsAt?.toIso8601String(),
        'responsibleUnitId': responsibleUnitId,
        'explanation': explanation,
        'areaRadiusMeters': areaRadiusMeters,
        'publicInformationText': publicInformationText,
        'publicPreviewApproved': publicPreviewApproved,
        'reason': reason,
      };
}

final class MunicipalWorkPreview {
  const MunicipalWorkPreview({
    required this.work,
    required this.effectiveStatus,
    required this.pinKind,
    required this.publicVisible,
  });

  final MunicipalWorkDto work;
  final WorkStatus effectiveStatus;
  final PinKind? pinKind;
  final bool publicVisible;
}

abstract final class MunicipalWorkProjection {
  static WorkStatus effectiveStatus(MunicipalWorkDto work, DateTime now) {
    if (work.status == WorkStatus.publishedPlanned && !now.isBefore(work.startsAt)) {
      if (!now.isBefore(work.expectedEndsAt)) return WorkStatus.completed;
      return WorkStatus.active;
    }
    if (work.status == WorkStatus.active && !now.isBefore(work.expectedEndsAt)) {
      return WorkStatus.completed;
    }
    return work.status;
  }

  static MunicipalWorkPreview preview(MunicipalWorkDto work, DateTime now) {
    final status = effectiveStatus(work, now);
    final pin = switch (status) {
      WorkStatus.publishedPlanned => PinKind.publishedPlanned,
      WorkStatus.active => PinKind.verifiedActive,
      _ => null,
    };
    return MunicipalWorkPreview(
      work: work,
      effectiveStatus: status,
      pinKind: pin,
      publicVisible: pin != null,
    );
  }
}

final class MunicipalImpactAnalyzer {
  const MunicipalImpactAnalyzer();

  MunicipalWorkImpactDto analyze(
    MunicipalWorkDto work,
    Iterable<MunicipalWorkDto> otherWorks,
    DateTime now,
  ) {
    final overlaps = <OpaqueEntityDto>[];
    final roads = <String>{};
    final transit = <String>{};
    for (final ref in _impactReferences) {
      final distance = _distanceMeters(work.latitude, work.longitude, ref.latitude, ref.longitude);
      if (distance > work.areaRadiusMeters + ref.bufferMeters) continue;
      if (ref.kind == 'road_segment') roads.add(ref.name);
      if (ref.kind == 'transit_line') transit.add(ref.name);
      overlaps.add(
        OpaqueEntityDto(
          id: 'impact_${work.id}_${ref.id}',
          body: {
            'id': 'impact_${work.id}_${ref.id}',
            'kind': ref.kind,
            'sourceId': ref.id,
            'sourceLabel': ref.name,
            'distanceMeters': distance.round(),
            'rule': 'work_radius + reference_buffer',
            'explanation':
                '${ref.name}, çalışma merkezine ${distance.round()} m uzaklıkta; ${ref.bufferMeters} m referans buffer + ${work.areaRadiusMeters} m çalışma alanı çakışıyor.',
          },
        ),
      );
    }
    final temporalConflicts = <MunicipalWorkDto>[];
    for (final other in otherWorks) {
      if (other.id == work.id || other.status == WorkStatus.cancelled || other.status == WorkStatus.completed) {
        continue;
      }
      if (!_timeOverlaps(work.startsAt, work.expectedEndsAt, other.startsAt, other.expectedEndsAt)) {
        continue;
      }
      final distance = _distanceMeters(work.latitude, work.longitude, other.latitude, other.longitude);
      if (distance > work.areaRadiusMeters + other.areaRadiusMeters) continue;
      temporalConflicts.add(other);
      overlaps.add(
        OpaqueEntityDto(
          id: 'impact_${work.id}_work_${other.id}',
          body: {
            'id': 'impact_${work.id}_work_${other.id}',
            'kind': 'municipal_work',
            'sourceId': other.id,
            'sourceLabel': other.explanation,
            'distanceMeters': distance.round(),
            'timeOverlapMinutes': _overlapMinutes(
              work.startsAt,
              work.expectedEndsAt,
              other.startsAt,
              other.expectedEndsAt,
            ),
            'rule': 'spatial_radius_and_time_interval_overlap',
            'explanation':
                'Başka belediye çalışması hem zaman aralığında hem etki alanında çakışıyor; bu bir trafik tahmini değildir.',
          },
        ),
      );
    }
    final suggestions = <String>[];
    if (temporalConflicts.isNotEmpty) {
      var after = temporalConflicts.first.expectedEndsAt;
      for (final conflict in temporalConflicts.skip(1)) {
        if (conflict.expectedEndsAt.isAfter(after)) after = conflict.expectedEndsAt;
      }
      final duration = work.expectedEndsAt.difference(work.startsAt);
      final alternativeStart = after.add(const Duration(minutes: 30));
      final alternativeEnd = alternativeStart.add(duration);
      suggestions.add(
        'Zaman alternatifi: ${alternativeStart.toIso8601String()}–${alternativeEnd.toIso8601String()}; gerekçe: uzamsal ve zamansal çalışma çakışmasını ayırmak.',
      );
    }
    if (roads.isNotEmpty) {
      suggestions.add(
        'Güzergâh alternatifi: saha planında ${roads.first} segmentini açık tutacak kademeli çalışma değerlendirilsin; öneri yalnız geometrik çakışma kuralına dayanır.',
      );
    }
    if (suggestions.isEmpty) {
      suggestions.add('Belirgin kural tabanlı çakışma yok; mevcut zaman penceresi korunabilir.');
    }
    final citizenDraft = _citizenDraft(work, roads, transit);
    final explanation =
        'Etki analizi ${overlaps.length} açıklanabilir çakışma buldu. Kaynaklar: demo yol segmenti bufferları, toplu taşıma hat bufferları ve yayımlanmış/planlanan belediye işleri. AI trafik tahmini kullanılmadı.';
    return MunicipalWorkImpactDto(
      analyzedAt: now,
      overlaps: overlaps,
      affectedRoadSegments: roads,
      affectedTransitLines: transit,
      suggestions: suggestions,
      citizenInformationDraft: citizenDraft,
      explanation: explanation,
    );
  }

  String _citizenDraft(
    MunicipalWorkDto work,
    Set<String> roads,
    Set<String> transit,
  ) {
    final affected = <String>[
      if (roads.isNotEmpty) 'yol: ${roads.join(', ')}',
      if (transit.isNotEmpty) 'toplu taşıma: ${transit.join(', ')}',
    ];
    return 'Planlı ${work.category} çalışması ${work.startsAt.toIso8601String()} ile ${work.expectedEndsAt.toIso8601String()} arasında yürütülecek. ${affected.isEmpty ? 'Yakın çevrede kontrollü saha etkisi bekleniyor.' : 'Geometrik etki analizi: ${affected.join(' · ')}.'} Bu bilgilendirme personel onayı olmadan yayımlanmaz.';
  }
}

extension MunicipalWorkCommandOperations on SnapshotCommandProcessor {
  Future<MutationResult> municipalWork(MunicipalWorkCommand command) {
    return transactionQueue.run(() async {
      final current = await store.read();
      final replay = _workMutationAudit(current, command.clientMutationId);
      if (replay != null) {
        if (replay.body['actorId'] != command.actorId) {
          fail(FailureCode.unauthorized, 'clientMutationId başka aktöre ait.');
        }
        return MutationResult(
          snapshot: current,
          resourceId: command.workId ?? 'work_clock',
          trackingNumber: null,
          replayed: true,
        );
      }
      if (command.expectedRevision != current.revision) {
        throw CommandConflict(expectedRevision: command.expectedRevision, current: current);
      }
      final actor = _workActor(current, command.actorId);
      AuthorizationPolicy.requirePermission(actor, Permission.manageMunicipalWork);
      final now = clock.nowUtc();
      final ordinal = current.revision + 1;
      var works = current.payload.municipalWorks;
      final audits = [...current.payload.auditEvents];
      final timeline = [...current.payload.timeline];
      String resourceId = command.workId ?? '';
      var changed = false;

      switch (command.action) {
        case MunicipalWorkAction.saveDraft:
          final existing = command.workId == null ? null : _findWorkOrNull(current, command.workId!);
          if (existing != null &&
              existing.status != WorkStatus.draft &&
              existing.status != WorkStatus.impactReady) {
            fail(FailureCode.invalidTransition, 'Yalnız taslak/impact-ready çalışma düzenlenebilir.');
          }
          resourceId = existing?.id ?? _uniqueWorkId(current, ordinal);
          final draft = MunicipalWorkDto(
            id: resourceId,
            status: WorkStatus.draft,
            category: command.category!,
            latitude: command.latitude!,
            longitude: command.longitude!,
            startsAt: command.startsAt!,
            expectedEndsAt: command.expectedEndsAt!,
            responsibleUnitId: command.responsibleUnitId!,
            explanation: command.explanation!,
            areaRadiusMeters: command.areaRadiusMeters,
            createdBy: existing?.createdBy ?? actor.id,
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
          );
          works = existing == null
              ? [...works, draft]
              : [for (final item in works) if (item.id == resourceId) draft else item];
          audits.add(_workAudit(
            id: 'audit_work_draft_${ordinal}_$resourceId',
            actorId: actor.id,
            activeRoleContext: actor.role.name,
            action: existing == null ? 'municipal_work_draft_created' : 'municipal_work_draft_autosaved',
            resourceId: resourceId,
            at: now,
            reason: 'Planner autosave; draft is not public',
            before: existing?.toJson() ?? const {},
            after: {...draft.toJson(), 'clientMutationId': command.clientMutationId},
          ));
          changed = true;
          break;
        case MunicipalWorkAction.analyzeImpact:
          final work = _work(current, command.workId!);
          if (work.status != WorkStatus.draft && work.status != WorkStatus.impactReady) {
            fail(FailureCode.invalidTransition, 'Etki analizi taslak çalışma üzerinde yapılır.');
          }
          if (work.status == WorkStatus.draft) {
            WorkTransitionPolicy.requireAllowed(work.status, WorkStatus.impactReady);
          }
          final impact = const MunicipalImpactAnalyzer().analyze(work, works, now);
          final updated = _copyWork(
            work,
            status: WorkStatus.impactReady,
            impact: impact,
            affectedRoadSegments: impact.affectedRoadSegments,
            affectedTransitLines: impact.affectedTransitLines,
            publicInformationText: impact.citizenInformationDraft,
            updatedAt: now,
          );
          works = [for (final item in works) if (item.id == work.id) updated else item];
          resourceId = work.id;
          audits.add(_workAudit(
            id: 'audit_work_impact_${ordinal}_${work.id}',
            actorId: actor.id,
            activeRoleContext: actor.role.name,
            action: 'municipal_work_impact_analyzed',
            resourceId: work.id,
            at: now,
            reason: impact.explanation,
            before: {'status': enumWire(work.status)},
            after: {
              'status': enumWire(updated.status),
              'overlapCount': impact.overlaps.length,
              'sources': impact.overlaps.map((item) => item.body['sourceId']).toList(),
              'clientMutationId': command.clientMutationId,
            },
          ));
          changed = true;
          break;
        case MunicipalWorkAction.markReviewReady:
          final work = _work(current, command.workId!);
          if (work.status != WorkStatus.impactReady || work.impact == null) {
            fail(FailureCode.invalidTransition, 'Yayın öncesi etki analizi tamamlanmalıdır.');
          }
          WorkTransitionPolicy.requireAllowed(work.status, WorkStatus.reviewReady);
          final updated = _copyWork(work, status: WorkStatus.reviewReady, updatedAt: now);
          works = [for (final item in works) if (item.id == work.id) updated else item];
          resourceId = work.id;
          audits.add(_workAudit(
            id: 'audit_work_review_ready_${ordinal}_${work.id}',
            actorId: actor.id,
            activeRoleContext: actor.role.name,
            action: 'municipal_work_review_ready',
            resourceId: work.id,
            at: now,
            reason: 'Impact report accepted for human publication review',
            before: {'status': enumWire(work.status)},
            after: {'status': enumWire(updated.status), 'clientMutationId': command.clientMutationId},
          ));
          changed = true;
          break;
        case MunicipalWorkAction.publish:
          final work = _work(current, command.workId!);
          if (work.status != WorkStatus.reviewReady || work.impact == null) {
            fail(FailureCode.invalidTransition, 'Yalnız review-ready çalışma yayımlanabilir.');
          }
          WorkTransitionPolicy.requireAllowed(work.status, WorkStatus.publishedPlanned);
          final updated = _copyWork(
            work,
            status: WorkStatus.publishedPlanned,
            publicInformationText: command.publicInformationText!.trim(),
            publicPreviewApproved: true,
            publishedAt: now,
            updatedAt: now,
          );
          works = [for (final item in works) if (item.id == work.id) updated else item];
          resourceId = work.id;
          timeline.add(_workTimeline(
            id: 'timeline_work_published_${ordinal}_${work.id}',
            resourceId: work.id,
            type: 'municipal_work_published',
            at: now,
            publicMessageKey: 'timeline.municipal_work_published',
            detail: updated.publicInformationText,
          ));
          audits.add(_workAudit(
            id: 'audit_work_published_${ordinal}_${work.id}',
            actorId: actor.id,
            activeRoleContext: actor.role.name,
            action: 'municipal_work_published',
            resourceId: work.id,
            at: now,
            reason: 'Human approved public preview and publication',
            before: {'status': enumWire(work.status)},
            after: {
              'status': enumWire(updated.status),
              'publicPreviewApproved': true,
              'clientMutationId': command.clientMutationId,
            },
          ));
          changed = true;
          break;
        case MunicipalWorkAction.reconcileClock:
          final updatedWorks = <MunicipalWorkDto>[];
          for (final work in works) {
            var updated = work;
            final desired = MunicipalWorkProjection.effectiveStatus(work, now);
            if (desired != work.status) {
              try {
                final transitions = _clockTransitions(work.status, desired);
                for (final nextStatus in transitions) {
                  WorkTransitionPolicy.requireAllowed(updated.status, nextStatus);
                  final beforeStatus = updated.status;
                  updated = _copyWork(
                    updated,
                    status: nextStatus,
                    completedAt: nextStatus == WorkStatus.completed ? now : updated.completedAt,
                    updatedAt: now,
                  );
                  audits.add(_workAudit(
                    id: 'audit_work_clock_${ordinal}_${work.id}_${nextStatus.name}',
                    actorId: actor.id,
                    activeRoleContext: actor.role.name,
                    action: 'municipal_work_clock_transition',
                    resourceId: work.id,
                    at: now,
                    reason: 'DemoClock/app-resume deterministic transition',
                    before: {'status': enumWire(beforeStatus)},
                    after: {
                      'status': enumWire(nextStatus),
                      'clientMutationId': command.clientMutationId,
                    },
                  ));
                  timeline.add(_workTimeline(
                    id: 'timeline_work_clock_${ordinal}_${work.id}_${nextStatus.name}',
                    resourceId: work.id,
                    type: 'municipal_work_${nextStatus.name}',
                    at: now,
                    publicMessageKey: 'timeline.municipal_work_${nextStatus.name}',
                  ));
                  changed = true;
                }
              } on DomainFailure catch (error) {
                audits.add(_workAudit(
                  id: 'audit_work_clock_failure_${ordinal}_${work.id}',
                  actorId: actor.id,
                  activeRoleContext: actor.role.name,
                  action: 'admin_alert',
                  resourceId: work.id,
                  at: now,
                  reason: 'Municipal work automatic transition failed: ${error.message}',
                  before: {'status': enumWire(work.status)},
                  after: {
                    'desiredStatus': enumWire(desired),
                    'alertCode': 'municipal_work_transition_failed',
                    'clientMutationId': command.clientMutationId,
                  },
                ));
                changed = true;
              }
            }
            updatedWorks.add(updated);
          }
          works = updatedWorks;
          resourceId = 'work_clock';
          break;
        case MunicipalWorkAction.cancel:
          final work = _work(current, command.workId!);
          WorkTransitionPolicy.requireAllowed(work.status, WorkStatus.cancelled);
          final updated = _copyWork(work, status: WorkStatus.cancelled, updatedAt: now);
          works = [for (final item in works) if (item.id == work.id) updated else item];
          resourceId = work.id;
          audits.add(_workAudit(
            id: 'audit_work_cancel_${ordinal}_${work.id}',
            actorId: actor.id,
            activeRoleContext: actor.role.name,
            action: 'municipal_work_cancelled',
            resourceId: work.id,
            at: now,
            reason: command.reason!,
            before: {'status': enumWire(work.status)},
            after: {'status': enumWire(updated.status), 'clientMutationId': command.clientMutationId},
          ));
          changed = true;
          break;
      }

      if (!changed) {
        return MutationResult(
          snapshot: current,
          resourceId: resourceId,
          trackingNumber: null,
          replayed: true,
        );
      }
      _assertWorkInvariants(works);
      final next = codec.seal(
        current.copyWith(
          revision: current.revision + 1,
          updatedAt: now,
          checksum: 'sha256:unsealed',
          payload: current.payload.copyWith(
            municipalWorks: works,
            auditEvents: audits,
            timeline: timeline,
          ),
        ),
      );
      final committed = await store.write(next);
      return MutationResult(
        snapshot: committed,
        resourceId: resourceId,
        trackingNumber: null,
        replayed: false,
      );
    });
  }
}


List<WorkStatus> _clockTransitions(WorkStatus from, WorkStatus desired) {
  if (from == desired) return const [];
  if (from == WorkStatus.publishedPlanned && desired == WorkStatus.completed) {
    return const [WorkStatus.active, WorkStatus.completed];
  }
  return [desired];
}

MunicipalWorkDto _copyWork(
  MunicipalWorkDto work, {
  WorkStatus? status,
  MunicipalWorkImpactDto? impact,
  List<String>? affectedRoadSegments,
  List<String>? affectedTransitLines,
  String? publicInformationText,
  bool? publicPreviewApproved,
  DateTime? publishedAt,
  DateTime? completedAt,
  DateTime? updatedAt,
}) {
  return MunicipalWorkDto(
    id: work.id,
    status: status ?? work.status,
    category: work.category,
    latitude: work.latitude,
    longitude: work.longitude,
    startsAt: work.startsAt,
    expectedEndsAt: work.expectedEndsAt,
    responsibleUnitId: work.responsibleUnitId,
    explanation: work.explanation,
    areaRadiusMeters: work.areaRadiusMeters,
    affectedRoadSegments: affectedRoadSegments ?? work.affectedRoadSegments,
    affectedTransitLines: affectedTransitLines ?? work.affectedTransitLines,
    createdBy: work.createdBy,
    createdAt: work.createdAt,
    updatedAt: updatedAt ?? work.updatedAt,
    impact: impact ?? work.impact,
    publicInformationText: publicInformationText ?? work.publicInformationText,
    publicPreviewApproved: publicPreviewApproved ?? work.publicPreviewApproved,
    publishedAt: publishedAt ?? work.publishedAt,
    completedAt: completedAt ?? work.completedAt,
  );
}

UserAccount _workActor(AppSnapshotDto snapshot, String actorId) {
  for (final dto in snapshot.payload.accounts) {
    if (dto.id == actorId) {
      return UserAccount(
        id: dto.id,
        role: dto.role,
        permissions: dto.permissions,
        unitId: dto.unitId,
        deletionRequested: dto.deletionRequested,
      );
    }
  }
  fail(FailureCode.unauthorized, 'Demo hesabı bulunamadı.');
}

MunicipalWorkDto _work(AppSnapshotDto snapshot, String id) {
  final found = _findWorkOrNull(snapshot, id);
  if (found != null) return found;
  fail(FailureCode.notFound, 'Planlı çalışma bulunamadı.');
}

MunicipalWorkDto? _findWorkOrNull(AppSnapshotDto snapshot, String id) {
  for (final work in snapshot.payload.municipalWorks) {
    if (work.id == id) return work;
  }
  return null;
}

OpaqueEntityDto? _workMutationAudit(AppSnapshotDto snapshot, String mutationId) {
  for (final event in snapshot.payload.auditEvents) {
    final after = event.body['after'];
    if (after is Map<String, Object?> && after['clientMutationId'] == mutationId) return event;
  }
  return null;
}

String _uniqueWorkId(AppSnapshotDto snapshot, int ordinal) {
  final ids = snapshot.payload.municipalWorks.map((item) => item.id).toSet();
  var value = ordinal;
  while (true) {
    final id = 'work_demo_${value.toString().padLeft(6, '0')}';
    if (!ids.contains(id)) return id;
    value += 1;
  }
}

void _assertWorkInvariants(Iterable<MunicipalWorkDto> works) {
  final ids = <String>{};
  for (final work in works) {
    if (!ids.add(work.id)) fail(FailureCode.corruption, 'MunicipalWork ID tekil olmalıdır.');
    if ((work.status == WorkStatus.impactReady ||
            work.status == WorkStatus.reviewReady ||
            work.status == WorkStatus.publishedPlanned ||
            work.status == WorkStatus.active ||
            work.status == WorkStatus.completed) &&
        work.impact == null &&
        work.createdBy != null) {
      fail(FailureCode.corruption, 'Yeni planlı çalışma impact analizi olmadan ilerleyemez.');
    }
    if ((work.status == WorkStatus.publishedPlanned || work.status == WorkStatus.active) &&
        work.createdBy != null &&
        (!work.publicPreviewApproved || (work.publicInformationText?.trim().isEmpty ?? true))) {
      fail(FailureCode.corruption, 'Yayımlanmış çalışma insan onaylı public preview ister.');
    }
  }
}

OpaqueEntityDto _workAudit({
  required String id,
  required String actorId,
  required String activeRoleContext,
  required String action,
  required String resourceId,
  required DateTime at,
  required String reason,
  required JsonMap before,
  required JsonMap after,
}) =>
    OpaqueEntityDto(
      id: id,
      body: {
        'id': id,
        'actorId': actorId,
        'activeRoleContext': activeRoleContext,
        'action': action,
        'resourceId': resourceId,
        'at': at.toIso8601String(),
        'reason': reason,
        'before': before,
        'after': after,
      },
    );

OpaqueEntityDto _workTimeline({
  required String id,
  required String resourceId,
  required String type,
  required DateTime at,
  required String publicMessageKey,
  String? detail,
}) =>
    OpaqueEntityDto(
      id: id,
      body: {
        'id': id,
        'resourceId': resourceId,
        'type': type,
        'at': at.toIso8601String(),
        'publicMessageKey': publicMessageKey,
        if (detail != null) 'detail': detail,
      },
    );

bool _timeOverlaps(DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd) {
  return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
}

int _overlapMinutes(DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd) {
  final start = aStart.isAfter(bStart) ? aStart : bStart;
  final end = aEnd.isBefore(bEnd) ? aEnd : bEnd;
  return end.isAfter(start) ? end.difference(start).inMinutes : 0;
}

double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
  const radius = 6371000.0;
  final p1 = lat1 * math.pi / 180;
  final p2 = lat2 * math.pi / 180;
  final dp = (lat2 - lat1) * math.pi / 180;
  final dl = (lon2 - lon1) * math.pi / 180;
  final a = math.sin(dp / 2) * math.sin(dp / 2) +
      math.cos(p1) * math.cos(p2) * math.sin(dl / 2) * math.sin(dl / 2);
  return radius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double? _nullableNumber(Object? value, String path) {
  if (value == null) return null;
  if (value is! num) fail(FailureCode.validation, '$path sayı olmalıdır.', field: path);
  return (value as num).toDouble();
}

final class _ImpactReference {
  const _ImpactReference({
    required this.id,
    required this.kind,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.bufferMeters,
  });

  final String id;
  final String kind;
  final String name;
  final double latitude;
  final double longitude;
  final int bufferMeters;
}

const _impactReferences = <_ImpactReference>[
  _ImpactReference(
    id: 'road_uskudar_coastal_demo',
    kind: 'road_segment',
    name: 'Üsküdar sahil yol segmenti (demo geometri)',
    latitude: 41.0232,
    longitude: 29.0150,
    bufferMeters: 90,
  ),
  _ImpactReference(
    id: 'road_kadikoy_rasimpasa_demo',
    kind: 'road_segment',
    name: 'Kadıköy Rasimpaşa yol segmenti (demo geometri)',
    latitude: 40.9958,
    longitude: 29.0276,
    bufferMeters: 100,
  ),
  _ImpactReference(
    id: 'transit_m5_uskudar_demo',
    kind: 'transit_line',
    name: 'M5 Üsküdar çevresi hat bufferı (demo)',
    latitude: 41.0254,
    longitude: 29.0152,
    bufferMeters: 180,
  ),
  _ImpactReference(
    id: 'transit_marmaray_uskudar_demo',
    kind: 'transit_line',
    name: 'Marmaray Üsküdar çevresi bufferı (demo)',
    latitude: 41.0258,
    longitude: 29.0157,
    bufferMeters: 180,
  ),
];
