import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:kent_takip_app/src/app.dart';
import 'package:kent_takip_app/src/bootstrap/app_bootstrapper.dart';
import 'package:kent_takip_app/src/logging/structured_logger.dart';
import 'package:kent_takip_app/src/ui/design/tokens.dart';

void main() {
  final logger = StructuredLogger();
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        logger.error(
          'flutter.framework_error',
          error: details.exception,
          stackTrace: details.stack,
        );
      };
      PlatformDispatcher.instance.onError = (error, stackTrace) {
        logger.error(
          'flutter.platform_error',
          error: error,
          stackTrace: stackTrace,
        );
        return true;
      };
      ErrorWidget.builder = (details) => Directionality(
        textDirection: TextDirection.ltr,
        child: ColoredBox(
          color: KtColors.page,
          child: Center(
            child: Semantics(
              liveRegion: true,
              child: Text('Ekran güvenli biçimde açılamadı.'),
            ),
          ),
        ),
      );
      runApp(
        KentTakipApp(bootstrapper: AppBootstrapper(logger: logger)),
      );
    },
    (error, stackTrace) => logger.error(
      'flutter.uncaught_error',
      error: error,
      stackTrace: stackTrace,
    ),
  );
}
