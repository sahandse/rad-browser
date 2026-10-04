import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import '../domain/network_mode.dart';

class NetworkProbeService {
  NetworkProbeService({
    Connectivity? connectivity,
    http.Client? client,
    List<Uri>? internalProbes,
    List<Uri>? globalProbes,
  })  : _connectivity = connectivity ?? Connectivity(),
        _client = client ?? http.Client(),
        internalProbes = internalProbes ??
            [
              Uri.https('www.nic.ir'),
              Uri.https('zarebin.ir'),
              Uri.https('141.ir'),
            ],
        globalProbes = globalProbes ??
            [
              Uri.https('www.google.com', '/generate_204'),
            ];

  final Connectivity _connectivity;
  final http.Client _client;
  final List<Uri> internalProbes;
  final List<Uri> globalProbes;

  static const _probeTimeout = Duration(seconds: 4);

  Future<NetworkMode> check() async {
    final transports = await _connectivity.checkConnectivity();
    if (transports.isEmpty ||
        transports.every((item) => item == ConnectivityResult.none)) {
      return NetworkMode.offline;
    }

    final internalFuture = _anyReachable(internalProbes);
    final globalFuture = _google204Reachable();
    final results = await Future.wait<bool>([internalFuture, globalFuture]);

    final internalReachable = results[0];
    final globalReachable = results[1];

    if (globalReachable) return NetworkMode.fullInternet;
    if (internalReachable) return NetworkMode.internalOnly;
    return NetworkMode.offline;
  }

  Stream<NetworkMode> watch() async* {
    var last = await check();
    yield last;

    final connectivityEvents = _connectivity.onConnectivityChanged.asBroadcastStream();
    final periodic = Stream<void>.periodic(const Duration(seconds: 15));
    final controller = StreamController<void>();
    late final StreamSubscription connectivitySub;
    late final StreamSubscription periodicSub;

    connectivitySub = connectivityEvents.listen((_) => controller.add(null));
    periodicSub = periodic.listen((_) => controller.add(null));

    try {
      await for (final _ in controller.stream) {
        final current = await check();
        if (current != last) {
          last = current;
          yield current;
        }
      }
    } finally {
      await connectivitySub.cancel();
      await periodicSub.cancel();
      await controller.close();
    }
  }


  Future<bool> _google204Reachable() async {
    for (final uri in globalProbes) {
      try {
        final response = await _client
            .get(uri, headers: const {
              'Cache-Control': 'no-cache',
              'User-Agent': 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36',
            })
            .timeout(_probeTimeout);
        if (response.statusCode == 204) return true;
      } on Object {
        // Try the next probe if one is added later.
      }
    }
    return false;
  }

  Future<bool> canReach(Uri uri) => _isReachable(uri);

  Future<bool> _anyReachable(List<Uri> probes) async {
    final results = await Future.wait(probes.map(_isReachable));
    return results.any((value) => value);
  }

  Future<bool> _isReachable(Uri uri) async {
    try {
      final response = await _client
          .get(uri, headers: const {'Cache-Control': 'no-cache'})
          .timeout(_probeTimeout);
      return response.statusCode >= 200 && response.statusCode < 500;
    } on Object {
      return false;
    }
  }

  void dispose() => _client.close();
}
