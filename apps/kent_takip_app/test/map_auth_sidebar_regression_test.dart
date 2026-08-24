import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kent_takip_app/src/app.dart';
import 'package:kent_takip_app/src/bootstrap/app_bootstrapper.dart';
import 'package:kent_takip_app/src/config/app_environment.dart';

void main() {
  testWidgets('citizen map pans, zooms and focuses an exact district search', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Vatandaş'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Misafir devam et'));
    await tester.pumpAndSettle();

    final map = find.byKey(const ValueKey('interactive-city-map'));
    expect(map, findsOneWidget);
    expect(find.byKey(const ValueKey('map-zoom-in')), findsOneWidget);
    expect(find.byKey(const ValueKey('map-zoom-out')), findsOneWidget);

    await tester.drag(map, const Offset(120, 0));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Bu alanda ara'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Sancaktepe');
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const ValueKey('map-focus-status')), findsOneWidget);
    expect(find.text('Tüm İstanbul’u göster'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('verification screens do not reveal fixed demo codes', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Vatandaş'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Demo hesabıyla giriş yap'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Demo hesabını doldur'));
    await tester.tap(find.text('Doğrulama kodu gönder'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Demo kodu:'), findsNothing);
    expect(find.text('123456'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Belediye yetkilisi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Demo hesabını doldur'));
    await tester.tap(find.text('Devam et'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Demo kodu:'), findsNothing);
    expect(find.text('654321'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop staff sidebar keeps privacy and settings reachable', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 800);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Belediye yetkilisi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Demo hesabını doldur'));
    await tester.tap(find.text('Devam et'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '654321');
    await tester.tap(find.text('Doğrula ve devam et'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('staff-navigation-scroll')), findsOneWidget);
    expect(find.text('KVKK'), findsOneWidget);
    expect(find.text('Ayarlar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

KentTakipApp _testApp() => KentTakipApp(
  bootstrapper: AppBootstrapper(
    loadConfig: () => const AppConfig(
      environment: AppEnvironment.test,
      dataMode: DemoDataMode.local,
    ),
  ),
);
