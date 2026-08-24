import 'package:flutter/material.dart';
import 'package:kent_takip_app/src/localization/app_strings.dart';
import 'package:kent_takip_app/src/ui/app_theme.dart';

final class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.onDark = false, this.compact = false});

  final bool onDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = onDark ? Colors.white : AppColors.brandBlue900;
    return Semantics(
      label: context.strings.appName,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_city_rounded, color: color, size: compact ? 28 : 34),
          const SizedBox(width: 12),
          Container(width: 1, height: compact ? 28 : 36, color: color.withValues(alpha: 0.35)),
          const SizedBox(width: 12),
          Text(
            compact ? 'Kent Takip' : context.strings.appName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontSize: compact ? 18 : 22,
            ),
          ),
        ],
      ),
    );
  }
}
