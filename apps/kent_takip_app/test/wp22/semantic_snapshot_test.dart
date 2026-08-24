import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kent_takip_app/src/ui/app_theme.dart';
import 'package:kent_takip_app/src/ui/design/components.dart';
import 'package:kent_takip_app/src/ui/design/pins.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';

void main() {
  testWidgets('WP-22 semantic snapshot primary actions and status are named without color-only meaning', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        theme: AppTheme.light(),
        home: Scaffold(
          body: Column(
            children: [
              KtBanner(
                title: 'İnceleme gerekli',
                message: 'Bu kayıt insan incelemesi bekliyor.',
              ),
              KtButton(label: 'Kaydı aç', onPressed: () {}),
              const KtMapPin(
                kind: PinKind.criticalReview,
                category: 'Trafik',
                location: 'Şişli',
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Kaydı aç'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('İnceleme gerekli.*insan incelemesi')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp('Trafik')), findsWidgets);
  });
}
