import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:kent_takip_app/src/auth/auth_flow_controller.dart';
import 'package:kent_takip_app/src/auth/demo_auth_service.dart';
import 'package:kent_takip_app/src/auth/session_controller.dart';
import 'package:kent_takip_app/src/config/app_environment.dart';
import 'package:kent_takip_app/src/features/walking_skeleton/snapshot_controller.dart';
import 'package:kent_takip_app/src/localization/locale_controller.dart';
import 'package:kent_takip_app/src/logging/structured_logger.dart';
import 'package:kent_takip_application/kent_takip_application.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:kent_takip_persistence/kent_takip_persistence.dart';

final class AppCompositionRoot {
  AppCompositionRoot({
    required this.config,
    required this.logger,
    required this.clock,
    required this.snapshotStore,
    required this.seed,
    required this.codec,
    required this.authService,
    required this.authFlow,
    required this.session,
    required this.locale,
    required this.resetCoordinator,
    required this.dataGateway,
    required this.snapshotController,
    required this.cameraGateway,
    required this.mediaPipeline,
    required this.aiAnalysisService,
    required this.disposeBindings,
    required this.router,
  });

  final AppConfig config;
  final StructuredLogger logger;
  final Clock clock;
  final SnapshotStore snapshotStore;
  final AppSnapshotDto seed;
  final SnapshotCodec codec;
  final DemoAuthService authService;
  final AuthFlowController authFlow;
  final SessionController session;
  final LocaleController locale;
  final DemoResetCoordinator resetCoordinator;
  final DemoDataGateway dataGateway;
  final SnapshotController snapshotController;
  final CameraCaptureGateway cameraGateway;
  final MediaPipeline mediaPipeline;
  final KentAiAnalysisService aiAnalysisService;
  final VoidCallback disposeBindings;
  final GoRouter router;

  void dispose() {
    disposeBindings();
    router.dispose();
    session.dispose();
    authFlow.dispose();
    locale.dispose();
    snapshotController.dispose();
  }
}
