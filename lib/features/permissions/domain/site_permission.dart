enum SitePermissionKind { camera, microphone, location, notifications }

enum SitePermissionDecision { ask, allow, block }

class SitePermissionEntry {
  const SitePermissionEntry({
    required this.host,
    required this.kind,
    required this.decision,
  });

  final String host;
  final SitePermissionKind kind;
  final SitePermissionDecision decision;

  String get key => '$host:${kind.name}';

  Map<String, Object?> toJson() => {
        'host': host,
        'kind': kind.name,
        'decision': decision.name,
      };

  factory SitePermissionEntry.fromJson(Map<String, Object?> json) {
    final kindName = json['kind'] as String? ?? SitePermissionKind.camera.name;
    final decisionName = json['decision'] as String? ?? SitePermissionDecision.ask.name;
    return SitePermissionEntry(
      host: json['host'] as String? ?? '',
      kind: SitePermissionKind.values.firstWhere(
        (item) => item.name == kindName,
        orElse: () => SitePermissionKind.camera,
      ),
      decision: SitePermissionDecision.values.firstWhere(
        (item) => item.name == decisionName,
        orElse: () => SitePermissionDecision.ask,
      ),
    );
  }
}

extension SitePermissionKindInfo on SitePermissionKind {
  String get title => switch (this) {
        SitePermissionKind.camera => 'دوربین',
        SitePermissionKind.microphone => 'میکروفون',
        SitePermissionKind.location => 'موقعیت مکانی',
        SitePermissionKind.notifications => 'اعلان‌ها',
      };
}

extension SitePermissionDecisionInfo on SitePermissionDecision {
  String get title => switch (this) {
        SitePermissionDecision.ask => 'هر بار بپرس',
        SitePermissionDecision.allow => 'اجازه',
        SitePermissionDecision.block => 'مسدود',
      };
}
