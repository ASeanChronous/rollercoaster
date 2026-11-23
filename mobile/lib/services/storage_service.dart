import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/watchlist_model.dart';
import '../models/service_model.dart';

class StorageService {
  static const String _keyBaseUrl = 'api_base_url';
  static const String _keyDeviceId = 'device_id';
  static const String _keyZip = 'saved_zip';
  static const String _keyState = 'saved_state';
  static const String _keyFavorites = 'favorite_services';
  static const String _keyWatchlist = 'watchlist_locations';
  static const String _keyCachedServices = 'cached_services_data';
  static const String _keyCachedTimestamp = 'cached_services_timestamp';
  static const String _keyMapProvider = 'map_tile_provider';
  static const String _keyMapApiKey = 'map_tile_api_key';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Ensure anonymous device ID exists
    if (!_prefs.containsKey(_keyDeviceId)) {
      final newId = const Uuid().v4();
      await _prefs.setString(_keyDeviceId, newId);
    }
  }

  String get baseUrl => _prefs.getString(_keyBaseUrl) ?? 'http://10.0.2.2:3000'; // 10.0.2.2 for Android emulator, localhost for iOS simulator / web
  Future<void> setBaseUrl(String url) async => await _prefs.setString(_keyBaseUrl, url);

  String get deviceId => _prefs.getString(_keyDeviceId) ?? 'anonymous-device';

  String get mapProvider => _prefs.getString(_keyMapProvider) ?? 'cartodb';
  Future<void> setMapProvider(String provider) async => await _prefs.setString(_keyMapProvider, provider);

  String get mapApiKey => _prefs.getString(_keyMapApiKey) ?? '';
  Future<void> setMapApiKey(String key) async => await _prefs.setString(_keyMapApiKey, key);

  String get mapTileUrl {
    final key = mapApiKey.trim();
    final provider = mapProvider;

    if (provider == 'maptiler' && key.isNotEmpty) {
      return 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$key';
    } else if (provider == 'mapbox' && key.isNotEmpty) {
      return 'https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/{z}/{x}/{y}?access_token=$key';
    } else if (provider == 'osm') {
      return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
    return 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';
  }

  String? get savedZip => _prefs.getString(_keyZip);
  Future<void> setSavedZip(String? zip) async {
    if (zip == null || zip.isEmpty) {
      await _prefs.remove(_keyZip);
    } else {
      await _prefs.setString(_keyZip, zip);
    }
  }

  String? get savedState => _prefs.getString(_keyState);
  Future<void> setSavedState(String? state) async {
    if (state == null || state.isEmpty) {
      await _prefs.remove(_keyState);
    } else {
      await _prefs.setString(_keyState, state);
    }
  }

  List<String> get favorites => _prefs.getStringList(_keyFavorites) ?? [];
  Future<void> toggleFavorite(String slug) async {
    final list = favorites;
    if (list.contains(slug)) {
      list.remove(slug);
    } else {
      list.add(slug);
    }
    await _prefs.setStringList(_keyFavorites, list);
  }

  bool isFavorite(String slug) => favorites.contains(slug);

  List<WatchlistLocation> get watchlist {
    final raw = _prefs.getStringList(_keyWatchlist);
    if (raw == null || raw.isEmpty) {
      // Default pre-seeded watchlist
      return [
        WatchlistLocation(
          id: 'home',
          label: 'Home',
          zip: '75001',
          cityState: 'Dallas, TX',
          iconName: 'home',
          primaryIspSlug: 'spectrum',
        ),
        WatchlistLocation(
          id: 'office',
          label: 'Downtown Office',
          zip: '10001',
          cityState: 'New York, NY',
          iconName: 'work',
          primaryIspSlug: 'verizon',
        ),
      ];
    }
    return raw
        .map((str) => WatchlistLocation.fromJson(json.decode(str) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveWatchlistLocation(WatchlistLocation location) async {
    final list = watchlist;
    final index = list.indexWhere((l) => l.id == location.id);
    if (index >= 0) {
      list[index] = location;
    } else {
      list.add(location);
    }
    await _saveWatchlistList(list);
  }

  Future<void> deleteWatchlistLocation(String id) async {
    final list = watchlist;
    list.removeWhere((l) => l.id == id);
    await _saveWatchlistList(list);
  }

  Future<void> _saveWatchlistList(List<WatchlistLocation> list) async {
    final strings = list.map((l) => json.encode(l.toJson())).toList();
    await _prefs.setStringList(_keyWatchlist, strings);
  }

  Future<void> cacheServices(List<ServiceSummary> services) async {
    final list = services.map((s) => s.toJson()).toList();
    await _prefs.setString(_keyCachedServices, json.encode(list));
    await _prefs.setInt(_keyCachedTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  List<ServiceSummary>? getCachedServices() {
    final raw = _prefs.getString(_keyCachedServices);
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = json.decode(raw) as List<dynamic>;
      return list.map((item) => ServiceSummary.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  DateTime? get lastCachedTime {
    final ts = _prefs.getInt(_keyCachedTimestamp);
    return ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : null;
  }
}
