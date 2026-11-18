import 'package:flutter/material.dart';
import '../models/service_model.dart';

class StatusPill extends StatelessWidget {
  final StatusLevel level;
  final bool compact;

  const StatusPill({
    super.key,
    required this.level,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = level.color;
    final bg = level.backgroundColor;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(level.icon, size: compact ? 14 : 16, color: color),
          const SizedBox(width: 5),
          Text(
            level.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 12 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
