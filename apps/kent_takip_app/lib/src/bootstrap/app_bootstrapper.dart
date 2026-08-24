import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:kent_takip_app/src/auth/auth_flow_controller.dart';
import 'package:kent_takip_app/src/auth/demo_auth_service.dart';
import 'package:kent_takip_app/src/auth/session_controller.dart';
import 'package:kent_takip_app/src/bootstrap/app_composition_root.dart';
import 'package:kent_takip_app/src/config/app_environment.dart';
import 'package:kent_takip_app/src/features/walking_skeleton/snapshot_controller.dart';
import 'package:kent_takip_app/src/localization/locale_controller.dart';
import 'package:kent_takip_app/src/logging/structured_logger.dart';
import 'package:kent_takip_app/src/media/image_picker_camera_gateway.dart';
import 'package:kent_takip_app/src/navigation/app_router.dart';
import 'package:kent_takip_app/src/storage/local_runtime_stores.dart';
import 'package:kent_takip_app/src/storage/remote_demo_data_gateway.dart';
import 'package:kent_takip_application/kent_takip_application.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:kent_takip_persistence/kent_takip_persistence.dart';

typedef ConfigLoader = AppConfig Function();
typedef BootstrapStageObserver = void Function(BootstrapStage stage);

enum BootstrapStage {
  config,
  logging,
  seedMigration,
  storeAdapter,
  repositories,
  router,
}

final class SystemClock implements Clock, DemoClockControl {
  Duration _offset = Duration.zero;

  @override
  DateTime nowUtc() => DateTime.now().toUtc().add(_offset);

  @override
  Duration get offset => _offset;

  @override
  void advance(Duration duration) {
    if (duration.isNegative) {
      fail(FailureCode.validation, 'DemoClock geriye alınamaz.');
    }
    _offset += duration;
  }

  @override
  void reset() => _offset = Duration.zero;
}

final class AppBootstrapper {
  AppBootstrapper({
    StructuredLogger? logger,
    AssetBundle? assets,
    ConfigLoader? loadConfig,
    Clock? clock,
    this.stageObserver,
  }) : logger = logger ?? StructuredLogger(),
       assets = assets ?? rootBundle,
       loadConfig = loadConfig ?? AppConfig.fromEnvironment,
       clock = clock ?? SystemClock();

  final StructuredLogger logger;
  final AssetBundle assets;
  final ConfigLoader loadConfig;
  final Clock clock;
  final BootstrapStageObserver? stageObserver;

  Future<AppCompositionRoot> initialize() async {
    final correlationId = logger.ids.next();
    try {
      final config = loadConfig();
      stageObserver?.call(BootstrapStage.config);
      logger.info('bootstrap.started', correlationId: correlationId);
      logger.info(
        'bootstrap.config_ready',
        correlationId: correlationId,
        fields: {
          'environment': config.environment.name,
          'dataMode': config.dataMode.name,
        },
      );
      stageObserver?.call(BootstrapStage.logging);
      if (config.forceBootstrapFailure) {
        throw StateError('Forced bootstrap failure');
      }
      if (config.environment == AppEnvironment.release) {
        throw UnsupportedError(
          'Üretim kimlik adaptörü onaylanmadan release ortamı açılamaz.',
        );
      }
      final registry = MigrationRegistry(currentVersion: 1);
      final codec = SnapshotCodec(migrations: registry);
      final source = await assets.loadString(
        'assets/demo_data/v1/snapshot.json',
      );
      final seed = codec.decode(source);
      stageObserver?.call(BootstrapStage.seedMigration);
      stageObserver?.call(BootstrapStage.storeAdapter);
      final localStores = config.environment == AppEnvironment.test
          ? LocalRuntimeStores(
              snapshotStore: InMemorySnapshotStore(initial: seed, codec: codec),
              mediaStore: InMemoryMediaStore(),
              draftStore: InMemoryDraftStore(),
            )
          : await createLocalRuntimeStores(seed: seed, codec: codec);
      final session = SessionController(clock: clock);
      final SnapshotStore store;
      final MediaStore mediaStore;
      final DemoDataGateway dataGateway;
      if (config.dataMode == DemoDataMode.shared) {
        final remote = RemoteDemoDataGateway(
          apiBase: config.demoApiUri,
          codec: codec,
          tokenProvider: () => _demoToken(session),
          cacheStore: localStores.snapshotStore,
        );
        dataGateway = remote;
        store = _GatewaySnapshotStore(remote);
        mediaStore = _GatewayMediaStore(remote);
      } else {
        store = localStores.snapshotStore;
        mediaStore = localStores.mediaStore;
        final processor = SnapshotCommandProcessor(
          store: store,
          codec: codec,
          clock: clock,
        );
        dataGateway = LocalDemoDataGateway(
          store: store,
          mediaStore: mediaStore,
          processor: processor,
        );
      }
      logger.info(
        'bootstrap.store_ready',
        correlationId: correlationId,
        fields: {'schemaVersion': seed.schemaVersion},
      );

      final locale = LocaleController();
      final authService = DemoAuthService(clock: clock, logger: logger);
      final authFlow = AuthFlowController();
      final resetCoordinator = DemoResetCoordinator(
        store: store,
        mediaStore: mediaStore,
        codec: codec,
        clock: clock,
        seed: seed,
      );
      final snapshotController = SnapshotController(
        gateway: dataGateway,
        drafts: OfflineDraftQueue(store: localStores.draftStore),
        stagingMediaStore: localStores.mediaStore,
        deleteStagingAfterCommit: config.dataMode == DemoDataMode.shared,
      );
      final cameraGateway = ImagePickerCameraGateway();
      final mediaPipeline = MediaPipeline();
      final aiAnalysisService = ControllableDemoAiAnalysisService();
      await snapshotController.initialize();
      void refreshForPrincipal() => unawaited(snapshotController.refresh());
      session.addListener(refreshForPrincipal);
      stageObserver?.call(BootstrapStage.repositories);
      final router = createAppRouter(
        config: config,
        session: session,
        logger: logger,
      );
      stageObserver?.call(BootstrapStage.router);
      final root = AppCompositionRoot(
        config: config,
        logger: logger,
        clock: clock,
        snapshotStore: store,
        seed: seed,
        codec: codec,
        authService: authService,
        authFlow: authFlow,
        session: session,
        locale: locale,
        resetCoordinator: resetCoordinator,
        dataGateway: dataGateway,
        snapshotController: snapshotController,
        cameraGateway: cameraGateway,
        mediaPipeline: mediaPipeline,
        aiAnalysisService: aiAnalysisService,
        disposeBindings: () => session.removeListener(refreshForPrincipal),
        router: router,
      );
      logger.info('bootstrap.ready', correlationId: correlationId);
      return root;
    } on Object catch (error, stackTrace) {
      logger.error(
        'bootstrap.failed',
        error: error,
        stackTrace: stackTrace,
        correlationId: correlationId,
      );
      throw BootstrapFailure(
        technicalReference: correlationId,
        cause: error,
      );
    }
  }
}

String _demoToken(SessionController session) {
  final principal = session.principal;
  if (principal == null) return 'demo-guest';
  if (principal.account.id == 'usr_citizen_demo_001') {
    return 'demo-citizen-001';
  }
  if (principal.account.id == 'usr_citizen_demo_002') {
    return 'demo-citizen-002';
  }
  if (principal.account.id == 'usr_citizen_demo_003') {
    return 'demo-citizen-003';
  }
  if (session.isStaff) return 'demo-staff-supervisor';
  return 'demo-guest';
}

final class _GatewaySnapshotStore implements SnapshotStore {
  _GatewaySnapshotStore(this.gateway);
  final DemoDataGateway gateway;

  @override
  Future<AppSnapshotDto> read() => gateway.fetchSnapshot();

  @override
  Future<AppSnapshotDto> write(AppSnapshotDto snapshot) {
    throw UnsupportedError('Shared modda snapshot doğrudan yazılamaz; komut kullanın.');
  }
}

final class _GatewayMediaStore implements MediaStore {
  _GatewayMediaStore(this.gateway);
  final DemoDataGateway gateway;

  @override
  Future<void> delete(String id) {
    throw UnsupportedError('Shared demo medya silme endpointi sunmaz.');
  }

  @override
  Future<Uint8List?> get(String id) => gateway.getMedia(id);

  @override
  Future<void> put(String id, Uint8List bytes) => gateway.putMedia(id, bytes);
}

final class BootstrapFailure extends Error {
  BootstrapFailure({required this.technicalReference, required this.cause});

  final String technicalReference;
  final Object cause;
}
