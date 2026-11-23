import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state.dart';
import '../constants/app_constants.dart';

class ReportScreen extends StatefulWidget {
  final String? preselectedSlug;

  const ReportScreen({super.key, this.preselectedSlug});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String? _selectedSlug;
  String _selectedProblem = 'no_connection';
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedSlug = widget.preselectedSlug;
    final state = context.read<AppState>();
    if (state.zip != null && state.zip!.isNotEmpty) {
      _zipController.text = state.zip!;
    }
  }

  @override
  void dispose() {
    _zipController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendSmsReport() async {
    final serviceName = _selectedSlug ?? 'Unknown Service';
    final zip = _zipController.text.trim();
    final problem = AppConstants.problemLabels[_selectedProblem] ?? _selectedProblem;
    final comment = _commentController.text.trim();

    final body = 'ROLLERCOASTER REPORT: $serviceName (ZIP: ${zip.isEmpty ? "Unknown" : zip}) - Issue: $problem${comment.isNotEmpty ? " Note: $comment" : ""}';
    final uri = Uri.parse('sms:?body=${Uri.encodeComponent(body)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _submit() async {
    if (_selectedSlug == null || _selectedSlug!.isEmpty) {
      setState(() => _error = 'Please select a service.');
      return;
    }
    final zip = _zipController.text.trim();
    if (zip.length != 5 || int.tryParse(zip) == null) {
      setState(() => _error = 'Please enter a valid 5-digit US ZIP code.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final state = context.read<AppState>();
    final res = await state.api.submitReport(
      serviceSlug: _selectedSlug!,
      problemType: _selectedProblem,
      zip: zip,
      comment: _commentController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (res['ok'] == true && mounted) {
      final nearby = res['nearby'] ?? 1;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF10B981), size: 28),
              SizedBox(width: 10),
              Text('Report Logged!', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: Text(
            'Thank you for reporting. Your signal has been registered.\n\n$nearby other reports have been submitted nearby in the last hour.',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
                state.loadServices();
              },
              child: const Text('Done', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else if (mounted) {
      setState(() => _error = res['error']?.toString() ?? 'Failed to submit report');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final services = state.services;

    if (_selectedSlug == null && services.isNotEmpty) {
      _selectedSlug = services.first.slug;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text('Quick Report (<10s)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Having trouble? Let everyone know.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your anonymous report helps pinpoint real-time outages across your neighborhood.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Service selector
            const Text('1. Affected Service', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSlug,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  items: services.map((s) {
                    return DropdownMenuItem(
                      value: s.slug,
                      child: Text(s.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSlug = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Problem type
            const Text('2. What is happening?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.problemLabels.entries.map((entry) {
                final isSelected = _selectedProblem == entry.key;
                return ChoiceChip(
                  label: Text(entry.value),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.grey[300],
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF2563EB),
                  backgroundColor: const Color(0xFF1E293B),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF334155),
                  ),
                  onSelected: (_) => setState(() => _selectedProblem = entry.key),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ZIP code
            const Text('3. Your ZIP Code', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 8),
            TextField(
              controller: _zipController,
              keyboardType: TextInputType.number,
              maxLength: 5,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '5-digit US ZIP code',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Optional note
            const Text('4. Additional details (Optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. Red lights on modem, started 10 minutes ago',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x26EF4444),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13))),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit Outage Report',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF334155)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.sms_outlined, color: Color(0xFF38BDF8), size: 18),
                label: const Text(
                  'No Internet? Send Report via SMS',
                  style: TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.bold),
                ),
                onPressed: _sendSmsReport,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
