import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kent_takip_app/src/app.dart';
import 'package:kent_takip_app/src/bootstrap/app_bootstrapper.dart';
import 'package:kent_takip_app/src/config/app_environment.dart';

void main() {
  testWidgets('deterministic bootstrap opens the demo role selector', (
    tester,
  ) async {
    final stages = <BootstrapStage>[];
    await tester.pumpWidget(
      KentTakipApp(
        bootstrapper: _testBootstrapper(stageObserver: stages.add),
      ),
    );
    await tester.pumpAndSettle();

    expect(stages, BootstrapStage.values);
    expect(find.text('Nasıl devam etmek istiyorsunuz?'), findsOneWidget);
    expect(find.text('Vatandaş'), findsOneWidget);
    expect(find.text('Belediye yetkilisi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bootstrap failure renders a typed recovery screen', (
    tester,
  ) async {
    final bootstrapper = AppBootstrapper(
      loadConfig: () => const AppConfig(
        environment: AppEnvironment.demo,
        dataMode: DemoDataMode.local,
        forceBootstrapFailure: true,
      ),
    );

    await tester.pumpWidget(KentTakipApp(bootstrapper: bootstrapper));
    await tester.pumpAndSettle();

    expect(find.text('Demo verisi açılamadı'), findsOneWidget);
    expect(find.byKey(const ValueKey('bootstrap-retry')), findsOneWidget);
    expect(find.textContaining('Teknik referans:'), findsOneWidget);
  });

  testWidgets('locale switch updates the active UI without rebuilding state', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();

    expect(find.text('How would you like to continue?'), findsOneWidget);
    expect(find.text('Citizen'), findsOneWidget);
    expect(find.text('Municipal officer'), findsOneWidget);
  });

  testWidgets('guest citizen shell keeps exactly three primary destinations', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Vatandaş'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Misafir devam et'));
    await tester.pumpAndSettle();

    expect(find.text('Harita'), findsOneWidget);
    expect(find.text('Bildir'), findsOneWidget);
    expect(find.text('Bildirimlerim'), findsOneWidget);
    expect(find.text('İnceleme kuyrukları'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('role switch signs out without resetting the snapshot', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vatandaş'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Misafir devam et'));
    await tester.pumpAndSettle();

    expect(find.text('Aktif'), findsOneWidget);
    await tester.tap(find.text('Rolü değiştir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vatandaş'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Misafir devam et'));
    await tester.pumpAndSettle();

    expect(find.text('Aktif'), findsOneWidget);
    expect(find.text('Planlanan'), findsOneWidget);
  });
}

KentTakipApp _testApp() => KentTakipApp(bootstrapper: _testBootstrapper());

AppBootstrapper _testBootstrapper({BootstrapStageObserver? stageObserver}) {
  return AppBootstrapper(
    stageObserver: stageObserver,
    loadConfig: () => const AppConfig(
      environment: AppEnvironment.test,
      dataMode: DemoDataMode.local,
    ),
  );
}
