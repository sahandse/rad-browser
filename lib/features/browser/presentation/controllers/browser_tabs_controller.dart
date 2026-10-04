import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/browser_tab.dart';

final browserTabsProvider =
    StateNotifierProvider<BrowserTabsController, List<BrowserTab>>((ref) {
  return BrowserTabsController();
});

class BrowserTabsController extends StateNotifier<List<BrowserTab>> {
  BrowserTabsController() : super(const []);

  String open(Uri url) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final tab = BrowserTab(
      id: id,
      url: url,
      title: url.host.isEmpty ? 'تب جدید' : url.host,
      isLoading: true,
    );
    state = [...state, tab];
    return id;
  }

  void update(
    String id, {
    Uri? url,
    String? title,
    Uri? faviconUrl,
    bool? isLoading,
    double? progress,
  }) {
    state = [
      for (final tab in state)
        if (tab.id == id)
          tab.copyWith(
            url: url,
            title: title,
            faviconUrl: faviconUrl,
            isLoading: isLoading,
            progress: progress,
          )
        else
          tab,
    ];
  }

  void close(String id) {
    state = state.where((tab) => tab.id != id).toList(growable: false);
  }

  void closeAll() {
    state = const [];
  }
}
