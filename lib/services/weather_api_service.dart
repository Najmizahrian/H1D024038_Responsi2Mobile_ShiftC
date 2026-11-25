import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/location_model.dart';
import '../models/weather_model.dart';

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

/// Service untuk melakukan HTTP GET request ke Open-Meteo REST API
/// (Geocoding API dan Weather Forecast API).
class WeatherApiService {
  static const String _forecastBaseUrl =
      'https://api.open-meteo.com/v1/forecast';
  static const String _geocodingBaseUrl =
      'https://geocoding-api.open-meteo.com/v1/search';

  final http.Client _client;

  WeatherApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Mencari lokasi kota berdasarkan nama menggunakan Open-Meteo Geocoding API.
  Future<List<LocationModel>> searchCities(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final uri = Uri.parse(_geocodingBaseUrl).replace(
      queryParameters: {
        'name': trimmed,
        'count': '10',
        'language': 'id',
        'format': 'json',
      },
    );

    try {
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw ApiException(
          'Gagal mencari kota (HTTP ${response.statusCode}).',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) {
        return [];
      }

      return results
          .map((item) => LocationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw const ApiException(
        'Tidak dapat terhubung ke server Geocoding. Periksa koneksi internet Anda.',
      );
    }
  }

  /// Mengambil data cuaca terkini & perkiraan harian dari Open-Meteo Forecast API.
  Future<WeatherModel> fetchWeather({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(_forecastBaseUrl).replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current': [
          'temperature_2m',
          'relative_humidity_2m',
          'apparent_temperature',
          'precipitation',
          'weather_code',
          'wind_speed_10m',
        ].join(','),
        'daily': [
          'weather_code',
          'temperature_2m_max',
          'temperature_2m_min',
          'precipitation_probability_max',
        ].join(','),
        'timezone': 'auto',
      },
    );

    try {
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw ApiException(
          'Gagal mengambil data cuaca (HTTP ${response.statusCode}).',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['current'] == null || data['daily'] == null) {
        throw const ApiException('Data cuaca tidak lengkap dari server.');
      }

      return WeatherModel.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw const ApiException(
        'Gagal memuat data cuaca. Periksa koneksi internet Anda dan coba lagi.',
      );
    }
  }
}
