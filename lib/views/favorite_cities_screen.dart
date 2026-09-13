import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/preferences_service.dart';
import '../services/weather_service.dart';

class FavoriteCitiesScreen extends StatefulWidget {
  final Function(LocationData) onSelectCity;

  const FavoriteCitiesScreen({
    super.key,
    required this.onSelectCity,
  });

  @override
  State<FavoriteCitiesScreen> createState() => _FavoriteCitiesScreenState();
}

class _FavoriteCitiesScreenState extends State<FavoriteCitiesScreen> {
  List<LocationData> _cities = [];
  bool _isLoading = true;
  final WeatherService _weatherService = WeatherService();

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    setState(() => _isLoading = true);
    final cities = await PreferencesService.getFavoriteCities();
    setState(() {
      _cities = cities;
      _isLoading = false;
    });
  }

  Future<void> _removeCity(String name) async {
    await PreferencesService.removeFavoriteCity(name);
    _loadCities();
  }

  void _showAddCityDialog() {
    final searchController = TextEditingController();
    List<LocationData> searchResults = [];
    bool isSearching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const Text('إضافة مدينة للمفضلة', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'اكتب اسم المدينة (مثال: الإسكندرية، جدة)...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.search, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    onChanged: (query) async {
                      if (query.trim().length >= 2) {
                        setModalState(() => isSearching = true);
                        final results = await _weatherService.searchCities(query);
                        setModalState(() {
                          searchResults = results;
                          isSearching = false;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  if (isSearching)
                    const CircularProgressIndicator(color: Colors.amberAccent)
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final loc = searchResults[index];
                          return ListTile(
                            title: Text(loc.name, style: const TextStyle(color: Colors.white)),
                            subtitle: Text(loc.country, style: const TextStyle(color: Colors.white54)),
                            trailing: const Icon(Icons.add_circle_outline, color: Colors.amberAccent),
                            onTap: () async {
                              await PreferencesService.addFavoriteCity(loc);
                              if (!mounted) return;
                              Navigator.pop(context);
                              _loadCities();
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text('المدن المفضلة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: _showAddCityDialog,
            icon: const Icon(Icons.add_location_alt_rounded, color: Colors.amberAccent),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amberAccent))
          : _cities.isEmpty
              ? const Center(
                  child: Text('لا توجد مدن مفضلة محفوظة حتى الآن', style: TextStyle(color: Colors.white54)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cities.length,
                  itemBuilder: (context, index) {
                    final city = _cities[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amberAccent.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_city_rounded, color: Colors.amberAccent),
                        ),
                        title: Text(city.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text(city.country, style: const TextStyle(color: Colors.white54)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          onPressed: () => _removeCity(city.name),
                        ),
                        onTap: () {
                          widget.onSelectCity(city);
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
