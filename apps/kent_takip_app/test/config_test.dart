import 'package:flutter_test/flutter_test.dart';
import 'package:kent_takip_app/src/config/app_environment.dart';

void main() {
  test('default environment is deterministic local demo', () {
    final config = AppConfig.fromEnvironment();

    expect(config.environment, AppEnvironment.demo);
    expect(config.dataMode, DemoDataMode.local);
  });
}
