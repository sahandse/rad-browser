import 'package:flutter/material.dart';

import 'core/theme/rad_theme.dart';
import 'features/home/presentation/pages/home_page.dart';

class RadApp extends StatelessWidget {
  const RadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RAD Browser',
      theme: RadTheme.light(),
      darkTheme: RadTheme.dark(),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}
