import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/watchlist_model.dart';
import '../models/weather_alert_model.dart';

class AppState extends ChangeNotifier {
  final StorageService storage;
  late ApiService api;

  String _selectedCategory = 'all';
  String _searchQuery = '';
  String? _zip;
  String? _state;
  bool _isLoading = false;
  bool _isOffline = false;
  String? _errorMessage;
  List<ServiceSummary> _services = [];
  List<WeatherAlert> _weatherAlerts = [];

  AppState({required this.storage}) {
    _zip = storage.savedZip;
    _state = storage.savedState;
    api = ApiService(
      baseUrl: storage.baseUrl,
      deviceId: storage.deviceId,
    );
    loadServices();
  }

  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  String? get zip => _zip;
  String? get state => _state;
  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;
  DateTime? get lastCachedTime => storage.lastCachedTime;
  String? get errorMessage => _errorMessage;
  List<WeatherAlert> get weatherAlerts => _weatherAlerts;

  List<ServiceSummary> get services {
    var filtered = _services;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((s) => s.name.toLowerCase().contains(q) || s.slug.toLowerCase().contains(q))
          .toList();
    }
    return filtered;
  }

  List<ServiceSummary> get outageServices =>
      services.where((s) => s.level != StatusLevel.ok).toList();

  List<ServiceSummary> get favoriteServices =>
      services.where((s) => storage.isFavorite(s.slug)).toList();

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
    loadServices();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> setZip(String? newZip) async {
    _zip = newZip;
    await storage.setSavedZip(newZip);
    notifyListeners();
    loadServices();
  }

  Future<void> setStateCode(String? newState) async {
    _state = newState;
    await storage.setSavedState(newState);
    notifyListeners();
    loadServices();
  }

  Future<void> clearLocation() async {
    _zip = null;
    _state = null;
    await storage.setSavedZip(null);
    await storage.setSavedState(null);
    notifyListeners();
    loadServices();
  }

  Future<void> toggleFavorite(String slug) async {
    await storage.toggleFavorite(slug);
    notifyListeners();
  }

  bool isFavorite(String slug) => storage.isFavorite(slug);

  List<WatchlistLocation> get watchlist => storage.watchlist;

  Future<void> saveWatchlistLocation(WatchlistLocation location) async {
    await storage.saveWatchlistLocation(location);
    notifyListeners();
  }

  Future<void> deleteWatchlistLocation(String id) async {
    await storage.deleteWatchlistLocation(id);
    notifyListeners();
  }

  String get mapTileUrl => storage.mapTileUrl;

  Future<void> updateMapSettings(String provider, String apiKey) async {
    await storage.setMapProvider(provider);
    await storage.setMapApiKey(apiKey);
    notifyListeners();
  }

  void updateBaseUrl(String newUrl) {
    storage.setBaseUrl(newUrl);
    api = ApiService(baseUrl: newUrl, deviceId: storage.deviceId);
    loadServices();
  }

  Future<void> loadServices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        api.getServices(
          category: _selectedCategory,
          zip: _zip,
          state: _state,
        ),
        api.getWeatherAlerts(
          zip: _zip,
          state: _state,
        ),
      ]);
      _services = results[0] as List<ServiceSummary>;
      _weatherAlerts = results[1] as List<WeatherAlert>;
      _isOffline = false;
      await storage.cacheServices(_services);
    } catch (e) {
      final cached = storage.getCachedServices();
      if (cached != null && cached.isNotEmpty) {
        _services = cached;
        _isOffline = true;
      } else {
        _errorMessage = 'Could not load service status';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
