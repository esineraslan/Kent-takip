import 'package:flutter/material.dart' hide SnapshotController;
import 'package:kent_takip_app/src/localization/app_strings.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kent_takip_app/src/auth/demo_auth_service.dart';
import 'package:kent_takip_app/src/bootstrap/app_bootstrapper.dart';
import 'package:kent_takip_app/src/bootstrap/app_composition_root.dart';
import 'package:kent_takip_app/src/config/app_environment.dart';
import 'package:kent_takip_app/src/features/walking_skeleton/snapshot_controller.dart';
import 'package:kent_takip_app/src/localization/locale_controller.dart';
import 'package:kent_takip_app/src/logging/structured_logger.dart';
import 'package:kent_takip_app/src/ui/app_theme.dart';
import 'package:kent_takip_app/src/ui/widgets/brand_header.dart';
import 'package:kent_takip_app/src/ui/widgets/demo_environment_banner.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_application/kent_takip_application.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:kent_takip_persistence/kent_takip_persistence.dart';
import 'package:provider/provider.dart';

final class KentTakipApp extends StatefulWidget {
  KentTakipApp({this.bootstrapper, super.key});

  final AppBootstrapper? bootstrapper;

  @override
  State<KentTakipApp> createState() => _KentTakipAppState();
}

final class _KentTakipAppState extends State<KentTakipApp> {
  AppCompositionRoot? _composition;
  late Future<AppCompositionRoot> _initialization;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _composition?.dispose();
    super.dispose();
  }

  void _initialize() {
    _initialization = _buildComposition();
  }

  Future<AppCompositionRoot> _buildComposition() async {
    final composition = await (widget.bootstrapper ?? AppBootstrapper())
        .initialize();
    if (!mounted) {
      composition.dispose();
    } else {
      _composition = composition;
    }
    return composition;
  }

  void _retry() {
    setState(_initialize);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppCompositionRoot>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _RuntimeApp(composition: snapshot.requireData);
        }
        if (snapshot.hasError) {
          final failure = snapshot.error;
          return _BootstrapRecoveryApp(
            technicalReference: failure is BootstrapFailure
                ? failure.technicalReference
                : 'bootstrap-unexpected',
            onRetry: _retry,
          );
        }
        return _BootstrapLoadingApp();
      },
    );
  }
}

final class _RuntimeApp extends StatelessWidget {
  _RuntimeApp({required this.composition});

  final AppCompositionRoot composition;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppConfig>.value(value: composition.config),
        Provider<StructuredLogger>.value(value: composition.logger),
        Provider<Clock>.value(value: composition.clock),
        Provider<SnapshotStore>.value(value: composition.snapshotStore),
        Provider<DemoAuthService>.value(value: composition.authService),
        Provider<DemoResetCoordinator>.value(
          value: composition.resetCoordinator,
        ),
        Provider<CameraCaptureGateway>.value(value: composition.cameraGateway),
        Provider<MediaPipeline>.value(value: composition.mediaPipeline),
        Provider<KentAiAnalysisService>.value(
          value: composition.aiAnalysisService,
        ),
        ChangeNotifierProvider.value(value: composition.authFlow),
        ChangeNotifierProvider.value(value: composition.session),
        ChangeNotifierProvider.value(value: composition.locale),
        ChangeNotifierProvider<SnapshotController>.value(
          value: composition.snapshotController,
        ),
      ],
      child: Consumer<LocaleController>(
        builder: (context, locale, child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (context) => context.strings.text('u0321'),
            theme: AppTheme.light(),
            highContrastTheme: AppTheme.highContrast(),
            locale: locale.locale,
            supportedLocales: [Locale('tr'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            routerConfig: composition.router,
            builder: (context, child) {
              final content = child ?? SizedBox.shrink();
              if (!composition.config.isDemo) {
                return content;
              }
              return Column(
                children: [
                  SafeArea(
                    top: true,
                    bottom: false,
                    child: DemoEnvironmentBanner(router: composition.router),
                  ),
                  Expanded(
                    child: MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: content,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

final class _BootstrapLoadingApp extends StatelessWidget {
  _BootstrapLoadingApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      supportedLocales: [Locale('tr'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Semantics(
              liveRegion: true,
              label: 'Yukleniyor',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BrandMark(compact: true),
                  SizedBox(height: 28),
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Yukleniyor...'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _BootstrapRecoveryApp extends StatelessWidget {
  _BootstrapRecoveryApp({
    required this.technicalReference,
    required this.onRetry,
  });

  final String technicalReference;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      supportedLocales: [Locale('tr'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 520),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.settings_backup_restore_rounded,
                          size: 52,
                          color: AppColors.brandBlue800,
                        ),
                        SizedBox(height: 18),
                        Text(
                          context.strings.text('u0002'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        SizedBox(height: 10),
                        Text(
                          context.strings.text('u0197'),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        SelectableText(
                          context.strings.format('u0322', {
                            'reference': technicalReference,
                          }),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 24),
                        FilledButton.icon(
                          key: ValueKey('bootstrap-retry'),
                          onPressed: onRetry,
                          icon: Icon(Icons.refresh_rounded),
                          label: Text(context.strings.text('u0004')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
