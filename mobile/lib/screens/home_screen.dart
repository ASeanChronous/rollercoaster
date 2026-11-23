import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/service_model.dart';
import '../widgets/location_bar.dart';
import '../widgets/category_chips.dart';
import '../widgets/service_card.dart';
import 'report_screen.dart';
import 'diagnostics_screen.dart';
import 'bill_credit_screen.dart';
import 'emergency_guide_screen.dart';
import '../widgets/weather_alert_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final outageCount = state.outageServices.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search service (e.g. Spectrum, Verizon)...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
                onChanged: (val) => state.setSearchQuery(val),
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.show_chart_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Rollercoaster',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            tooltip: 'Emergency Offline Guide',
            icon: const Icon(Icons.offline_bolt_outlined, color: Color(0xFFF97316)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmergencyGuideScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'ISP Bill Credit Claimer',
            icon: const Icon(Icons.monetization_on_outlined, color: Color(0xFF10B981)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BillCreditScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Run Diagnoser',
            icon: const Icon(Icons.troubleshoot_rounded, color: Color(0xFF38BDF8)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DiagnosticsScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  state.setSearchQuery('');
                  _isSearching = false;
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF38BDF8),
          indicatorWeight: 3,
          labelColor: const Color(0xFF38BDF8),
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            const Tab(text: 'All Services'),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Outages'),
                  if (outageCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$outageCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Favorites'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.add_alert_rounded, color: Colors.white),
        label: const Text(
          'Report Outage',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportScreen()),
          );
        },
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.isOffline)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_off_rounded, color: Color(0xFFFB923C), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Offline Mode: Showing cached data${state.lastCachedTime != null ? " (${state.lastCachedTime!.hour}:${state.lastCachedTime!.minute.toString().padLeft(2, '0')})" : ""}.',
                            style: const TextStyle(color: Colors.white, fontSize: 11.5),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const EmergencyGuideScreen()),
                            );
                          },
                          child: const Text('Guide', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11.5, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                const LocationBar(),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DiagnosticsScreen()),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF1E293B)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.troubleshoot_rounded, color: Color(0xFF38BDF8), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Is It Me or Them? Quick Diagnoser',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'Isolate whether an outage is your Wi-Fi or the remote service',
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF38BDF8), size: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                if (state.weatherAlerts.isNotEmpty) ...[
                  ...state.weatherAlerts.map((alert) => WeatherAlertBanner(alert: alert)),
                  const SizedBox(height: 4),
                ],
                CategoryChips(
                  selectedCategory: state.selectedCategory,
                  onSelected: (cat) => state.setCategory(cat),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildServiceList(state.services, state),
            _buildServiceList(state.outageServices, state, emptyMessage: 'No active outages right now! All tracked services are operational.'),
            _buildServiceList(state.favoriteServices, state, emptyMessage: 'No starred services yet. Tap the star icon on any service to pin it here.'),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceList(
    List<ServiceSummary> list,
    AppState state, {
    String emptyMessage = 'No services found.',
  }) {
    if (state.isLoading && list.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
    }

    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => state.loadServices(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 60),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 48, color: Color(0xFF10B981)),
                    const SizedBox(height: 12),
                    Text(
                      emptyMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF38BDF8),
      backgroundColor: const Color(0xFF1E293B),
      onRefresh: () => state.loadServices(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80, top: 4),
        itemCount: list.length,
        itemBuilder: (context, index) {
          return ServiceCard(service: list[index]);
        },
      ),
    );
  }
}
