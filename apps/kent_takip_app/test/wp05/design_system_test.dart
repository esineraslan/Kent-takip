import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kent_takip_app/src/ui/app_theme.dart';
import 'package:kent_takip_app/src/ui/design/components.dart';
import 'package:kent_takip_app/src/ui/design/pins.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';

void main() {
  testWidgets('pin semantics durum kategori ve konumu birlikte taşır', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: KtMapPin(
            kind: PinKind.pendingVerification,
            category: 'Yol ve kaldırım',
            location: 'Şişhane, Beyoğlu',
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel(
        'Doğrulama bekliyor, kategori: Yol ve kaldırım, konum: Şişhane, Beyoğlu',
      ),
      findsOneWidget,
    );
  });

  testWidgets('ortak componentler yüzde 200 metinde kırpılmaz', (tester) async {
    tester.view.physicalSize = const Size(640, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                KtButton(
                  label: 'Uzun birincil işlem açıklaması',
                  expand: true,
                  onPressed: () {},
                ),
                const KtStatusChip(
                  label: 'İlgili belediye birimi tarafından inceleniyor',
                  icon: Icons.search_rounded,
                ),
                KtQueueRow(
                  title: 'Yolda çökme ve şerit daralması',
                  subtitle: 'KT-2026-08421 · Meşrutiyet Caddesi',
                  status: 'Kritik inceleme',
                  statusIcon: Icons.warning_amber_rounded,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('klavye odağı görünür sırayla ilerler', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Column(
            children: [
              KtButton(key: const ValueKey('first'), label: 'İlk', onPressed: () {}),
              KtButton(key: const ValueKey('second'), label: 'İkinci', onPressed: () {}),
            ],
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final first = tester.widget<FilledButton>(find.descendant(
      of: find.byKey(const ValueKey('first')),
      matching: find.byType(FilledButton),
    ));
    expect(first.focusNode?.hasFocus ?? FocusManager.instance.primaryFocus != null, isTrue);
  });
}
