import 'package:flutter/foundation.dart';
import '../models/location_model.dart';
import '../models/weather_model.dart';
import '../services/local_storage_service.dart';
import '../services/weather_api_service.dart';

/// ViewModel utama untuk Home / Weather Screen (pola MVVM).
/// Mengelola state cuaca terkini, perkiraan harian, lokasi terpilih,
/// serta daftar lokasi favorit yang tersimpan di Local Storage.
class WeatherViewModel extends ChangeNotifier {
  final WeatherApiService _apiService;
  final LocalStorageService _storageService;

  static const LocationModel _defaultLocation = LocationModel(
    id: 1621177,
    name: 'Yogyakarta',
    country: 'Indonesia',
    admin1: 'Daerah Istimewa Yogyakarta',
    latitude: -7.7956,
    longitude: 110.3695,
    timezone: 'Asia/Jakarta',
  );

  WeatherViewModel({
    required WeatherApiService apiService,
    required LocalStorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService;

  LocationModel _selectedLocation = _defaultLocation;
  WeatherModel? _weather;
  List<LocationModel> _favorites = [];
  bool _isLoading = false;
  String? _errorMessage;

  LocationModel get selectedLocation => _selectedLocation;
  WeatherModel? get weather => _weather;
  List<LocationModel> get favorites => List.unmodifiable(_favorites);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isFavorite(LocationModel location) {
    return _favorites.contains(location);
  }

  /// Memuat lokasi favorit dan lokasi terakhir dari Local Storage saat aplikasi dibuka,
  /// lalu mengambil data cuaca terkini dari Open-Meteo API.
  Future<void> init() async {
    _favorites = await _storageService.getFavorites();
    final lastLocation = await _storageService.getLastLocation();
    if (lastLocation != null) {
      _selectedLocation = lastLocation;
    } else if (_favorites.isNotEmpty) {
      _selectedLocation = _favorites.first;
    }
    notifyListeners();
    await fetchWeatherForSelectedLocation();
  }

  /// Memilih lokasi baru, menyimpannya sebagai lokasi terakhir, dan memuat cuacanya.
  Future<void> selectLocation(LocationModel location) async {
    _selectedLocation = location;
    notifyListeners();
    await _storageService.saveLastLocation(location);
    await fetchWeatherForSelectedLocation();
  }

  /// Mengambil data cuaca dari Open-Meteo API untuk lokasi yang sedang dipilih.
  Future<void> fetchWeatherForSelectedLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _weather = await _apiService.fetchWeather(
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Menambah atau menghapus lokasi dari daftar favorit dan menyimpannya ke Local Storage.
  Future<void> toggleFavorite(LocationModel location) async {
    final updated = List<LocationModel>.from(_favorites);
    if (updated.contains(location)) {
      updated.remove(location);
    } else {
      updated.insert(0, location);
    }
    _favorites = updated;
    notifyListeners();
    await _storageService.saveFavorites(_favorites);
  }
}
