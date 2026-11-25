import 'package:flutter/foundation.dart';
import '../models/location_model.dart';
import '../services/local_storage_service.dart';
import '../services/weather_api_service.dart';

/// ViewModel untuk Search / Location Screen (pola MVVM).
/// Mengelola pencarian kota melalui Open-Meteo Geocoding API
/// serta riwayat pencarian yang disimpan di Local Storage.
class SearchViewModel extends ChangeNotifier {
  final WeatherApiService _apiService;
  final LocalStorageService _storageService;

  static const int _maxHistoryItems = 10;

  SearchViewModel({
    required WeatherApiService apiService,
    required LocalStorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService;

  List<LocationModel> _searchResults = [];
  List<LocationModel> _searchHistory = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _errorMessage;

  List<LocationModel> get searchResults => List.unmodifiable(_searchResults);
  List<LocationModel> get searchHistory => List.unmodifiable(_searchHistory);
  bool get isSearching => _isSearching;
  bool get hasSearched => _hasSearched;
  String? get errorMessage => _errorMessage;

  /// Memuat riwayat pencarian dari Local Storage.
  Future<void> loadHistory() async {
    _searchHistory = await _storageService.getSearchHistory();
    notifyListeners();
  }

  /// Melakukan pencarian kota ke Open-Meteo Geocoding API.
  Future<void> searchCities(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      clearSearch();
      return;
    }

    _isSearching = true;
    _hasSearched = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _searchResults = await _apiService.searchCities(trimmed);
    } catch (e) {
      _searchResults = [];
      _errorMessage = e.toString();
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Menyimpan lokasi yang dipilih ke riwayat pencarian di Local Storage.
  Future<void> addToHistory(LocationModel location) async {
    final updated = List<LocationModel>.from(_searchHistory)
      ..remove(location)
      ..insert(0, location);

    if (updated.length > _maxHistoryItems) {
      updated.removeRange(_maxHistoryItems, updated.length);
    }

    _searchHistory = updated;
    notifyListeners();
    await _storageService.saveSearchHistory(_searchHistory);
  }

  /// Menghapus seluruh riwayat pencarian.
  Future<void> clearHistory() async {
    _searchHistory = [];
    notifyListeners();
    await _storageService.saveSearchHistory(_searchHistory);
  }

  void clearSearch() {
    _searchResults = [];
    _hasSearched = false;
    _errorMessage = null;
    notifyListeners();
  }
}
