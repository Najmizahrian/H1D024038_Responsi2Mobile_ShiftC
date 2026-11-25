import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/location_model.dart';
import '../models/weather_model.dart';
import '../utils/weather_code_helper.dart';
import '../viewmodels/weather_viewmodel.dart';
import 'search_location_screen.dart';

/// Screen utama (Home / Weather Screen) yang menampilkan kondisi cuaca terkini,
/// detail metrik cuaca, daftar lokasi favorit, dan perkiraan cuaca beberapa hari ke depan.
class HomeWeatherScreen extends StatefulWidget {
  const HomeWeatherScreen({super.key});

  @override
  State<HomeWeatherScreen> createState() => _HomeWeatherScreenState();
}

class _HomeWeatherScreenState extends State<HomeWeatherScreen> {
  Future<void> _openSearchScreen(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SearchLocationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherViewModel>(
      builder: (context, vm, _) {
        final location = vm.selectedLocation;
        final isFav = vm.isFavorite(location);

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(location.name),
                if (location.subtitle.isNotEmpty)
                  Text(
                    location.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: isFav ? 'Hapus dari Favorit' : 'Simpan ke Favorit',
                icon: Icon(
                  isFav ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFav ? Colors.amber.shade700 : null,
                ),
                onPressed: () => vm.toggleFavorite(location),
              ),
              IconButton(
                tooltip: 'Cari Kota',
                icon: const Icon(Icons.search_rounded),
                onPressed: () => _openSearchScreen(context),
              ),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  children: [
                    if (vm.favorites.isNotEmpty)
                      _FavoriteChipsBar(
                        favorites: vm.favorites,
                        selectedLocation: location,
                        onSelect: vm.selectLocation,
                      ),
                    Expanded(
                      child: _buildBody(context, vm),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, WeatherViewModel vm) {
    if (vm.isLoading && vm.weather == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat data cuaca dari Open-Meteo...'),
          ],
        ),
      );
    }

    if (vm.errorMessage != null && vm.weather == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Gagal Memuat Cuaca',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                vm.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: vm.fetchWeatherForSelectedLocation,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final weather = vm.weather;
    if (weather == null) {
      return const Center(child: Text('Data cuaca tidak tersedia.'));
    }

    return RefreshIndicator(
      onRefresh: vm.fetchWeatherForSelectedLocation,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (vm.isLoading) const LinearProgressIndicator(),
          if (vm.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MaterialBanner(
                content: Text(vm.errorMessage!),
                leading: const Icon(Icons.warning_amber_rounded),
                actions: [
                  TextButton(
                    onPressed: vm.fetchWeatherForSelectedLocation,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          _CurrentWeatherHeroCard(
            location: vm.selectedLocation,
            weather: weather,
          ),
          const SizedBox(height: 16),
          _WeatherDetailsGrid(weather: weather),
          const SizedBox(height: 20),
          Text(
            'Perkiraan Cuaca Harian',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          _DailyForecastCard(daily: weather.daily),
        ],
      ),
    );
  }
}

class _FavoriteChipsBar extends StatelessWidget {
  final List<LocationModel> favorites;
  final LocationModel selectedLocation;
  final ValueChanged<LocationModel> onSelect;

  const _FavoriteChipsBar({
    required this.favorites,
    required this.selectedLocation,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: favorites.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final fav = favorites[index];
          final isSelected = fav == selectedLocation;
          return ChoiceChip(
            label: Text(fav.name),
            avatar: Icon(
              Icons.star_rounded,
              size: 16,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Colors.amber.shade700,
            ),
            selected: isSelected,
            onSelected: (_) => onSelect(fav),
          );
        },
      ),
    );
  }
}

class _CurrentWeatherHeroCard extends StatelessWidget {
  final LocationModel location;
  final WeatherModel weather;

  const _CurrentWeatherHeroCard({
    required this.location,
    required this.weather,
  });

  @override
  Widget build(BuildContext context) {
    final current = weather.current;
    final today = weather.daily.isNotEmpty ? weather.daily.first : null;
    final gradientColors =
        WeatherCodeHelper.getGradientColors(current.weatherCode);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      WeatherCodeHelper.getDescription(current.weatherCode),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Terasa seperti ${current.apparentTemperature.toStringAsFixed(1)}°C',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                WeatherCodeHelper.getIcon(current.weatherCode),
                color: Colors.white,
                size: 64,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '${current.temperature2m.toStringAsFixed(1)}°C',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                ),
          ),
          if (today != null) ...[
            const SizedBox(height: 8),
            Text(
              'Maks ${today.temperature2mMax.toStringAsFixed(1)}°  •  Min ${today.temperature2mMin.toStringAsFixed(1)}°  •  Peluang Hujan ${today.precipitationProbabilityMax}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeatherDetailsGrid extends StatelessWidget {
  final WeatherModel weather;

  const _WeatherDetailsGrid({required this.weather});

  @override
  Widget build(BuildContext context) {
    final current = weather.current;
    final todayRainProb = weather.daily.isNotEmpty
        ? weather.daily.first.precipitationProbabilityMax
        : 0;

    final metrics = [
      _MetricItem(
        icon: Icons.water_drop_outlined,
        label: 'Kelembapan',
        value: '${current.relativeHumidity2m}%',
      ),
      _MetricItem(
        icon: Icons.air_rounded,
        label: 'Kecepatan Angin',
        value: '${current.windSpeed10m.toStringAsFixed(1)} km/j',
      ),
      _MetricItem(
        icon: Icons.umbrella_outlined,
        label: 'Peluang Hujan',
        value: '$todayRainProb%',
      ),
      _MetricItem(
        icon: Icons.grain_rounded,
        label: 'Curah Hujan',
        value: '${current.precipitation.toStringAsFixed(1)} mm',
      ),
      _MetricItem(
        icon: Icons.thermostat_outlined,
        label: 'Suhu Dirasakan',
        value: '${current.apparentTemperature.toStringAsFixed(1)}°C',
      ),
      _MetricItem(
        icon: Icons.tag_rounded,
        label: 'Kode Cuaca',
        value: 'WMO ${current.weatherCode}',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 500 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.1,
          ),
          itemBuilder: (context, index) {
            final item = metrics[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MetricItem {
  final IconData icon;
  final String label;
  final String value;

  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _DailyForecastCard extends StatelessWidget {
  final List<DailyForecast> daily;

  const _DailyForecastCard({required this.daily});

  @override
  Widget build(BuildContext context) {
    if (daily.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Data perkiraan harian tidak tersedia.'),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: daily.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: Colors.grey.shade200,
        ),
        itemBuilder: (context, index) {
          final item = daily[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  child: Text(
                    WeatherCodeHelper.formatDayDate(item.date, index),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(
                  WeatherCodeHelper.getIcon(item.weatherCode),
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${item.precipitationProbabilityMax}% hujan',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                Text(
                  '${item.temperature2mMin.toStringAsFixed(0)}° / ${item.temperature2mMax.toStringAsFixed(0)}°',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
