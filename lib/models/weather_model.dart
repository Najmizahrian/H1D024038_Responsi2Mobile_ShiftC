/// Model data cuaca lengkap dari Open-Meteo Weather Forecast API.
class WeatherModel {
  final double latitude;
  final double longitude;
  final String timezone;
  final CurrentWeather current;
  final List<DailyForecast> daily;

  const WeatherModel({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.current,
    required this.daily,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final currentJson = json['current'] as Map<String, dynamic>;
    final dailyJson = json['daily'] as Map<String, dynamic>;

    final times = (dailyJson['time'] as List<dynamic>).cast<String>();
    final codes = (dailyJson['weather_code'] as List<dynamic>)
        .map((e) => (e as num).toInt())
        .toList();
    final maxTemps = (dailyJson['temperature_2m_max'] as List<dynamic>)
        .map((e) => (e as num).toDouble())
        .toList();
    final minTemps = (dailyJson['temperature_2m_min'] as List<dynamic>)
        .map((e) => (e as num).toDouble())
        .toList();
    final rainProbs = (dailyJson['precipitation_probability_max'] as List<dynamic>)
        .map((e) => (e as num?)?.toInt() ?? 0)
        .toList();

    final dailyList = List<DailyForecast>.generate(times.length, (i) {
      return DailyForecast(
        date: times[i],
        weatherCode: i < codes.length ? codes[i] : 0,
        temperature2mMax: i < maxTemps.length ? maxTemps[i] : 0.0,
        temperature2mMin: i < minTemps.length ? minTemps[i] : 0.0,
        precipitationProbabilityMax: i < rainProbs.length ? rainProbs[i] : 0,
      );
    });

    return WeatherModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timezone: (json['timezone'] as String?) ?? 'auto',
      current: CurrentWeather.fromJson(currentJson),
      daily: dailyList,
    );
  }
}

/// Data cuaca terkini (`current.*`).
class CurrentWeather {
  final String time;
  final double temperature2m;
  final int relativeHumidity2m;
  final double apparentTemperature;
  final double precipitation;
  final int weatherCode;
  final double windSpeed10m;

  const CurrentWeather({
    required this.time,
    required this.temperature2m,
    required this.relativeHumidity2m,
    required this.apparentTemperature,
    required this.precipitation,
    required this.weatherCode,
    required this.windSpeed10m,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      time: (json['time'] as String?) ?? '',
      temperature2m: (json['temperature_2m'] as num).toDouble(),
      relativeHumidity2m: (json['relative_humidity_2m'] as num).toInt(),
      apparentTemperature: (json['apparent_temperature'] as num).toDouble(),
      precipitation: (json['precipitation'] as num).toDouble(),
      weatherCode: (json['weather_code'] as num).toInt(),
      windSpeed10m: (json['wind_speed_10m'] as num).toDouble(),
    );
  }
}

/// Data perkiraan cuaca harian (`daily.*`).
class DailyForecast {
  final String date;
  final int weatherCode;
  final double temperature2mMax;
  final double temperature2mMin;
  final int precipitationProbabilityMax;

  const DailyForecast({
    required this.date,
    required this.weatherCode,
    required this.temperature2mMax,
    required this.temperature2mMin,
    required this.precipitationProbabilityMax,
  });
}
