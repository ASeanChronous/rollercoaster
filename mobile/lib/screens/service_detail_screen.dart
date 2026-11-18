import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/service_model.dart';
import '../providers/app_state.dart';
import '../constants/app_constants.dart';
import '../widgets/status_pill.dart';
import '../widgets/outage_chart.dart';
import 'report_screen.dart';

class ServiceDetailScreen extends StatefulWidget {
  final String slug;

  const ServiceDetailScreen({super.key, required this.slug});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  ServiceDetail? _detail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final state = context.read<AppState>();
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await state.api.getServiceDetail(
        widget.slug,
        zip: state.zip,
        state: state.state,
      );
      if (mounted) {
        setState(() {
          _detail = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load service details.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isFav = state.isFavorite(widget.slug);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Text(
          _detail?.name ?? widget.slug,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.star_rounded : Icons.star_border_rounded,
              color: isFav ? const Color(0xFFFBBF24) : Colors.white,
            ),
            onPressed: () => state.toggleFavorite(widget.slug),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.campaign_rounded, color: Colors.white),
            label: Text(
              'Report an issue with ${_detail?.name ?? widget.slug}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportScreen(preselectedSlug: widget.slug),
                ),
              );
            },
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetchDetail,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF38BDF8),
                  backgroundColor: const Color(0xFF1E293B),
                  onRefresh: _fetchDetail,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusHeader(_detail!),
                        const SizedBox(height: 16),
                        if (_detail!.status.officialMessage != null) ...[
                          _buildOfficialMessageCard(_detail!.status),
                          const SizedBox(height: 16),
                        ],
                        _buildCurveCard(_detail!),
                        const SizedBox(height: 16),
                        if (_detail!.breakdown.isNotEmpty) ...[
                          _buildBreakdownCard(_detail!.breakdown),
                          const SizedBox(height: 16),
                        ],
                        _buildTroubleshootingCard(_detail!),
                        const SizedBox(height: 16),
                        _buildSourcesCard(_detail!.sources),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatusHeader(ServiceDetail detail) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: detail.status.level != StatusLevel.ok
              ? detail.status.level.color.withOpacity(0.5)
              : const Color(0xFF334155),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppConstants.categoryLabels[detail.category] ?? detail.category,
                      style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
              StatusPill(level: detail.status.level),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStat('Current Reports', '${detail.status.current}', 'in last 15 min'),
              const SizedBox(width: 16),
              _buildStat(
                'Baseline Ratio',
                '${detail.status.ratio.toStringAsFixed(1)}x',
                detail.status.ratio > 2 ? 'elevated' : 'normal',
                highlightColor: detail.status.level.color,
              ),
              const SizedBox(width: 16),
              _buildStat('24h Uptime', '${detail.uptime24h.toStringAsFixed(1)}%', 'last 24 hours'),
            ],
          ),
          if (detail.status.reasons.isNotEmpty) ...[
            const Divider(color: Color(0xFF334155), height: 24),
            ...detail.status.reasons.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 6, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r,
                          style: TextStyle(fontSize: 12, color: Colors.grey[300]),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, String subtext, {Color? highlightColor}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: highlightColor ?? Colors.white,
            ),
          ),
          Text(subtext, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildOfficialMessageCard(StatusResult status) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x26EF4444),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFEF4444)),
              SizedBox(width: 8),
              Text(
                'Provider Notice',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            status.officialMessage!,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCurveCard(ServiceDetail detail) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '24-Hour Outage Curve',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(width: 12, height: 3, color: const Color(0xFF38BDF8)),
              const SizedBox(width: 6),
              const Text('Outage reports', style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(width: 16),
              Container(width: 12, height: 1.5, color: Colors.grey),
              const SizedBox(width: 6),
              const Text('Normal baseline', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          OutageChart(points: detail.curve, level: detail.status.level),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(Map<String, int> breakdown) {
    final total = breakdown.values.fold<int>(0, (sum, val) => sum + val);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Most Reported Problems',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          ...breakdown.entries.map((entry) {
            final label = AppConstants.problemLabels[entry.key] ?? entry.key;
            final pct = total > 0 ? (entry.value / total) : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(label, style: const TextStyle(fontSize: 13, color: Colors.white)),
                      Text('${(pct * 100).toInt()}%',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF38BDF8))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: const Color(0xFF0F172A),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF38BDF8)),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingCard(ServiceDetail detail) {
    final isDown = detail.status.level != StatusLevel.ok;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDown ? Icons.sentiment_satisfied_alt_rounded : Icons.build_outlined,
                color: isDown ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isDown ? "It's probably not you!" : 'Troubleshooting Steps',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isDown)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Multiple independent outage signals are confirmed in this area. You do not need to replace your hardware — engineers are already notified.',
                style: TextStyle(fontSize: 13, color: Colors.grey[300]),
              ),
            ),
          ...detail.troubleshooting.asMap().entries.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${item.key + 1}. ',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                  Expanded(
                    child: Text(
                      item.value,
                      style: TextStyle(fontSize: 13, color: Colors.grey[300]),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSourcesCard(List<SourceInfo> sources) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monitored Sources',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sources.map((s) {
              return Chip(
                label: Text(s.name, style: const TextStyle(fontSize: 12, color: Colors.white)),
                backgroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFF334155)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
