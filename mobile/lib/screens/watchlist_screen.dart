import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/watchlist_model.dart';
import '../providers/app_state.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  void _openAddLocationSheet([WatchlistLocation? existing]) {
    final labelCtrl = TextEditingController(text: existing?.label ?? '');
    final zipCtrl = TextEditingController(text: existing?.zip ?? '');
    String selectedIcon = existing?.iconName ?? 'home';
    String? selectedIsp = existing?.primaryIspSlug ?? 'spectrum';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existing != null ? 'Edit Location' : 'Add Property to Watchlist',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: labelCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Property Label',
                      hintText: 'e.g. Home, Downtown Office, Parents',
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: zipCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: '5-Digit US ZIP Code',
                      hintText: 'e.g. 75001',
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Select Icon:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildIconOption('home', Icons.home_rounded, selectedIcon, (v) => setModalState(() => selectedIcon = v)),
                      const SizedBox(width: 10),
                      _buildIconOption('work', Icons.business_rounded, selectedIcon, (v) => setModalState(() => selectedIcon = v)),
                      const SizedBox(width: 10),
                      _buildIconOption('parents', Icons.family_restroom_rounded, selectedIcon, (v) => setModalState(() => selectedIcon = v)),
                      const SizedBox(width: 10),
                      _buildIconOption('store', Icons.storefront_rounded, selectedIcon, (v) => setModalState(() => selectedIcon = v)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Primary ISP at Location:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedIsp,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        items: const [
                          DropdownMenuItem(value: 'spectrum', child: Text('Spectrum')),
                          DropdownMenuItem(value: 'xfinity', child: Text('Xfinity (Comcast)')),
                          DropdownMenuItem(value: 'att-internet', child: Text('AT&T Internet')),
                          DropdownMenuItem(value: 'verizon', child: Text('Verizon Fios / 5G')),
                          DropdownMenuItem(value: 't-mobile', child: Text('T-Mobile 5G Home')),
                        ],
                        onChanged: (v) => setModalState(() => selectedIsp = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        final label = labelCtrl.text.trim();
                        final zip = zipCtrl.text.trim();
                        if (zip.length == 5 && label.isNotEmpty) {
                          final loc = WatchlistLocation(
                            id: existing?.id ?? const Uuid().v4(),
                            label: label,
                            zip: zip,
                            cityState: 'ZIP $zip',
                            iconName: selectedIcon,
                            primaryIspSlug: selectedIsp,
                          );
                          final state = context.read<AppState>();
                          state.saveWatchlistLocation(loc);
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text('Save Location', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIconOption(String id, IconData icon, String selected, ValueChanged<String> onSelect) {
    final isSel = id == selected;
    return InkWell(
      onTap: () => onSelect(id),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSel ? const Color(0xFF38BDF8) : const Color(0xFF334155)),
        ),
        child: Icon(icon, color: isSel ? Colors.white : Colors.grey, size: 22),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final locations = state.watchlist;
    final currentActiveZip = state.zip;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text('Location Watchlist', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF38BDF8)),
            onPressed: () => _openAddLocationSheet(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
        label: const Text('Add Location', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: () => _openAddLocationSheet(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.pin_drop_rounded, color: Color(0xFF38BDF8), size: 26),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Multi-Property Monitoring',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Track internet reliability across your home, business, and family properties at once.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          ...locations.map((loc) {
            final isActive = currentActiveZip == loc.zip;
            final isProblemArea = loc.zip == '75001'; // Spectrum Dallas cluster

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF38BDF8)
                      : isProblemArea
                          ? const Color(0xFFEF4444).withValues(alpha: 0.6)
                          : const Color(0xFF334155),
                  width: isActive ? 2.0 : 1.0,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
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
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(loc.icon, color: const Color(0xFF38BDF8), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      loc.label,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (isActive) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2563EB),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text('ACTIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  'ZIP ${loc.zip} (${loc.cityState})',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.grey),
                          color: const Color(0xFF1E293B),
                          onSelected: (val) {
                            if (val == 'edit') {
                              _openAddLocationSheet(loc);
                            } else if (val == 'delete') {
                              state.deleteWatchlistLocation(loc.id);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Colors.white))),
                            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Color(0xFFEF4444)))),
                          ],
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFF334155), height: 24),

                    // Health row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Primary Provider:', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                            const SizedBox(height: 2),
                            Text(
                              loc.primaryIspSlug?.toUpperCase() ?? 'BROADBAND',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isProblemArea
                                ? const Color(0x26EF4444)
                                : const Color(0x2610B981),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isProblemArea
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF10B981),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isProblemArea ? Icons.error_outline : Icons.check_circle_outline,
                                size: 14,
                                color: isProblemArea ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isProblemArea ? 'Disruptions Reported' : 'No Problems',
                                style: TextStyle(
                                  color: isProblemArea ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Action: Apply as active ZIP
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: isActive ? const Color(0xFF38BDF8) : const Color(0xFF334155)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: Icon(
                          isActive ? Icons.check : Icons.filter_alt_outlined,
                          size: 16,
                          color: isActive ? const Color(0xFF38BDF8) : Colors.white,
                        ),
                        label: Text(
                          isActive ? 'Currently Active Scope' : 'Filter App to this Location',
                          style: TextStyle(
                            color: isActive ? const Color(0xFF38BDF8) : Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: isActive
                            ? null
                            : () {
                                state.setZip(loc.zip);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Switched active location to ${loc.label} (${loc.zip})')),
                                );
                              },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
