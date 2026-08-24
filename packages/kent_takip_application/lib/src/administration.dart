import 'dart:convert';

import 'package:kent_takip_application/src/commands.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';

abstract final class RolePermissionMatrix {
  static const Map<UserRole, Set<Permission>> byRole = {
    UserRole.guest: {Permission.viewPublicMap},
    UserRole.citizen: {Permission.viewPublicMap, Permission.submitReport, Permission.viewOwnReport},
    UserRole.reviewer: {Permission.viewPublicMap, Permission.viewReviewQueue, Permission.viewOriginalMedia, Permission.reviewReport, Permission.routeReport, Permission.mergeReport},
    UserRole.unitOfficer: {Permission.viewPublicMap, Permission.viewReviewQueue, Permission.viewOriginalMedia, Permission.manageFieldWork},
    UserRole.planner: {Permission.viewPublicMap, Permission.manageMunicipalWork},
    UserRole.systemAdmin: {Permission.viewPublicMap, Permission.manageSources, Permission.manageUsers, Permission.viewAudit, Permission.managePrivacyRequests, Permission.resetDemo},
    UserRole.demoSupervisor: {
      Permission.viewPublicMap,
      Permission.viewReviewQueue,
      Permission.viewOriginalMedia,
      Permission.reviewReport,
      Permission.routeReport,
      Permission.mergeReport,
      Permission.manageFieldWork,
      Permission.manageMunicipalWork,
      Permission.manageSources,
      Permission.manageUsers,
      Permission.viewAudit,
      Permission.managePrivacyRequests,
      Permission.resetDemo,
    },
  };

  static Set<Permission> permissionsFor(UserRole role) => Set.unmodifiable(byRole[role] ?? const {});

  static void requireAllowed(UserRole role, Iterable<Permission> permissions) {
    final allowed = byRole[role] ?? const <Permission>{};
    final forbidden = permissions.where((permission) => !allowed.contains(permission)).toList();
    if (forbidden.isNotEmpty) {
      fail(FailureCode.unauthorized, 'Rol dışı permission atanamaz: ${forbidden.map((e) => e.name).join(', ')}.');
    }
  }
}

enum GovernanceAlertKind { sourceHealth, securityDenied, automationFailure, privacyBacklog, restrictionAppeal }

final class GovernanceAlert {
  const GovernanceAlert({
    required this.kind,
    required this.resourceId,
    required this.message,
    required this.createdAt,
  });

  final GovernanceAlertKind kind;
  final String resourceId;
  final String message;
  final DateTime createdAt;
}

abstract final class AdministrationProjection {
  static List<GovernanceAlert> alerts(AppSnapshotDto snapshot, DateTime now) {
    final result = <GovernanceAlert>[];
    for (final health in snapshot.payload.dataSourceHealth) {
      final state = health.body['health']?.toString();
      if (state != 'stale' && state != 'unavailable' && state != 'quarantined') continue;
      result.add(GovernanceAlert(
        kind: GovernanceAlertKind.sourceHealth,
        resourceId: health.body['sourceId']?.toString() ?? health.id,
        message: 'Kaynak sağlığı: ${health.body['sourceId'] ?? health.id} · $state',
        createdAt: DateTime.tryParse(health.body['lastAttemptAt']?.toString() ?? '') ?? now,
      ));
    }
    for (final audit in snapshot.payload.auditEvents) {
      final action = audit.body['action']?.toString() ?? '';
      if (action.startsWith('denied_')) {
        result.add(GovernanceAlert(
          kind: GovernanceAlertKind.securityDenied,
          resourceId: audit.body['resourceId']?.toString() ?? audit.id,
          message: 'Yetki reddi audit olayı: $action',
          createdAt: DateTime.tryParse(audit.body['at']?.toString() ?? '') ?? now,
        ));
      } else if (action == 'admin_alert' &&
          (audit.body['after'] is Map) &&
          (audit.body['after'] as Map)['alertCode'] != null) {
        result.add(GovernanceAlert(
          kind: GovernanceAlertKind.automationFailure,
          resourceId: audit.body['resourceId']?.toString() ?? audit.id,
          message: 'Otomasyon uyarısı: ${(audit.body['after'] as Map)['alertCode']}',
          createdAt: DateTime.tryParse(audit.body['at']?.toString() ?? '') ?? now,
        ));
      }
    }
    for (final request in snapshot.payload.privacyRequests) {
      final status = request.body['status']?.toString();
      if (status != enumWire(PrivacyRequestStatus.received) && status != enumWire(PrivacyRequestStatus.inReview)) continue;
      result.add(GovernanceAlert(
        kind: GovernanceAlertKind.privacyBacklog,
        resourceId: request.id,
        message: 'Açık KVKK talebi: ${request.body['trackingNumber'] ?? request.id}',
        createdAt: DateTime.tryParse(request.body['createdAt']?.toString() ?? '') ?? now,
      ));
    }
    for (final restriction in snapshot.payload.restrictions) {
      if (restriction.body['appealStatus'] != 'human_review_required') continue;
      result.add(GovernanceAlert(
        kind: GovernanceAlertKind.restrictionAppeal,
        resourceId: restriction.id,
        message: 'Restriction itirazı insan incelemesi bekliyor.',
        createdAt: DateTime.tryParse(restriction.body['appealedAt']?.toString() ?? '') ?? now,
      ));
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List<GovernanceAlert>.unmodifiable(result);
  }
}

enum AdministrationAction {
  createPrivacyRequest,
  resolvePrivacyRequest,
  requestAccountDeletion,
  decideRestriction,
  appealRestriction,
  updateUserAccess,
}

final class AdministrationCommand {
  AdministrationCommand({
    required this.actorId,
    required this.clientMutationId,
    required this.expectedRevision,
    required this.action,
    required JsonMap payload,
  }) : payload = deepFreezeJson(payload, 'payload') as JsonMap {
    requireText(actorId, 'actorId');
    requireText(clientMutationId, 'clientMutationId');
    if (expectedRevision < 0) fail(FailureCode.validation, 'expectedRevision negatif olamaz.');
  }

  factory AdministrationCommand.fromJson(JsonMap json) => AdministrationCommand(
        actorId: expectString(json['actorId'], 'actorId'),
        clientMutationId: expectString(json['clientMutationId'], 'clientMutationId'),
        expectedRevision: expectInt(json['expectedRevision'], 'expectedRevision'),
        action: expectEnum(json['action'], 'action', enumValues(AdministrationAction.values)),
        payload: expectMap(json['payload'] ?? const <String, Object?>{}, 'payload'),
      );

  final String actorId;
  final String clientMutationId;
  final int expectedRevision;
  final AdministrationAction action;
  final JsonMap payload;

  JsonMap toJson() => {
        'actorId': actorId,
        'clientMutationId': clientMutationId,
        'expectedRevision': expectedRevision,
        'action': enumWire(action),
        'payload': payload,
      };
}

final class AdministrationProcessor {
  AdministrationProcessor({required this.processor});
  final SnapshotCommandProcessor processor;

  Future<MutationResult> execute(AdministrationCommand command) {
    return processor.transactionQueue.run(() async {
      final current = await processor.store.read();
      if (current.revision != command.expectedRevision) {
        throw CommandConflict(expectedRevision: command.expectedRevision, current: current);
      }
      final actor = _actor(current, command.actorId);
      final now = processor.clock.nowUtc();
      return switch (command.action) {
        AdministrationAction.createPrivacyRequest => _createPrivacy(current, command, actor, now),
        AdministrationAction.resolvePrivacyRequest => _resolvePrivacy(current, command, actor, now),
        AdministrationAction.requestAccountDeletion => _requestDeletion(current, command, actor, now),
        AdministrationAction.decideRestriction => _decideRestriction(current, command, actor, now),
        AdministrationAction.appealRestriction => _appealRestriction(current, command, actor, now),
        AdministrationAction.updateUserAccess => _updateUserAccess(current, command, actor, now),
      };
    });
  }

  Future<MutationResult> _createPrivacy(AppSnapshotDto current, AdministrationCommand command, UserAccount actor, DateTime now) async {
    if (actor.role != UserRole.citizen && actor.role != UserRole.demoSupervisor) {
      fail(FailureCode.unauthorized, 'KVKK talebi vatandaş bağlamında oluşturulmalıdır.');
    }
    final ownerId = command.payload['ownerId']?.toString() ?? actor.id;
    if (actor.role == UserRole.citizen && ownerId != actor.id) {
      fail(FailureCode.unauthorized, 'Başka vatandaş adına KVKK talebi açılamaz.');
    }
    final type = expectEnum(command.payload['type'], 'payload.type', enumValues(PrivacyRequestType.values));
    final note = expectString(command.payload['note'], 'payload.note');
    final ordinal = current.payload.privacyRequests.length + 1;
    final tracking = 'KV-${now.year}-${ordinal.toString().padLeft(6, '0')}';
    final id = 'privacy_${ordinal.toString().padLeft(6, '0')}';
    final request = OpaqueEntityDto(id: id, body: {
      'id': id,
      'ownerId': ownerId,
      'trackingNumber': tracking,
      'type': enumWire(type),
      'status': enumWire(PrivacyRequestStatus.received),
      'createdAt': now.toIso8601String(),
      'note': note,
      'appealRequiresHumanReview': true,
    });
    final payload = current.payload.copyWith(privacyRequests: [...current.payload.privacyRequests, request]);
    return _commit(current, payload, command, now, id, 'privacy_request_created', note, trackingNumber: tracking, extraAfter: {'type': enumWire(type), 'ownerId': ownerId});
  }

  Future<MutationResult> _resolvePrivacy(AppSnapshotDto current, AdministrationCommand command, UserAccount actor, DateTime now) async {
    AuthorizationPolicy.requirePermission(actor, Permission.managePrivacyRequests);
    final requestId = expectString(command.payload['requestId'], 'payload.requestId');
    final reason = expectString(command.payload['reason'], 'payload.reason');
    final accepted = command.payload['accepted'] == true;
    OpaqueEntityDto? existing;
    for (final item in current.payload.privacyRequests) {
      if (item.id == requestId) existing = item;
    }
    if (existing == null) fail(FailureCode.notFound, 'KVKK talebi bulunamadı.');
    final updated = OpaqueEntityDto(id: existing.id, body: {
      ...existing.body,
      'status': enumWire(accepted ? PrivacyRequestStatus.resolved : PrivacyRequestStatus.rejected),
      'resolvedAt': now.toIso8601String(),
      'resolvedBy': actor.id,
      'resolutionReason': reason,
    });
    final payload = current.payload.copyWith(privacyRequests: [for (final item in current.payload.privacyRequests) if (item.id == requestId) updated else item]);
    return _commit(current, payload, command, now, requestId, 'privacy_request_resolved', reason, trackingNumber: existing.body['trackingNumber']?.toString(), extraAfter: {'accepted': accepted});
  }

  Future<MutationResult> _requestDeletion(AppSnapshotDto current, AdministrationCommand command, UserAccount actor, DateTime now) async {
    if (actor.role != UserRole.citizen && actor.role != UserRole.demoSupervisor) {
      fail(FailureCode.unauthorized, 'Hesap silme vatandaş bağlamında başlatılır.');
    }
    final ownerId = command.payload['ownerId']?.toString() ?? actor.id;
    if (actor.role == UserRole.citizen && ownerId != actor.id) fail(FailureCode.unauthorized, 'Başka hesap silinemez.');
    if (command.payload['reauthVerified'] != true) fail(FailureCode.unauthorized, 'Hesap silme yeniden doğrulama ister.');
    if (command.payload['confirmed'] != true) fail(FailureCode.validation, 'Hesap silme etkileri açıkça onaylanmalıdır.');
    AccountDto? account;
    for (final item in current.payload.accounts) {
      if (item.id == ownerId) account = item;
    }
    if (account == null) fail(FailureCode.notFound, 'Hesap bulunamadı.');
    final updated = AccountDto(id: account.id, role: account.role, permissions: account.permissions, unitId: account.unitId, deletionRequested: true);
    final ordinal = current.payload.privacyRequests.length + 1;
    final tracking = 'KV-${now.year}-${ordinal.toString().padLeft(6, '0')}';
    final privacy = OpaqueEntityDto(id: 'privacy_delete_${ordinal.toString().padLeft(6, '0')}', body: {
      'id': 'privacy_delete_${ordinal.toString().padLeft(6, '0')}',
      'ownerId': ownerId,
      'trackingNumber': tracking,
      'type': enumWire(PrivacyRequestType.deletion),
      'status': enumWire(PrivacyRequestStatus.received),
      'createdAt': now.toIso8601String(),
      'note': 'Hesap silme talebi; gerçek hukuki imha demo dışında.',
      'reauthVerified': true,
    });
    final payload = current.payload.copyWith(
      accounts: [for (final item in current.payload.accounts) if (item.id == ownerId) updated else item],
      privacyRequests: [...current.payload.privacyRequests, privacy],
    );
    return _commit(current, payload, command, now, ownerId, 'account_deletion_requested', 'Yeniden doğrulanmış hesap silme talebi.', trackingNumber: tracking, extraAfter: {'deletionRequested': true, 'newReportBlocked': true});
  }

  Future<MutationResult> _decideRestriction(AppSnapshotDto current, AdministrationCommand command, UserAccount actor, DateTime now) async {
    AuthorizationPolicy.requirePermission(actor, Permission.manageUsers);
    final accountId = expectString(command.payload['accountId'], 'payload.accountId');
    final level = expectEnum(command.payload['level'], 'payload.level', enumValues(RestrictionLevel.values));
    final reason = expectString(command.payload['reason'], 'payload.reason');
    final previousLevel = _latestRestrictionLevel(current, accountId, now);
    final maxNextIndex = previousLevel == null ? 0 : RestrictionLevel.values.indexOf(previousLevel) + 1;
    if (RestrictionLevel.values.indexOf(level) > maxNextIndex) {
      fail(FailureCode.validation, 'Restriction yalnız kademeli olarak artırılabilir.');
    }
    if (level == RestrictionLevel.temporaryRestriction && command.payload['confirmedByHuman'] != true) {
      fail(FailureCode.validation, 'Geçici restriction insan ikinci onayı ister.');
    }
    if (!current.payload.accounts.any((e) => e.id == accountId)) fail(FailureCode.notFound, 'Restriction hesabı bulunamadı.');
    final id = 'restriction_${current.payload.restrictions.length + 1}';
    final expiresAt = level == RestrictionLevel.temporaryRestriction ? now.add(const Duration(hours: 24)) : null;
    final restriction = OpaqueEntityDto(id: id, body: {
      'id': id,
      'accountId': accountId,
      'level': enumWire(level),
      'reason': reason,
      'startsAt': now.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'decidedBy': actor.id,
      'decisionMode': 'human',
      'appealStatus': 'not_submitted',
      'permanent': false,
    });
    final payload = current.payload.copyWith(restrictions: [...current.payload.restrictions, restriction]);
    return _commit(current, payload, command, now, id, 'account_restriction_decided', reason, extraAfter: {'level': enumWire(level), 'accountId': accountId, 'permanent': false});
  }

  Future<MutationResult> _appealRestriction(AppSnapshotDto current, AdministrationCommand command, UserAccount actor, DateTime now) async {
    final restrictionId = expectString(command.payload['restrictionId'], 'payload.restrictionId');
    final reason = expectString(command.payload['reason'], 'payload.reason');
    OpaqueEntityDto? existing;
    for (final item in current.payload.restrictions) {
      if (item.id == restrictionId) existing = item;
    }
    if (existing == null) fail(FailureCode.notFound, 'Restriction bulunamadı.');
    final accountId = existing.body['accountId']?.toString();
    if (actor.id != accountId && !actor.permissions.contains(Permission.manageUsers)) {
      fail(FailureCode.unauthorized, 'Bu restriction için itiraz yetkiniz yok.');
    }
    final updated = OpaqueEntityDto(id: existing.id, body: {
      ...existing.body,
      'appealStatus': 'human_review_required',
      'appealedAt': now.toIso8601String(),
      'appealReason': reason,
      'appealedBy': actor.id,
    });
    final payload = current.payload.copyWith(restrictions: [for (final item in current.payload.restrictions) if (item.id == restrictionId) updated else item]);
    return _commit(current, payload, command, now, restrictionId, 'restriction_appealed', reason, extraAfter: {'humanReviewRequired': true});
  }

  Future<MutationResult> _updateUserAccess(AppSnapshotDto current, AdministrationCommand command, UserAccount actor, DateTime now) async {
    AuthorizationPolicy.requirePermission(actor, Permission.manageUsers);
    if (command.payload['secondConfirmation'] != true) fail(FailureCode.validation, 'Kritik yetki değişikliği ikinci onay ister.');
    final accountId = expectString(command.payload['accountId'], 'payload.accountId');
    final role = expectEnum(command.payload['role'], 'payload.role', enumValues(UserRole.values));
    final unitId = expectNullableString(command.payload['unitId'], 'payload.unitId');
    final permissionsRaw = expectList(command.payload['permissions'], 'payload.permissions');
    final permissions = [for (final item in permissionsRaw) expectEnum(item, 'payload.permissions', enumValues(Permission.values))];
    if (role == UserRole.demoSupervisor && accountId != 'usr_supervisor_demo_001') {
      fail(FailureCode.unauthorized, 'Demo supervisor rolü yalnız sabit demo hesabına atanabilir.');
    }
    RolePermissionMatrix.requireAllowed(role, permissions);
    AccountDto? existing;
    for (final item in current.payload.accounts) {
      if (item.id == accountId) existing = item;
    }
    if (existing == null) fail(FailureCode.notFound, 'Kullanıcı bulunamadı.');
    final updated = AccountDto(id: existing.id, role: role, permissions: permissions, unitId: unitId, deletionRequested: existing.deletionRequested);
    final payload = current.payload.copyWith(accounts: [for (final item in current.payload.accounts) if (item.id == accountId) updated else item]);
    return _commit(current, payload, command, now, accountId, 'user_access_updated', 'Rol/permission yönetimi ikinci onayla değiştirildi.', extraAfter: {'role': enumWire(role), 'permissions': permissions.map(enumWire).toList()});
  }

  Future<MutationResult> _commit(
    AppSnapshotDto current,
    SnapshotPayloadDto payload,
    AdministrationCommand command,
    DateTime now,
    String resourceId,
    String action,
    String reason, {
    String? trackingNumber,
    JsonMap extraAfter = const {},
  }) async {
    final auditId = 'audit_${action}_${current.revision + 1}_${now.microsecondsSinceEpoch}';
    final audit = OpaqueEntityDto(id: auditId, body: {
      'id': auditId,
      'actorId': command.actorId,
      'action': action,
      'resourceId': resourceId,
      'at': now.toIso8601String(),
      'reason': reason,
      'before': const <String, Object?>{},
      'after': {'clientMutationId': command.clientMutationId, 'activeRoleContext': _actor(current, command.actorId).role.name, ...extraAfter},
    });
    final next = processor.codec.seal(current.copyWith(
      revision: current.revision + 1,
      updatedAt: now,
      checksum: 'sha256:unsealed',
      payload: payload.copyWith(auditEvents: [...payload.auditEvents, audit]),
    ));
    final committed = await processor.store.write(next);
    return MutationResult(snapshot: committed, resourceId: resourceId, trackingNumber: trackingNumber, replayed: false);
  }
}

abstract final class AuditExport {
  static String toCsv(Iterable<OpaqueEntityDto> events) {
    final buffer = StringBuffer('id,at,actorId,activeRoleContext,action,resourceId,reason,before,after\n');
    for (final event in events) {
      final body = event.body;
      buffer.writeln([
        event.id,
        body['at'] ?? '',
        body['actorId'] ?? '',
        body['activeRoleContext'] ?? ((body['after'] is Map) ? (body['after'] as Map)['activeRoleContext'] ?? '' : ''),
        body['action'] ?? '',
        body['resourceId'] ?? '',
        body['reason'] ?? '',
        jsonEncode(body['before'] ?? const <String, Object?>{}),
        jsonEncode(body['after'] ?? const <String, Object?>{}),
      ].map(_csv).join(','));
    }
    return buffer.toString();
  }

  static String toJson(Iterable<OpaqueEntityDto> events) => const JsonEncoder.withIndent('  ').convert(events.map((e) => e.toJson()).toList());
}

RestrictionLevel? _latestRestrictionLevel(
  AppSnapshotDto snapshot,
  String accountId,
  DateTime now,
) {
  for (final item in snapshot.payload.restrictions.reversed) {
    if (item.body['accountId'] != accountId) continue;
    final expiresAt = DateTime.tryParse(item.body['expiresAt']?.toString() ?? '');
    if (expiresAt != null && !now.isBefore(expiresAt)) continue;
    final raw = item.body['level'];
    if (raw == null) continue;
    return expectEnum(raw, 'restriction.level', enumValues(RestrictionLevel.values));
  }
  return null;
}

UserAccount _actor(AppSnapshotDto snapshot, String id) {
  for (final dto in snapshot.payload.accounts) {
    if (dto.id == id) {
      return UserAccount(id: dto.id, role: dto.role, permissions: dto.permissions, unitId: dto.unitId, deletionRequested: dto.deletionRequested);
    }
  }
  fail(FailureCode.unauthorized, 'Demo hesabı bulunamadı.');
}

String _csv(Object? value) {
  final text = value?.toString() ?? '';
  return '"' + text.replaceAll('"', '""') + '"';
}
