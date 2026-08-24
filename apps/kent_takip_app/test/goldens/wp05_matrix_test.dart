import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kent_takip_app/src/ui/app_theme.dart';
import 'package:kent_takip_app/src/ui/design/components.dart';
import 'package:kent_takip_app/src/ui/design/pins.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';

const _enabled = bool.fromEnvironment('KT_ENABLE_GOLDENS');

void main() {
  const viewports = <String, Size>{
    'citizen_320x568': Size(320, 568),
    'citizen_390x844': Size(390, 844),
    'citizen_768x1024': Size(768, 1024),
    'citizen_1024x768': Size(1024, 768),
    'staff_1024x768': Size(1024, 768),
    'staff_1280x800': Size(1280, 800),
    'staff_1440x900': Size(1440, 900),
    'staff_1600x1000': Size(1600, 1000),
  };

  for (final locale in const ['tr', 'en-long']) {
    for (final entry in viewports.entries) {
      testWidgets(
        '${entry.key} $locale golden',
        (tester) async {
          tester.view.physicalSize = entry.value;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              home: _GoldenFixture(longEnglish: locale == 'en-long'),
            ),
          );
          await expectLater(
            find.byType(_GoldenFixture),
            matchesGoldenFile('wp05/${entry.key}_$locale.png'),
          );
        },
        skip: !_enabled,
      );
    }
  }
}

final class _GoldenFixture extends StatelessWidget {
  const _GoldenFixture({required this.longEnglish});
  final bool longEnglish;

  @override
  Widget build(BuildContext context) {
    final title = longEnglish
        ? 'Municipal incident review and public information workspace'
        : 'Kent Takip bileşen matrisi';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          KtBanner(
            title: longEnglish ? 'Review required' : 'İnceleme gerekli',
            message: longEnglish
                ? 'This intentionally long copy validates wrapping without hiding operational information.'
                : 'Durum yalnız renk ile anlatılmaz; ikon ve metin birlikte kullanılır.',
          ),
          const SizedBox(height: 16),
          const Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              KtMapPin(
                kind: PinKind.verifiedActive,
                category: 'Yol hasarı',
                location: 'Beyoğlu',
              ),
              KtMapPin(
                kind: PinKind.publishedPlanned,
                category: 'Altyapı',
                location: 'Fatih',
              ),
              KtMapPin(
                kind: PinKind.pendingVerification,
                category: 'Aydınlatma',
                location: 'Kadıköy',
              ),
              KtMapPin(
                kind: PinKind.criticalReview,
                category: 'Trafik',
                location: 'Şişli',
              ),
            ],
          ),
          const SizedBox(height: 16),
          KtQueueRow(
            title: title,
            subtitle: 'KT-2026-08421 · Meşrutiyet Caddesi',
            status: longEnglish ? 'Awaiting authorized human review' : 'İnsan incelemesi bekliyor',
            statusIcon: Icons.warning_amber_rounded,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
