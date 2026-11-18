import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/map_models.dart';
import '../models/service_model.dart';
import '../providers/app_state.dart';
import '../constants/app_constants.dart';
import 'service_detail_screen.dart';
import 'report_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  double _currentZoom = 4.2;
  int _selectedMinutes = 60;
  String _selectedCategory = 'all';
  String _mode = 'cells'; // 'cells' or 'states'

  List<MapCell> _cells = [];
  List<StateOutageSummary> _states = [];
  bool _isLoading = true;

  static const LatLng _usCenter = LatLng(39.8283, -98.5795);

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    setState(() => _isLoading = true);
    final state = context.read<AppState>();
    try {
      final res = await state.api.getMapData(
        minutes: _selectedMinutes,
        category: _selectedCategory,
      );
      if (mounted) {
        setState(() {
          _cells = res.cells;
          _states = res.states;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _recenter() {
    _mapController.move(_usCenter, 4.2);
  }

  void _zoomIn() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1.0);
  }

  void _zoomOut() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1.0);
  }

  void _showCellDetails(MapCell cell) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: cell.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.radar_rounded, color: cell.color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Outage Cell (~7-mi radius)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'GPS: ${cell.lat.toStringAsFixed(2)}, ${cell.lng.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Crowd Reports (${_selectedMinutes == 60 ? 'Last hour' : '${_selectedMinutes ~/ 60} hours'}):',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      Text(
                        '${cell.count}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: cell.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Top Affected Services in this Area:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ...cell.top.map((top) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(top.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        Row(
                          children: [
                            Text('${top.count} reports', style: TextStyle(color: cell.color, fontSize: 13)),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ServiceDetailScreen(slug: top.slug),
                                  ),
                                );
                              },
                              child: const Icon(Icons.chevron_right, size: 18, color: Color(0xFF38BDF8)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add_alert_rounded, color: Colors.white),
                    label: const Text('Report an Issue Here', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReportScreen(
                            preselectedSlug: cell.top.isNotEmpty ? cell.top.first.slug : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // FlutterMap Tile & Marker Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _usCenter,
              initialZoom: _currentZoom,
              minZoom: 3.0,
              maxZoom: 16.0,
              onPositionChanged: (camera, _) {
                setState(() => _currentZoom = camera.zoom);
              },
            ),
            children: [
              // Dark theme high performance CartoDB tile layer
              TileLayer(
                urlTemplate: 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.rollercoaster.rollercoaster_mobile',
                tileBuilder: (context, widget, tile) {
                  return ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Colors.transparent,
                      BlendMode.multiply,
                    ),
                    child: widget,
                  );
                },
              ),

              // CircleLayer for High-LOD Outage Cells (Heat halos)
              if (_mode == 'cells')
                CircleLayer(
                  circles: _cells.map((cell) {
                    final radius = cell.calculateRadius(_currentZoom);
                    return CircleMarker(
                      point: cell.point,
                      radius: radius,
                      useRadiusInMeter: false,
                      color: cell.color.withValues(alpha: 0.4),
                      borderColor: cell.color,
                      borderStrokeWidth: 1.5,
                    );
                  }).toList(),
                ),

              // Interactive MarkerLayer (Tappable Badges)
              if (_mode == 'cells')
                MarkerLayer(
                  markers: _cells.map((cell) {
                    final isHighLod = _currentZoom >= 5.5;
                    return Marker(
                      point: cell.point,
                      width: isHighLod ? 64 : 32,
                      height: isHighLod ? 36 : 32,
                      child: GestureDetector(
                        onTap: () => _showCellDetails(cell),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: cell.color,
                            shape: isHighLod ? BoxShape.rectangle : BoxShape.circle,
                            borderRadius: isHighLod ? BorderRadius.circular(18) : null,
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: cell.color.withValues(alpha: 0.6),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: isHighLod
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.bolt, color: Colors.white, size: 13),
                                    Text(
                                      '${cell.count}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  cell.count > 99 ? '99+' : '${cell.count}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

              // State Summary Mode
              if (_mode == 'states')
                MarkerLayer(
                  markers: _states.map((st) {
                    final hasProblems = st.level != StatusLevel.ok;
                    return Marker(
                      point: st.point,
                      width: 48,
                      height: 48,
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${st.name}: ${st.problems} major problems, ${st.possible} possible',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: st.level.color.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: hasProblems
                                ? [
                                    BoxShadow(
                                      color: st.level.color.withValues(alpha: 0.6),
                                      blurRadius: 12,
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                st.state,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              if (st.problems > 0)
                                Text(
                                  '${st.problems}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),

          // Top Header & Glassmorphic Controls Bar
          SafeArea(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF334155)),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 12, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Mode & Title Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.radar_rounded, color: Color(0xFF38BDF8), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _mode == 'cells' ? 'Outage Cells (High LOD)' : 'State Heatmap',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          // Mode toggle
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'cells', icon: Icon(Icons.grain_rounded, size: 16)),
                              ButtonSegment(value: 'states', icon: Icon(Icons.map_outlined, size: 16)),
                            ],
                            selected: {_mode},
                            onSelectionChanged: (set) {
                              setState(() => _mode = set.first);
                            },
                            style: ButtonStyle(
                              visualDensity: VisualDensity.compact,
                              backgroundColor: WidgetStateProperty.resolveWith(
                                (states) => states.contains(WidgetState.selected)
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Filter Row: Time Window & Category
                      Row(
                        children: [
                          // Time Window chips
                          Wrap(
                            spacing: 6,
                            children: [60, 360, 1440].map((m) {
                              final label = m == 60 ? '1h' : m == 360 ? '6h' : '24h';
                              final isSelected = _selectedMinutes == m;
                              return ChoiceChip(
                                label: Text(label),
                                labelStyle: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.white : Colors.grey[400],
                                ),
                                selected: isSelected,
                                selectedColor: const Color(0xFF2563EB),
                                backgroundColor: const Color(0xFF0F172A),
                                side: const BorderSide(color: Color(0xFF334155)),
                                onSelected: (_) {
                                  setState(() => _selectedMinutes = m);
                                  _loadMapData();
                                },
                              );
                            }).toList(),
                          ),
                          const Spacer(),
                          // Category selector dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCategory,
                                dropdownColor: const Color(0xFF1E293B),
                                style: const TextStyle(fontSize: 12, color: Colors.white),
                                items: AppConstants.categoryLabels.entries.map((e) {
                                  return DropdownMenuItem(value: e.key, child: Text(e.value));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedCategory = val);
                                    _loadMapData();
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Floating Action Buttons (Right side: Zoom +, Zoom -, Recenter)
          Positioned(
            right: 16,
            bottom: 32,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'recenter_btn',
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: const Color(0xFF38BDF8),
                  onPressed: _recenter,
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_in_btn',
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out_btn',
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),

          // Bottom Left LOD & Outage Density Legend
          Positioned(
            left: 16,
            bottom: 32,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('100+ (Severe)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFF97316), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('25–99 (High)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('5–24 (Moderate)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Positioned(
              top: 140,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8))),
                      SizedBox(width: 8),
                      Text('Refreshing map data...', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
