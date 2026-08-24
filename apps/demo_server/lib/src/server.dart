import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:kent_takip_application/kent_takip_application.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:kent_takip_persistence/kent_takip_persistence.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final class KentTakipDemoServer {
  KentTakipDemoServer({
    required this.store,
    required this.mediaStore,
    required this.codec,
    required this.clock,
  }) : processor = SnapshotCommandProcessor(
         store: store,
         codec: codec,
         clock: clock,
       ),
       _sessionEpoch = clock.nowUtc();

  final SnapshotStore store;
  final MediaStore mediaStore;
  final SnapshotCodec codec;
  final Clock clock;
  final SnapshotCommandProcessor processor;
  final DateTime _sessionEpoch;
  int _failedBearerAttempts = 0;
  final Set<WebSocketChannel> _sockets = {};

  Handler get handler {
    final router = Router()
      ..get('/health/live', _live)
      ..get('/health/ready', _ready)
      ..get('/v1/snapshot', _snapshot)
      ..post('/v1/commands/report', _createReport)
      ..post('/v1/commands/verify', _verifyReport)
      ..post('/v1/commands/review-lease', _reviewLease)
      ..post('/v1/commands/staff-decision', _staffDecision)
      ..post('/v1/commands/citizen-action', _citizenAction)
      ..post('/v1/commands/field-operation', _fieldOperation)
      ..post('/v1/commands/municipal-work', _municipalWork)
      ..post('/v1/commands/source-operation', _sourceOperation)
      ..post('/v1/commands/administration', _administration)
      ..put('/v1/media/<mediaId>', _putMedia)
      ..get('/v1/media/<mediaId>', _getMedia)
      ..get('/v1/public-media/<mediaId>', _getPublicMedia)
      ..get('/v1/revisions', _revisionSocket)
      ..options('/<ignored|.*>', _options);
    return const Pipeline()
        .addMiddleware(_securityHeaders())
        .addMiddleware(_cors())
        .addMiddleware(_requestSafety())
        .addHandler(router.call);
  }

  Response _live(Request request) => _json(200, {'status': 'live'});

  Future<Response> _ready(Request request) async {
    try {
      final snapshot = await store.read();
      return _json(200, {
        'status': 'ready',
        'schemaVersion': snapshot.schemaVersion,
        'revision': snapshot.revision,
      });
    } on Object {
      return _json(503, {'status': 'not_ready'});
    }
  }

  Future<Response> _snapshot(Request request) async {
    final actor = await _authenticate(request, allowGuest: true);
    final snapshot = await store.read();
    return _json(200, _authorizedSnapshot(snapshot, actor).toJson(), headers: {
      'etag': '"revision-${snapshot.revision}"',
    });
  }

  Future<Response> _createReport(Request request) async {
    _Actor? actor;
    try {
      actor = await _authenticate(request);
      final command = CreateReportCommand.fromJson(await _body(request));
      if (command.actorId != actor.accountId) {
        fail(FailureCode.unauthorized, 'Komut aktörü oturumla eşleşmiyor.');
      }
      for (final media in command.media) {
        for (final ref in [media.originalRef, media.publicRef]) {
          if (ref == null) continue;
          final id = validateMediaId(ref.substring('media://'.length));
          if (await mediaStore.get(id) == null) {
            fail(FailureCode.validation, 'Komuttaki medya sunucuya yüklenmemiş.');
          }
        }
      }
      final result = await processor.createReport(command);
      if (!result.replayed) _broadcast(result.snapshot.revision);
      return _json(result.replayed ? 200 : 201, result.toJson());
    } on CommandConflict catch (error) {
      return _conflict(error, actor);
    } on DomainFailure catch (error) {
      return _domainFailure(
        error,
        actor: actor,
        action: 'create_report',
        resourceId: 'new_report',
      );
    }
  }

  Future<Response> _verifyReport(Request request) async {
    _Actor? actor;
    String resourceId = 'unknown_report';
    try {
      actor = await _authenticate(request);
      final command = VerifyReportCommand.fromJson(await _body(request));
      resourceId = command.reportId;
      if (command.actorId != actor.accountId) {
        fail(FailureCode.unauthorized, 'Komut aktörü oturumla eşleşmiyor.');
      }
      final result = await processor.verifyReport(command);
      if (!result.replayed) _broadcast(result.snapshot.revision);
      return _json(200, result.toJson());
    } on CommandConflict catch (error) {
      return _conflict(error, actor);
    } on DomainFailure catch (error) {
      return _domainFailure(
        error,
        actor: actor,
        action: 'verify_report',
        resourceId: resourceId,
      );
    }
  }


  Future<Response> _reviewLease(Request request) async {
    _Actor? actor;
    String resourceId = 'unknown_report';
    try {
      actor = await _authenticate(request);
      final command = ReviewLeaseCommand.fromJson(await _body(request));
      resourceId = command.reportId;
      if (command.actorId != actor.accountId) {
        fail(FailureCode.unauthorized, 'Komut aktörü oturumla eşleşmiyor.');
      }
      final result = await processor.reviewLease(command);
      if (!result.replayed) _broadcast(result.snapshot.revision);
      return _json(200, result.toJson());
    } on CommandConflict catch (error) {
      return _conflict(error, actor);
    } on DomainFailure catch (error) {
      return _domainFailure(
        error,
        actor: actor,
        action: 'review_lease',
        resourceId: resourceId,
      );
    }
  }

  Future<Response> _staffDecision(Request request) async {
    _Actor? actor;
    String resourceId = 'unknown_report';
    try {
      actor = await _authenticate(request);
      final command = StaffDecisionCommand.fromJson(await _body(request));
      resourceId = command.reportId;
      if (command.actorId != actor.accountId) {
        fail(FailureCode.unauthorized, 'Komut aktörü oturumla eşleşmiyor.');
      }
      final result = await processor.staffDecision(command);
      if (!result.replayed) _broadcast(result.snapshot.revision);
      return _json(200, result.toJson());
    } on CommandConflict catch (error) {
      return _conflict(error, actor);
    } on DomainFailure catch (error) {
      return _domainFailure(
        error,
        actor: actor,
        action: 'staff_decision',
        resourceId: resourceId,
      );
    }
  }

  Future<Response> _citizenAction(Request request) async {
    _Actor? actor;
    String resourceId = 'unknown';
    try {
      actor = await _authenticate(request);
      final command = CitizenActionCommand.fromJson(await _body(request));
      resourceId = command.resourceId;
      if (command.actorId != actor.accountId) {
        fail(FailureCode.unauthorized, 'Komut aktörü oturumla eşleşmiyor.');
      }
      final result = await processor.citizenAction(command);
      if (!result.replayed) _broadcast(result.snapshot.revision);
      return _json(200, result.toJson());
    } on CommandConflict catch (error) {
      return _conflict(error, actor);
    } on DomainFailure catch (error) {
      return _domainFailure(
        error,
        actor: actor,
        action: 'citizen_action',
        resourceId: resourceId,
      );
    }
  }

  Future<Response> _fieldOperation(Request request) async {
    _Actor? actor;
    String resourceId = 'unknown_incident';
    try {
      actor = await _authenticate(request);
      final command = FieldOperationCommand.fromJson(await _body(request));
      resourceId = command.incidentId;
      if (command.actorId != actor.accountId) {
        fail(FailureCode.unauthorized, 'Komut aktörü oturumla eşleşmiyor.');
      }
      final result = await processor.fieldOperation(command);
      if (!result.replayed) _broadcast(result.snapshot.revision);
      return _json(200, result.toJson());
    } on CommandConflict catch (error) {
      return _conflict(error, actor);
    } on DomainFailure catch (error) {
      return _domainFailure(error, actor: actor, action: 'field_operation', resourceId: resourceId);
    }
  }

  Future<Response> _municipalWork(Request request) async {
    _Actor? actor;
    String resourceId = 'municipal_work';
    try {
      actor = await _authenticate(request);
      final command = MunicipalWorkCommand.fromJson(await _body(request));
      resourceId = command.workId ?? resourceId;
      if (command.actorId != actor.accountId) {
        fail(FailureCode.unauthorized, 'Komut aktörü oturumla eşleşmiyor.');
      }
      final result = await processor.municipalWork(command);
      if (!result.replayed) _broadcast(result.snapshot.revision);
      return _json(200, result.toJson());
    } on CommandConflict catch (error) {
      return _conflict(error, actor);
    } on DomainFailure catch (error) {
      return _domainFailure(error, actor: actor, action: 'municipal_work', resourceId: resourceId);
    }
  }

  Future<Response> _sourceOperation(Request request) async {
    _Actor? actor;
    String resourceId = 'source_operation';
    try {
      actor = await _authenticate(request);
      final command = SourceOperationCommand.fromJson(await _body(request));
      resourceId = command.payload['sourceId']?.toString() ?? command.action.name;
      if (command.actorId != actor.accountId) {
        fail(FailureCode.unauthorized, 'Komut aktörü oturumla eşleşmiyor.');
      }
      final result = await SourceGovernanceProcessor(processor: processor).execute(command);
      if (!result.replayed) _broadcast(result.snapshot.revision);
      return _json(200, result.toJson());
    } on CommandConflict catch (error) {
      return _conflict(error, actor);
    } on DomainFailure catch (error) {
      return _domainFailure(error, actor: actor, action: 'source_operation', resourceId: resourceId);
    }
  }

  Future<Response> _administration(Request request) async {
    _Actor? actor;
    String resourceId = 'administration';
    try {
      actor = await _authenticate(request);
      final command = AdministrationCommand.fromJson(await _body(request));
      resourceId = command.payload['accountId']?.toString() ??
          command.payload['requestId']?.toString() ??
          command.payload['restrictionId']?.toString() ??
          command.action.name;
      if (command.actorId != actor.accountId) {
        fail(FailureCode.unauthorized, 'Komut aktörü oturumla eşleşmiyor.');
      }
      final result = await AdministrationProcessor(processor: processor).execute(command);
      if (!result.replayed) _broadcast(result.snapshot.revision);
      return _json(200, result.toJson());
    } on CommandConflict catch (error) {
      return _conflict(error, actor);
    } on DomainFailure catch (error) {
      return _domainFailure(error, actor: actor, action: 'administration', resourceId: resourceId);
    }
  }

  Future<Response> _putMedia(Request request, String mediaId) async {
    _Actor? actor;
    try {
      actor = await _authenticate(request);
      final snapshot = await store.read();
      final account = _account(snapshot, actor.accountId);
      AuthorizationPolicy.requirePermission(account, Permission.submitReport);
      validateMediaId(mediaId);
      if (!mediaId.startsWith('media_${actor.accountId}_')) {
        fail(
          FailureCode.unauthorized,
          'Medya ID kimliği oturum sahibinin namespace alanında olmalıdır.',
        );
      }
      const limit = 8 * 1024 * 1024;
      final builder = BytesBuilder(copy: false);
      await for (final chunk in request.read()) {
        if (builder.length + chunk.length > limit) {
          fail(FailureCode.validation, 'Medya 8 MB sınırını aşıyor.');
        }
        builder.add(chunk);
      }
      final incoming = builder.takeBytes();
      final existing = await mediaStore.get(mediaId);
      if (existing != null) {
        if (!_sameBytes(existing, incoming)) {
          fail(FailureCode.conflict, 'Var olan medya immutable kabul edilir.');
        }
        return Response(204, headers: {'x-idempotent-replay': 'true'});
      }
      await mediaStore.put(mediaId, incoming);
      return Response(204);
    } on DomainFailure catch (error) {
      return _domainFailure(
        error,
        actor: actor,
        action: 'media_upload',
        resourceId: mediaId,
      );
    }
  }

  Future<Response> _getMedia(Request request, String mediaId) async {
    _Actor? actor;
    try {
      actor = await _authenticate(request);
      final snapshot = await store.read();
      final account = _account(snapshot, actor.accountId);
      AuthorizationPolicy.requirePermission(account, Permission.viewOriginalMedia);
      final reason = request.url.queryParameters['reason']?.trim() ?? '';
      if (reason.length < 8 || reason.length > 240) {
        fail(FailureCode.validation, 'Orijinal medya erişim gerekçesi zorunludur.');
      }
      final validatedId = validateMediaId(mediaId);
      final bytes = await mediaStore.get(validatedId);
      if (bytes == null) return _json(404, {'code': 'not_found'});
      final audited = await processor.recordOriginalMediaAccess(
        actorId: actor.accountId,
        mediaId: validatedId,
        reason: reason,
      );
      _broadcast(audited.revision);
      return Response.ok(
        bytes,
        headers: {'content-type': 'application/octet-stream'},
      );
    } on DomainFailure catch (error) {
      return _domainFailure(
        error,
        actor: actor,
        action: 'original_media_access',
        resourceId: mediaId,
      );
    }
  }

  Future<Response> _getPublicMedia(Request request, String mediaId) async {
    await _authenticate(request, allowGuest: true);
    final validatedId = validateMediaId(mediaId);
    final snapshot = await store.read();
    final visible = snapshot.payload.media.any(
      (item) => item.privacyStatus == PrivacyStatus.safe &&
          item.publicRef == 'media://$validatedId',
    );
    if (!visible) return _json(404, {'code': 'not_found'});
    final bytes = await mediaStore.get(validatedId);
    if (bytes == null) return _json(404, {'code': 'not_found'});
    return Response.ok(bytes, headers: {
      'content-type': 'application/octet-stream',
      'cache-control': 'private, max-age=60',
    });
  }

  Future<Response> _revisionSocket(Request request) async {
    final actor = await _authenticate(request, allowQueryToken: true);
    if (actor.guest) return _json(401, {'code': 'authentication_required'});
    final socketHandler = webSocketHandler((socket, protocol) {
      _sockets.add(socket);
      unawaited(
        store.read().then((snapshot) {
          socket.sink.add(jsonEncode({
            'type': 'revision',
            'revision': snapshot.revision,
          }));
        }),
      );
      socket.stream.listen(
        (_) {},
        onDone: () => _sockets.remove(socket),
        onError: (_, _) => _sockets.remove(socket),
        cancelOnError: true,
      );
    });
    return socketHandler(request);
  }

  Response _options(Request request, String ignored) => Response(204);

  Future<Response> _conflict(CommandConflict error, _Actor? actor) async {
    return _json(409, {
      'code': 'revision_conflict',
      'expectedRevision': error.expectedRevision,
      'currentRevision': error.current.revision,
      'current': _authorizedSnapshot(error.current, actor ?? _Actor.guest()).toJson(),
      'retryable': true,
    });
  }

  Future<Response> _domainFailure(
    DomainFailure error, {
    required _Actor? actor,
    required String action,
    required String resourceId,
  }) async {
    if (error.code == FailureCode.unauthorized) {
      try {
        final updated = await processor.recordDenied(
          actorId: actor?.accountId ?? 'anonymous',
          action: action,
          resourceId: resourceId,
          reason: error.message,
        );
        _broadcast(updated.revision);
      } on Object {
        // Yetki reddi yanıtı audit depolama hatasında da fail-closed kalır.
      }
    }
    final status = switch (error.code) {
      FailureCode.unauthorized || FailureCode.privacy => 403,
      FailureCode.notFound => 404,
      FailureCode.conflict => 409,
      FailureCode.validation || FailureCode.invalidTransition => 422,
      _ => 500,
    };
    return _json(status, {
      'code': enumWire(error.code),
      'message': _safeFailureMessage(error.code),
      'field': error.field,
      'retryable': error.retryable,
    });
  }

  Future<_Actor> _authenticate(
    Request request, {
    bool allowGuest = false,
    bool allowQueryToken = false,
  }) async {
    final authorization = request.headers['authorization'];
    final headerToken = authorization?.startsWith('Bearer ') ?? false
        ? authorization!.substring('Bearer '.length)
        : null;
    final token = headerToken ??
        (allowQueryToken ? request.url.queryParameters['token'] : null);
    final authenticatedToken = token == 'demo-citizen-001' ||
        token == 'demo-citizen-002' ||
        token == 'demo-citizen-003' ||
        token == 'demo-staff-supervisor';
    if (authenticatedToken &&
        clock.nowUtc().difference(_sessionEpoch) > const Duration(hours: 8)) {
      fail(FailureCode.unauthorized, 'Demo sunucu oturumu sona erdi.');
    }
    if (authenticatedToken) _failedBearerAttempts = 0;
    if (token == 'demo-citizen-001') {
      return const _Actor('usr_citizen_demo_001');
    }
    if (token == 'demo-citizen-002') {
      return const _Actor('usr_citizen_demo_002');
    }
    if (token == 'demo-citizen-003') {
      return const _Actor('usr_citizen_demo_003');
    }
    if (token == 'demo-staff-supervisor') {
      return const _Actor('usr_supervisor_demo_001');
    }
    if (allowGuest && (token == null || token == 'demo-guest')) {
      return const _Actor.guest();
    }
    _failedBearerAttempts += 1;
    final delayMs = (_failedBearerAttempts * 100).clamp(100, 1000);
    await Future<void>.delayed(Duration(milliseconds: delayMs));
    fail(FailureCode.unauthorized, 'Geçerli demo bearer token gerekli.');
  }

  AppSnapshotDto _authorizedSnapshot(AppSnapshotDto snapshot, _Actor actor) {
    if (!actor.guest) {
      final account = _account(snapshot, actor.accountId);
      if (account.role == UserRole.demoSupervisor) return snapshot;
      if (account.role != UserRole.citizen && account.role != UserRole.guest) {
        return _staffSnapshot(snapshot, account);
      }
    }
    final reports = actor.guest
        ? const <CitizenReportDto>[]
        : snapshot.payload.reports
              .where((report) => report.ownerId == actor.accountId)
              .map(
                (report) => CitizenReportDto(
                  id: report.id,
                  trackingNumber: report.trackingNumber,
                  ownerId: report.ownerId,
                  status: report.status,
                  category: report.category,
                  latitude: report.latitude,
                  longitude: report.longitude,
                  createdAt: report.createdAt,
                  updatedAt: report.updatedAt,
                  clientMutationId: report.clientMutationId,
                  mediaIds: report.mediaIds,
                  analysisId: report.analysisId,
                  linkedIncidentId: report.linkedIncidentId,
                  manualReviewRequired: report.manualReviewRequired,
                  riskLevel: report.riskLevel,
                  // Internal reviewer rationale never crosses the citizen boundary.
                  humanDecisionReason: null,
                  resolutionExplanation: report.resolutionExplanation,
                  resolvedAt: report.resolvedAt,
                  resolutionPublicMediaRef: report.resolutionPublicMediaRef,
                ),
              )
              .toList(growable: false);
    final visibleReportIds = reports.map((report) => report.id).toSet();
    final visibleMediaIds = reports
        .expand((report) => [
          ...report.mediaIds,
          if (report.resolutionPublicMediaRef != null)
            report.resolutionPublicMediaRef!,
        ])
        .toSet();
    final visibleAnalysisIds = reports
        .map((report) => report.analysisId)
        .whereType<String>()
        .toSet();
    final projectedIncidents = <UrbanIncidentDto>[];
    final syntheticRecords = <OpaqueEntityDto>[];
    for (final incident in snapshot.payload.incidents) {
      final sensitiveLocation = snapshot.payload.sourceRecords.any(
        (record) => incident.sourceRecordIds.contains(record.id) &&
            record.body['sensitiveLocation'] == true,
      );
      final visibleIncidentReports = incident.reportIds
          .where(visibleReportIds.contains)
          .toList(growable: false);
      final sourceIds = [...incident.sourceRecordIds];
      if (visibleIncidentReports.isEmpty && sourceIds.isEmpty) {
        final syntheticId = 'src_projection_${incident.id}';
        sourceIds.add(syntheticId);
        syntheticRecords.add(
          OpaqueEntityDto(
            id: syntheticId,
            body: {
              'id': syntheticId,
              'sourceId': 'public_projection',
              'externalId': incident.id,
              'authorityId': 'authority_public_projection',
              'health': enumWire(SourceHealth.fresh),
              'sourceUpdatedAt': incident.updatedAt.toIso8601String(),
              'ingestedAt': snapshot.updatedAt.toIso8601String(),
              'licenseId': 'internal-demo-projection',
              'attribution': 'İBB Kent Takip doğrulanmış olay projeksiyonu',
            },
          ),
        );
      }
      projectedIncidents.add(
        UrbanIncidentDto(
          id: incident.id,
          status: incident.status,
          category: incident.category,
          latitude: _publicCoordinate(incident.latitude, sensitiveLocation),
          longitude: _publicCoordinate(incident.longitude, sensitiveLocation),
          reportIds: visibleIncidentReports,
          sourceRecordIds: sourceIds,
          createdAt: incident.createdAt,
          updatedAt: incident.updatedAt,
          responsibleUnitId: incident.responsibleUnitId,
          resolutionExplanation: incident.resolutionExplanation,
          resolvedAt: incident.resolvedAt,
        ),
      );
    }
    final authorities = [
      ...snapshot.payload.sourceAuthorities,
      if (syntheticRecords.isNotEmpty &&
          !snapshot.payload.sourceAuthorities
              .any((item) => item.id == 'authority_public_projection'))
        OpaqueEntityDto(
          id: 'authority_public_projection',
          body: {
            'id': 'authority_public_projection',
            'displayName': 'Kent Takip doğrulanmış olay projeksiyonu',
            'rank': enumWire(SourceAuthorityRank.ibbApproved),
            'officialAlertAuthority': false,
          },
        ),
    ];
    final visibleResources = <String>{
      ...reports.map((report) => report.id),
      ...snapshot.payload.incidents.map((incident) => incident.id),
      ...snapshot.payload.municipalWorks.map((work) => work.id),
    };
    final accounts = actor.guest
        ? const <AccountDto>[]
        : snapshot.payload.accounts
              .where((account) => account.id == actor.accountId)
              .toList(growable: false);
    return codec.seal(
      snapshot.copyWith(
        checksum: 'sha256:unsealed',
        payload: snapshot.payload.copyWith(
          accounts: accounts,
          reports: reports,
          media: snapshot.payload.media
              .where((item) => visibleMediaIds.contains(item.id))
              .map(
                (item) => MediaRefDto(
                  id: item.id,
                  privacyStatus: item.privacyStatus,
                  originalRef: null,
                  publicRef: item.privacyStatus == PrivacyStatus.safe
                      ? item.publicRef
                      : null,
                  mimeType: item.mimeType,
                ),
              )
              .toList(growable: false),
          analyses: snapshot.payload.analyses
              .where((item) => visibleAnalysisIds.contains(item.id))
              .map(
                (item) => AiAnalysisDto(
                  id: item.id,
                  status: item.status,
                  reasonCodes: item.reasonCodes
                      .where((code) =>
                          code.startsWith('category:') ||
                          code.startsWith('privacy:'))
                      .toList(growable: false),
                  modelVersion: 'citizen-projection',
                  configVersion: item.configVersion,
                  createdAt: item.createdAt,
                ),
              )
              .toList(growable: false),
          incidents: projectedIncidents,
          sourceAuthorities: authorities,
          sourceRecords: [
            ...snapshot.payload.sourceRecords,
            ...syntheticRecords,
          ],
          timeline: snapshot.payload.timeline
              .where((event) => visibleResources.contains(event.body['resourceId']))
              .toList(growable: false),
          notifications: actor.guest
              ? const <OpaqueEntityDto>[]
              : snapshot.payload.notifications
                    .where((item) => item.body['recipientId'] == actor.accountId)
                    .toList(growable: false),
          auditEvents: const [],
          corroborations: const [],
          privacyRequests: actor.guest
              ? const <OpaqueEntityDto>[]
              : snapshot.payload.privacyRequests
                  .where((item) => item.body['ownerId'] == actor.accountId)
                  .toList(growable: false),
          restrictions: actor.guest
              ? const <OpaqueEntityDto>[]
              : snapshot.payload.restrictions
                  .where((item) => item.body['accountId'] == actor.accountId)
                  .toList(growable: false),
        ),
      ),
    );
  }

  AppSnapshotDto _staffSnapshot(AppSnapshotDto snapshot, UserAccount account) {
    final canOriginal = account.permissions.contains(Permission.viewOriginalMedia);
    final canUsers = account.permissions.contains(Permission.manageUsers);
    final canAudit = account.permissions.contains(Permission.viewAudit);
    final canPrivacy = account.permissions.contains(Permission.managePrivacyRequests);
    final canSources = account.permissions.contains(Permission.manageSources);
    return codec.seal(
      snapshot.copyWith(
        checksum: 'sha256:unsealed',
        payload: snapshot.payload.copyWith(
          accounts: canUsers
              ? snapshot.payload.accounts
              : snapshot.payload.accounts.where((item) => item.id == account.id).toList(growable: false),
          media: canOriginal
              ? snapshot.payload.media
              : snapshot.payload.media
                  .map((item) => MediaRefDto(
                        id: item.id,
                        privacyStatus: item.privacyStatus,
                        publicRef: item.publicRef,
                        mimeType: item.mimeType,
                      ))
                  .toList(growable: false),
          auditEvents: canAudit ? snapshot.payload.auditEvents : const <OpaqueEntityDto>[],
          privacyRequests: canPrivacy ? snapshot.payload.privacyRequests : const <OpaqueEntityDto>[],
          restrictions: canUsers ? snapshot.payload.restrictions : const <OpaqueEntityDto>[],
          dataSourceHealth: canSources ? snapshot.payload.dataSourceHealth : const <OpaqueEntityDto>[],
        ),
      ),
    );
  }

  UserAccount _account(AppSnapshotDto snapshot, String id) {
    for (final dto in snapshot.payload.accounts) {
      if (dto.id == id) {
        return UserAccount(
          id: dto.id,
          role: dto.role,
          permissions: dto.permissions,
          unitId: dto.unitId,
          deletionRequested: dto.deletionRequested,
        );
      }
    }
    fail(FailureCode.unauthorized, 'Demo hesabı snapshot içinde bulunamadı.');
  }

  Future<JsonMap> _body(Request request) async {
    const limit = 128 * 1024;
    final builder = BytesBuilder(copy: false);
    await for (final chunk in request.read()) {
      if (builder.length + chunk.length > limit) {
        fail(FailureCode.validation, 'Komut gövdesi çok büyük.');
      }
      builder.add(chunk);
    }
    try {
      final raw = utf8.decode(builder.takeBytes());
      return expectMap(jsonDecode(raw), 'request');
    } on Object {
      fail(FailureCode.validation, 'Komut JSON olarak çözülemedi.');
    }
  }

  void _broadcast(int revision) {
    final message = jsonEncode({'type': 'revision', 'revision': revision});
    for (final socket in _sockets.toList(growable: false)) {
      try {
        socket.sink.add(message);
      } on Object {
        _sockets.remove(socket);
      }
    }
  }
}

bool _sameBytes(Uint8List left, Uint8List right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

double _publicCoordinate(double value, bool sensitive) {
  if (!sensitive) return value;
  return (value * 1000).roundToDouble() / 1000;
}

final class _Actor {
  const _Actor(this.accountId) : guest = false;
  const _Actor.guest() : accountId = 'guest', guest = true;

  final String accountId;
  final bool guest;
}

Response _json(
  int status,
  Object body, {
  Map<String, String>? headers,
}) {
  return Response(
    status,
    body: jsonEncode(body),
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store',
      ...?headers,
    },
  );
}

Middleware _securityHeaders() {
  return (inner) => (request) async {
    final response = await inner(request);
    return response.change(headers: {
      'x-content-type-options': 'nosniff',
      'x-frame-options': 'DENY',
      'referrer-policy': 'no-referrer',
      'permissions-policy': 'camera=(), microphone=(), geolocation=()',
      'cross-origin-resource-policy': 'same-site',
    });
  };
}

const _allowedDemoOrigins = <String>{
  'http://localhost',
  'http://127.0.0.1',
};

bool _allowedOrigin(String origin) {
  final uri = Uri.tryParse(origin);
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) return false;
  final base = '${uri.scheme}://${uri.host}';
  return _allowedDemoOrigins.contains(base);
}

Middleware _cors() {
  return (inner) => (request) async {
    final origin = request.headers['origin'];
    final browserOriginAllowed = origin == null || _allowedOrigin(origin);
    final mutating = const {'POST', 'PUT', 'PATCH', 'DELETE'}.contains(request.method);
    if (mutating && origin != null && !browserOriginAllowed) {
      return _json(403, {
        'code': 'origin_forbidden',
        'message': 'İstek kaynağı demo sunucusu tarafından kabul edilmedi.',
      });
    }
    if (request.method == 'OPTIONS' && origin != null && !browserOriginAllowed) {
      return _json(403, {'code': 'origin_forbidden'});
    }
    final response = await inner(request);
    return response.change(headers: {
      if (origin != null && browserOriginAllowed) 'access-control-allow-origin': origin,
      'vary': 'Origin',
      'access-control-allow-headers': 'authorization, content-type, if-match, x-requested-with',
      'access-control-allow-methods': 'GET, POST, PUT, OPTIONS',
      'access-control-max-age': '600',
    });
  };
}

Middleware _requestSafety() {
  return (inner) => (request) async {
    try {
      return await inner(request);
    } on DomainFailure catch (error) {
      final status = switch (error.code) {
        FailureCode.unauthorized || FailureCode.privacy => 403,
        FailureCode.notFound => 404,
        FailureCode.conflict => 409,
        FailureCode.validation || FailureCode.invalidTransition => 422,
        _ => 500,
      };
      return _json(status, {
        'code': enumWire(error.code),
        'message': _safeFailureMessage(error.code),
      });
    } on Object {
      return _json(500, {'code': 'internal_error', 'message': 'İstek güvenli biçimde tamamlanamadı.'});
    }
  };
}

String _safeFailureMessage(FailureCode code) => switch (code) {
  FailureCode.unauthorized => 'Bu işlem için yetkiniz yok veya oturum geçersiz.',
  FailureCode.privacy => 'Gizlilik politikası bu işlemi engelledi.',
  FailureCode.notFound => 'İstenen kayıt bulunamadı.',
  FailureCode.conflict => 'Kayıt başka bir işlemle değişti.',
  FailureCode.validation => 'Gönderilen veri doğrulanamadı.',
  FailureCode.invalidTransition => 'Bu durum geçişine izin verilmiyor.',
  _ => 'İstek güvenli biçimde tamamlanamadı.',
};
