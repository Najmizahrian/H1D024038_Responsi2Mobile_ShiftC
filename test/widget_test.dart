import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/models/location_model.dart';
import 'package:weather_app/models/weather_model.dart';
import 'package:weather_app/theme/app_theme.dart';

void main() {
  group('Model JSON Parsing', () {
    test('LocationModel.fromJson parses Open-Meteo Geocoding response', () {
      final json = {
        'id': 1642911,
        'name': 'Jakarta',
        'country': 'Indonesia',
        'admin1': 'Jakarta',
        'latitude': -6.21462,
        'longitude': 106.84513,
        'timezone': 'Asia/Jakarta',
      };

      final location = LocationModel.fromJson(json);

      expect(location.id, 1642911);
      expect(location.name, 'Jakarta');
      expect(location.country, 'Indonesia');
      expect(location.latitude, -6.21462);
      expect(location.longitude, 106.84513);
    });

    test('WeatherModel.fromJson parses Open-Meteo Forecast response', () {
      final json = {
        'latitude': -6.25,
        'longitude': 106.875,
        'timezone': 'Asia/Jakarta',
        'current': {
          'time': '2026-11-25T18:00',
          'temperature_2m': 29.4,
          'relative_humidity_2m': 78,
          'apparent_temperature': 33.1,
          'precipitation': 0.2,
          'weather_code': 3,
          'wind_speed_10m': 11.5,
        },
        'daily': {
          'time': ['2026-11-25', '2026-11-26'],
          'weather_code': [3, 61],
          'temperature_2m_max': [32.0, 31.5],
          'temperature_2m_min': [25.0, 24.5],
          'precipitation_probability_max': [40, 80],
        },
      };

      final weather = WeatherModel.fromJson(json);

      expect(weather.current.temperature2m, 29.4);
      expect(weather.current.relativeHumidity2m, 78);
      expect(weather.current.apparentTemperature, 33.1);
      expect(weather.current.precipitation, 0.2);
      expect(weather.current.weatherCode, 3);
      expect(weather.current.windSpeed10m, 11.5);
      expect(weather.daily.length, 2);
      expect(weather.daily.first.temperature2mMax, 32.0);
      expect(weather.daily.first.precipitationProbabilityMax, 40);
    });
  });

  testWidgets('AppTheme renders MaterialApp cleanly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: Text('Cuaca Open-Meteo')),
      ),
    );
    expect(find.text('Cuaca Open-Meteo'), findsOneWidget);
  });
}
