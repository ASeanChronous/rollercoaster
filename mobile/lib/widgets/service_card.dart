import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/service_model.dart';
import '../providers/app_state.dart';
import '../constants/app_constants.dart';
import 'status_pill.dart';
import '../screens/service_detail_screen.dart';

class ServiceCard extends StatelessWidget {
  final ServiceSummary service;

  const ServiceCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isFav = state.isFavorite(service.slug);
    final categoryIcon = AppConstants.categoryIcons[service.category] ?? Icons.wifi;
    final categoryName = AppConstants.categoryLabels[service.category] ?? service.category;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: service.level == StatusLevel.problems
              ? const Color(0x66EF4444)
              : service.level == StatusLevel.possible
                  ? const Color(0x66F59E0B)
                  : const Color(0xFF334155),
          width: service.level != StatusLevel.ok ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ServiceDetailScreen(slug: service.slug),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: category & favorite
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(categoryIcon, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 6),
                        Text(
                          categoryName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        isFav ? Icons.star_rounded : Icons.star_border_rounded,
                        color: isFav ? const Color(0xFFFBBF24) : Colors.grey[500],
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => state.toggleFavorite(service.slug),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Middle row: Service Name & Status Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        service.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusPill(level: service.level),
                  ],
                ),

                const SizedBox(height: 10),

                // Reports & normal ratio
                Row(
                  children: [
                    Text(
                      '${service.current} reports in last 15 min',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                    if (service.level != StatusLevel.ok) ...[
                      const SizedBox(width: 6),
                      Text(
                        '· ${service.ratio.toStringAsFixed(1)}x normal',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: service.level.color,
                        ),
                      ),
                    ],
                  ],
                ),

                // If outage or reasons exist
                if (service.reasons.isNotEmpty && service.level != StatusLevel.ok) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            service.reasons.first,
                            style: TextStyle(fontSize: 11, color: Colors.grey[300]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
