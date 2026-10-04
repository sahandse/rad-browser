import 'package:flutter_test/flutter_test.dart';
import 'package:rad_browser/features/network/domain/network_mode.dart';
import 'package:rad_browser/features/search/domain/automatic_search_engine.dart';
import 'package:rad_browser/features/settings/domain/app_settings.dart';

void main() {
  test('uses Google on full internet', () {
    expect(
      automaticSearchEngine(NetworkMode.fullInternet),
      RadSearchEngine.google,
    );
  });

  test('uses Zarebin on internal-only network', () {
    expect(
      automaticSearchEngine(NetworkMode.internalOnly),
      RadSearchEngine.zarebin,
    );
  });

  test('does not issue web search while fully offline', () {
    expect(automaticSearchEngine(NetworkMode.offline), isNull);
  });
}
