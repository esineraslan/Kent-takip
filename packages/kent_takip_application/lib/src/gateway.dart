import 'dart:async';
import 'dart:typed_data';

import 'package:kent_takip_application/src/commands.dart';
import 'package:kent_takip_application/src/staff_commands.dart';
import 'package:kent_takip_application/src/field_operations.dart';
import 'package:kent_takip_application/src/municipal_work.dart';
import 'package:kent_takip_application/src/source_governance.dart';
import 'package:kent_takip_application/src/administration.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:kent_takip_persistence/kent_takip_persistence.dart';

abstract interface class DemoDataGateway {
  bool get lastReadWasOfflineCache;

  Future<AppSnapshotDto> fetchSnapshot();

  Stream<int> watchRevisions();

  Future<MutationResult> createReport(CreateReportCommand command);

  Future<MutationResult> verifyReport(VerifyReportCommand command);

  Future<MutationResult> reviewLease(ReviewLeaseCommand command);

  Future<MutationResult> staffDecision(StaffDecisionCommand command);

  Future<MutationResult> citizenAction(CitizenActionCommand command);

  Future<MutationResult> fieldOperation(FieldOperationCommand command);

  Future<MutationResult> municipalWork(MunicipalWorkCommand command);

  Future<MutationResult> sourceOperation(SourceOperationCommand command);

  Future<MutationResult> administration(AdministrationCommand command);

  Future<void> putMedia(String id, Uint8List bytes);

  Future<Uint8List?> getMedia(
    String id, {
    String reason = 'application_media_access',
    String? actorId,
  });

  Future<void> close();
}

final class LocalDemoDataGateway implements DemoDataGateway {
  LocalDemoDataGateway({
    required this.store,
    required this.mediaStore,
    required this.processor,
  });

  final SnapshotStore store;
  final MediaStore mediaStore;
  final SnapshotCommandProcessor processor;
  final StreamController<int> _revisions = StreamController<int>.broadcast();

  @override
  bool get lastReadWasOfflineCache => false;

  @override
  Future<void> close() => _revisions.close();

  @override
  Future<MutationResult> createReport(CreateReportCommand command) async {
    final result = await processor.createReport(command);
    if (!result.replayed) _revisions.add(result.snapshot.revision);
    return result;
  }

  @override
  Future<MutationResult> citizenAction(CitizenActionCommand command) async {
    final result = await processor.citizenAction(command);
    if (!result.replayed) _revisions.add(result.snapshot.revision);
    return result;
  }

  @override
  Future<AppSnapshotDto> fetchSnapshot() => store.read();

  @override
  Future<MutationResult> fieldOperation(FieldOperationCommand command) async {
    final result = await processor.fieldOperation(command);
    if (!result.replayed) _revisions.add(result.snapshot.revision);
    return result;
  }

  @override
  Future<MutationResult> municipalWork(MunicipalWorkCommand command) async {
    final result = await processor.municipalWork(command);
    if (!result.replayed) _revisions.add(result.snapshot.revision);
    return result;
  }

  @override
  Future<Uint8List?> getMedia(
    String id, {
    String reason = 'application_media_access',
    String? actorId,
  }) async {
    if (actorId != null) {
      final updated = await processor.recordOriginalMediaAccess(
        actorId: actorId,
        mediaId: id,
        reason: reason,
      );
      _revisions.add(updated.revision);
    }
    return mediaStore.get(id);
  }

  @override
  Future<void> putMedia(String id, Uint8List bytes) => mediaStore.put(id, bytes);


  @override
  Future<MutationResult> reviewLease(ReviewLeaseCommand command) async {
    final result = await processor.reviewLease(command);
    if (!result.replayed) _revisions.add(result.snapshot.revision);
    return result;
  }

  @override
  Future<MutationResult> staffDecision(StaffDecisionCommand command) async {
    final result = await processor.staffDecision(command);
    if (!result.replayed) _revisions.add(result.snapshot.revision);
    return result;
  }

  @override
  Future<MutationResult> verifyReport(VerifyReportCommand command) async {
    final result = await processor.verifyReport(command);
    if (!result.replayed) _revisions.add(result.snapshot.revision);
    return result;
  }


  @override
  Future<MutationResult> sourceOperation(SourceOperationCommand command) async {
    final result = await SourceGovernanceProcessor(processor: processor).execute(command);
    if (!result.replayed) _revisions.add(result.snapshot.revision);
    return result;
  }

  @override
  Future<MutationResult> administration(AdministrationCommand command) async {
    final result = await AdministrationProcessor(processor: processor).execute(command);
    if (!result.replayed) _revisions.add(result.snapshot.revision);
    return result;
  }
  @override
  Stream<int> watchRevisions() => _revisions.stream;
}
