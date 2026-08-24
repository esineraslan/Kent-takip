import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kent_takip_app/src/localization/app_strings.dart';
import 'package:kent_takip_app/src/localization/app_text_catalog.dart';
import 'package:kent_takip_app/src/localization/locale_formatter.dart';
import 'package:kent_takip_app/src/ui/app_theme.dart';
import 'package:kent_takip_app/src/ui/design/components.dart';

void main() {
  test('WP-20 TR/EN catalogları aynı ve eksiksiz key setini taşır', () {
    expect(appTextTr, isNotEmpty);
    expect(appTextTr.keys.toSet(), appTextEn.keys.toSet());
    expect(appTextTr.values.every((value) => value.trim().isNotEmpty), isTrue);
    expect(appTextEn.values.every((value) => value.trim().isNotEmpty), isTrue);
    expect(const AppStrings(Locale('de')).text('u0004'), appTextEn['u0004']);
  });

  test('WP-20 locale number/phone/plural biçimleme ayrışır', () {
    const tr = LocaleFormatter(Locale('tr'));
    const en = LocaleFormatter(Locale('en'));
    expect(tr.number(12.5, fractionDigits: 1), '12,5');
    expect(en.number(12.5, fractionDigits: 1), '12.5');
    expect(tr.phone('05550001122'), '+90 555 000 11 22');
    expect(en.phone('05550001122'), '+90 (555) 000-1122');
    expect(
      tr.count(
        2,
        singularTr: 'kayıt',
        pluralTr: 'kayıt',
        singularEn: 'record',
        pluralEn: 'records',
      ),
      '2 kayıt',
    );
    expect(
      en.count(
        2,
        singularTr: 'kayıt',
        pluralTr: 'kayıt',
        singularEn: 'record',
        pluralEn: 'records',
      ),
      '2 records',
    );
  });

  testWidgets('WP-20 yüzde 200 metinde temel aksiyonlar taşmadan ve 48px hedefle kalır', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: AppTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                KtBanner(
                  title: appTextEn['u0495']!,
                  message: appTextEn['u0496']!,
                ),
                const SizedBox(height: 12),
                KtButton(
                  key: const ValueKey('wp20-primary'),
                  label: appTextEn['u0508']!,
                  expand: true,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final button = find.descendant(
      of: find.byKey(const ValueKey('wp20-primary')),
      matching: find.byType(FilledButton),
    );
    final size = tester.getSize(button);
    expect(size.height, greaterThanOrEqualTo(48));
    expect(size.width, greaterThanOrEqualTo(48));
  });

  test('WP-20 high-contrast tema standart temadan daha güçlü outline kullanır', () {
    final normal = AppTheme.light();
    final high = AppTheme.highContrast();
    expect(high.colorScheme.outline, isNot(normal.colorScheme.outline));
  });
}
