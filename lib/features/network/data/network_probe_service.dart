import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import '../domain/network_mode.dart';

class NetworkProbeService {
  NetworkProbeService({
    Connectivity? connectivity,
    http.Client? client,
    this.internalProbe = const Uri(scheme: 'https', host: 'www.nic.ir'),
    this.globalProbe = const Uri(
      scheme: 'https',
      host: 'www.google.com',
      path: '/generate_204',
    ),
  })  : _connectivity = connectivity ?? Connectivity(),
        _client = client ?? http.Client();

  final Connectivity _connectivity;
  final http.Client _client;
  final Uri internalProbe;
  final Uri globalProbe;

  static const _probeTimeout = Duration(seconds: 4);

  Future<NetworkMode> check() async {
    final transports = await _connectivity.checkConnectivity();
    if (transports.isEmpty || transports.every((item) => item == ConnectivityResult.none)) {
      return NetworkMode.offline;
    }

    final results = await Future.wait<bool>([
      _isReachable(internalProbe),
      _isReachable(globalProbe),
    ]);

    final internalReachable = results[0];
    final globalReachable = results[1];

    if (globalReachable) return NetworkMode.fullInternet;
    if (internalReachable) return NetworkMode.internalOnly;
    return NetworkMode.offline;
  }

  Stream<NetworkMode> watch() async* {
    yield await check();
    await for (final _ in _connectivity.onConnectivityChanged) {
      yield await check();
    }
  }

  Future<bool> canReach(Uri uri) => _isReachable(uri);

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
