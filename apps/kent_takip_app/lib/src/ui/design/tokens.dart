import 'package:flutter/material.dart';

/// DESIGN.md'nin kod tarafındaki tek kaynak tasarım tokenları.
abstract final class KtColors {
  static const brandBlue900 = Color(0xFF003378);
  static const brandBlue800 = Color(0xFF0E3B83);
  static const brandBlue700 = Color(0xFF1457A6);
  static const brandBlue100 = Color(0xFFDCE8F7);
  static const brandBlue050 = Color(0xFFF2F7FF);
  static const magenta700 = Color(0xFFA91850);
  static const magenta600 = Color(0xFFC31E60);

  static const page = Color(0xFFF4F7FB);
  static const white = Color(0xFFFFFFFF);
  static const subtle = Color(0xFFEAF0F7);
  static const textStrong = Color(0xFF172033);
  static const textDefault = Color(0xFF30394D);
  static const textMuted = Color(0xFF5D687C);
  static const border = Color(0xFFD7DFEA);
  static const borderStrong = Color(0xFFAEB9C9);

  static const success = Color(0xFF1D7A55);
  static const successSurface = Color(0xFFE4F4ED);
  static const active = Color(0xFFC12637);
  static const activeDark = Color(0xFF9A1C2A);
  static const dangerSurface = Color(0xFFFBE9EC);
  static const planned = Color(0xFFF4C542);
  static const plannedInk = Color(0xFF3B3000);
  static const warningSurface = Color(0xFFFFF4D6);
  static const pending = Color(0xFF687386);
  static const critical = Color(0xFFB84A00);
  static const infoSurface = Color(0xFFE8F1FC);

  static const mapWater = Color(0xFFCCE6F5);
  static const mapLand = Color(0xFFF4F3EF);
  static const mapRoad = Color(0xFFFFFFFF);
  static const mapRoadOutline = Color(0xFFD2D5D8);
  static const mapPark = Color(0xFFDCEAD8);
  static const mapBuilding = Color(0xFFE8E6E1);

  static const shadow1 = Color(0x1A001C44);
  static const shadow2 = Color(0x24001C44);
  static const shadow3 = Color(0x2E001C44);
  static const onDarkMuted = Color(0xFFDCE8F7);
  static const onDarkDivider = Color(0x55FFFFFF);
  static const translucentWhite = Color(0x1AFFFFFF);
}

abstract final class KtSpacing {
  static const x1 = 4.0;
  static const x2 = 8.0;
  static const x3 = 12.0;
  static const x4 = 16.0;
  static const x5 = 20.0;
  static const x6 = 24.0;
  static const x8 = 32.0;
  static const x10 = 40.0;
  static const x12 = 48.0;
  static const x16 = 64.0;
}

abstract final class KtRadius {
  static const control = 8.0;
  static const card = 12.0;
  static const hero = 16.0;
  static const pill = 999.0;
}

abstract final class KtElevation {
  static const none = <BoxShadow>[];
  static const level1 = <BoxShadow>[
    BoxShadow(color: KtColors.shadow1, blurRadius: 6, offset: Offset(0, 2)),
  ];
  static const level2 = <BoxShadow>[
    BoxShadow(color: KtColors.shadow2, blurRadius: 20, offset: Offset(0, 8)),
  ];
  static const level3 = <BoxShadow>[
    BoxShadow(color: KtColors.shadow3, blurRadius: 36, offset: Offset(0, 16)),
  ];
}

abstract final class KtMotion {
  static const quick = Duration(milliseconds: 120);
  static const standard = Duration(milliseconds: 200);
  static const emphasized = Duration(milliseconds: 280);

  static Duration effective(BuildContext context, Duration duration) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false
        ? Duration.zero
        : duration;
  }
}

abstract final class KtTypography {
  /// Resmî dosya onayı gelene kadar yalnız sistem fallback'i kullanılır.
  static const displayFamily = 'Rubik';
  static const bodyFamily = 'Urbanist';
  static const fallback = <String>['Arial', 'sans-serif'];
}

abstract final class KtBreakpoints {
  static const narrowMobile = 360.0;
  static const tablet = 600.0;
  static const twoPanel = 840.0;
  static const desktop = 1024.0;
  static const expandedSidebar = 1280.0;
  static const wide = 1600.0;
}
