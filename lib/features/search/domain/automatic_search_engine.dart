import '../../network/domain/network_mode.dart';
import '../../settings/domain/app_settings.dart';

/// Returns the search engine RAD should use for the current network state.
///
/// Full global internet always uses Google. When only Iran's internal network
/// is reachable RAD switches to Zarebin. Fully offline mode intentionally
/// returns null so callers can use local/offline data instead of issuing a
/// broken web request.
RadSearchEngine? automaticSearchEngine(NetworkMode mode) => switch (mode) {
      NetworkMode.fullInternet => RadSearchEngine.google,
      NetworkMode.internalOnly => RadSearchEngine.zarebin,
      NetworkMode.offline => null,
    };
