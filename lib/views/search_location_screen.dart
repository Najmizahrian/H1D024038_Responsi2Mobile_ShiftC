import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/location_model.dart';
import '../viewmodels/search_viewmodel.dart';
import '../viewmodels/weather_viewmodel.dart';

/// Screen kedua (Search / Location Screen) untuk mencari kota via Open-Meteo
/// Geocoding API, memilih lokasi untuk melihat cuacanya, serta mengelola
/// daftar lokasi favorit dan riwayat pencarian yang tersimpan di Local Storage.
class SearchLocationScreen extends StatefulWidget {
  const SearchLocationScreen({super.key});

  @override
  State<SearchLocationScreen> createState() => _SearchLocationScreenState();
}

class _SearchLocationScreenState extends State<SearchLocationScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final searchVm = context.read<SearchViewModel>();
      searchVm.clearSearch();
      searchVm.loadHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String value) {
    context.read<SearchViewModel>().searchCities(value);
  }

  Future<void> _selectCity(LocationModel location) async {
    final searchVm = context.read<SearchViewModel>();
    final weatherVm = context.read<WeatherViewModel>();

    await searchVm.addToHistory(location);
    await weatherVm.selectLocation(location);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Lokasi'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _onSearchSubmitted,
                    onChanged: (value) {
                      setState(() {});
                      if (value.trim().isEmpty) {
                        context.read<SearchViewModel>().clearSearch();
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Masukkan nama kota (misal: Jakarta, Tokyo)',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              tooltip: 'Hapus',
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                context.read<SearchViewModel>().clearSearch();
                                setState(() {});
                              },
                            ),
                          IconButton(
                            tooltip: 'Cari',
                            icon: const Icon(Icons.arrow_forward_rounded),
                            onPressed: () =>
                                _onSearchSubmitted(_searchController.text),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Consumer2<SearchViewModel, WeatherViewModel>(
                    builder: (context, searchVm, weatherVm, _) {
                      if (searchVm.isSearching) {
                        return const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 12),
                              Text('Mencari kota...'),
                            ],
                          ),
                        );
                      }

                      if (searchVm.errorMessage != null) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  size: 48,
                                  color: Colors.red.shade400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  searchVm.errorMessage!,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                FilledButton(
                                  onPressed: () => _onSearchSubmitted(
                                    _searchController.text,
                                  ),
                                  child: const Text('Coba Lagi'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (searchVm.hasSearched) {
                        if (searchVm.searchResults.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_off_rounded,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Kota tidak ditemukan. Coba kata kunci lain.',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: searchVm.searchResults.length,
                          itemBuilder: (context, index) {
                            final loc = searchVm.searchResults[index];
                            return _LocationListTile(
                              location: loc,
                              isFavorite: weatherVm.isFavorite(loc),
                              onTap: () => _selectCity(loc),
                              onToggleFavorite: () =>
                                  weatherVm.toggleFavorite(loc),
                            );
                          },
                        );
                      }

                      return _SavedLocationsView(
                        favorites: weatherVm.favorites,
                        history: searchVm.searchHistory,
                        isFavorite: weatherVm.isFavorite,
                        onSelect: _selectCity,
                        onToggleFavorite: weatherVm.toggleFavorite,
                        onClearHistory: searchVm.clearHistory,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SavedLocationsView extends StatelessWidget {
  final List<LocationModel> favorites;
  final List<LocationModel> history;
  final bool Function(LocationModel) isFavorite;
  final ValueChanged<LocationModel> onSelect;
  final ValueChanged<LocationModel> onToggleFavorite;
  final VoidCallback onClearHistory;

  const _SavedLocationsView({
    required this.favorites,
    required this.history,
    required this.isFavorite,
    required this.onSelect,
    required this.onToggleFavorite,
    required this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    if (favorites.isEmpty && history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Ketik nama kota lalu tekan Enter atau tombol cari.\nLokasi favorit dan riwayat pencarian akan tersimpan di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (favorites.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Lokasi Favorit',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...favorites.map(
            (loc) => _LocationListTile(
              location: loc,
              isFavorite: true,
              onTap: () => onSelect(loc),
              onToggleFavorite: () => onToggleFavorite(loc),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (history.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Riwayat Pencarian',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton(
                onPressed: onClearHistory,
                child: const Text('Hapus Semua'),
              ),
            ],
          ),
          ...history.map(
            (loc) => _LocationListTile(
              location: loc,
              isFavorite: isFavorite(loc),
              onTap: () => onSelect(loc),
              onToggleFavorite: () => onToggleFavorite(loc),
            ),
          ),
        ],
      ],
    );
  }
}

class _LocationListTile extends StatelessWidget {
  final LocationModel location;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const _LocationListTile({
    required this.location,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.location_on_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          location.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          location.subtitle.isNotEmpty
              ? '${location.subtitle} (${location.latitude.toStringAsFixed(2)}, ${location.longitude.toStringAsFixed(2)})'
              : '${location.latitude.toStringAsFixed(2)}, ${location.longitude.toStringAsFixed(2)}',
        ),
        trailing: IconButton(
          tooltip: isFavorite ? 'Hapus dari Favorit' : 'Simpan ke Favorit',
          icon: Icon(
            isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
            color: isFavorite ? Colors.amber.shade700 : Colors.grey,
          ),
          onPressed: onToggleFavorite,
        ),
        onTap: onTap,
      ),
    );
  }
}
