import 'package:flutter/material.dart';
import '../models/service_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  int _selectedMinutes = 60;

  @override
  Widget build(BuildContext context) {
    final stateOutages = [
      {'state': 'TX', 'name': 'Texas', 'reports': 1420, 'topService': 'Spectrum', 'level': StatusLevel.problems},
      {'state': 'NY', 'name': 'New York', 'reports': 860, 'topService': 'Verizon', 'level': StatusLevel.possible},
      {'state': 'FL', 'name': 'Florida', 'reports': 340, 'topService': 'FPL / Power', 'level': StatusLevel.possible},
      {'state': 'CA', 'name': 'California', 'reports': 120, 'topService': 'AT&T', 'level': StatusLevel.ok},
      {'state': 'IL', 'name': 'Illinois', 'reports': 85, 'topService': 'Comcast', 'level': StatusLevel.ok},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text('Live Outage Map', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time filter
            Row(
              children: [
                const Text('Time Window:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(width: 12),
                Wrap(
                  spacing: 6,
                  children: [60, 360, 1440].map((m) {
                    final label = m == 60 ? '1 hr' : m == 360 ? '6 hrs' : '24 hrs';
                    final isSelected = _selectedMinutes == m;
                    return ChoiceChip(
                      label: Text(label),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : Colors.grey[400],
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF2563EB),
                      backgroundColor: const Color(0xFF1E293B),
                      side: const BorderSide(color: Color(0xFF334155)),
                      onSelected: (_) => setState(() => _selectedMinutes = m),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Map preview representation
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.map_rounded, size: 100, color: Colors.white.withValues(alpha: 0.04)),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.radar_rounded, color: Color(0xFFEF4444), size: 36),
                      const SizedBox(height: 8),
                      const Text(
                        'Active Outage Hotspots',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dallas-Fort Worth Metro (Spectrum) • NYC Metro (Verizon)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Outages by State',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),

            ...stateOutages.map((item) {
              final level = item['level'] as StatusLevel;
              final stateCode = item['state'] as String;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: level != StatusLevel.ok ? level.color.withValues(alpha: 0.4) : const Color(0xFF334155),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: level.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        stateCode,
                        style: TextStyle(color: level.color, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                          ),
                          Text(
                            'Highest reports: ${item['topService']}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item['reports']} reports',
                          style: TextStyle(fontWeight: FontWeight.bold, color: level.color, fontSize: 13),
                        ),
                        Text(
                          level.label,
                          style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
