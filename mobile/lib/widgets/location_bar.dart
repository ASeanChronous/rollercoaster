import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class LocationBar extends StatelessWidget {
  const LocationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    String locationText = 'United States (National)';
    IconData icon = Icons.public_rounded;

    if (state.zip != null && state.zip!.isNotEmpty) {
      locationText = 'ZIP ${state.zip} (15-mile radius)';
      icon = Icons.my_location_rounded;
    } else if (state.state != null && state.state!.isNotEmpty) {
      locationText = 'State: ${state.state}';
      icon = Icons.location_on_rounded;
    }

    return InkWell(
      onTap: () => _showLocationDialog(context, state),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF38BDF8)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                locationText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Text(
              'Change',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF38BDF8),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: Color(0xFF38BDF8),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationDialog(BuildContext context, AppState state) {
    final zipController = TextEditingController(text: state.zip ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
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
                  const Text(
                    'Select Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter a 5-digit US ZIP code to view outages within 15 miles, or filter by State.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              if (state.watchlist.isNotEmpty) ...[
                const Text('Quick Switch from Watchlist:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: state.watchlist.map((loc) {
                      final isSelected = state.zip == loc.zip;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: Icon(loc.icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF38BDF8)),
                          label: Text('${loc.label} (${loc.zip})'),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.grey[300],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          backgroundColor: isSelected ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
                          side: BorderSide(color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF334155)),
                          onPressed: () {
                            state.setZip(loc.zip);
                            Navigator.pop(ctx);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              TextField(
                controller: zipController,
                keyboardType: TextInputType.number,
                maxLength: 5,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'US ZIP Code',
                  hintText: 'e.g. 75001 or 10001',
                  prefixIcon: const Icon(Icons.pin_drop_outlined, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        final val = zipController.text.trim();
                        if (val.length == 5) {
                          state.setZip(val);
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text('Apply ZIP', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF334155)),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      state.clearLocation();
                      Navigator.pop(ctx);
                    },
                    child: const Text('National', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Or filter by state:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ['CA', 'NY', 'TX', 'FL', 'IL', 'WA', 'OH', 'GA']
                    .map((s) => ActionChip(
                          label: Text(s, style: const TextStyle(fontSize: 12, color: Colors.white)),
                          backgroundColor: state.state == s
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF0F172A),
                          side: const BorderSide(color: Color(0xFF334155)),
                          onPressed: () {
                            state.setStateCode(s);
                            Navigator.pop(ctx);
                          },
                        ))
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
