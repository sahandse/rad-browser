import 'package:flutter/material.dart';

import '../../domain/tracker_blocker.dart';

class TrackingExceptionsPage extends StatefulWidget {
  const TrackingExceptionsPage({super.key});

  @override
  State<TrackingExceptionsPage> createState() => _TrackingExceptionsPageState();
}

class _TrackingExceptionsPageState extends State<TrackingExceptionsPage> {
  final _controller = TextEditingController();
  bool _loading = true;
  List<String> _hosts = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await TrackingExceptionRegistry.ensureLoaded();
    if (!mounted) return;
    setState(() {
      _hosts = TrackingExceptionRegistry.hosts.toList()..sort();
      _loading = false;
    });
  }

  Future<void> _add() async {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    await TrackingExceptionRegistry.add(value);
    _controller.clear();
    await _load();
  }

  Future<void> _remove(String host) async {
    await TrackingExceptionRegistry.remove(host);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('استثناءهای رهگیری')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'اگر سایتی با محافظت رهگیری درست کار نمی‌کند، فقط همان دامنه را اینجا مستثنی کنید.',
                    textDirection: TextDirection.rtl,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.done,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            hintText: 'example.com',
                            prefixIcon: Icon(Icons.language_rounded),
                          ),
                          onSubmitted: (_) => _add(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _add,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('افزودن'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _hosts.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Text(
                              'هیچ استثنایی ثبت نشده است.\nمحافظت رهگیری برای همه سایت‌ها طبق تنظیم کلی راد اعمال می‌شود.',
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.7,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                          itemCount: _hosts.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final host = _hosts[index];
                            return ListTile(
                              leading: const Icon(Icons.shield_outlined),
                              title: Text(host),
                              subtitle: const Text('محافظت رهگیری برای این دامنه خاموش است'),
                              trailing: IconButton(
                                tooltip: 'حذف استثناء',
                                onPressed: () => _remove(host),
                                icon: const Icon(Icons.delete_outline_rounded),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
