import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kent_takip_app/src/ui/app_theme.dart';
import 'package:kent_takip_app/src/ui/design/states.dart';

void main() {
  Future<void> pumpState(WidgetTester tester, Widget child, {Locale locale = const Locale('tr')}) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        theme: AppTheme.light(),
        home: Scaffold(body: child),
      ),
    );
    await tester.pump();
  }

  testWidgets('WP-22 state matrix loading exposes live semantics', (tester) async {
    await pumpState(tester, const LoadingView());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.liveRegion == true,
      ),
      findsWidgets,
    );
  });

  testWidgets('WP-22 state matrix empty remains non-blocking', (tester) async {
    var tapped = false;
    await pumpState(
      tester,
      EmptyView(
        title: 'Boş durum',
        description: 'Henüz kayıt yok.',
        action: TextButton(onPressed: () => tapped = true, child: const Text('Aksiyon')),
      ),
    );
    expect(find.text('Boş durum'), findsOneWidget);
    await tester.tap(find.text('Aksiyon'));
    expect(tapped, isTrue);
  });

  testWidgets('WP-22 state matrix offline cached mode has retry and read-only message', (tester) async {
    var retried = false;
    await pumpState(
      tester,
      OfflineView(readOnly: true, onRetry: () => retried = true),
    );
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    await tester.tap(find.byType(OutlinedButton));
    expect(retried, isTrue);
  });

  testWidgets('WP-22 state matrix recoverable error has retry', (tester) async {
    var retried = false;
    await pumpState(
      tester,
      RecoverableErrorView(message: 'Geçici hata', onRetry: () => retried = true),
    );
    await tester.tap(find.byType(FilledButton));
    expect(retried, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('WP-22 state matrix blocking error exposes technical reference', (tester) async {
    await pumpState(
      tester,
      const BlockingErrorView(message: 'Veri açılamadı', reference: 'ERR-DEMO-001'),
      locale: const Locale('en'),
    );
    expect(find.textContaining('ERR-DEMO-001'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });
}
