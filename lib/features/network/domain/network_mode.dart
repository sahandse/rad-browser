enum NetworkMode {
  fullInternet,
  internalOnly,
  offline,
}

extension NetworkModeLabel on NetworkMode {
  String get title => switch (this) {
        NetworkMode.fullInternet => 'اینترنت',
        NetworkMode.internalOnly => 'شبکه داخلی',
        NetworkMode.offline => 'آفلاین',
      };
}
