import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/credit_claim_model.dart';
import '../providers/app_state.dart';
import '../services/credit_service.dart';

class BillCreditScreen extends StatefulWidget {
  final OutageIncidentRecord? initialIncident;

  const BillCreditScreen({super.key, this.initialIncident});

  @override
  State<BillCreditScreen> createState() => _BillCreditScreenState();
}

class _BillCreditScreenState extends State<BillCreditScreen> {
  final CreditService _creditService = CreditService();
  late List<OutageIncidentRecord> _incidents;
  OutageIncidentRecord? _selectedIncident;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  double _monthlyBill = 85.0;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _incidents = _creditService.getRecentIncidents(state.zip);
    _selectedIncident = widget.initialIncident ?? (_incidents.isNotEmpty ? _incidents.first : null);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
            SizedBox(width: 10),
            Text('Claim letter copied to clipboard! Ready to paste into chat.'),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incident = _selectedIncident;
    final prorated = incident != null
        ? _creditService.calculateProratedCredit(
            monthlyBill: _monthlyBill,
            durationMinutes: incident.durationMinutes,
          )
        : 0.0;
    final courtesy = _creditService.getSuggestedCourtesyCredit(_monthlyBill);

    final generatedLetter = incident != null
        ? _creditService.generateClaimLetter(
            incident: incident,
            customerName: _nameController.text,
            accountNumber: _accountController.text,
            monthlyBill: _monthlyBill,
          )
        : '';

    final supportPhone = incident != null
        ? CreditService.providerSupportPhones[incident.serviceSlug]
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text('ISP Bill Credit Claimer', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF065F46), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.monetization_on_rounded, color: Color(0xFF10B981), size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Claim Your Outage Credit',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Broadband providers rarely apply outage credits automatically. Use verified incident data to claim what you are owed.',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Step 1: Select Outage Incident
            const Text(
              '1. Select Documented Outage Incident',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
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
                child: DropdownButton<OutageIncidentRecord>(
                  value: _selectedIncident,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  items: _incidents.map((inc) {
                    return DropdownMenuItem(
                      value: inc,
                      child: Text(
                        '${inc.serviceName} (${inc.formattedDuration} downtime · ZIP ${inc.zip})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedIncident = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Step 2: Bill & Account Information
            const Text(
              '2. Your Plan Details',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Approximate Monthly Bill:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Text(
                        '\$${_monthlyBill.toInt()} / mo',
                        style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  Slider(
                    value: _monthlyBill,
                    min: 30,
                    max: 200,
                    divisions: 34,
                    activeColor: const Color(0xFF38BDF8),
                    inactiveColor: const Color(0xFF0F172A),
                    onChanged: (val) => setState(() => _monthlyBill = val),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Your Name (Optional)',
                            labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _accountController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Account # (Optional)',
                            labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Credit Calculation Highlight Cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Prorated Value', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          '\$${prorated.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text('${incident?.formattedDuration ?? '0m'} offline', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Suggested Claim', style: TextStyle(fontSize: 11, color: Color(0xFF10B981))),
                        const SizedBox(height: 4),
                        Text(
                          '\$${courtesy.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                        ),
                        const Text('Standard courtesy', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Step 3: Generated Claim Letter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '3. Generated Credit Claim Letter',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.copy, size: 14, color: Color(0xFF38BDF8)),
                  label: const Text('Copy', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.bold)),
                  onPressed: () => _copyToClipboard(generatedLetter),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: SelectableText(
                generatedLetter,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11.5,
                  color: Colors.white70,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Primary Action Button: Copy
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.copy_rounded, color: Colors.white),
                label: const Text(
                  'Copy Claim Letter to Clipboard',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                onPressed: () => _copyToClipboard(generatedLetter),
              ),
            ),
            const SizedBox(height: 12),

            // Support Phone / Live Chat Shortcut
            if (supportPhone != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.phone_in_talk, size: 16, color: Color(0xFF38BDF8)),
                        const SizedBox(width: 8),
                        Text(
                          '${incident?.serviceName} Support: $supportPhone',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: supportPhone));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Copied phone number $supportPhone')),
                        );
                      },
                      child: const Text('Copy #', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
