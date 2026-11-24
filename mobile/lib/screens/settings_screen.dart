import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _mapApiKeyController = TextEditingController();
  late String _selectedMapProvider;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _urlController.text = state.storage.baseUrl;
    final savedProvider = state.storage.mapProvider;
    // If the saved provider was cartodb with no key, default smoothly to esri
    if (savedProvider == 'cartodb' && state.storage.mapApiKey.isEmpty) {
      _selectedMapProvider = 'esri';
    } else {
      _selectedMapProvider = ['esri', 'cartodb', 'maptiler', 'mapbox', 'osm'].contains(savedProvider)
          ? savedProvider
          : 'esri';
    }
    _mapApiKeyController.text = state.storage.mapApiKey;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _mapApiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Backend Connection',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'API Base URL',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Points to the Rollercoaster API (e.g. http://localhost:3000 or your Fly.io instance)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _urlController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'http://localhost:3000',
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final url = _urlController.text.trim();
                    if (url.isNotEmpty) {
                      state.updateBaseUrl(url);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('API URL updated')),
                      );
                    }
                  },
                  child: const Text('Save & Reconnect', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Outage Map Tiles & API Key',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Map Tile Provider',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose your tile provider or enter your MapTiler / Mapbox API key.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedMapProvider,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      items: const [
                        DropdownMenuItem(value: 'esri', child: Text('Esri Dark Gray Canvas (Default - Free, No Key)')),
                        DropdownMenuItem(value: 'cartodb', child: Text('CartoDB Dark Matter (Requires Carto API Key)')),
                        DropdownMenuItem(value: 'maptiler', child: Text('MapTiler Cloud (Requires API Key)')),
                        DropdownMenuItem(value: 'mapbox', child: Text('Mapbox (Requires Access Token)')),
                        DropdownMenuItem(value: 'osm', child: Text('OpenStreetMap Standard (Free, No Key)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedMapProvider = val);
                      },
                    ),
                  ),
                ),
                if (_selectedMapProvider == 'cartodb' || _selectedMapProvider == 'maptiler' || _selectedMapProvider == 'mapbox') ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedMapProvider == 'cartodb'
                            ? 'CartoDB API Key'
                            : _selectedMapProvider == 'maptiler'
                                ? 'MapTiler API Key'
                                : 'Mapbox Access Token',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13),
                      ),
                      if (_selectedMapProvider == 'cartodb')
                        const Text(
                          'carto.com/basemaps/apikey',
                          style: TextStyle(fontSize: 11, color: Color(0xFF38BDF8)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _mapApiKeyController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: _selectedMapProvider == 'cartodb'
                          ? 'Paste key from carto.com/basemaps/apikey'
                          : _selectedMapProvider == 'maptiler'
                              ? 'e.g. 7qX... (from cloud.maptiler.com)'
                              : 'e.g. pk.eyJ1...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                    ),
                  ),
                  if (_selectedMapProvider == 'cartodb')
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'CARTO recently began requiring an API key. Free keys can be created in 30s at carto.com/basemaps/apikey. While blank, Esri Dark Canvas is used automatically.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                ],
                const SizedBox(height: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final key = _mapApiKeyController.text.trim();
                    state.updateMapSettings(_selectedMapProvider, key);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Map settings & API key saved!')),
                    );
                  },
                  child: const Text('Save Map Settings', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Device & Privacy',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Anonymous Device Identifier', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  state.storage.deviceId,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF38BDF8)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Used to prevent duplicate report spam while strictly protecting your privacy. No personal data is collected.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'About',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rollercoaster Outage Aggregator for iOS',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 4),
                Text('Version 1.0.0 (Flutter / iOS)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                SizedBox(height: 8),
                Text(
                  'Combines crowd reports with licensed outage trackers and official status pages into one unified status model.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
