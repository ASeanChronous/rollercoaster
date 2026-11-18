class OutageIncidentRecord {
  final String id;
  final String serviceName;
  final String serviceSlug;
  final String zip;
  final DateTime startedAt;
  final DateTime? resolvedAt;
  final int durationMinutes;
  final int peakReports;
  final String statusSummary;

  OutageIncidentRecord({
    required this.id,
    required this.serviceName,
    required this.serviceSlug,
    required this.zip,
    required this.startedAt,
    this.resolvedAt,
    required this.durationMinutes,
    required this.peakReports,
    required this.statusSummary,
  });

  bool get isResolved => resolvedAt != null;

  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    if (hours > 0 && mins > 0) {
      return '${hours}h ${mins}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${mins}m';
    }
  }

  factory OutageIncidentRecord.fromJson(Map<String, dynamic> json) {
    return OutageIncidentRecord(
      id: json['id'] as String? ?? '',
      serviceName: json['serviceName'] as String? ?? '',
      serviceSlug: json['serviceSlug'] as String? ?? '',
      zip: json['zip'] as String? ?? '',
      startedAt: DateTime.fromMillisecondsSinceEpoch(json['startedAt'] as int),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['resolvedAt'] as int)
          : null,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      peakReports: (json['peakReports'] as num?)?.toInt() ?? 0,
      statusSummary: json['statusSummary'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceName': serviceName,
      'serviceSlug': serviceSlug,
      'zip': zip,
      'startedAt': startedAt.millisecondsSinceEpoch,
      'resolvedAt': resolvedAt?.millisecondsSinceEpoch,
      'durationMinutes': durationMinutes,
      'peakReports': peakReports,
      'statusSummary': statusSummary,
    };
  }
}
