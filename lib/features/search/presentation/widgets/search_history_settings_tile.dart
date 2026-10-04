import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistorySettingsTile extends StatefulWidget {
  const SearchHistorySettingsTile({super.key});

  @override
  State<SearchHistorySettingsTile> createState() => _SearchHistorySettingsTileState();
}

class _SearchHistorySettingsTileState extends State<SearchHistorySettingsTile> {
  bool _enabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _enabled = prefs.getBool('rad.searchHistory.enabled') ?? true;
      _loading = false;
    });
  }

  Future<void> _setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rad.searchHistory.enabled', value);
    if (!value) await prefs.remove('rad.searchHistory.v1');
    if (!mounted) return;
    setState(() => _enabled = value);
  }

  Future<void> _clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('rad.searchHistory.v1');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تاریخچه جستجو پاک شد.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ListTile(
        leading: Icon(Icons.manage_search_rounded),
        title: Text('تاریخچه جستجو'),
        trailing: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return Column(
      children: [
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.manage_search_rounded),
          title: const Text('ذخیره تاریخچه جستجو'),
          subtitle: const Text('برای پیشنهاد سریع‌تر عبارت‌های قبلی روی همین دستگاه ذخیره شوند.'),
          value: _enabled,
          onChanged: _setEnabled,
        ),
        if (_enabled) ...[
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined),
            title: const Text('پاک کردن تاریخچه جستجو'),
            onTap: _clear,
          ),
        ],
      ],
    );
  }
}
