import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyGuideScreen extends StatelessWidget {
  const EmergencyGuideScreen({super.key});

  Future<void> _sendSms(String number, String body) async {
    final uri = Uri.parse('sms:$number?body=${Uri.encodeComponent(body)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text('Offline Emergency Guide', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C2D12), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.wifi_off_rounded, color: Color(0xFFFB923C), size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Blackout Recovery',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'All guides here work 100% offline without requiring active mobile data or Wi-Fi.',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 1: Carrier SMS Outage Inquiries
          const Text(
            '1. Report / Check Outage via SMS',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            'SMS text messages work even when 5G/LTE data is too congested to open websites.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 10),

          _buildSmsCard(
            provider: 'Spectrum',
            shortcode: '468311',
            textCommand: 'OUTAGE',
            description: 'Texts Spectrum automated bot to check your account status',
            onTap: () => _sendSms('468311', 'OUTAGE'),
          ),
          const SizedBox(height: 8),
          _buildSmsCard(
            provider: 'Xfinity (Comcast)',
            shortcode: '266278',
            textCommand: 'OUTAGE',
            description: 'Requests status update on your local node',
            onTap: () => _sendSms('266278', 'OUTAGE'),
          ),
          const SizedBox(height: 8),
          _buildSmsCard(
            provider: 'AT&T',
            shortcode: '88288',
            textCommand: 'ALERT',
            description: 'Signs up for SMS updates on active wire repairs',
            onTap: () => _sendSms('88288', 'ALERT'),
          ),

          const SizedBox(height: 24),

          // Section 2: Personal Hotspot Setup
          const Text(
            '2. iOS Personal Hotspot Quick Setup',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tether your work laptop or family devices to your iPhone cellular connection.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StepRow(step: '1', title: 'Open iPhone Settings', desc: 'Tap Personal Hotspot.'),
                _StepRow(step: '2', title: 'Enable Sharing', desc: 'Toggle "Allow Others to Join" ON.'),
                _StepRow(
                  step: '3',
                  title: 'Turn ON "Maximize Compatibility"',
                  desc: 'Switches transmission to 2.4 GHz so older laptops & smart TVs can connect.',
                ),
                _StepRow(
                  step: '4',
                  title: 'Connect Devices',
                  desc: 'On your laptop, select your iPhone Wi-Fi name and enter the Wi-Fi password.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 3: Hardware Power Cycle
          const Text(
            '3. Proper Hardware Reboot Protocol',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            'The standard 10-second button press is insufficient; follow this complete discharge routine.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StepRow(
                  step: '1',
                  title: 'Unplug Both Modem & Separate Router',
                  desc: 'Remove the black power adapter cables directly from the wall outlet.',
                ),
                _StepRow(
                  step: '2',
                  title: 'Wait 60 Full Seconds',
                  desc: 'Capacitors on optical fiber ONTs and DOCSIS modems require 45–60 seconds to fully reset their routing tables.',
                ),
                _StepRow(
                  step: '3',
                  title: 'Power ON Modem First',
                  desc: 'Wait 2–3 minutes until the Online/Internet LED is solid blue/green.',
                ),
                _StepRow(
                  step: '4',
                  title: 'Power ON Wi-Fi Router Second',
                  desc: 'Reconnect your standalone router or mesh nodes (e.g. Eero, Nest, Asus).',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 4: Battery & Data Preservation
          const Text(
            '4. Conserve Mobile Data & iPhone Battery',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: const Column(
              children: [
                _TipRow(
                  icon: Icons.data_saver_on_rounded,
                  title: 'Enable iOS Low Data Mode',
                  desc: 'Settings > Cellular > Cellular Data Options > Data Mode > Low Data Mode. Stops background iCloud sync and automatic app updates.',
                ),
                Divider(color: Color(0xFF334155), height: 20),
                _TipRow(
                  icon: Icons.battery_saver_rounded,
                  title: 'Activate Low Power Mode',
                  desc: 'Settings > Battery > Low Power Mode. Keeps your hotspot functioning hours longer during municipal power blackouts.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSmsCard({
    required String provider,
    required String shortcode,
    required String textCommand,
    required String description,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.sms_rounded, size: 14, color: Colors.white),
            label: Text('SMS $shortcode', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String step;
  final String title;
  final String desc;

  const _StepRow({required this.step, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            child: Text(step, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _TipRow({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF38BDF8), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 11.5)),
            ],
          ),
        ),
      ],
    );
  }
}
