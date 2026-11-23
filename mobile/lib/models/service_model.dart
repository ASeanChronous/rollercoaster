import 'package:flutter/material.dart';

enum StatusLevel { ok, possible, problems }

extension StatusLevelExtension on StatusLevel {
  String get label {
    switch (this) {
      case StatusLevel.ok:
        return 'No problems';
      case StatusLevel.possible:
        return 'Possible problems';
      case StatusLevel.problems:
        return 'Problems';
    }
  }

  Color get color {
    switch (this) {
      case StatusLevel.ok:
        return const Color(0xFF10B981); // Emerald Green
      case StatusLevel.possible:
        return const Color(0xFFF59E0B); // Amber
      case StatusLevel.problems:
        return const Color(0xFFEF4444); // Red
    }
  }

  Color get backgroundColor {
    switch (this) {
      case StatusLevel.ok:
        return const Color(0x1A10B981);
      case StatusLevel.possible:
        return const Color(0x1AF59E0B);
      case StatusLevel.problems:
        return const Color(0x1AEF4444);
    }
  }

  IconData get icon {
    switch (this) {
      case StatusLevel.ok:
        return Icons.check_circle_outline;
      case StatusLevel.possible:
        return Icons.warning_amber_rounded;
      case StatusLevel.problems:
        return Icons.error_outline;
    }
  }

  static StatusLevel fromString(String? level) {
    switch (level?.toLowerCase()) {
      case 'problems':
        return StatusLevel.problems;
      case 'possible':
        return StatusLevel.possible;
      case 'ok':
      default:
        return StatusLevel.ok;
    }
  }
}

class ServiceSummary {
  final String slug;
  final String name;
  final String category;
  final StatusLevel level;
  final int current;
  final int baseline;
  final double ratio;
  final List<String> reasons;
  final String? officialMessage;
  final int? etaAt;
  final bool? inheritedOnly;

  ServiceSummary({
    required this.slug,
    required this.name,
    required this.category,
    required this.level,
    required this.current,
    required this.baseline,
    required this.ratio,
    required this.reasons,
    this.officialMessage,
    this.etaAt,
    this.inheritedOnly,
  });

  factory ServiceSummary.fromJson(Map<String, dynamic> json) {
    return ServiceSummary(
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'isp',
      level: StatusLevelExtension.fromString(json['level'] as String?),
      current: (json['current'] as num?)?.toInt() ?? 0,
      baseline: (json['baseline'] as num?)?.toInt() ?? 0,
      ratio: (json['ratio'] as num?)?.toDouble() ?? 0.0,
      reasons: (json['reasons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      officialMessage: json['officialMessage'] as String?,
      etaAt: (json['etaAt'] as num?)?.toInt(),
      inheritedOnly: json['inheritedOnly'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'name': name,
      'category': category,
      'level': level.name,
      'current': current,
      'baseline': baseline,
      'ratio': ratio,
      'reasons': reasons,
      'officialMessage': officialMessage,
      'etaAt': etaAt,
      'inheritedOnly': inheritedOnly,
    };
  }
}

class ServiceDetail {
  final String slug;
  final String name;
  final String category;
  final List<String> aliases;
  final List<String> states;
  final List<String> problemTypes;
  final List<String> troubleshooting;
  final String? officialStatusUrl;
  final StatusResult status;
  final StatusResult? national;
  final List<ReportCurvePoint> curve;
  final Map<String, int> breakdown;
  final double uptime24h;
  final List<SourceInfo> sources;

  ServiceDetail({
    required this.slug,
    required this.name,
    required this.category,
    required this.aliases,
    required this.states,
    required this.problemTypes,
    required this.troubleshooting,
    this.officialStatusUrl,
    required this.status,
    this.national,
    required this.curve,
    required this.breakdown,
    required this.uptime24h,
    required this.sources,
  });

  factory ServiceDetail.fromJson(Map<String, dynamic> json) {
    final s = json['service'] as Map<String, dynamic>? ?? {};
    final rawBreakdown = json['breakdown'] as Map<String, dynamic>? ?? {};
    final breakdown = <String, int>{};
    rawBreakdown.forEach((k, v) {
      if (v is num) breakdown[k] = v.toInt();
    });

    final rawCurve = json['curve'] as List<dynamic>? ?? [];
    final curve = rawCurve
        .map((p) => ReportCurvePoint.fromJson(p as Map<String, dynamic>))
        .toList();

    final rawSources = json['sources'] as List<dynamic>? ?? [];
    final sources = rawSources
        .map((src) => SourceInfo.fromJson(src as Map<String, dynamic>))
        .toList();

    return ServiceDetail(
      slug: s['slug'] as String? ?? '',
      name: s['name'] as String? ?? '',
      category: s['category'] as String? ?? 'isp',
      aliases: (s['aliases'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      states: (s['states'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      problemTypes: (s['problemTypes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      troubleshooting: (s['troubleshooting'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      officialStatusUrl: s['officialStatusUrl'] as String?,
      status: StatusResult.fromJson(json['status'] as Map<String, dynamic>? ?? {}),
      national: json['national'] != null ? StatusResult.fromJson(json['national'] as Map<String, dynamic>) : null,
      curve: curve,
      breakdown: breakdown,
      uptime24h: (json['uptime24h'] as num?)?.toDouble() ?? 100.0,
      sources: sources,
    );
  }
}

class StatusResult {
  final StatusLevel level;
  final double confidence;
  final int current;
  final int baseline;
  final double ratio;
  final List<String> reasons;
  final List<String> sourcesReporting;
  final int sourcesTotal;
  final String? officialMessage;
  final int? etaAt;
  final bool? inheritedOnly;

  StatusResult({
    required this.level,
    required this.confidence,
    required this.current,
    required this.baseline,
    required this.ratio,
    required this.reasons,
    required this.sourcesReporting,
    required this.sourcesTotal,
    this.officialMessage,
    this.etaAt,
    this.inheritedOnly,
  });

  factory StatusResult.fromJson(Map<String, dynamic> json) {
    return StatusResult(
      level: StatusLevelExtension.fromString(json['level'] as String?),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      current: (json['current'] as num?)?.toInt() ?? 0,
      baseline: (json['baseline'] as num?)?.toInt() ?? 0,
      ratio: (json['ratio'] as num?)?.toDouble() ?? 0.0,
      reasons: (json['reasons'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      sourcesReporting: (json['sourcesReporting'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      sourcesTotal: (json['sourcesTotal'] as num?)?.toInt() ?? 0,
      officialMessage: json['officialMessage'] as String?,
      etaAt: (json['etaAt'] as num?)?.toInt(),
      inheritedOnly: json['inheritedOnly'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level.name,
      'confidence': confidence,
      'current': current,
      'baseline': baseline,
      'ratio': ratio,
      'reasons': reasons,
      'sourcesReporting': sourcesReporting,
      'sourcesTotal': sourcesTotal,
      'officialMessage': officialMessage,
      'etaAt': etaAt,
      'inheritedOnly': inheritedOnly,
    };
  }
}

class ReportCurvePoint {
  final int timestamp;
  final int count;
  final int baseline;

  ReportCurvePoint({
    required this.timestamp,
    required this.count,
    required this.baseline,
  });

  factory ReportCurvePoint.fromJson(Map<String, dynamic> json) {
    return ReportCurvePoint(
      timestamp: (json['t'] as num?)?.toInt() ?? (json['timestamp'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? (json['reports'] as num?)?.toInt() ?? 0,
      baseline: (json['baseline'] as num?)?.toInt() ?? 0,
    );
  }
}

class SourceInfo {
  final String id;
  final String name;
  final String? url;
  final String? attribution;

  SourceInfo({
    required this.id,
    required this.name,
    this.url,
    this.attribution,
  });

  factory SourceInfo.fromJson(Map<String, dynamic> json) {
    return SourceInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      url: json['url'] as String?,
      attribution: json['attribution'] as String?,
    );
  }
}
