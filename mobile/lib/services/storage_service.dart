import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  static const String _keyBaseUrl = 'api_base_url';
  static const String _keyDeviceId = 'device_id';
  static const String _keyZip = 'saved_zip';
  static const String _keyState = 'saved_state';
  static const String _keyFavorites = 'favorite_services';

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
}
