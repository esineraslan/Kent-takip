enum AppEnvironment { demo, test, release }

enum DemoDataMode { local, shared }

final class AppConfig {
  const AppConfig({
    required this.environment,
    required this.dataMode,
    this.forceBootstrapFailure = false,
    this.demoApiUrl = 'http://127.0.0.1:8080',
    this.mapTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    this.mapTileTimeoutMs = 4000,
  });

  factory AppConfig.fromEnvironment() {
    const environmentValue = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'demo',
    );
    const dataModeValue = String.fromEnvironment(
      'DEMO_DATA_MODE',
      defaultValue: 'local',
    );
    const forceBootstrapFailure = bool.fromEnvironment(
      'FORCE_BOOTSTRAP_FAILURE',
    );
    const demoApiUrl = String.fromEnvironment(
      'DEMO_API_URL',
      defaultValue: 'http://127.0.0.1:8080',
    );
    const mapTileUrl = String.fromEnvironment(
      'MAP_TILE_URL',
      defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    );
    const mapTileTimeoutMs = int.fromEnvironment(
      'MAP_TILE_TIMEOUT_MS',
      defaultValue: 4000,
    );
    final parsedApiUrl = Uri.tryParse(demoApiUrl);
    if (parsedApiUrl == null ||
        !parsedApiUrl.hasAuthority ||
        !{'http', 'https'}.contains(parsedApiUrl.scheme)) {
      throw const FormatException('DEMO_API_URL geçerli HTTP(S) adresi olmalıdır.');
    }
    final parsedTileUrl = Uri.tryParse(
      mapTileUrl
          .replaceAll('{z}', '11')
          .replaceAll('{x}', '1188')
          .replaceAll('{y}', '768'),
    );
    if (parsedTileUrl == null || parsedTileUrl.scheme != 'https' ||
        !mapTileUrl.contains('{z}') ||
        !mapTileUrl.contains('{x}') ||
        !mapTileUrl.contains('{y}')) {
      throw const FormatException('MAP_TILE_URL HTTPS ve {z}/{x}/{y} şablonlu olmalıdır.');
    }
    if (mapTileTimeoutMs < 1000 || mapTileTimeoutMs > 15000) {
      throw const FormatException('MAP_TILE_TIMEOUT_MS 1000–15000 aralığında olmalıdır.');
    }
    return AppConfig(
      environment: _parse(
        AppEnvironment.values,
        environmentValue,
        'APP_ENV',
      ),
      dataMode: _parse(
        DemoDataMode.values,
        dataModeValue,
        'DEMO_DATA_MODE',
      ),
      forceBootstrapFailure: forceBootstrapFailure,
      demoApiUrl: demoApiUrl,
      mapTileUrl: mapTileUrl,
      mapTileTimeoutMs: mapTileTimeoutMs,
    );
  }

  final AppEnvironment environment;
  final DemoDataMode dataMode;
  final bool forceBootstrapFailure;
  final String demoApiUrl;
  final String mapTileUrl;
  final int mapTileTimeoutMs;

  Uri get demoApiUri => Uri.parse(demoApiUrl);

  bool get isDemo => environment == AppEnvironment.demo;

  static T _parse<T extends Enum>(
    Iterable<T> values,
    String raw,
    String key,
  ) {
    for (final value in values) {
      if (value.name == raw) {
        return value;
      }
    }
    throw FormatException('$key değeri desteklenmiyor: $raw');
  }
}
