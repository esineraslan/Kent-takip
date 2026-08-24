import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kent_takip_app/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('citizen demo login reaches isolated citizen shell', (
    tester,
  ) async {
    await tester.pumpWidget(const KentTakipApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Vatandaş'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Demo hesabıyla giriş yap'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Demo hesabını doldur'));
    await tester.tap(find.text('Doğrulama kodu gönder'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Demo kodu:'), findsNothing);
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Doğrula ve devam et'));
    await tester.pumpAndSettle();

    expect(find.text('Harita'), findsOneWidget);
    expect(find.text('Bildir'), findsOneWidget);
    expect(find.text('Bildirimlerim'), findsOneWidget);
    expect(find.text('İnceleme kuyrukları'), findsNothing);
  });

  testWidgets('staff password and MFA reach isolated staff shell', (
    tester,
  ) async {
    await tester.pumpWidget(const KentTakipApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Belediye yetkilisi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Demo hesabını doldur'));
    await tester.tap(find.text('Devam et'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Demo kodu:'), findsNothing);
    await tester.enterText(find.byType(TextField), '654321');
    await tester.tap(find.text('Doğrula ve devam et'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('İnceleme kuyrukları'), findsOneWidget);
    expect(find.text('Bildirimlerim'), findsNothing);
    expect(find.text('Çıkış yap'), findsOneWidget);

    await tester.tap(find.text('Çıkış yap'));
    await tester.pumpAndSettle();
    expect(find.text('Kurumsal demo hesabı'), findsOneWidget);
  });
}
