import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/service_model.dart';
import 'package:intl/intl.dart';

class OutageChart extends StatelessWidget {
  final List<ReportCurvePoint> points;
  final StatusLevel level;

  const OutageChart({
    super.key,
    required this.points,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text('No historical data available', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final spots = <FlSpot>[];
    final baselineSpots = <FlSpot>[];
    double maxY = 10;

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final y = p.count.toDouble();
      final base = p.baseline.toDouble();
      spots.add(FlSpot(i.toDouble(), y));
      baselineSpots.add(FlSpot(i.toDouble(), base));
      if (y > maxY) maxY = y;
      if (base > maxY) maxY = base;
    }

    maxY = (maxY * 1.25).ceilToDouble();

    return Container(
      height: 200,
      padding: const EdgeInsets.only(top: 16, right: 16, left: 0, bottom: 8),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 20 ? (maxY / 4).roundToDouble() : 5,
            getDrawingHorizontalLine: (value) => const FlLine(
              color: Color(0xFF334155),
              strokeWidth: 0.8,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: (points.length / 4).floorToDouble().clamp(1.0, 10.0),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) return const SizedBox.shrink();
                  final dt = DateTime.fromMillisecondsSinceEpoch(points[index].timestamp);
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      DateFormat.j().format(dt), // e.g. 2 PM
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            // Actual reports curve
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.2,
              color: level == StatusLevel.problems
                  ? const Color(0xFFEF4444)
                  : level == StatusLevel.possible
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF38BDF8),
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: (level == StatusLevel.problems
                        ? const Color(0xFFEF4444)
                        : level == StatusLevel.possible
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF38BDF8))
                    .withOpacity(0.15),
              ),
            ),
            // Expected Baseline line (dashed)
            LineChartBarData(
              spots: baselineSpots,
              isCurved: false,
              color: Colors.grey.withOpacity(0.4),
              barWidth: 1.5,
              dashArray: [4, 4],
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
