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
              Uri.https('www.cloudflare.com', '/cdn-cgi/trace'),
              Uri.https('www.bing.com'),
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

    final results = await Future.wait<bool>([
      _anyReachable(internalProbes),
      _anyReachable(globalProbes),
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
