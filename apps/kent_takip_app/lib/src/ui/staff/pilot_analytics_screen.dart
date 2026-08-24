import 'package:flutter/material.dart' hide SnapshotController;
import 'package:kent_takip_app/src/features/walking_skeleton/snapshot_controller.dart';
import 'package:kent_takip_app/src/localization/app_strings.dart';
import 'package:kent_takip_app/src/localization/locale_formatter.dart';
import 'package:kent_takip_app/src/ui/design/components.dart';
import 'package:kent_takip_app/src/ui/design/states.dart';
import 'package:kent_takip_app/src/ui/design/tokens.dart';
import 'package:kent_takip_application/kent_takip_application.dart';
import 'package:provider/provider.dart';

final class PilotAnalyticsScreen extends StatefulWidget {
  const PilotAnalyticsScreen({super.key});

  @override
  State<PilotAnalyticsScreen> createState() => _PilotAnalyticsScreenState();
}

final class _PilotAnalyticsScreenState extends State<PilotAnalyticsScreen> {
  final Map<String, TextEditingController> _roi = {
    for (final key in <String>[
      'baselineTriage',
      'pilotTriage',
      'monthlyReports',
      'staffMinuteCost',
      'baselineWrongRouting',
      'pilotWrongRouting',
      'reworkCost',
      'baselineDuplicates',
      'pilotDuplicates',
      'processingCost',
      'baselineStatusRequests',
      'pilotStatusRequests',
      'statusRequestCost',
      'infrastructureCost',
      'aiCost',
      'mapCost',
      'smsCost',
      'supportCost',
      'operationsCost',
    ])
      key: TextEditingController(),
  };
  RoiResult? _result;
  bool _invalid = false;

  @override
  void dispose() {
    for (final controller in _roi.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SnapshotController>();
    final snapshot = controller.snapshot;
    if (snapshot == null && controller.error == null) return const LoadingView();
    if (snapshot == null) {
      return RecoverableErrorView(
        message: context.strings.text('u0431'),
        onRetry: () { controller.refresh(); },
      );
    }
    final kpi = PilotAnalyticsProjection.calculate(snapshot);
    return ListView(
      padding: const EdgeInsets.all(KtSpacing.x6),
      children: [
        Text(context.strings.text('u0672'), style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: KtSpacing.x1),
        Text(context.strings.text('u0673')),
        const SizedBox(height: KtSpacing.x3),
        KtBanner(
          title: context.strings.text('u0734'),
          message: context.strings.text('u0720'),
          tone: KtBannerTone.info,
        ),
        const SizedBox(height: KtSpacing.x4),
        Wrap(
          spacing: KtSpacing.x3,
          runSpacing: KtSpacing.x3,
          children: [
            _KpiCard(label: context.strings.text('u0674'), value: _percent(context, kpi.northStarRate)),
            _KpiCard(label: context.strings.text('u0675'), value: _duration(context, kpi.firstHumanReviewMedian)),
            _KpiCard(label: context.strings.text('u0676'), value: _percent(context, kpi.firstPassRoutingRate)),
            _KpiCard(label: context.strings.text('u0677'), value: _decimal(context, kpi.duplicateReportsPerIncident)),
            _KpiCard(label: context.strings.text('u0678'), value: _percent(context, kpi.staffAiOverrideRate)),
            _KpiCard(label: context.strings.text('u0679'), value: _percent(context, kpi.resolutionWithinTargetRate)),
            _KpiCard(label: context.strings.text('u0680'), value: _percent(context, kpi.repeatStatusRequestRate)),
            _KpiCard(label: context.strings.text('u0681'), value: _percent(context, kpi.resolutionConfirmedRate)),
          ],
        ),
        const SizedBox(height: KtSpacing.x4),
        Wrap(
          spacing: KtSpacing.x3,
          runSpacing: KtSpacing.x2,
          children: [
            _CountChip(label: context.strings.text('u0721'), value: kpi.reviewedReports),
            _CountChip(label: context.strings.text('u0722'), value: kpi.routedReports),
            _CountChip(label: context.strings.text('u0723'), value: kpi.resolvedIncidents),
            _CountChip(label: context.strings.text('u0724'), value: kpi.feedbackCount),
            _CountChip(label: context.strings.text('u0725'), value: kpi.statusRequestCount),
          ],
        ),
        const SizedBox(height: KtSpacing.x6),
        Text(context.strings.text('u0683'), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: KtSpacing.x1),
        Text(context.strings.text('u0731')),
        const SizedBox(height: KtSpacing.x3),
        _RoiForm(controllers: _roi),
        const SizedBox(height: KtSpacing.x3),
        Wrap(
          spacing: KtSpacing.x2,
          runSpacing: KtSpacing.x2,
          children: [
            KtButton(label: context.strings.text('u0704'), onPressed: _calculate),
            KtButton(label: context.strings.text('u0732'), kind: KtButtonKind.secondary, onPressed: _clear),
          ],
        ),
        if (_invalid) ...[
          const SizedBox(height: KtSpacing.x2),
          KtBanner(title: context.strings.text('u0683'), message: context.strings.text('u0733'), tone: KtBannerTone.warning),
        ],
        if (_result != null) ...[
          const SizedBox(height: KtSpacing.x3),
          Wrap(
            spacing: KtSpacing.x3,
            runSpacing: KtSpacing.x3,
            children: [
              _KpiCard(label: context.strings.text('u0705'), value: context.localeFormat.number(_result!.grossBenefit, fractionDigits: 2)),
              _KpiCard(label: context.strings.text('u0706'), value: context.localeFormat.number(_result!.operatingCost, fractionDigits: 2)),
              _KpiCard(label: context.strings.text('u0707'), value: context.localeFormat.number(_result!.netMonthlyBenefit, fractionDigits: 2)),
            ],
          ),
        ],
        const SizedBox(height: KtSpacing.x5),
        KtBanner(
          title: context.strings.text('u0730'),
          message: context.strings.text('u0735'),
          tone: KtBannerTone.info,
        ),
      ],
    );
  }

  void _clear() {
    for (final controller in _roi.values) controller.clear();
    setState(() {
      _result = null;
      _invalid = false;
    });
  }

  void _calculate() {
    double? d(String key) => double.tryParse(_roi[key]!.text.trim().replaceAll(',', '.'));
    int? i(String key) => int.tryParse(_roi[key]!.text.trim());
    final values = <Object?>[
      d('baselineTriage'), d('pilotTriage'), i('monthlyReports'), d('staffMinuteCost'),
      i('baselineWrongRouting'), i('pilotWrongRouting'), d('reworkCost'),
      i('baselineDuplicates'), i('pilotDuplicates'), d('processingCost'),
      i('baselineStatusRequests'), i('pilotStatusRequests'), d('statusRequestCost'),
      d('infrastructureCost'), d('aiCost'), d('mapCost'), d('smsCost'), d('supportCost'), d('operationsCost'),
    ];
    if (values.any((value) => value == null)) {
      setState(() {
        _invalid = true;
        _result = null;
      });
      return;
    }
    final input = RoiInputs(
      baselineTriageMinutes: d('baselineTriage')!,
      pilotTriageMinutes: d('pilotTriage')!,
      monthlyReportCount: i('monthlyReports')!,
      staffCostPerMinute: d('staffMinuteCost')!,
      baselineWrongRoutingCount: i('baselineWrongRouting')!,
      pilotWrongRoutingCount: i('pilotWrongRouting')!,
      reworkCost: d('reworkCost')!,
      baselineDuplicateCount: i('baselineDuplicates')!,
      pilotDuplicateCount: i('pilotDuplicates')!,
      processingCostPerRecord: d('processingCost')!,
      baselineStatusRequestCount: i('baselineStatusRequests')!,
      pilotStatusRequestCount: i('pilotStatusRequests')!,
      statusRequestCost: d('statusRequestCost')!,
      infrastructureCost: d('infrastructureCost')!,
      aiCost: d('aiCost')!,
      mapCost: d('mapCost')!,
      smsCost: d('smsCost')!,
      supportCost: d('supportCost')!,
      operationsCost: d('operationsCost')!,
    );
    setState(() {
      _invalid = false;
      _result = RoiCalculator.calculate(input);
    });
  }
}

final class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 232,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(KtSpacing.x4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: KtSpacing.x2),
                Text(value, style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
          ),
        ),
      );
}

final class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Chip(label: Text('$label: $value'));
}

final class _RoiForm extends StatelessWidget {
  const _RoiForm({required this.controllers});
  final Map<String, TextEditingController> controllers;

  @override
  Widget build(BuildContext context) {
    final fields = <(String, String)>[
      ('baselineTriage', 'u0685'), ('pilotTriage', 'u0686'), ('monthlyReports', 'u0687'),
      ('staffMinuteCost', 'u0688'), ('baselineWrongRouting', 'u0689'), ('pilotWrongRouting', 'u0690'),
      ('reworkCost', 'u0691'), ('baselineDuplicates', 'u0692'), ('pilotDuplicates', 'u0693'),
      ('processingCost', 'u0694'), ('baselineStatusRequests', 'u0695'), ('pilotStatusRequests', 'u0696'),
      ('statusRequestCost', 'u0697'), ('infrastructureCost', 'u0698'), ('aiCost', 'u0699'),
      ('mapCost', 'u0700'), ('smsCost', 'u0701'), ('supportCost', 'u0702'), ('operationsCost', 'u0703'),
    ];
    return Wrap(
      spacing: KtSpacing.x3,
      runSpacing: KtSpacing.x3,
      children: [
        for (final field in fields)
          SizedBox(
            width: 250,
            child: TextField(
              controller: controllers[field.$1],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: context.strings.text(field.$2)),
            ),
          ),
      ],
    );
  }
}

String _percent(BuildContext context, double? value) => value == null
    ? context.strings.text('u0682')
    : '${context.localeFormat.number(value * 100, fractionDigits: 1)}%';

String _decimal(BuildContext context, double? value) => value == null
    ? context.strings.text('u0682')
    : context.localeFormat.number(value, fractionDigits: 2);

String _duration(BuildContext context, Duration? value) {
  if (value == null) return context.strings.text('u0682');
  final minutes = value.inSeconds / 60;
  return context.strings.format('u0641', {'minutes': context.localeFormat.number(minutes, fractionDigits: 1)});
}
