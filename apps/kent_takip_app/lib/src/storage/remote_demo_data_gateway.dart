import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:kent_takip_application/kent_takip_application.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:kent_takip_persistence/kent_takip_persistence.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final class RemoteGatewayFailure implements Exception {
  RemoteGatewayFailure({required this.statusCode, required this.message});
  final int statusCode;
  final String message;

  @override
  String toString() => 'RemoteGatewayFailure($statusCode, $message)';
}

final class RemoteDemoDataGateway implements DemoDataGateway {
  RemoteDemoDataGateway({
    required this.apiBase,
    required this.codec,
    required this.tokenProvider,
    this.cacheStore,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 4),
    this.retryPolicy = const ResilienceRetryPolicy(),
    this.delay = Future<void>.delayed,
  }) : _client = client ?? http.Client() {
    _connectRevisions();
  }

  final Uri apiBase;
  final SnapshotCodec codec;
  final String Function() tokenProvider;
  final SnapshotStore? cacheStore;
  final http.Client _client;
  final Duration requestTimeout;
  final ResilienceRetryPolicy retryPolicy;
  final Delay delay;
  final StreamController<int> _revisions = StreamController<int>.broadcast();
  WebSocketChannel? _socket;
  String? _socketToken;
  bool _closed = false;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _lastReadWasOfflineCache = false;

  @override
  bool get lastReadWasOfflineCache => _lastReadWasOfflineCache;

  @override
  Future<void> close() async {
    _closed = true;
    _reconnectTimer?.cancel();
    await _socket?.sink.close();
    _client.close();
    await _revisions.close();
  }

  @override
  Future<MutationResult> createReport(CreateReportCommand command) {
    return _command('/v1/commands/report', command.toJson(), command.expectedRevision);
  }

  @override
  Future<MutationResult> citizenAction(CitizenActionCommand command) {
    return _command(
      '/v1/commands/citizen-action',
      command.toJson(),
      command.expectedRevision,
    );
  }

  @override
  Future<MutationResult> fieldOperation(FieldOperationCommand command) {
    return _command(
      '/v1/commands/field-operation',
      command.toJson(),
      command.expectedRevision,
    );
  }

  @override
  Future<MutationResult> municipalWork(MunicipalWorkCommand command) {
    return _command(
      '/v1/commands/municipal-work',
      command.toJson(),
      command.expectedRevision,
    );
  }

  @override
  Future<MutationResult> sourceOperation(SourceOperationCommand command) {
    return _command('/v1/commands/source-operation', command.toJson(), command.expectedRevision);
  }

  @override
  Future<MutationResult> administration(AdministrationCommand command) {
    return _command('/v1/commands/administration', command.toJson(), command.expectedRevision);
  }

  @override
  Future<AppSnapshotDto> fetchSnapshot() async {
    _connectRevisions();
    try {
      final snapshot = await retryIdempotent<AppSnapshotDto>(
        policy: retryPolicy,
        delay: delay,
        jitterSeed: apiBase.hashCode,
        shouldRetry: _shouldRetryReadFailure,
        operation: (attempt) async {
          try {
            final response = await _client
                .get(_uri('/v1/snapshot'), headers: _headers())
                .timeout(requestTimeout);
            _requireSuccess(response);
            try {
              return codec.decode(response.body);
            } on DomainFailure {
              throw RemoteGatewayFailure(
                statusCode: 502,
                message: 'Sunucu snapshot yanıtı doğrulanamadı.',
              );
            }
          } on TimeoutException {
            throw RemoteGatewayFailure(
              statusCode: 408,
              message: 'Snapshot isteği zaman aşımına uğradı.',
            );
          } on http.ClientException {
            throw RemoteGatewayFailure(
              statusCode: 503,
              message: 'Snapshot bağlantısı geçici olarak kullanılamıyor.',
            );
          }
        },
      );
      _lastReadWasOfflineCache = false;
      await _persistSnapshotCache(snapshot);
      return snapshot;
    } on Object {
      final cache = cacheStore;
      if (cache == null) rethrow;
      final snapshot = await cache.read();
      _lastReadWasOfflineCache = true;
      return snapshot;
    }
  }

  Future<void> _persistSnapshotCache(AppSnapshotDto snapshot) async {
    final cache = cacheStore;
    if (cache == null) return;
    try {
      final current = await cache.read();
      if (snapshot.revision > current.revision) {
        await cache.write(snapshot);
      }
    } on Object {
      // Remote truth remains usable even if the optional offline cache is full,
      // corrupt, unavailable or a stale local revision cannot be advanced.
      // Cache is a resilience aid; it must never poison a successful remote read.
    }
  }

  @override
  Future<Uint8List?> getMedia(
    String id, {
    String reason = 'application_media_access',
    String? actorId,
  }) {
    return retryIdempotent<Uint8List?>(
      policy: retryPolicy,
      delay: delay,
      jitterSeed: id.hashCode,
      shouldRetry: _shouldRetryReadFailure,
      operation: (attempt) async {
        try {
          final response = await _client
              .get(
                _uri('/v1/media/$id').replace(queryParameters: {'reason': reason}),
                headers: _headers(),
              )
              .timeout(requestTimeout);
          if (response.statusCode == 404) return null;
          _requireSuccess(response);
          return response.bodyBytes;
        } on TimeoutException {
          throw RemoteGatewayFailure(
            statusCode: 408,
            message: 'Medya isteği zaman aşımına uğradı.',
          );
        } on http.ClientException {
          throw RemoteGatewayFailure(
            statusCode: 503,
            message: 'Medya bağlantısı geçici olarak kullanılamıyor.',
          );
        }
      },
    );
  }

  @override
  Future<void> putMedia(String id, Uint8List bytes) async {
    // PUT to the stable media id is idempotent: transient transport failures may
    // retry the exact same bytes without creating a second media resource.
    await retryIdempotent<void>(
      policy: retryPolicy,
      delay: delay,
      jitterSeed: id.hashCode,
      shouldRetry: _shouldRetryReadFailure,
      operation: (attempt) async {
        try {
          final response = await _client
              .put(
                _uri('/v1/media/$id'),
                headers: {
                  ..._headers(),
                  'content-type': 'application/octet-stream',
                },
                body: bytes,
              )
              .timeout(requestTimeout);
          if (retryPolicy.shouldRetryStatus(response.statusCode)) {
            throw RemoteGatewayFailure(
              statusCode: response.statusCode,
              message: 'Medya yükleme servisi geçici olarak kullanılamıyor.',
            );
          }
          _requireSuccess(response);
        } on TimeoutException {
          throw RemoteGatewayFailure(
            statusCode: 408,
            message: 'Medya yükleme isteği zaman aşımına uğradı.',
          );
        } on http.ClientException {
          throw RemoteGatewayFailure(
            statusCode: 503,
            message: 'Medya yükleme bağlantısı geçici olarak kullanılamıyor.',
          );
        }
      },
    );
  }


  @override
  Future<MutationResult> reviewLease(ReviewLeaseCommand command) {
    return _command(
      '/v1/commands/review-lease',
      command.toJson(),
      command.expectedRevision,
    );
  }

  @override
  Future<MutationResult> staffDecision(StaffDecisionCommand command) {
    return _command(
      '/v1/commands/staff-decision',
      command.toJson(),
      command.expectedRevision,
    );
  }

  @override
  Future<MutationResult> verifyReport(VerifyReportCommand command) {
    return _command('/v1/commands/verify', command.toJson(), command.expectedRevision);
  }

  @override
  Stream<int> watchRevisions() => _revisions.stream;

  Future<MutationResult> _command(
    String path,
    JsonMap command,
    int expectedRevision,
  ) async {
    // Commands carry a stable clientMutationId. Retrying the exact request is
    // safe after transient transport failures because the server command
    // processors return the prior idempotent result instead of duplicating it.
    final response = await retryIdempotent<http.Response>(
      policy: retryPolicy,
      delay: delay,
      jitterSeed: (command['clientMutationId'] ?? path).hashCode,
      shouldRetry: _shouldRetryReadFailure,
      operation: (attempt) async {
        try {
          final value = await _client
              .post(
                _uri(path),
                headers: {..._headers(), 'content-type': 'application/json'},
                body: jsonEncode(command),
              )
              .timeout(requestTimeout);
          if (retryPolicy.shouldRetryStatus(value.statusCode)) {
            throw RemoteGatewayFailure(
              statusCode: value.statusCode,
              message: 'Geçici sunucu hatası; aynı idempotency anahtarıyla tekrar denenecek.',
            );
          }
          return value;
        } on TimeoutException {
          throw RemoteGatewayFailure(
            statusCode: 408,
            message: 'Komut isteği zaman aşımına uğradı.',
          );
        } on http.ClientException {
          throw RemoteGatewayFailure(
            statusCode: 503,
            message: 'Komut bağlantısı geçici olarak kullanılamıyor.',
          );
        }
      },
    );
    final body = _decodeMap(response.body);
    if (response.statusCode == 409) {
      final current = codec.decode(jsonEncode(expectMap(body['current'], 'current')));
      throw CommandConflict(expectedRevision: expectedRevision, current: current);
    }
    _requireSuccess(response, decoded: body);
    final snapshot = await fetchSnapshot();
    if (lastReadWasOfflineCache) {
      throw RemoteGatewayFailure(
        statusCode: 503,
        message: 'Komut işlendi; güncel revision bağlantı geri geldiğinde doğrulanacak.',
      );
    }
    return MutationResult(
      snapshot: snapshot,
      resourceId: expectString(body['resourceId'], 'resourceId'),
      trackingNumber: expectNullableString(body['trackingNumber'], 'trackingNumber'),
      replayed: expectBool(body['replayed'], 'replayed'),
    );
  }

  void _connectRevisions() {
    if (_closed) return;
    final token = tokenProvider();
    if (_socket != null && _socketToken == token) return;
    unawaited(_socket?.sink.close());
    _socket = null;
    _socketToken = token;
    // Guest yalnız filtrelenmiş REST snapshot kullanır. Kimliksiz WebSocket
    // açmayarak gereksiz 401/reconnect döngüsünü ve tokenless socket'i önleriz.
    if (token == 'demo-guest') return;
    final socketUri = _uri('/v1/revisions').replace(
      scheme: apiBase.scheme == 'https' ? 'wss' : 'ws',
      queryParameters: {'token': token},
    );
    try {
      final socket = WebSocketChannel.connect(socketUri);
      var failed = false;
      _socket = socket;
      socket.stream.listen(
        _handleRevisionMessage,
        onError: (Object error, StackTrace stackTrace) {
          if (!identical(_socket, socket)) return;
          failed = true;
          _socket = null;
          _revisions.addError(error, stackTrace);
          _scheduleReconnect();
        },
        onDone: () {
          final wasCurrent = identical(_socket, socket);
          if (wasCurrent) _socket = null;
          if (wasCurrent && !failed && !_closed) {
            _revisions.addError(
              RemoteGatewayFailure(
                statusCode: 0,
                message: 'Canlı revision bağlantısı kapandı.',
              ),
            );
            _scheduleReconnect();
          }
        },
        cancelOnError: false,
      );
    } on Object catch (error, stackTrace) {
      _revisions.addError(error, stackTrace);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_closed || tokenProvider() == 'demo-guest' || _reconnectTimer != null) return;
    _reconnectAttempt += 1;
    final delayDuration = retryPolicy.delayForAttempt(
      _reconnectAttempt,
      jitterSeed: apiBase.hashCode,
    );
    _reconnectTimer = Timer(delayDuration, () {
      _reconnectTimer = null;
      if (_closed) return;
      _connectRevisions();
    });
  }

  bool _shouldRetryReadFailure(Object error) {
    return error is RemoteGatewayFailure &&
        retryPolicy.shouldRetryStatus(error.statusCode);
  }

  Uri _uri(String path) {
    final prefix = apiBase.path.endsWith('/')
        ? apiBase.path.substring(0, apiBase.path.length - 1)
        : apiBase.path;
    return apiBase.replace(path: '$prefix$path', queryParameters: const {});
  }

  Map<String, String> _headers() => {
    'authorization': 'Bearer ${tokenProvider()}',
    'accept': 'application/json',
  };

  JsonMap _decodeMap(String source) {
    try {
      return expectMap(jsonDecode(source), 'response');
    } on Object {
      throw RemoteGatewayFailure(
        statusCode: 502,
        message: 'Sunucu JSON olmayan yanıt döndürdü.',
      );
    }
  }

  void _handleRevisionMessage(Object? message) {
    if (message is! String) return;
    try {
      final event = _decodeMap(message);
      if (event['type'] == 'revision' && event['revision'] is int) {
        _reconnectAttempt = 0;
        _revisions.add(event['revision']! as int);
      }
    } on Object catch (error, stackTrace) {
      _revisions.addError(error, stackTrace);
    }
  }

  void _requireSuccess(http.Response response, {JsonMap? decoded}) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final body = decoded ?? _decodeMap(response.body);
    final message = body['message'];
    if (response.statusCode == 401 || response.statusCode == 403) {
      fail(
        FailureCode.unauthorized,
        message is String ? message : 'Sunucu işlemi reddetti.',
      );
    }
    throw RemoteGatewayFailure(
      statusCode: response.statusCode,
      message: message is String ? message : 'Sunucu isteği tamamlayamadı.',
    );
  }
}
