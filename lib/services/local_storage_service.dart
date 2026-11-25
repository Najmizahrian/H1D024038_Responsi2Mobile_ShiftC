import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location_model.dart';

/// Service penyimpanan lokal menggunakan SharedPreferences
/// untuk menyimpan lokasi favorit, riwayat pencarian, dan lokasi terakhir.
class LocalStorageService {
  static const String _favoritesKey = 'favorite_locations';
  static const String _historyKey = 'search_history';
  static const String _lastLocationKey = 'last_selected_location';

  Future<List<LocationModel>> getFavorites() async {
    return _readLocationList(_favoritesKey);
  }

  Future<void> saveFavorites(List<LocationModel> favorites) async {
    await _writeLocationList(_favoritesKey, favorites);
  }

  Future<List<LocationModel>> getSearchHistory() async {
    return _readLocationList(_historyKey);
  }

  Future<void> saveSearchHistory(List<LocationModel> history) async {
    await _writeLocationList(_historyKey, history);
  }

  Future<LocationModel?> getLastLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastLocationKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return LocationModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLastLocation(LocationModel location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLocationKey, jsonEncode(location.toJson()));
  }

  Future<List<LocationModel>> _readLocationList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(key) ?? <String>[];
    final result = <LocationModel>[];
    for (final raw in rawList) {
      try {
        result.add(
          LocationModel.fromJson(jsonDecode(raw) as Map<String, dynamic>),
        );
      } catch (_) {
        // Lewati entri yang rusak jika ada
      }
    }
    return result;
  }

  Future<void> _writeLocationList(
    String key,
    List<LocationModel> locations,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = locations.map((loc) => jsonEncode(loc.toJson())).toList();
    await prefs.setStringList(key, encoded);
  }
}
