final class SlaTargetRange {
  const SlaTargetRange({required this.min, required this.max});

  final Duration min;
  final Duration max;

  String get label {
    final minHours = min.inHours;
    final maxHours = max.inHours;
    return '$minHours–$maxHours saat hedef aralığı (garanti değildir)';
  }
}

abstract final class FieldSlaPolicy {
  static SlaTargetRange targetFor(String category, String unitId) {
    final base = switch (category) {
      'water_infrastructure' || 'water_leak' => const SlaTargetRange(
          min: Duration(hours: 8),
          max: Duration(hours: 36),
        ),
      'traffic_signal' || 'lighting' => const SlaTargetRange(
          min: Duration(hours: 12),
          max: Duration(hours: 48),
        ),
      'road_surface_damage' || 'road_maintenance' => const SlaTargetRange(
          min: Duration(hours: 24),
          max: Duration(hours: 96),
        ),
      _ => const SlaTargetRange(
          min: Duration(hours: 24),
          max: Duration(hours: 120),
        ),
    };
    // Demo config is deterministic. The unit remains part of the policy key so
    // a real backend can replace this table without changing callers.
    if (unitId.contains('critical')) {
      return SlaTargetRange(
        min: Duration(microseconds: base.min.inMicroseconds ~/ 2),
        max: Duration(microseconds: base.max.inMicroseconds ~/ 2),
      );
    }
    return base;
  }
}
