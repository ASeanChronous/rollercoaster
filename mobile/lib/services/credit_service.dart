import 'package:intl/intl.dart';
import '../models/credit_claim_model.dart';

class CreditService {
  static const Map<String, String> providerSupportLinks = {
    'spectrum': 'https://www.spectrum.net/contact-us',
    'xfinity': 'https://www.xfinity.com/support/chat',
    'att-internet': 'https://www.att.com/support/contact-us/',
    'verizon': 'https://www.verizon.com/support/contact-us/',
    'cox': 'https://www.cox.com/residential/contactus.html',
  };

  static const Map<String, String> providerSupportPhones = {
    'spectrum': '1-833-267-6094',
    'xfinity': '1-800-934-6489',
    'att-internet': '1-800-288-2020',
    'verizon': '1-800-837-4966',
    'cox': '1-800-234-3993',
  };

  List<OutageIncidentRecord> getRecentIncidents(String? zip) {
    final now = DateTime.now();
    return [
      OutageIncidentRecord(
        id: 'inc-01',
        serviceName: 'Spectrum Internet',
        serviceSlug: 'spectrum',
        zip: zip ?? '75001',
        startedAt: now.subtract(const Duration(hours: 5, minutes: 20)),
        resolvedAt: now.subtract(const Duration(minutes: 35)),
        durationMinutes: 285, // 4 hours 45 mins
        peakReports: 1240,
        statusSummary: 'Major North Texas fiber cut affecting broadband & VoIP',
      ),
      OutageIncidentRecord(
        id: 'inc-02',
        serviceName: 'Verizon Fios / 5G Home',
        serviceSlug: 'verizon',
        zip: zip ?? '10001',
        startedAt: now.subtract(const Duration(days: 1, hours: 3)),
        resolvedAt: now.subtract(const Duration(days: 1)),
        durationMinutes: 180, // 3 hours
        peakReports: 580,
        statusSummary: 'Routing and gateway degradation in NY/NJ area',
      ),
      OutageIncidentRecord(
        id: 'inc-03',
        serviceName: 'Xfinity (Comcast)',
        serviceSlug: 'xfinity',
        zip: zip ?? '33101',
        startedAt: now.subtract(const Duration(days: 3, hours: 6)),
        resolvedAt: now.subtract(const Duration(days: 3, hours: 1)),
        durationMinutes: 300, // 5 hours
        peakReports: 890,
        statusSummary: 'Substation power outage cascading to local node',
      ),
    ];
  }

  double calculateProratedCredit({
    required double monthlyBill,
    required int durationMinutes,
  }) {
    // 720 hours in a 30-day month
    final outageHours = durationMinutes / 60.0;
    final hourlyRate = monthlyBill / 720.0;
    final prorated = hourlyRate * outageHours;

    // Many providers have a 1-day minimum bill credit policy if outage > 4 hours
    if (durationMinutes >= 240) {
      final oneDayRate = monthlyBill / 30.0;
      return prorated > oneDayRate ? prorated : oneDayRate;
    }
    return prorated;
  }

  double getSuggestedCourtesyCredit(double monthlyBill) {
    // Standard customer retention courtesy credit commonly offered by tier-1 ISPs
    if (monthlyBill >= 100) return 20.0;
    if (monthlyBill >= 60) return 15.0;
    return 10.0;
  }

  String generateClaimLetter({
    required OutageIncidentRecord incident,
    required String customerName,
    required String accountNumber,
    required double monthlyBill,
  }) {
    final startStr = DateFormat('MMMM d, yyyy h:mm a').format(incident.startedAt);
    final endStr = incident.resolvedAt != null
        ? DateFormat('MMMM d, yyyy h:mm a').format(incident.resolvedAt!)
        : 'Still Ongoing';
    final suggestedCredit = getSuggestedCourtesyCredit(monthlyBill);
    final proratedCredit = calculateProratedCredit(
      monthlyBill: monthlyBill,
      durationMinutes: incident.durationMinutes,
    );

    final displayAccount = accountNumber.trim().isEmpty ? '[ACCOUNT NUMBER]' : accountNumber.trim();
    final displayName = customerName.trim().isEmpty ? '[CUSTOMER NAME]' : customerName.trim();

    return '''
Hello,

I am writing regarding my ${incident.serviceName} service on Account #$displayAccount under the name $displayName (Service ZIP: ${incident.zip}).

On $startStr through $endStr, our residence experienced a continuous, verified service disruption lasting ${incident.formattedDuration}. During this downtime, internet connectivity was unavailable for our household.

According to documented multi-source network tracking, this was a confirmed regional service outage (${incident.statusSummary}) that caused over ${incident.peakReports} local reports.

Under your customer satisfaction guarantee and applicable service terms, I am formally requesting a billing adjustment credit for the downtime experienced.

Details for your reference:
- Service Provider: ${incident.serviceName}
- Service Address ZIP: ${incident.zip}
- Outage Start: $startStr
- Outage Restored: $endStr
- Total Downtime Duration: ${incident.formattedDuration}
- Estimated Prorated Credit: \$${proratedCredit.toStringAsFixed(2)}
- Requested Courtesy Account Adjustment: \$${suggestedCredit.toStringAsFixed(2)}

Please apply this credit to my next billing cycle and confirm once processed.

Thank you,
$displayName
''';
  }
}
