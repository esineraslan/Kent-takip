import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kent_takip_app/src/app.dart';
import 'package:kent_takip_app/src/bootstrap/app_bootstrapper.dart';
import 'package:kent_takip_app/src/config/app_environment.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E-WALKING-SKELETON citizen staff citizen', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      KentTakipApp(
        bootstrapper: AppBootstrapper(
          loadConfig: () => const AppConfig(
            environment: AppEnvironment.test,
            dataMode: DemoDataMode.local,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _loginCitizen(tester);
    await tester.tap(find.text('Bildir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fotoğrafa geç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fotoğrafsız devam et'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Devam et'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('report-description')),
      'Meşrutiyet Caddesi üzerinde büyük çukur var.',
    );
    await tester.tap(find.text('Devam et'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Onayla ve gönder'));
    await tester.pumpAndSettle();
    expect(find.text('Bildirimin alındı'), findsOneWidget);
    final banner = tester.widget<Text>(find.textContaining('Takip numarası:'));
    final tracking = RegExp(r'KT-[0-9]{4}-[0-9]{6}').firstMatch(banner.data!)!.group(0)!;

    await tester.tap(find.text('Rolü değiştir'));
    await tester.pumpAndSettle();
    await _loginStaff(tester);
    await tester.tap(find.text('İnceleme kuyrukları').first);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(tracking));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('review-reason')),
        matching: find.byType(TextFormField),
      ),
      'Konum ve açıklama yetkili personel tarafından doğrulandı.',
    );
    await tester.tap(find.byKey(const ValueKey('walking-skeleton-verify-report')));
    await tester.pumpAndSettle();
    expect(find.textContaining('$tracking doğrulandı'), findsOneWidget);

    await tester.tap(find.text('Rolü değiştir'));
    await tester.pumpAndSettle();
    await _loginCitizen(tester);
    await tester.tap(find.text('Bildirimlerim'));
    await tester.pumpAndSettle();
    expect(find.textContaining(tracking), findsOneWidget);
    await tester.tap(find.textContaining(tracking));
    await tester.pumpAndSettle();
    expect(find.text('Ön kontroller tamamlandı ve ilgili birime yönlendirildi'), findsOneWidget);
  });
}

Future<void> _loginCitizen(WidgetTester tester) async {
  await tester.tap(find.text('Vatandaş'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Demo hesabıyla giriş yap'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Demo hesabını doldur'));
  await tester.tap(find.text('Doğrulama kodu gönder'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), '123456');
  await tester.tap(find.text('Doğrula ve devam et'));
  await tester.pumpAndSettle();
}

Future<void> _loginStaff(WidgetTester tester) async {
  await tester.tap(find.text('Belediye yetkilisi'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Demo hesabını doldur'));
  await tester.tap(find.text('Devam et'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), '654321');
  await tester.tap(find.text('Doğrula ve devam et'));
  await tester.pumpAndSettle();
}
