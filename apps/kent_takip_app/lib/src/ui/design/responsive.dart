import 'package:flutter/material.dart';
import 'package:kent_takip_app/src/ui/design/tokens.dart';

enum KtLayoutClass { narrowMobile, mobile, tablet, desktop, wide }

KtLayoutClass ktLayoutClass(double width) {
  if (width < KtBreakpoints.narrowMobile) return KtLayoutClass.narrowMobile;
  if (width < KtBreakpoints.tablet) return KtLayoutClass.mobile;
  if (width < KtBreakpoints.desktop) return KtLayoutClass.tablet;
  if (width < KtBreakpoints.wide) return KtLayoutClass.desktop;
  return KtLayoutClass.wide;
}

final class KtResponsiveLayout extends StatelessWidget {
  const KtResponsiveLayout({
    required this.mobile,
    required this.desktop,
    this.tablet,
    super.key,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = ktLayoutClass(constraints.maxWidth);
        if (layout == KtLayoutClass.desktop || layout == KtLayoutClass.wide) {
          return desktop(context);
        }
        if (layout == KtLayoutClass.tablet && tablet != null) {
          return tablet!(context);
        }
        return mobile(context);
      },
    );
  }
}

final class KtPageBody extends StatelessWidget {
  const KtPageBody({required this.child, this.maxWidth = 1440, super.key});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final padding = width < KtBreakpoints.narrowMobile
        ? KtSpacing.x3
        : width >= KtBreakpoints.wide
        ? KtSpacing.x8
        : width >= KtBreakpoints.tablet
        ? KtSpacing.x6
        : KtSpacing.x4;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: EdgeInsets.all(padding), child: child),
      ),
    );
  }
}
