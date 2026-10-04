import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/network_probe_service.dart';
import '../domain/network_mode.dart';

final networkProbeServiceProvider = Provider<NetworkProbeService>((ref) {
  final service = NetworkProbeService();
  ref.onDispose(service.dispose);
  return service;
});

final networkModeProvider = StreamProvider<NetworkMode>((ref) {
  return ref.watch(networkProbeServiceProvider).watch();
});
