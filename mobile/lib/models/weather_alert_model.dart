import 'package:flutter/material.dart';

class WeatherAlert {
  final String id;
  final String event;
  final String severity;
  final String headline;
  final String areaDesc;
  final List<String> states;
  final String? onset;
  final String? ends;
  final String sender;

  WeatherAlert({
    required this.id,
    required this.event,
    required this.severity,
    required this.headline,
    required this.areaDesc,
    required this.states,
    this.onset,
    this.ends,
    required this.sender,
  });

  factory WeatherAlert.fromJson(Map<String, dynamic> json) {
    final rawStates = json['states'] as List<dynamic>? ?? [];
    return WeatherAlert(
      id: json['id'] as String? ?? '',
      event: json['event'] as String? ?? 'Severe Weather Warning',
      severity: json['severity'] as String? ?? 'Severe',
      headline: json['headline'] as String? ?? '',
      areaDesc: json['areaDesc'] as String? ?? '',
      states: rawStates.map((s) => s.toString()).toList(),
      onset: json['onset'] as String?,
      ends: json['ends'] as String?,
      sender: json['sender'] as String? ?? 'National Weather Service',
    );
  }

  Color get color {
    final ev = event.toLowerCase();
    if (ev.contains('tornado') || ev.contains('extreme') || severity.toLowerCase() == 'extreme') {
      return const Color(0xFFDC2626); // Bright Crimson
    } else if (ev.contains('thunderstorm') || ev.contains('wind') || ev.contains('surge')) {
      return const Color(0xFFF97316); // Amber / Orange
    } else if (ev.contains('flood')) {
      return const Color(0xFF2563EB); // Blue
    } else if (ev.contains('winter') || ev.contains('ice') || ev.contains('blizzard')) {
      return const Color(0xFF38BDF8); // Cyan
    } else {
      return const Color(0xFFEAB308); // Yellow
    }
  }

  IconData get icon {
    final ev = event.toLowerCase();
    if (ev.contains('tornado')) return Icons.cyclone_rounded;
    if (ev.contains('thunderstorm')) return Icons.thunderstorm_rounded;
    if (ev.contains('wind')) return Icons.air_rounded;
    if (ev.contains('flood')) return Icons.water_rounded;
    if (ev.contains('winter') || ev.contains('ice') || ev.contains('snow')) return Icons.ac_unit_rounded;
    if (ev.contains('heat') || ev.contains('fire')) return Icons.local_fire_department_rounded;
    return Icons.warning_amber_rounded;
  }
}
