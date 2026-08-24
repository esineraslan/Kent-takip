import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:kent_takip_app/src/config/app_environment.dart';
import 'package:kent_takip_app/src/localization/app_strings.dart';
import 'package:kent_takip_app/src/localization/locale_formatter.dart';
import 'package:kent_takip_app/src/ui/app_theme.dart';
import 'package:kent_takip_app/src/ui/design/components.dart';
import 'package:kent_takip_app/src/ui/design/pins.dart';
import 'package:kent_takip_application/kent_takip_application.dart';
import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:provider/provider.dart';

enum MapViewMode { map, accessibleList }

enum MapFilter { all, active, planned, traffic }

final class MapExperience extends StatefulWidget {
  MapExperience({
    required this.snapshot,
    required this.viewerId,
    required this.staff,
    this.previewPins = const [],
    super.key,
  });

  final AppSnapshotDto snapshot;
  final String? viewerId;
  final bool staff;
  final List<VisibleMapPin> previewPins;

  @override
  State<MapExperience> createState() => _MapExperienceState();
}

final class _MapExperienceState extends State<MapExperience>
    with WidgetsBindingObserver {
  final _search = TextEditingController();
  Timer? _debounce;
  Timer? _workClockTimer;
  PlaceSearchIndex? _places;
  List<IstanbulPlace> _results = [];
  MapViewMode _mode = MapViewMode.map;
  MapFilter _filter = MapFilter.all;
  VisibleMapPin? _selected;
  IstanbulPlace? _center;
  ({double latitude, double longitude})? _areaCenter;
  ({double latitude, double longitude})? _viewportCenter;
  bool _searchAreaOnly = false;
  bool _mapMovedByUser = false;
  int _viewCommand = 0;
  String? _focusAnnouncement;
  final _projection = MemoizedMapProjectionService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadPlaces());
    _scheduleWorkClock();
  }

  @override
  void didUpdateWidget(covariant MapExperience oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshot.revision != widget.snapshot.revision ||
        oldWidget.previewPins != widget.previewPins) {
      _scheduleWorkClock();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (mounted) setState(() {});
    _scheduleWorkClock();
  }

  void _scheduleWorkClock() {
    _workClockTimer?.cancel();
    final now = DateTime.now().toUtc();
    DateTime? nextBoundary;
    for (final work in widget.snapshot.payload.municipalWorks) {
      if (work.status != WorkStatus.publishedPlanned &&
          work.status != WorkStatus.active) {
        continue;
      }
      for (final boundary in [work.startsAt, work.expectedEndsAt]) {
        if (!boundary.isAfter(now)) continue;
        if (nextBoundary == null || boundary.isBefore(nextBoundary))
          nextBoundary = boundary;
      }
    }
    if (nextBoundary == null) return;
    final wait = nextBoundary.difference(now) + Duration(milliseconds: 50);
    _workClockTimer = Timer(wait, () {
      if (!mounted) return;
      setState(() {});
      _scheduleWorkClock();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _workClockTimer?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadPlaces() async {
    final raw = await rootBundle.loadString('assets/map/places.json');
    final values = expectList(jsonDecode(raw), 'places');
    final places = decodeList(values, 'places', IstanbulPlace.fromObject);
    if (!mounted) return;
    setState(() => _places = PlaceSearchIndex(places));
  }

  void _onQuery(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      final results = _places?.search(value) ?? const <IstanbulPlace>[];
      final normalized = normalizeTurkishSearch(value);
      IstanbulPlace? exact;
      for (final result in results) {
        if (normalizeTurkishSearch(result.label) == normalized ||
            normalizeTurkishSearch(result.district) == normalized) {
          exact = result;
          break;
        }
      }
      if (exact != null) {
        _focusPlace(exact);
        return;
      }
      setState(() => _results = results);
    });
  }

  void _submitSearch(String _) {
    final results = _places?.search(_search.text) ?? const <IstanbulPlace>[];
    if (results.isNotEmpty) _focusPlace(results.first);
  }

  void _focusPlace(IstanbulPlace place) {
    if (!mounted) return;
    setState(() {
      _center = place;
      _areaCenter = (latitude: place.latitude, longitude: place.longitude);
      _viewportCenter = _areaCenter;
      _searchAreaOnly = true;
      _mapMovedByUser = false;
      _search.text = place.label;
      _results = [];
      _viewCommand++;
      _focusAnnouncement = context.strings.format('u0757', {
        'place': place.label,
      });
    });
  }

  void _showAllIstanbul() {
    setState(() {
      _center = null;
      _areaCenter = null;
      _viewportCenter = null;
      _searchAreaOnly = false;
      _mapMovedByUser = false;
      _search.clear();
      _results = [];
      _focusAnnouncement = null;
      _viewCommand++;
    });
  }

  void _searchCurrentArea() {
    final viewport = _viewportCenter;
    if (viewport == null) return;
    setState(() {
      _areaCenter = viewport;
      _searchAreaOnly = true;
      _mapMovedByUser = false;
    });
  }

  void _onViewportSettled(double latitude, double longitude) {
    if (!mounted) return;
    setState(() {
      _viewportCenter = (latitude: latitude, longitude: longitude);
      _searchAreaOnly = false;
      _mapMovedByUser = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final projectedPins = _projection.project(
      widget.snapshot,
      viewerId: widget.viewerId,
      staff: widget.staff,
      nowUtc: DateTime.now().toUtc(),
    );
    var pins = <VisibleMapPin>[...projectedPins, ...widget.previewPins];
    pins = switch (_filter) {
      MapFilter.active =>
        pins.where((item) => item.kind == PinKind.verifiedActive).toList(),
      MapFilter.planned =>
        pins.where((item) => item.kind == PinKind.publishedPlanned).toList(),
      _ => pins,
    };
    final areaCenter = _areaCenter;
    if (_searchAreaOnly && areaCenter != null) {
      pins = pins
          .where(
            (item) =>
                (item.latitude - areaCenter.latitude).abs() <= .06 &&
                (item.longitude - areaCenter.longitude).abs() <= .06,
          )
          .toList();
    }
    final alerts = _projection.officialAlerts(widget.snapshot);
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            children: [
              TextField(
                controller: _search,
                onChanged: _onQuery,
                onSubmitted: _submitSearch,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: context.strings.text('u0198'),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: context.strings.text('u0199'),
                          onPressed: _showAllIstanbul,
                          icon: Icon(Icons.close_rounded),
                        ),
                ),
              ),
              if (_results.isNotEmpty)
                Material(
                  elevation: 4,
                  child: Column(
                    children: [
                      for (final result in _results.take(5))
                        ListTile(
                          dense: true,
                          leading: Icon(Icons.place_outlined),
                          title: Text(result.label),
                          subtitle: Text(result.district),
                          onTap: () => _focusPlace(result),
                        ),
                    ],
                  ),
                ),
              SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<MapFilter>(
                  segments: [
                    ButtonSegment(
                      value: MapFilter.all,
                      label: Text(context.strings.text('u0026')),
                    ),
                    ButtonSegment(
                      value: MapFilter.active,
                      label: Text(context.strings.text('u0024')),
                    ),
                    ButtonSegment(
                      value: MapFilter.planned,
                      label: Text(context.strings.text('u0193')),
                    ),
                    ButtonSegment(
                      value: MapFilter.traffic,
                      label: Text(context.strings.text('u0194')),
                    ),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (value) =>
                      setState(() => _filter = value.first),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 4,
            runSpacing: 0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (_mapMovedByUser && !_searchAreaOnly)
                TextButton.icon(
                  onPressed: _searchCurrentArea,
                  icon: const Icon(Icons.center_focus_strong),
                  label: Text(context.strings.text('u0201')),
                ),
              if (_center != null || _searchAreaOnly || _mapMovedByUser)
                TextButton.icon(
                  onPressed: _showAllIstanbul,
                  icon: const Icon(Icons.public_rounded),
                  label: Text(context.strings.text('u0200')),
                ),
              IconButton(
                tooltip: _mode == MapViewMode.map
                    ? context.strings.text('u0202')
                    : context.strings.text('u0756'),
                onPressed: () => setState(() {
                  _mode = _mode == MapViewMode.map
                      ? MapViewMode.accessibleList
                      : MapViewMode.map;
                }),
                icon: Icon(
                  _mode == MapViewMode.map
                      ? Icons.view_list_rounded
                      : Icons.map_rounded,
                ),
              ),
            ],
          ),
        ),
        if (_focusAnnouncement != null)
          Semantics(
            key: const ValueKey('map-focus-status'),
            liveRegion: true,
            label: _focusAnnouncement,
            child: const SizedBox.shrink(),
          ),
        Expanded(
          child: _mode == MapViewMode.accessibleList
              ? _AccessiblePinList(pins: pins, onSelected: _select)
              : MapSurface(
                  pins: pins,
                  alerts: alerts,
                  showTraffic: _filter == MapFilter.traffic,
                  center: _center,
                  viewCommand: _viewCommand,
                  onViewportSettled: _onViewportSettled,
                  onSelected: _select,
                ),
        ),
        if (_selected != null)
          _PinDetail(pin: _selected!, onClose: () => _select(null)),
      ],
    );
  }

  void _select(VisibleMapPin? pin) => setState(() => _selected = pin);
}

typedef MapViewportSettled = void Function(double latitude, double longitude);

final class MapSurface extends StatefulWidget {
  MapSurface({
    required this.pins,
    required this.alerts,
    required this.showTraffic,
    required this.onSelected,
    required this.viewCommand,
    required this.onViewportSettled,
    this.center,
    super.key,
  });

  final List<VisibleMapPin> pins;
  final List<OfficialAlertPin> alerts;
  final bool showTraffic;
  final IstanbulPlace? center;
  final int viewCommand;
  final MapViewportSettled onViewportSettled;
  final ValueChanged<VisibleMapPin?> onSelected;

  @override
  State<MapSurface> createState() => _MapSurfaceState();
}

final class _MapSurfaceState extends State<MapSurface> {
  static const _istanbulCenter = LatLng(41.045, 28.98);
  static const _overviewZoom = 10.2;
  static const _focusedZoom = 13.2;
  static const _minZoom = 9.0;
  static const _maxZoom = 18.0;

  final MapController _mapController = MapController();
  Timer? _viewportDebounce;
  bool _mapReady = false;
  bool _tileUnavailable = false;

  @override
  void didUpdateWidget(covariant MapSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewCommand != widget.viewCommand) {
      _applyRequestedView();
    }
  }

  @override
  void dispose() {
    _viewportDebounce?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _applyRequestedView() {
    if (!_mapReady) return;
    final place = widget.center;
    _mapController.move(
      place == null ? _istanbulCenter : LatLng(place.latitude, place.longitude),
      place == null ? _overviewZoom : _focusedZoom,
      id: 'search-focus',
    );
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;
    _viewportDebounce?.cancel();
    _viewportDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      widget.onViewportSettled(camera.center.latitude, camera.center.longitude);
    });
  }

  void _markTileUnavailable(TileImage _, Object __, StackTrace? ___) {
    if (_tileUnavailable || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _tileUnavailable = true);
    });
  }

  void _zoomBy(double delta) {
    if (!_mapReady) return;
    final camera = _mapController.camera;
    final next = (camera.zoom + delta).clamp(_minZoom, _maxZoom).toDouble();
    _mapController.move(camera.center, next, id: 'zoom-control');
  }

  void _zoomCluster(double latitude, double longitude) {
    if (!_mapReady) return;
    final next = (_mapController.camera.zoom + 1.5)
        .clamp(_minZoom, _maxZoom)
        .toDouble();
    _mapController.move(LatLng(latitude, longitude), next, id: 'cluster-focus');
  }

  @override
  Widget build(BuildContext context) {
    final config = context.read<AppConfig>();
    final clusters = DemoProjections.clusters(widget.pins);
    final offline =
        config.environment == AppEnvironment.test || _tileUnavailable;

    final markers = <Marker>[
      for (final cluster in clusters)
        Marker(
          point: LatLng(cluster.latitude, cluster.longitude),
          width: 58,
          height: 58,
          child: cluster.pins.length == 1
              ? GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onSelected(cluster.pins.first),
                  child: KtMapPin(
                    kind: cluster.pins.first.kind,
                    category: context.strings.categoryLabel(
                      cluster.pins.first.category,
                    ),
                    location: cluster.pins.first.locationLabel,
                  ),
                )
              : Semantics(
                  button: true,
                  label: context.strings.format('u0372', {
                    'count': cluster.pins.length,
                  }),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () =>
                        _zoomCluster(cluster.latitude, cluster.longitude),
                    child: CircleAvatar(
                      backgroundColor: AppColors.brandBlue800,
                      foregroundColor: Colors.white,
                      child: Text('${cluster.pins.length}'),
                    ),
                  ),
                ),
        ),
      for (final alert in widget.alerts)
        Marker(
          point: LatLng(alert.latitude, alert.longitude),
          width: 48,
          height: 48,
          child: Tooltip(
            message: context.strings.format('u0471', {
              'title': alert.title,
              'authority': alert.authority,
            }),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.critical,
              size: 36,
            ),
          ),
        ),
    ];

    return Semantics(
      label: context.strings.text('u0204'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          FlutterMap(
            key: const ValueKey('interactive-city-map'),
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _istanbulCenter,
              initialZoom: _overviewZoom,
              minZoom: _minZoom,
              maxZoom: _maxZoom,
              backgroundColor: const Color(0xffedf2ec),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onMapReady: () {
                _mapReady = true;
                _applyRequestedView();
              },
              onPositionChanged: _onPositionChanged,
            ),
            children: [
              if (config.environment == AppEnvironment.test)
                IgnorePointer(child: CustomPaint(painter: _OfflineMapPainter()))
              else
                TileLayer(
                  urlTemplate: config.mapTileUrl,
                  userAgentPackageName: 'com.ibb.kent_takip',
                  maxNativeZoom: 19,
                  panBuffer: 1,
                  errorTileCallback: _markTileUnavailable,
                ),
              if (widget.showTraffic)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: const [
                        LatLng(41.015, 28.91),
                        LatLng(41.035, 28.97),
                        LatLng(41.055, 29.05),
                      ],
                      strokeWidth: 7,
                      color: Color(0xb3d32f2f),
                    ),
                    Polyline(
                      points: const [
                        LatLng(41.09, 28.90),
                        LatLng(41.075, 28.99),
                        LatLng(41.065, 29.08),
                      ],
                      strokeWidth: 6,
                      color: Color(0xb3f57c00),
                    ),
                  ],
                ),
              MarkerLayer(markers: markers),
            ],
          ),
          if (offline)
            Positioned(
              left: 12,
              right: 72,
              top: 12,
              child: KtBanner(
                title: context.strings.text('u0205'),
                message: context.strings.text('u0206'),
                tone: KtBannerTone.warning,
              ),
            ),
          Positioned(
            right: 12,
            bottom: 34,
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox.square(
                    dimension: 48,
                    child: IconButton(
                      key: const ValueKey('map-zoom-in'),
                      tooltip: context.strings.text('u0754'),
                      onPressed: () => _zoomBy(1),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ),
                  const SizedBox(width: 48, child: Divider(height: 1)),
                  SizedBox.square(
                    dimension: 48,
                    child: IconButton(
                      key: const ValueKey('map-zoom-out'),
                      tooltip: context.strings.text('u0755'),
                      onPressed: () => _zoomBy(-1),
                      icon: const Icon(Icons.remove_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 6,
            child: ColoredBox(
              color: Colors.white70,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  context.strings.text('u0195'),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _AccessiblePinList extends StatelessWidget {
  _AccessiblePinList({required this.pins, required this.onSelected});
  final List<VisibleMapPin> pins;
  final ValueChanged<VisibleMapPin?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (pins.isEmpty) {
      return Center(child: Text(context.strings.text('u0196')));
    }
    return ListView.separated(
      padding: EdgeInsets.all(12),
      itemCount: pins.length,
      separatorBuilder: (_, _) => SizedBox(height: 8),
      itemBuilder: (context, index) {
        final pin = pins[index];
        return Card(
          child: ListTile(
            leading: Icon(_icon(pin.kind), color: _color(pin.kind)),
            title: Text(context.strings.categoryLabel(pin.category)),
            subtitle: Text('${pin.locationLabel}\n${pin.sourceLabel}'),
            isThreeLine: true,
            trailing: Icon(Icons.chevron_right_rounded),
            onTap: () => onSelected(pin),
          ),
        );
      },
    );
  }
}

final class _PinDetail extends StatelessWidget {
  _PinDetail({required this.pin, required this.onClose});
  final VisibleMapPin pin;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(_icon(pin.kind), color: _color(pin.kind), size: 34),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.strings.categoryLabel(pin.category),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    context.strings.format('u0373', {
                      'source': pin.sourceLabel,
                      'verified': pin.verified
                          ? context.strings.text('u0375')
                          : context.strings.text('u0037'),
                    }),
                  ),
                  Text(
                    context.strings.format('u0374', {
                      'freshness': pin.freshness.name,
                      'updated': pin.updatedAt == null
                          ? ''
                          : context.strings.format('u0377', {
                              'date': context.localeFormat.dateTime(
                                pin.updatedAt!,
                              ),
                            }),
                    }),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: context.strings.text('u0062'),
              onPressed: onClose,
              icon: Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _icon(PinKind kind) => switch (kind) {
  PinKind.verifiedActive => Icons.priority_high_rounded,
  PinKind.publishedPlanned => Icons.schedule_rounded,
  PinKind.pendingVerification => Icons.question_mark_rounded,
  PinKind.criticalReview => Icons.warning_amber_rounded,
};

Color _color(PinKind kind) => switch (kind) {
  PinKind.verifiedActive => AppColors.active,
  PinKind.publishedPlanned => AppColors.plannedInk,
  PinKind.pendingVerification => AppColors.textMuted,
  PinKind.criticalReview => AppColors.critical,
};

final class _OfflineMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Color(0xffedf2ec));
    final water = ui.Path()
      ..moveTo(size.width * .58, 0)
      ..quadraticBezierTo(
        size.width * .42,
        size.height * .45,
        size.width * .64,
        size.height,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(water, Paint()..color = Color(0xffcce6f7));
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 3;
    for (var index = 1; index < 9; index++) {
      final y = size.height * index / 9;
      canvas.drawLine(Offset(0, y), Offset(size.width * .72, y - 20), road);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
