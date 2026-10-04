import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/rad_theme.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/settings/domain/app_settings.dart';
import 'features/settings/presentation/controllers/settings_controller.dart';

class RadApp extends ConsumerWidget {
  const RadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final compact = settings.uiDensity == RadUiDensity.compact;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RAD Browser',
      theme: RadTheme.light(compact: compact),
      darkTheme: RadTheme.dark(compact: compact),
      themeMode: settings.themeMode,
      home: const HomePage(),
    );
  }
}
