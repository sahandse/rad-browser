import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/privacy/domain/tracker_blocker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TrackingExceptionRegistry.ensureLoaded();
  runApp(const ProviderScope(child: RadApp()));
}
