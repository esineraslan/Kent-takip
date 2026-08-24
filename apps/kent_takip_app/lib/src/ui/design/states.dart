import 'package:kent_takip_app/src/localization/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:kent_takip_app/src/ui/design/components.dart';
import 'package:kent_takip_app/src/ui/design/tokens.dart';

final class LoadingView extends StatelessWidget {
  const LoadingView({this.message, super.key});
  final String? message;

  @override
  Widget build(BuildContext context) => _StateView(
    icon: const CircularProgressIndicator(),
    title: message ?? context.strings.text('u0472'),
    description: context.strings.text('u0453'),
    liveRegion: true,
  );
}

final class EmptyView extends StatelessWidget {
  const EmptyView({required this.title, required this.description, this.action, super.key});
  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) => _StateView(
    icon: const Icon(Icons.inbox_outlined, size: 48, color: KtColors.textMuted),
    title: title,
    description: description,
    action: action,
  );
}

final class OfflineView extends StatelessWidget {
  const OfflineView({required this.onRetry, this.readOnly = false, super.key});
  final VoidCallback onRetry;
  final bool readOnly;

  @override
  Widget build(BuildContext context) => _StateView(
    icon: const Icon(Icons.cloud_off_rounded, size: 48, color: KtColors.critical),
    title: context.strings.text('u0315'),
    description: readOnly
        ? context.strings.text('u0473')
        : context.strings.text('u0474'),
    action: KtButton(label: context.strings.text('u0004'), onPressed: onRetry, kind: KtButtonKind.secondary),
    liveRegion: true,
  );
}

final class RecoverableErrorView extends StatelessWidget {
  const RecoverableErrorView({required this.message, required this.onRetry, super.key});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _StateView(
    icon: const Icon(Icons.refresh_rounded, size: 48, color: KtColors.brandBlue800),
    title: context.strings.text('u0316'),
    description: message,
    action: KtButton(label: context.strings.text('u0004'), onPressed: onRetry),
    liveRegion: true,
  );
}

final class BlockingErrorView extends StatelessWidget {
  const BlockingErrorView({required this.message, required this.reference, super.key});
  final String message;
  final String reference;

  @override
  Widget build(BuildContext context) => _StateView(
    icon: const Icon(Icons.error_outline_rounded, size: 48, color: KtColors.activeDark),
    title: context.strings.text('u0317'),
    description: context.strings.format('u0467', {'message': message, 'reference': reference}),
    liveRegion: true,
  );
}

final class _StateView extends StatelessWidget {
  const _StateView({
    required this.icon,
    required this.title,
    required this.description,
    this.action,
    this.liveRegion = false,
  });

  final Widget icon;
  final String title;
  final String description;
  final Widget? action;
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: liveRegion,
      label: context.strings.format('u0466', {'title': title, 'description': description}),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(KtSpacing.x6),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(height: KtSpacing.x4),
                Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: KtSpacing.x2),
                Text(description, textAlign: TextAlign.center),
                if (action != null) ...[
                  const SizedBox(height: KtSpacing.x6),
                  action!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
