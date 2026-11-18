import 'package:flutter/material.dart';

enum DiagnosticVerdictType {
  itsThem,      // Target service is down, your internet is fine
  itsYourIsp,   // Your ISP has a confirmed outage in your area
  localGlitch,  // Your device or Wi-Fi is failing, but no neighborhood outage reported
  allOperational, // Everything is working normally
}

class DiagnosticStep {
  final String title;
  final String description;
  bool? isSuccess;
  bool isRunning;
  int? latencyMs;

  DiagnosticStep({
    required this.title,
    required this.description,
    this.isSuccess,
    this.isRunning = false,
    this.latencyMs,
  });
}

class DiagnosticVerdict {
  final DiagnosticVerdictType type;
  final String headline;
  final String summary;
  final String recommendedAction;
  final Color color;
  final IconData icon;

  DiagnosticVerdict({
    required this.type,
    required this.headline,
    required this.summary,
    required this.recommendedAction,
    required this.color,
    required this.icon,
  });
}
