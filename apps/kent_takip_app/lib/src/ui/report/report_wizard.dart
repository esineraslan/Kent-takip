import 'dart:async';

import 'package:kent_takip_app/src/localization/app_strings.dart';

import 'package:flutter/material.dart' hide SnapshotController;
import 'package:go_router/go_router.dart';
import 'package:kent_takip_app/src/auth/session_controller.dart';
import 'package:kent_takip_app/src/features/walking_skeleton/snapshot_controller.dart';
import 'package:kent_takip_app/src/navigation/route_policy.dart';
import 'package:kent_takip_app/src/ui/app_theme.dart';
import 'package:kent_takip_app/src/ui/design/components.dart';
import 'package:kent_takip_app/src/ui/design/tokens.dart';
import 'package:kent_takip_application/kent_takip_application.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:provider/provider.dart';

final class CitizenReportWizardScreen extends StatefulWidget {
  CitizenReportWizardScreen({super.key});

  @override
  State<CitizenReportWizardScreen> createState() =>
      _CitizenReportWizardScreenState();
}

final class _CitizenReportWizardScreenState
    extends State<CitizenReportWizardScreen>
    with WidgetsBindingObserver {
  final _description = TextEditingController();
  final _latitude = TextEditingController(text: '41.0302');
  final _longitude = TextEditingController(text: '28.9748');
  var _step = 0;
  var _category = 'road_surface_damage';
  CapturedPhoto? _capture;
  PreparedMedia? _prepared;
  AiAnalysisResult? _analysis;
  String? _cameraMessage;
  String? _formMessage;
  String? _tracking;
  bool _takingPhoto = false;
  bool _analyzing = false;
  bool _corroborateExisting = false;

  static final _categories =
      <({String id, String titleKey, String hintKey, IconData icon})>[
        (
          id: 'road_surface_damage',
          titleKey: 'u0051',
          hintKey: 'u0382',
          icon: Icons.add_road_rounded,
        ),
        (
          id: 'traffic_signal',
          titleKey: 'u0052',
          hintKey: 'u0383',
          icon: Icons.traffic_rounded,
        ),
        (
          id: 'water_infrastructure',
          titleKey: 'u0053',
          hintKey: 'u0384',
          icon: Icons.water_drop_outlined,
        ),
        (
          id: 'waste_cleaning',
          titleKey: 'u0318',
          hintKey: 'u0385',
          icon: Icons.delete_outline_rounded,
        ),
        (
          id: 'park_green',
          titleKey: 'u0319',
          hintKey: 'u0386',
          icon: Icons.park_outlined,
        ),
        (
          id: 'lighting',
          titleKey: 'u0054',
          hintKey: 'u0387',
          icon: Icons.light_outlined,
        ),
        (
          id: 'unsure',
          titleKey: 'u0320',
          hintKey: 'u0388',
          icon: Icons.more_horiz_rounded,
        ),
      ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_recoverCapture()),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _description.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _capture == null) {
      unawaited(_recoverCapture());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_tracking case final tracking?) {
      return ListView(
        padding: EdgeInsets.all(24),
        children: [
          Icon(Icons.check_circle_rounded, size: 72, color: AppColors.success),
          SizedBox(height: 16),
          Text(
            context.strings.text('u0005'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 8),
          Text(
            context.strings.format('u0325', {'tracking': tracking}),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          KtBanner(
            title: context.strings.text('u0211'),
            message: context.strings.text('u0212'),
            tone: KtBannerTone.info,
          ),
          SizedBox(height: 24),
          KtButton(
            label: context.strings.text('u0389'),
            icon: Icons.notifications_active_outlined,
            expand: true,
            onPressed: () => context.go(AppPaths.citizenReports),
          ),
        ],
      );
    }
    return Column(
      children: [
        _WizardHeader(
          step: _step,
          onClose: () => context.go(AppPaths.citizenMap),
        ),
        if (_formMessage != null)
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: KtBanner(
              title: context.strings.text('u0213'),
              message: _formMessage!,
              tone: KtBannerTone.warning,
            ),
          ),
        Expanded(
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: 220),
            child: KeyedSubtree(key: ValueKey(_step), child: _body(context)),
          ),
        ),
        _WizardFooter(
          step: _step,
          busy:
              context.watch<SnapshotController>().busy ||
              _analyzing ||
              _takingPhoto,
          onBack: _step == 0
              ? null
              : () => setState(() {
                  _formMessage = null;
                  _step -= 1;
                }),
          onNext: () => unawaited(_next()),
        ),
      ],
    );
  }

  Widget _body(BuildContext context) => switch (_step) {
    0 => _typeStep(context),
    1 => _photoStep(context),
    2 => _locationStep(context),
    3 => _detailsStep(context),
    _ => _reviewStep(context),
  };

  Widget _typeStep(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        Text(
          context.strings.text('u0006'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(height: 6),
        Text(context.strings.text('u0007')),
        SizedBox(height: 16),
        KtBanner(
          title: context.strings.text('u0214'),
          message: context.strings.text('u0218'),
          tone: KtBannerTone.info,
        ),
        SizedBox(height: 16),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var index = 0; index < _categories.length; index++) ...[
                RadioListTile<String>(
                  value: _categories[index].id,
                  groupValue: _category,
                  secondary: Icon(
                    _categories[index].icon,
                    color: AppColors.brandBlue800,
                  ),
                  title: Text(
                    context.strings.text(_categories[index].titleKey),
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    context.strings.text(_categories[index].hintKey),
                  ),
                  onChanged: (value) =>
                      setState(() => _category = value ?? _category),
                ),
                if (index != _categories.length - 1) Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _photoStep(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        Text(
          context.strings.text('u0008'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(height: 6),
        Text(context.strings.text('u0009')),
        SizedBox(height: 16),
        if (_capture == null)
          Container(
            height: 260,
            decoration: BoxDecoration(
              color: AppColors.brandBlue050,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Icon(
                Icons.add_a_photo_outlined,
                size: 72,
                color: AppColors.brandBlue800,
              ),
            ),
          )
        else
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _capture!.bytes,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                      ),
                      title: Text(context.strings.text('u0010')),
                    ),
                    Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                      ),
                      title: Text(context.strings.text('u0011')),
                    ),
                    Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.person_search_outlined,
                        color: AppColors.plannedInk,
                      ),
                      title: Text(context.strings.text('u0012')),
                      subtitle: Text(context.strings.text('u0013')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        SizedBox(height: 16),
        if (_cameraMessage != null)
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: KtBanner(
              title: context.strings.text('u0215'),
              message: _cameraMessage!,
              tone: KtBannerTone.warning,
            ),
          ),
        KtButton(
          label: _capture == null
              ? context.strings.text('u0489')
              : context.strings.text('u0490'),
          icon: Icons.camera_alt_outlined,
          expand: true,
          busy: _takingPhoto,
          onPressed: () => unawaited(_takePhoto()),
        ),
        SizedBox(height: 10),
        KtButton(
          label: context.strings.text('u0390'),
          kind: KtButtonKind.text,
          expand: true,
          onPressed: () => setState(() {
            _capture = null;
            _prepared = null;
            _step = 2;
          }),
        ),
      ],
    );
  }

  Widget _locationStep(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        Text(
          context.strings.text('u0014'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(height: 6),
        Text(context.strings.text('u0015')),
        SizedBox(height: 16),
        Container(
          height: 210,
          decoration: BoxDecoration(
            color: Color(0xffeaf1ed),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.map_outlined,
                size: 110,
                color: AppColors.brandBlue100,
              ),
              Icon(Icons.location_pin, size: 52, color: AppColors.critical),
            ],
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _latitude,
                keyboardType: TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: context.strings.text('u0208'),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _longitude,
                keyboardType: TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: context.strings.text('u0209'),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        KtBanner(
          title: context.strings.text('u0216'),
          message: context.strings.text('u0219'),
          tone: KtBannerTone.info,
        ),
      ],
    );
  }

  Widget _detailsStep(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        Text(
          context.strings.text('u0016'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(height: 6),
        Text(context.strings.text('u0017')),
        SizedBox(height: 16),
        TextField(
          key: ValueKey('report-description'),
          controller: _description,
          maxLines: 6,
          maxLength: 600,
          decoration: InputDecoration(
            labelText: context.strings.text('u0210'),
            hintText: context.strings.text('u0207'),
            alignLabelWithHint: true,
          ),
        ),
        SizedBox(height: 12),
        KtBanner(
          title: context.strings.text('u0217'),
          message: context.strings.text('u0220'),
          tone: KtBannerTone.info,
        ),
      ],
    );
  }

  Widget _reviewStep(BuildContext context) {
    final suggestions = _analysis?.suggestions ?? <AiCategorySuggestion>[];
    final duplicates =
        _analysis?.duplicateCandidates ?? <AiDuplicateCandidate>[];
    final primary = suggestions.isEmpty ? null : suggestions.first;
    final duplicate = duplicates.isEmpty ? null : duplicates.first;
    final mediaStatus = _prepared?.reference.privacyStatus;
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        Text(
          context.strings.text('u0018'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(height: 16),
        KtCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ReviewRow(
                label: context.strings.text('u0391'),
                value: context.strings.categoryLabel(_category),
              ),
              _ReviewRow(
                label: context.strings.text('u0505'),
                value: '${_latitude.text}, ${_longitude.text}',
              ),
              _ReviewRow(
                label: context.strings.text('u0392'),
                value: _capture == null
                    ? context.strings.text('u0645')
                    : context.strings.text('u0646'),
              ),
              _ReviewRow(
                label: context.strings.text('u0578'),
                value: mediaStatus == null
                    ? context.strings.text('u0491')
                    : mediaStatus == PrivacyStatus.safe
                    ? context.strings.text('u0492')
                    : context.strings.text('u0493'),
              ),
            ],
          ),
        ),
        SizedBox(height: 14),
        KtBanner(
          title: _analysis?.status == AiAnalysisStatus.complete
              ? context.strings.text('u0494')
              : context.strings.text('u0495'),
          message: primary == null
              ? context.strings.text('u0496')
              : context.strings.format('u0497', {
                  'category': context.strings.categoryLabel(primary.category),
                  'confidence': primary.confidence,
                }),
          tone: KtBannerTone.info,
          action: primary != null && primary.category != _category
              ? KtButton(
                  label: context.strings.text('u0393'),
                  kind: KtButtonKind.text,
                  onPressed: () => setState(() => _category = primary.category),
                )
              : null,
        ),
        if (duplicate != null) ...[
          SizedBox(height: 14),
          Card(
            child: Column(
              children: [
                RadioListTile<bool>(
                  value: true,
                  groupValue: _corroborateExisting,
                  title: Text(context.strings.text('u0019')),
                  subtitle: Text(
                    context.strings.format('u0326', {
                      'distance': duplicate.distanceMeters,
                      'confidence': duplicate.confidence,
                    }),
                  ),
                  onChanged: (value) =>
                      setState(() => _corroborateExisting = value ?? false),
                ),
                RadioListTile<bool>(
                  value: false,
                  groupValue: _corroborateExisting,
                  title: Text(context.strings.text('u0020')),
                  onChanged: (value) =>
                      setState(() => _corroborateExisting = value ?? false),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: 14),
        Text(context.strings.text('u0021')),
      ],
    );
  }

  Future<void> _next() async {
    setState(() => _formMessage = null);
    if (_step == 2) {
      final latitude = double.tryParse(_latitude.text);
      final longitude = double.tryParse(_longitude.text);
      if (latitude == null ||
          longitude == null ||
          !IstanbulBounds.contains(latitude, longitude)) {
        setState(() => _formMessage = context.strings.text('u0498'));
        return;
      }
    }
    if (_step == 3) {
      if (_description.text.trim().length < 10) {
        setState(() => _formMessage = context.strings.text('u0499'));
        return;
      }
      await _analyze();
      if (!mounted) return;
    }
    if (_step < 4) {
      setState(() => _step += 1);
      return;
    }
    await _submit();
  }

  Future<void> _takePhoto() async {
    setState(() {
      _takingPhoto = true;
      _cameraMessage = null;
    });
    try {
      final result = await context.read<CameraCaptureGateway>().capture();
      if (!mounted || result == null) return;
      final actorId = context.read<SessionController>().principal?.account.id;
      if (actorId == null) return;
      final prepared = context.read<MediaPipeline>().prepare(
        actorId: actorId,
        capture: result,
        // Gerçek bir yüz/plaka redaksiyon motoru bağlanana kadar kamusal kopya
        // üretmeyen fail-closed politika.
        scenario: DemoPrivacyScenario.manualReview,
      );
      setState(() {
        _capture = result;
        _prepared = prepared;
      });
    } on CameraFailure catch (error) {
      if (mounted)
        setState(
          () => _cameraMessage = _cameraFailureMessage(context, error.code),
        );
    } finally {
      if (mounted) setState(() => _takingPhoto = false);
    }
  }

  Future<void> _recoverCapture() async {
    try {
      final capture = await context
          .read<CameraCaptureGateway>()
          .recoverInterruptedCapture();
      if (!mounted || capture == null) return;
      final actorId = context.read<SessionController>().principal?.account.id;
      if (actorId == null) return;
      setState(() {
        _capture = capture;
        _prepared = context.read<MediaPipeline>().prepare(
          actorId: actorId,
          capture: capture,
          scenario: DemoPrivacyScenario.manualReview,
        );
        _cameraMessage = context.strings.text('u0500');
      });
    } on CameraFailure catch (error) {
      if (mounted)
        setState(
          () => _cameraMessage = _cameraFailureMessage(context, error.code),
        );
    }
  }

  Future<void> _analyze() async {
    setState(() => _analyzing = true);
    final result = await context.read<KentAiAnalysisService>().analyze(
      AiAnalysisInput(
        description: _description.text.trim(),
        categoryHint: _category,
        latitude: double.parse(_latitude.text),
        longitude: double.parse(_longitude.text),
        capturedAt: (_capture?.capturedAt ?? DateTime.now().toUtc()).toUtc(),
        mediaId: _prepared?.reference.id,
      ),
    );
    if (mounted)
      setState(() {
        _analysis = result;
        _analyzing = false;
      });
  }

  Future<void> _submit() async {
    final actorId = context.read<SessionController>().principal?.account.id;
    if (actorId == null || _analysis == null) return;
    final controller = context.read<SnapshotController>();
    final duplicate = _analysis!.duplicateCandidates.isEmpty
        ? null
        : _analysis!.duplicateCandidates.first;
    if (_corroborateExisting && duplicate != null) {
      final result = await controller.citizenAction(
        actorId: actorId,
        kind: CitizenActionKind.corroborate,
        resourceId: duplicate.incidentId,
        payload: {'kind': enumWire(CorroborationKind.stillPresent)},
      );
      if (mounted && result != null)
        setState(() => _tracking = context.strings.text('u0501'));
      return;
    }
    final now = DateTime.now().toUtc();
    final analysisDto = _analysis!.toSnapshotDto(
      id: 'analysis_${actorId}_${now.microsecondsSinceEpoch}',
      createdAt: now,
    );
    final result = await controller.createReport(
      actorId: actorId,
      clientMutationId: 'citizen_${actorId}_${now.microsecondsSinceEpoch}',
      category: _category,
      description: _description.text.trim(),
      latitude: double.parse(_latitude.text),
      longitude: double.parse(_longitude.text),
      preparedMedia: _prepared,
      analysis: analysisDto,
      manualReviewRequired:
          _prepared?.reference.privacyStatus != PrivacyStatus.safe ||
          _analysis!.status != AiAnalysisStatus.complete,
      riskLevel: _analysis!.riskLevel,
    );
    if (!mounted) return;
    if (result == null) {
      setState(() => _formMessage = context.strings.text('u0502'));
    } else {
      setState(() => _tracking = result.trackingNumber);
    }
  }
}

String _cameraFailureMessage(BuildContext context, CameraFailureCode code) =>
    switch (code) {
      CameraFailureCode.permissionDenied => context.strings.text('u0664'),
      CameraFailureCode.permissionRestricted => context.strings.text('u0665'),
      CameraFailureCode.unavailable => context.strings.text('u0666'),
      CameraFailureCode.cancelled => context.strings.text('u0669'),
      CameraFailureCode.interrupted => context.strings.text('u0667'),
      CameraFailureCode.quotaExceeded => context.strings.text('u0668'),
      CameraFailureCode.invalidMedia => context.strings.text('u0670'),
    };

final class _WizardHeader extends StatelessWidget {
  _WizardHeader({required this.step, required this.onClose});
  final int step;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final labels = [
      context.strings.text('u0503'),
      context.strings.text('u0504'),
      context.strings.text('u0505'),
      context.strings.text('u0506'),
      context.strings.text('u0507'),
    ];
    return Material(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 8, 12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.strings.text('u0022'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: context.strings.text('u0062'),
                  onPressed: onClose,
                  icon: Icon(Icons.close),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  '${step + 1} / 5',
                  style: TextStyle(
                    color: AppColors.brandBlue800,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  labels[step],
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: (step + 1) / 5,
              minHeight: 6,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}

final class _WizardFooter extends StatelessWidget {
  _WizardFooter({
    required this.step,
    required this.busy,
    required this.onBack,
    required this.onNext,
  });
  final int step;
  final bool busy;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Material(
        elevation: 8,
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              if (onBack != null) ...[
                Expanded(
                  child: KtButton(
                    label: context.strings.text('u0647'),
                    kind: KtButtonKind.secondary,
                    onPressed: onBack,
                  ),
                ),
                SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: KtButton(
                  label: step == 4
                      ? context.strings.text('u0508')
                      : step == 0
                      ? context.strings.text('u0509')
                      : context.strings.text('u0510'),
                  icon: step == 4
                      ? Icons.send_rounded
                      : Icons.arrow_forward_rounded,
                  busy: busy,
                  onPressed: busy ? null : onNext,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _ReviewRow extends StatelessWidget {
  _ReviewRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: KtSpacing.x2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
