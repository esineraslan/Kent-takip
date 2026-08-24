import 'package:kent_takip_contracts/kent_takip_contracts.dart';
import 'package:kent_takip_domain/kent_takip_domain.dart';

final class IstanbulPlace {
  IstanbulPlace({
    required this.id,
    required this.district,
    required this.label,
    required this.latitude,
    required this.longitude,
  }) {
    requireText(id, 'id');
    requireText(district, 'district');
    requireText(label, 'label');
    IstanbulBounds.requireInside(latitude, longitude);
  }

  factory IstanbulPlace.fromObject(Object? value, String path) {
    final json = expectMap(value, path);
    final latitude = json['latitude'];
    final longitude = json['longitude'];
    if (latitude is! num || longitude is! num) {
      fail(FailureCode.validation, '$path koordinatı geçersiz.');
    }
    return IstanbulPlace(
      id: expectString(json['id'], '$path.id'),
      district: expectString(json['district'], '$path.district'),
      label: expectString(json['label'], '$path.label'),
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
    );
  }

  final String id;
  final String district;
  final String label;
  final double latitude;
  final double longitude;
}

abstract final class IstanbulBounds {
  static const minLatitude = 40.802;
  static const maxLatitude = 41.352;
  static const minLongitude = 27.971;
  static const maxLongitude = 29.958;

  static bool contains(double latitude, double longitude) =>
      latitude >= minLatitude && latitude <= maxLatitude &&
      longitude >= minLongitude && longitude <= maxLongitude;

  static void requireInside(double latitude, double longitude) {
    GeoPoint(latitude: latitude, longitude: longitude);
    if (!contains(latitude, longitude)) {
      fail(
        FailureCode.validation,
        'Konum İstanbul hizmet sınırlarının dışında.',
        field: 'location',
      );
    }
  }
}

final class PlaceSearchIndex {
  PlaceSearchIndex(Iterable<IstanbulPlace> places)
      : _places = List.unmodifiable(places);

  final List<IstanbulPlace> _places;

  List<IstanbulPlace> search(String raw, {int limit = 8}) {
    final query = normalizeTurkishSearch(raw);
    if (query.isEmpty) return const [];
    final results = <({IstanbulPlace place, int rank})>[];
    for (final place in _places) {
      final district = normalizeTurkishSearch(place.district);
      final label = normalizeTurkishSearch(place.label);
      final exact = district == query || label == query;
      final prefix = district.startsWith(query) || label.startsWith(query);
      final contains = district.contains(query) || label.contains(query);
      if (!contains) continue;
      results.add((place: place, rank: exact ? 0 : prefix ? 1 : 2));
    }
    results.sort((left, right) {
      final rank = left.rank.compareTo(right.rank);
      return rank != 0 ? rank : left.place.label.compareTo(right.place.label);
    });
    return results.take(limit).map((item) => item.place).toList(growable: false);
  }
}

String normalizeTurkishSearch(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('İ'.toLowerCase(), 'i')
      .replaceAll('ç', 'c')
      .replaceAll('ğ', 'g')
      .replaceAll('ö', 'o')
      .replaceAll('ş', 's')
      .replaceAll('ü', 'u')
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
}
