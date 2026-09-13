import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/location_service.dart';
import '../services/preferences_service.dart';
import '../services/weather_service.dart';
import 'city_details_screen.dart';
import 'paywall_screen.dart';
import 'radar_map_screen.dart';
import 'settings_screen.dart';
import 'city_comparison_screen.dart';
import 'widgets/ai_advisor_sheet.dart';
import 'widgets/ad_banner_widget.dart';
import 'widgets/city_weather_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // 0 = Cities Dashboard, 1 = Radar, 2 = Settings
  final WeatherService _weatherService = WeatherService();

  bool _isProUser = false;
  bool _showCurrentLocation = true;
  bool _isCelsius = true;
  bool _useKmh = true;
  bool _is24Hour = false;

  // Current Location State
  LocationData? _currentLocation;
  FullWeatherData? _currentLocationWeather;
  bool _isLoadingLocation = true;

  // Saved Cities State
  List<LocationData> _savedCities = [];
  final Map<String, FullWeatherData?> _citiesWeather = {};
  bool _isLoadingSavedCities = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final isPro = await PreferencesService.isProUser();
    final showLoc = await PreferencesService.showCurrentLocation();
    final celsius = await PreferencesService.isCelsius();
    final kmh = await PreferencesService.useKmh();
    final is24 = await PreferencesService.is24Hour();

    if (mounted) {
      setState(() {
        _isProUser = isPro;
        _showCurrentLocation = showLoc;
        _isCelsius = celsius;
        _useKmh = kmh;
        _is24Hour = is24;
      });
    }

    await Future.wait([
      _loadCurrentLocation(),
      _loadSavedCities(),
    ]);
  }

  Future<void> _loadCurrentLocation() async {
    if (mounted) setState(() => _isLoadingLocation = true);

    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        final loc = LocationData(
          name: 'موقعي الحالي',
          latitude: position.latitude,
          longitude: position.longitude,
          country: 'الموقع الجغرافي',
        );
        _currentLocation = loc;

        final weather = await _weatherService.fetchWeather(
          loc.latitude,
          loc.longitude,
          locationName: loc.name,
        );

        if (mounted) {
          setState(() {
            _currentLocationWeather = weather;
            _isLoadingLocation = false;
          });
        }
      } else {
        // Fallback default location (e.g. Cairo)
        _currentLocation = LocationData(
          name: 'القاهرة',
          latitude: 30.0444,
          longitude: 31.2357,
          country: 'مصر',
        );
        final weather = await _weatherService.fetchWeather(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
          locationName: _currentLocation!.name,
        );
        if (mounted) {
          setState(() {
            _currentLocationWeather = weather;
            _isLoadingLocation = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _loadSavedCities() async {
    if (mounted) setState(() => _isLoadingSavedCities = true);

    final cities = await PreferencesService.getFavoriteCities();
    if (mounted) {
      setState(() {
        _savedCities = cities;
      });
    }

    await Future.wait(cities.map((city) async {
      try {
        final weather = await _weatherService.fetchWeather(
          city.latitude,
          city.longitude,
          locationName: city.name,
        );
        if (mounted) {
          setState(() {
            _citiesWeather[city.name] = weather;
          });
        }
      } catch (_) {}
    }));

    if (mounted) {
      setState(() => _isLoadingSavedCities = false);
    }
  }

  Future<void> _deleteWithUndo(LocationData city, int index) async {
    final deletedCity = city;
    final deletedWeather = _citiesWeather[city.name];

    setState(() {
      _savedCities.removeAt(index);
      _citiesWeather.remove(city.name);
    });
    await PreferencesService.removeFavoriteCity(city.name);

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حذف ${city.name} من القائمة'),
        duration: const Duration(seconds: 4),
        backgroundColor: const Color(0xFF1E293B),
        action: SnackBarAction(
          label: 'تراجع',
          textColor: Colors.amberAccent,
          onPressed: () async {
            setState(() {
              _savedCities.insert(index.clamp(0, _savedCities.length), deletedCity);
              if (deletedWeather != null) {
                _citiesWeather[deletedCity.name] = deletedWeather;
              }
            });
            await PreferencesService.addFavoriteCity(deletedCity);
          },
        ),
      ),
    );
  }

  void _showAddCitySearch() {
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
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Text(
                    'إضافة مدينة جديدة',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن اسم مدينة (مثال: دبي، الرياض، الإسكندرية)...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.search, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
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
                      child: searchResults.isEmpty
                          ? const Center(
                              child: Text(
                                'ابحث عن أي مدينة لعرضها وإضافتها لبطاقاتك',
                                style: TextStyle(color: Colors.white54),
                              ),
                            )
                          : ListView.builder(
                              itemCount: searchResults.length,
                              itemBuilder: (context, index) {
                                final loc = searchResults[index];
                                final alreadyAdded = _savedCities.any((c) => c.name == loc.name);

                                return ListTile(
                                  leading: const Icon(Icons.location_city_rounded, color: Colors.white70),
                                  title: Text(
                                    loc.name,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    loc.country,
                                    style: const TextStyle(color: Colors.white54),
                                  ),
                                  trailing: alreadyAdded
                                      ? const Chip(
                                          label: Text('مضافة', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                          backgroundColor: Colors.white10,
                                        )
                                      : IconButton(
                                          icon: const Icon(Icons.add_circle_outline, color: Colors.amberAccent),
                                          onPressed: () async {
                                            final nav = Navigator.of(context);
                                            await PreferencesService.addFavoriteCity(loc);
                                            if (!mounted) return;
                                            nav.pop();
                                            _loadSavedCities();
                                          },
                                        ),
                                  onTap: () async {
                                    final nav = Navigator.of(context);
                                    await PreferencesService.addFavoriteCity(loc);
                                    if (!mounted) return;
                                    nav.pop();
                                    _loadSavedCities();
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

  void _openCityDetails(LocationData location, FullWeatherData? initialWeather, {bool isCurrent = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CityDetailsScreen(
          location: location,
          initialWeatherData: initialWeather,
          isCurrentLocation: isCurrent,
        ),
      ),
    ).then((_) {
      _loadAllData();
    });
  }

  Widget _buildCitiesDashboard() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAllData,
          color: Colors.amberAccent,
          backgroundColor: const Color(0xFF1E293B),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Top Bar Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isProUser ? 'WeatherApp Pro 👑' : 'WeatherApp',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'لوحة بطاقات المدن والطقس',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (!_isProUser)
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amberAccent.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.workspace_premium_rounded, color: Colors.amberAccent, size: 20),
                          ),
                          tooltip: 'ترقية Pro',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PaywallScreen()),
                            ).then((_) => _loadAllData());
                          },
                        ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF38BDF8), Colors.amberAccent],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amberAccent.withValues(alpha: 0.3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF0F172A), size: 18),
                        ),
                        tooltip: 'مساعد الطقس الذكي',
                        onPressed: () {
                          final weather = _currentLocationWeather ??
                              (_savedCities.isNotEmpty ? _citiesWeather[_savedCities.first.name] : null);
                          final location = _currentLocation ??
                              (_savedCities.isNotEmpty ? _savedCities.first : null);
                          if (weather != null && location != null) {
                            AIAdvisorSheet.show(
                              context,
                              weather: weather,
                              location: location,
                              onAppNeedsRefresh: () => _loadAllData(),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('جاري تحميل بيانات الطقس، يرجى الانتظار ثانية واحدة...')),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.compare_arrows_rounded, color: Colors.amberAccent, size: 20),
                        ),
                        tooltip: 'مقارنة المدن',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CityComparisonScreen(
                                initialCity1: _currentLocation ??
                                    (_savedCities.isNotEmpty ? _savedCities.first : null),
                                initialWeather1: _currentLocationWeather ??
                                    (_savedCities.isNotEmpty
                                        ? _citiesWeather[_savedCities.first.name]
                                        : null),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                        ),
                        tooltip: 'إضافة مدينة',
                        onPressed: _showAddCitySearch,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Ad Banner for Free Users
              AdBannerWidget(
                isProUser: _isProUser,
                onUpgradeTap: _loadAllData,
              ),

              // Pinned Section: Current Location
              if (_showCurrentLocation && (_currentLocation != null || _isLoadingLocation)) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.my_location_rounded, color: Colors.amberAccent, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'موقعي الحالي',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                CityWeatherCard(
                  cityName: _currentLocation?.name ?? 'موقعي الحالي',
                  country: _currentLocation?.country ?? 'جاري التحديد...',
                  weatherData: _currentLocationWeather,
                  isCurrentLocation: true,
                  isLoading: _isLoadingLocation && _currentLocationWeather == null,
                  isCelsius: _isCelsius,
                  useKmh: _useKmh,
                  is24Hour: _is24Hour,
                  onTap: () {
                    if (_currentLocation != null) {
                      _openCityDetails(_currentLocation!, _currentLocationWeather, isCurrent: true);
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],

              // Section: Saved Cities
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.bookmarks_rounded, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'المدن المحفوظة (${_savedCities.length})',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              if (_isLoadingSavedCities && _savedCities.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: Colors.amberAccent),
                  ),
                )
              else if (_savedCities.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.location_off_rounded, color: Colors.white38, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'لا توجد مدن محفوظة حتى الآن',
                        style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'اضغط على زر "إضافة" في الأعلى للبحث عن أي مدينة وحفظها في بطاقاتك.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showAddCitySearch,
                        icon: const Icon(Icons.search),
                        label: const Text('ابحث عن مدينة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amberAccent,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _savedCities.length,
                  onReorder: (oldIndex, newIndex) async {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = _savedCities.removeAt(oldIndex);
                      _savedCities.insert(newIndex, item);
                    });
                    await PreferencesService.saveCitiesList(_savedCities);
                  },
                  itemBuilder: (context, index) {
                    final city = _savedCities[index];
                    final weather = _citiesWeather[city.name];
                    return Dismissible(
                      key: ValueKey('city_${city.name}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 24),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
                      ),
                      onDismissed: (_) => _deleteWithUndo(city, index),
                      child: CityWeatherCard(
                        cityName: city.name,
                        country: city.country,
                        weatherData: weather,
                        isLoading: weather == null && _isLoadingSavedCities,
                        isCelsius: _isCelsius,
                        useKmh: _useKmh,
                        is24Hour: _is24Hour,
                        onDelete: () => _deleteWithUndo(city, index),
                        onTap: () => _openCityDetails(city, weather),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double radarLat = _currentLocation?.latitude ?? 30.0444;
    final double radarLon = _currentLocation?.longitude ?? 31.2357;
    final String radarName = _currentLocation?.name ?? 'القاهرة';

    Widget body;
    switch (_currentIndex) {
      case 0:
        body = _buildCitiesDashboard();
        break;
      case 1:
        body = RadarMapScreen(
          latitude: radarLat,
          longitude: radarLon,
          locationName: radarName,
        );
        break;
      case 2:
        body = SettingsScreen(
          onSettingsChanged: _loadAllData,
        );
        break;
      default:
        body = _buildCitiesDashboard();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: Colors.amberAccent,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'المدن',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.radar_rounded),
            label: 'الرادار',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}
