import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kent_takip_app/src/ui/design/tokens.dart';

/// Keyboard focus region with an explicit focus ring and automatic scroll
/// recovery so focused controls are not hidden behind an on-screen keyboard,
/// sticky header, or a small viewport.
final class KtFocusRegion extends StatefulWidget {
  const KtFocusRegion({required this.child, this.autofocus = false, super.key});
  final Widget child;
  final bool autofocus;

  @override
  State<KtFocusRegion> createState() => _KtFocusRegionState();
}

final class _KtFocusRegionState extends State<KtFocusRegion> {
  late final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocus(bool focused) {
    if (!focused) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        alignment: .5,
        duration: KtMotion.effective(context, KtMotion.quick),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Focus(
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        onFocusChange: _handleFocus,
        child: Builder(
          builder: (context) => AnimatedContainer(
            duration: KtMotion.effective(context, KtMotion.quick),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(KtRadius.control),
              border: Focus.of(context).hasFocus
                  ? Border.all(color: KtColors.magenta600, width: 3)
                  : null,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

final class KtKeyboardScope extends StatelessWidget {
  const KtKeyboardScope({required this.child, required this.onRefresh, super.key});
  final Widget child;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyR, control: true): _RefreshIntent(),
      },
      child: Actions(
        actions: {
          _RefreshIntent: CallbackAction<_RefreshIntent>(onInvoke: (_) {
            onRefresh();
            return null;
          }),
        },
        child: FocusTraversalGroup(child: child),
      ),
    );
  }
}

final class KtLiveRegion extends StatelessWidget {
  const KtLiveRegion({required this.message, this.child, super.key});
  final String message;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: child ?? const SizedBox.shrink(),
    );
  }
}

final class _RefreshIntent extends Intent {
  const _RefreshIntent();
}
