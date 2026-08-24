import 'package:kent_takip_app/src/localization/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:kent_takip_app/src/ui/design/tokens.dart';

enum KtButtonKind { primary, secondary, danger, text }

final class KtButton extends StatelessWidget {
  const KtButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.kind = KtButtonKind.primary,
    this.busy = false,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final KtButtonKind kind;
  final bool busy;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final content = busy
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: KtSpacing.x2),
              ],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );
    final callback = busy ? null : onPressed;
    final button = switch (kind) {
      KtButtonKind.primary => FilledButton(onPressed: callback, child: content),
      KtButtonKind.secondary => OutlinedButton(onPressed: callback, child: content),
      KtButtonKind.danger => FilledButton(
          style: FilledButton.styleFrom(backgroundColor: KtColors.activeDark),
          onPressed: callback,
          child: content,
        ),
      KtButtonKind.text => TextButton(onPressed: callback, child: content),
    };
    return Semantics(
      button: true,
      enabled: callback != null,
      label: busy ? context.strings.format('u0630', {'label': label}) : label,
      child: SizedBox(width: expand ? double.infinity : null, child: button),
    );
  }
}

final class KtTextField extends StatelessWidget {
  const KtTextField({
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.error,
    this.prefixIcon,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
    this.validator,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final String? error;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        errorText: error,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      ),
    );
  }
}

enum KtStatusTone { neutral, info, success, warning, danger }

final class KtStatusChip extends StatelessWidget {
  const KtStatusChip({
    required this.label,
    required this.icon,
    this.tone = KtStatusTone.neutral,
    super.key,
  });

  final String label;
  final IconData icon;
  final KtStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (foreground, background) = switch (tone) {
      KtStatusTone.neutral => (KtColors.textDefault, KtColors.subtle),
      KtStatusTone.info => (KtColors.brandBlue800, KtColors.infoSurface),
      KtStatusTone.success => (KtColors.success, KtColors.successSurface),
      KtStatusTone.warning => (KtColors.plannedInk, KtColors.warningSurface),
      KtStatusTone.danger => (KtColors.activeDark, KtColors.dangerSurface),
    };
    return Semantics(
      label: label,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: (MediaQuery.sizeOf(context).width - (KtSpacing.x4 * 2))
              .clamp(48.0, double.infinity)
              .toDouble(),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: KtSpacing.x3,
          vertical: KtSpacing.x2,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(KtRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: KtSpacing.x2),
            Flexible(
              child: Text(
                label,
                style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class KtCard extends StatelessWidget {
  const KtCard({
    required this.child,
    this.padding = const EdgeInsets.all(KtSpacing.x4),
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Card(
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(KtRadius.card),
              child: content,
            ),
    );
  }
}

enum KtBannerTone { info, success, warning, danger }

final class KtBanner extends StatelessWidget {
  const KtBanner({
    required this.title,
    required this.message,
    this.tone = KtBannerTone.info,
    this.action,
    super.key,
  });

  final String title;
  final String message;
  final KtBannerTone tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final (icon, foreground, background) = switch (tone) {
      KtBannerTone.info =>
        (Icons.info_outline_rounded, KtColors.brandBlue800, KtColors.infoSurface),
      KtBannerTone.success =>
        (Icons.check_circle_outline_rounded, KtColors.success, KtColors.successSurface),
      KtBannerTone.warning =>
        (Icons.warning_amber_rounded, KtColors.plannedInk, KtColors.warningSurface),
      KtBannerTone.danger =>
        (Icons.error_outline_rounded, KtColors.activeDark, KtColors.dangerSurface),
    };
    return Semantics(
      container: true,
      liveRegion: tone == KtBannerTone.danger,
      label: context.strings.format('u0463', {'title': title, 'message': message}),
      child: Container(
        padding: const EdgeInsets.all(KtSpacing.x4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(KtRadius.control),
          border: Border.all(color: foreground),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scaled = MediaQuery.textScalerOf(context).scale(14);
            final stackAction =
                action != null && (constraints.maxWidth < 420 || scaled > 19.6);
            final messageContent = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: foreground),
                const SizedBox(width: KtSpacing.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: KtSpacing.x1),
                      Text(message),
                    ],
                  ),
                ),
                if (action != null && !stackAction) ...[
                  const SizedBox(width: KtSpacing.x2),
                  action!,
                ],
              ],
            );
            if (!stackAction) return messageContent;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                messageContent,
                const SizedBox(height: KtSpacing.x3),
                Align(alignment: Alignment.centerRight, child: action!),
              ],
            );
          },
        ),
      ),
    );
  }
}

final class KtTabs extends StatelessWidget {
  const KtTabs({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: [
        for (var i = 0; i < labels.length; i++)
          ButtonSegment(value: i, label: Text(labels[i])),
      ],
      selected: {selectedIndex},
      onSelectionChanged: (selection) => onSelected(selection.single),
      showSelectedIcon: true,
    );
  }
}

final class KtTable extends StatelessWidget {
  const KtTable({required this.columns, required this.rows, super.key});

  final List<String> columns;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    assert(rows.every((row) => row.length == columns.length));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [for (final column in columns) DataColumn(label: Text(column))],
        rows: [
          for (final row in rows)
            DataRow(cells: [for (final value in row) DataCell(Text(value))]),
        ],
      ),
    );
  }
}

final class KtQueueRow extends StatelessWidget {
  const KtQueueRow({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusIcon,
    required this.onTap,
    this.selected = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final String status;
  final IconData statusIcon;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: context.strings.format('u0464', {'title': title, 'subtitle': subtitle, 'status': status}),
      child: Material(
        color: selected ? KtColors.brandBlue050 : KtColors.white,
        child: ListTile(
          onTap: onTap,
          selected: selected,
          leading: Icon(statusIcon),
          title: Text(title, maxLines: 2),
          subtitle: Text(subtitle, maxLines: 2),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}

final class KtTimelineItem {
  const KtTimelineItem({
    required this.title,
    required this.description,
    required this.at,
    required this.icon,
    this.complete = true,
  });

  final String title;
  final String description;
  final String at;
  final IconData icon;
  final bool complete;
}

final class KtTimeline extends StatelessWidget {
  const KtTimeline({required this.items, super.key});

  final List<KtTimelineItem> items;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: context.strings.format('u0465', {'count': items.length}),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            _TimelineRow(item: items[i], showLine: i < items.length - 1),
        ],
      ),
    );
  }
}

final class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.item, required this.showLine});

  final KtTimelineItem item;
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    final color = item.complete ? KtColors.brandBlue800 : KtColors.pending;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Icon(item.icon, color: color, semanticLabel: item.complete ? context.strings.text('u0631') : context.strings.text('u0632')),
                if (showLine)
                  Expanded(child: Container(width: 2, color: KtColors.borderStrong)),
              ],
            ),
          ),
          const SizedBox(width: KtSpacing.x3),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: KtSpacing.x5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(item.description),
                  Text(item.at, style: const TextStyle(color: KtColors.textMuted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<T?> showKtDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  required List<Widget> actions,
}) {
  return showDialog<T>(
    context: context,
    requestFocus: true,
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: content,
      actions: actions,
    ),
  );
}

Future<T?> showKtSheet<T>({required BuildContext context, required Widget child}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    requestFocus: true,
    useSafeArea: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        left: KtSpacing.x4,
        top: KtSpacing.x4,
        right: KtSpacing.x4,
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + KtSpacing.x4,
      ),
      child: child,
    ),
  );
}
