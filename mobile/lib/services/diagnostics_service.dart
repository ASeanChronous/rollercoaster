import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/diagnostics_model.dart';
import '../models/service_model.dart';
import 'api_service.dart';

class DiagnosticsService {
  final ApiService api;

  DiagnosticsService({required this.api});

  Future<DiagnosticVerdict> runDiagnostics({
    required ServiceSummary targetService,
    required String? zip,
    required String? state,
    required void Function(int stepIndex, DiagnosticStep updatedStep) onStepUpdate,
  }) async {
    // Step 0: Check Local & Backbone Connectivity
    onStepUpdate(0, DiagnosticStep(
      title: 'Testing General Internet Access',
      description: 'Pinging global edge CDN...',
      isRunning: true,
    ));

    bool generalInternetOk = false;
    int latency = 0;

    final stopwatch = Stopwatch()..start();
    try {
      final res = await http
          .get(Uri.parse('https://1.1.1.1/cdn-cgi/trace'))
          .timeout(const Duration(seconds: 4));
      stopwatch.stop();
      if (res.statusCode == 200) {
        generalInternetOk = true;
        latency = stopwatch.elapsedMilliseconds;
      }
    } catch (_) {
      stopwatch.stop();
      // Try secondary fallback probe
      try {
        final res2 = await http
            .get(Uri.parse('https://dns.google/resolve?name=cloudflare.com'))
            .timeout(const Duration(seconds: 4));
        if (res2.statusCode == 200) {
          generalInternetOk = true;
          latency = stopwatch.elapsedMilliseconds;
        }
      } catch (_) {
        generalInternetOk = false;
      }
    }

    onStepUpdate(0, DiagnosticStep(
      title: 'General Internet Access',
      description: generalInternetOk
          ? 'Connected to global internet ($latency ms)'
          : 'Could not reach the global internet',
      isSuccess: generalInternetOk,
      isRunning: false,
      latencyMs: latency > 0 ? latency : null,
    ));

    await Future.delayed(const Duration(milliseconds: 400));

    // Step 1: Check Target Service Status in Rollercoaster Engine
    onStepUpdate(1, DiagnosticStep(
      title: 'Checking ${targetService.name} Status',
      description: 'Querying crowd and provider feeds...',
      isRunning: true,
    ));

    final serviceDetail = await api.getServiceDetail(
      targetService.slug,
      zip: zip,
      state: state,
    );

    final isServiceDown = serviceDetail.status.level != StatusLevel.ok;

    onStepUpdate(1, DiagnosticStep(
      title: '${targetService.name} Status',
      description: isServiceDown
          ? '${targetService.name} has ${serviceDetail.status.current} outage reports (${serviceDetail.status.ratio.toStringAsFixed(1)}x normal)'
          : '${targetService.name} is running normally (${serviceDetail.uptime24h.toStringAsFixed(1)}% uptime)',
      isSuccess: !isServiceDown,
      isRunning: false,
    ));

    await Future.delayed(const Duration(milliseconds: 400));

    // Step 2: Check Local ISP & Neighborhood Status
    onStepUpdate(2, DiagnosticStep(
      title: 'Analyzing Local ISP & Neighborhood',
      description: 'Scanning reports within 15 miles...',
      isRunning: true,
    ));

    final nearbyServices = await api.getServices(category: 'isp', zip: zip, state: state);
    final affectedIsps = nearbyServices.where((s) => s.level != StatusLevel.ok).toList();
    final isIspDown = affectedIsps.isNotEmpty;

    onStepUpdate(2, DiagnosticStep(
      title: 'Neighborhood & ISP Network',
      description: isIspDown
          ? '${affectedIsps.first.name} reporting active outage in your area'
          : 'Local broadband providers are operating normally',
      isSuccess: !isIspDown,
      isRunning: false,
    ));

    await Future.delayed(const Duration(milliseconds: 300));

    // Step 3: Synthesize Diagnostic Verdict
    if (isServiceDown && generalInternetOk) {
      return DiagnosticVerdict(
        type: DiagnosticVerdictType.itsThem,
        headline: "It's Them!",
        summary:
            "Your home internet is working fast ($latency ms latency), but ${targetService.name} is currently experiencing a confirmed outage.",
        recommendedAction:
            "You do not need to restart your router. The issue is on ${targetService.name}'s servers. We will track restoration for you.",
        color: const Color(0xFFEF4444), // Red
        icon: Icons.cloud_off_rounded,
      );
    } else if (!generalInternetOk && isIspDown) {
      final ispName = affectedIsps.first.name;
      return DiagnosticVerdict(
        type: DiagnosticVerdictType.itsYourIsp,
        headline: "It's Your ISP ($ispName)",
        summary:
            "Your general internet connection failed, and $ispName has ${affectedIsps.first.current} reports in your area right now (${affectedIsps.first.ratio.toStringAsFixed(1)}x normal volume).",
        recommendedAction:
            "This is a neighborhood provider outage. Switch your phone to cellular data or Personal Hotspot while crews work on restoration.",
        color: const Color(0xFFF97316), // Orange
        icon: Icons.wifi_off_rounded,
      );
    } else if (!generalInternetOk && !isIspDown) {
      return DiagnosticVerdict(
        type: DiagnosticVerdictType.localGlitch,
        headline: "Local Wi-Fi or Device Glitch",
        summary:
            "Your device cannot reach the internet, but no widespread ISP outages are detected in your area.",
        recommendedAction:
            "Try toggling Airplane Mode, restarting your phone's Wi-Fi, or power-cycling your home router for 60 seconds.",
        color: const Color(0xFFF59E0B), // Amber
        icon: Icons.router_rounded,
      );
    } else {
      return DiagnosticVerdict(
        type: DiagnosticVerdictType.allOperational,
        headline: "Everything Looks Operational!",
        summary:
            "Your internet connection is fast ($latency ms), and ${targetService.name} is operating normally with no widespread disruptions.",
        recommendedAction:
            "If you are having trouble logging in, try clearing your browser cache, checking your account credentials, or restarting the app.",
        color: const Color(0xFF10B981), // Emerald Green
        icon: Icons.verified_rounded,
      );
    }
  }
}
