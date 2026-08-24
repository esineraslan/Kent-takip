import 'package:flutter/material.dart';
import 'package:kent_takip_app/src/localization/app_strings.dart';
import 'package:kent_takip_app/src/ui/design/tokens.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';

final class KtMapPin extends StatelessWidget {
  const KtMapPin({
    required this.kind,
    required this.category,
    required this.location,
    this.selected = false,
    this.onTap,
    super.key,
  });

  final PinKind kind;
  final String category;
  final String location;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (label, color, foreground, icon) = switch (kind) {
      PinKind.verifiedActive => (
          context.strings.text('u0475'),
          KtColors.active,
          KtColors.white,
          Icons.priority_high_rounded,
        ),
      PinKind.publishedPlanned => (
          context.strings.text('u0193'),
          KtColors.planned,
          KtColors.plannedInk,
          Icons.schedule_rounded,
        ),
      PinKind.pendingVerification => (
          context.strings.text('u0476'),
          KtColors.pending,
          KtColors.white,
          Icons.question_mark_rounded,
        ),
      PinKind.criticalReview => (
          context.strings.text('u0477'),
          KtColors.critical,
          KtColors.white,
          Icons.warning_amber_rounded,
        ),
    };
    final size = selected ? 58.0 : 46.0;
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: context.strings.format('u0469', {'label': label, 'category': category, 'location': location}),
      child: Tooltip(
        message: context.strings.format('u0468', {'label': label, 'category': category, 'location': location}),
        child: InkResponse(
          onTap: onTap,
          radius: size / 1.6,
          child: AnimatedContainer(
            duration: KtMotion.effective(context, KtMotion.quick),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? KtColors.brandBlue900 : KtColors.white,
                width: selected ? 4 : 3,
              ),
              boxShadow: KtElevation.level1,
            ),
            child: Icon(icon, color: foreground, size: selected ? 30 : 24),
          ),
        ),
      ),
    );
  }
}

final class KtMapCluster extends StatelessWidget {
  const KtMapCluster({
    required this.count,
    required this.location,
    required this.onTap,
    super.key,
  });

  final int count;
  final String location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.strings.format('u0470', {'location': location, 'count': count}),
      child: InkResponse(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(KtSpacing.x2),
          decoration: const BoxDecoration(
            color: KtColors.brandBlue800,
            shape: BoxShape.circle,
            boxShadow: KtElevation.level1,
          ),
          child: Text(
            count > 99 ? '99+' : '$count',
            style: const TextStyle(color: KtColors.white, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
