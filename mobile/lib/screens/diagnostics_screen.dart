import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/diagnostics_model.dart';
import '../models/service_model.dart';
import '../providers/app_state.dart';
import '../services/diagnostics_service.dart';
import 'service_detail_screen.dart';
import 'report_screen.dart';

class DiagnosticsScreen extends StatefulWidget {
  final ServiceSummary? initialService;

  const DiagnosticsScreen({super.key, this.initialService});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  ServiceSummary? _selectedService;
  bool _isRunning = false;
  List<DiagnosticStep> _steps = [];
  DiagnosticVerdict? _verdict;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _selectedService = widget.initialService;
    _resetSteps();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _resetSteps() {
    _steps = [
      DiagnosticStep(
        title: 'Global Internet Access',
        description: 'Waiting to ping global CDN edge...',
      ),
      DiagnosticStep(
        title: 'Service Cloud Status',
        description: 'Waiting to check provider health...',
      ),
      DiagnosticStep(
        title: 'Local ISP & Neighborhood',
        description: 'Waiting to scan local 15-mile reports...',
      ),
    ];
    _verdict = null;
  }

  Future<void> _startDiagnostics() async {
    final state = context.read<AppState>();
    final target = _selectedService ?? (state.services.isNotEmpty ? state.services.first : null);

    if (target == null) return;

    setState(() {
      _isRunning = true;
      _resetSteps();
    });

    final service = DiagnosticsService(api: state.api);
    final verdict = await service.runDiagnostics(
      targetService: target,
      zip: state.zip,
      state: state.state,
      onStepUpdate: (index, updatedStep) {
        if (mounted) {
          setState(() {
            _steps[index] = updatedStep;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _verdict = verdict;
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final services = state.services;

    if (_selectedService == null && services.isNotEmpty) {
      _selectedService = services.first;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'Is It Me or Them?',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Intro Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.troubleshoot_rounded, color: Color(0xFF38BDF8), size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connection Diagnoser',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Determine in 3 seconds whether an outage is your home Wi-Fi or the remote service.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Service Selector Dropdown
            const Text(
              'Select Service to Test:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ServiceSummary>(
                  value: _selectedService,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  items: services.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(s.name),
                    );
                  }).toList(),
                  onChanged: _isRunning
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() {
                              _selectedService = val;
                              _resetSteps();
                            });
                          }
                        },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Run Diagnostics Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isRunning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_rounded, color: Colors.white),
                label: Text(
                  _isRunning ? 'Testing Connectivity...' : 'Run Quick Diagnostic',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                onPressed: _isRunning ? null : _startDiagnostics,
              ),
            ),
            const SizedBox(height: 24),

            // Diagnostic Steps Progress List
            const Text(
              'Diagnostic Progress:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 10),
            ..._steps.asMap().entries.map((entry) {
              final idx = entry.key;
              final step = entry.value;

              Widget statusIcon;
              if (step.isRunning) {
                statusIcon = const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Color(0xFF38BDF8), strokeWidth: 2),
                );
              } else if (step.isSuccess == true) {
                statusIcon = const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20);
              } else if (step.isSuccess == false) {
                statusIcon = const Icon(Icons.cancel, color: Color(0xFFEF4444), size: 20);
              } else {
                statusIcon = Icon(Icons.radio_button_unchecked, color: Colors.grey[600], size: 20);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: step.isRunning ? const Color(0xFF38BDF8) : const Color(0xFF334155),
                  ),
                ),
                child: Row(
                  children: [
                    statusIcon,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Step ${idx + 1}: ${step.title}',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            step.description,
                            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Verdict Card
            if (_verdict != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _verdict!.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _verdict!.color, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: _verdict!.color.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_verdict!.icon, color: _verdict!.color, size: 28),
                        const SizedBox(width: 10),
                        Text(
                          _verdict!.headline,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _verdict!.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _verdict!.summary,
                      style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_outline, size: 16, color: Color(0xFFFBBF24)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _verdict!.recommendedAction,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (_selectedService != null)
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E293B),
                                side: BorderSide(color: _verdict!.color),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ServiceDetailScreen(slug: _selectedService!.slug),
                                  ),
                                );
                              },
                              child: const Text('View Reports', style: TextStyle(color: Colors.white, fontSize: 13)),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReportScreen(
                                    preselectedSlug: _selectedService?.slug,
                                  ),
                                ),
                              );
                            },
                            child: const Text('Report Outage', style: TextStyle(color: Colors.white, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
