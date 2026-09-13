import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/preferences_service.dart';
import '../services/unit_helper.dart';
import '../services/weather_service.dart';
import '../theme/weather_colors.dart';

class CityComparisonScreen extends StatefulWidget {
  final LocationData? initialCity1;
  final LocationData? initialCity2;
  final FullWeatherData? initialWeather1;

  const CityComparisonScreen({
    super.key,
    this.initialCity1,
    this.initialCity2,
    this.initialWeather1,
  });

  @override
  State<CityComparisonScreen> createState() => _CityComparisonScreenState();
}

class _CityComparisonScreenState extends State<CityComparisonScreen> {
  final WeatherService _weatherService = WeatherService();

  late LocationData _city1;
  late LocationData _city2;

  FullWeatherData? _weather1;
  FullWeatherData? _weather2;

  bool _isLoading1 = false;
  bool _isLoading2 = false;

  bool _isCelsius = true;
  bool _useKmh = true;
  String _pressureUnit = 'hPa';
  bool _is24Hour = false;

  List<LocationData> _favorites = [];

  @override
  void initState() {
    super.initState();
    _initDefaults();
  }

  Future<void> _initDefaults() async {
    _isCelsius = await PreferencesService.isCelsius();
    _useKmh = await PreferencesService.useKmh();
    _pressureUnit = await PreferencesService.getPressureUnit();
    _is24Hour = await PreferencesService.is24Hour();
    _favorites = await PreferencesService.getFavoriteCities();

    // Setup city 1: provided or favorite #0 or Cairo
    _city1 = widget.initialCity1 ??
        (_favorites.isNotEmpty
            ? _favorites.first
            : LocationData(name: 'القاهرة', latitude: 30.0444, longitude: 31.2357, country: 'مصر'));

    // Setup city 2: provided or favorite #1 or Riyadh
    if (widget.initialCity2 != null) {
      _city2 = widget.initialCity2!;
    } else if (_favorites.length > 1) {
      _city2 = _favorites[1];
    } else {
      _city2 = LocationData(name: 'الرياض', latitude: 24.7136, longitude: 46.6753, country: 'السعودية');
    }

    if (widget.initialWeather1 != null && widget.initialCity1?.name == _city1.name) {
      _weather1 = widget.initialWeather1;
    } else {
      _fetchWeatherForCity1();
    }

    _fetchWeatherForCity2();
  }

  Future<void> _fetchWeatherForCity1() async {
    setState(() => _isLoading1 = true);
    try {
      final w = await _weatherService.fetchWeather(_city1.latitude, _city1.longitude, locationName: _city1.name);
      if (mounted) setState(() => _weather1 = w);
    } catch (_) {}
    if (mounted) setState(() => _isLoading1 = false);
  }

  Future<void> _fetchWeatherForCity2() async {
    setState(() => _isLoading2 = true);
    try {
      final w = await _weatherService.fetchWeather(_city2.latitude, _city2.longitude, locationName: _city2.name);
      if (mounted) setState(() => _weather2 = w);
    } catch (_) {}
    if (mounted) setState(() => _isLoading2 = false);
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _fetchWeatherForCity1(),
      _fetchWeatherForCity2(),
    ]);
  }

  void _swapCities() {
    setState(() {
      final tempCity = _city1;
      _city1 = _city2;
      _city2 = tempCity;

      final tempWeather = _weather1;
      _weather1 = _weather2;
      _weather2 = tempWeather;
    });
  }

  void _selectCity(int slot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CityPickerSheet(
        title: slot == 1 ? 'اختر المدينة الأولى' : 'اختر المدينة الثانية',
        favorites: _favorites,
        weatherService: _weatherService,
        onCitySelected: (selected) {
          Navigator.pop(ctx);
          setState(() {
            if (slot == 1) {
              _city1 = selected;
              _fetchWeatherForCity1();
            } else {
              _city2 = selected;
              _fetchWeatherForCity2();
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.compare_arrows_rounded, color: Colors.amberAccent),
            SizedBox(width: 8),
            Text(
              'مقارنة المدن جنباً إلى جنب',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'تحديث البيانات',
            onPressed: _refreshAll,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          color: Colors.amberAccent,
          backgroundColor: const Color(0xFF1E293B),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Dual City Header Card with Swap Button
              _buildDualCityHeader(),
              const SizedBox(height: 16),

              // Quick Verdict & Summary Card
              if (_weather1 != null && _weather2 != null) ...[
                _buildVerdictCard(),
                const SizedBox(height: 16),
              ],

              // Side-by-Side Metrics Matrix
              _buildComparisonMatrix(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDualCityHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: WeatherColors.glassDecoration(borderRadius: 24, opacity: 0.15),
      child: Column(
        children: [
          Row(
            children: [
              // City 1 Slot
              Expanded(
                child: _buildCityCard(
                  city: _city1,
                  weather: _weather1,
                  isLoading: _isLoading1,
                  accentColor: const Color(0xFF38BDF8),
                  onTap: () => _selectCity(1),
                ),
              ),

              // Center Swap Pill
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.swap_horiz_rounded, color: Colors.amberAccent, size: 20),
                      ),
                      tooltip: 'تبديل الترتيب',
                      onPressed: _swapCities,
                    ),
                    const Text(
                      'VS',
                      style: TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              // City 2 Slot
              Expanded(
                child: _buildCityCard(
                  city: _city2,
                  weather: _weather2,
                  isLoading: _isLoading2,
                  accentColor: const Color(0xFFF59E0B),
                  onTap: () => _selectCity(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'اضغط على أي مدينة لتغييرها أو البحث عن مدينة جديدة',
            style: TextStyle(color: Colors.white38, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCityCard({
    required LocationData city,
    required FullWeatherData? weather,
    required bool isLoading,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accentColor.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    city.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.edit_outlined, color: Colors.white38, size: 13),
              ],
            ),
            Text(
              city.country.isEmpty ? 'عالمي' : city.country,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amberAccent),
                ),
              )
            else if (weather != null) ...[
              Icon(
                WeatherCodeHelper.getIcon(weather.current.weatherCode, weather.current.isDay),
                color: accentColor,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                UnitHelper.formatTemp(weather.current.temperature, isCelsius: _isCelsius),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                WeatherCodeHelper.getDescription(weather.current.weatherCode, weather.current.isDay),
                style: const TextStyle(color: Colors.white70, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ] else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('غير متوفر', style: TextStyle(color: Colors.white38, fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerdictCard() {
    final t1 = _weather1!.current.temperature;
    final t2 = _weather2!.current.temperature;
    final diff = (t1 - t2).abs();
    final warmerCity = t1 > t2 ? _city1.name : _city2.name;
    final coolerCity = t1 > t2 ? _city2.name : _city1.name;

    String verdict;
    if (diff < 1.0) {
      verdict = 'درجات الحرارة متقاربة جداً بين ${_city1.name} و${_city2.name} بفارق لا يتعدى درجة واحدة.';
    } else {
      verdict = '$warmerCity أدفأ من $coolerCity بفارق ${diff.toStringAsFixed(1)}° مئوية.';
    }

    // Additional activity recommendation
    final aqi1 = _weather1!.airQuality?.aqi ?? 50;
    final aqi2 = _weather2!.airQuality?.aqi ?? 50;
    String airVerdict;
    if (aqi1 < aqi2) {
      airVerdict = 'جودة الهواء وأنقى في ${_city1.name}.';
    } else if (aqi2 < aqi1) {
      airVerdict = 'جودة الهواء وأنقى في ${_city2.name}.';
    } else {
      airVerdict = 'مستوى نقاء الهواء متطابق في المدينتين.';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF38BDF8).withValues(alpha: 0.12),
            Colors.amberAccent.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amberAccent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.analytics_rounded, color: Colors.amberAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'خلاصة المقارنة اللحظية ⚡',
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$verdict $airVerdict',
                  style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonMatrix() {
    final w1 = _weather1;
    final w2 = _weather2;

    if (w1 == null || w2 == null) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: WeatherColors.glassDecoration(borderRadius: 24, opacity: 0.1),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.amberAccent),
        ),
      );
    }

    final today1 = w1.daily.isNotEmpty ? w1.daily.first : null;
    final today2 = w2.daily.isNotEmpty ? w2.daily.first : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: WeatherColors.glassDecoration(borderRadius: 24, opacity: 0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: [
                Icon(Icons.table_chart_rounded, color: Colors.amberAccent, size: 18),
                SizedBox(width: 8),
                Text(
                  'المصفوفة المقارنة للعوامل الجوية',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 1. Apparent Temp
          _buildMetricRow(
            label: 'الحرارة المحسوسة',
            icon: Icons.thermostat_rounded,
            val1: UnitHelper.formatTemp(w1.current.apparentTemperature, isCelsius: _isCelsius),
            val2: UnitHelper.formatTemp(w2.current.apparentTemperature, isCelsius: _isCelsius),
            highlight1: w1.current.apparentTemperature > w2.current.apparentTemperature,
            highlight2: w2.current.apparentTemperature > w1.current.apparentTemperature,
          ),
          _buildDivider(),

          // 2. High / Low
          _buildMetricRow(
            label: 'العظمى / الصغرى',
            icon: Icons.swap_vert_rounded,
            val1: today1 != null
                ? '${UnitHelper.formatTemp(today1.tempMax, isCelsius: _isCelsius)} / ${UnitHelper.formatTemp(today1.tempMin, isCelsius: _isCelsius)}'
                : '—',
            val2: today2 != null
                ? '${UnitHelper.formatTemp(today2.tempMax, isCelsius: _isCelsius)} / ${UnitHelper.formatTemp(today2.tempMin, isCelsius: _isCelsius)}'
                : '—',
          ),
          _buildDivider(),

          // 3. Humidity
          _buildMetricRow(
            label: 'الرطوبة النسبية',
            icon: Icons.water_drop_rounded,
            val1: '${w1.current.humidity}%',
            val2: '${w2.current.humidity}%',
            highlight1: w1.current.humidity > w2.current.humidity,
            highlight2: w2.current.humidity > w1.current.humidity,
          ),
          _buildDivider(),

          // 4. Wind Speed
          _buildMetricRow(
            label: 'سرعة الرياح',
            icon: Icons.air_rounded,
            val1: UnitHelper.formatWind(w1.current.windSpeed, useKmh: _useKmh),
            val2: UnitHelper.formatWind(w2.current.windSpeed, useKmh: _useKmh),
            highlight1: w1.current.windSpeed > w2.current.windSpeed,
            highlight2: w2.current.windSpeed > w1.current.windSpeed,
          ),
          _buildDivider(),

          // 5. UV Index
          _buildMetricRow(
            label: 'مؤشر الأشعة UV',
            icon: Icons.wb_sunny_rounded,
            val1: today1 != null ? '${today1.uvIndexMax.round()} (${_getUvLabel(today1.uvIndexMax)})' : '—',
            val2: today2 != null ? '${today2.uvIndexMax.round()} (${_getUvLabel(today2.uvIndexMax)})' : '—',
          ),
          _buildDivider(),

          // 6. Air Quality
          _buildMetricRow(
            label: 'جودة الهواء (AQI)',
            icon: Icons.eco_rounded,
            val1: w1.airQuality != null ? '${w1.airQuality!.aqi} (${w1.airQuality!.statusText})' : 'جيد',
            val2: w2.airQuality != null ? '${w2.airQuality!.aqi} (${w2.airQuality!.statusText})' : 'جيد',
            highlightColor1: w1.airQuality?.statusColor,
            highlightColor2: w2.airQuality?.statusColor,
          ),
          _buildDivider(),

          // 7. Allergy Risk
          _buildMetricRow(
            label: 'خطر الحساسية',
            icon: Icons.masks_rounded,
            val1: w1.airQuality?.allergyRiskLevel ?? 'منخفض',
            val2: w2.airQuality?.allergyRiskLevel ?? 'منخفض',
            highlightColor1: w1.airQuality?.allergyRiskColor,
            highlightColor2: w2.airQuality?.allergyRiskColor,
          ),
          _buildDivider(),

          // 8. Surface Pressure
          _buildMetricRow(
            label: 'الضغط الجوي',
            icon: Icons.speed_rounded,
            val1: UnitHelper.formatPressure(w1.current.pressure, unit: _pressureUnit),
            val2: UnitHelper.formatPressure(w2.current.pressure, unit: _pressureUnit),
          ),
          _buildDivider(),

          // 9. Sunrise
          _buildMetricRow(
            label: 'شروق الشمس',
            icon: Icons.wb_twilight_rounded,
            val1: today1?.sunrise != null ? UnitHelper.formatTime(today1!.sunrise!, is24Hour: _is24Hour) : '—',
            val2: today2?.sunrise != null ? UnitHelper.formatTime(today2!.sunrise!, is24Hour: _is24Hour) : '—',
          ),
          _buildDivider(),

          // 10. Sunset
          _buildMetricRow(
            label: 'غروب الشمس',
            icon: Icons.nights_stay_outlined,
            val1: today1?.sunset != null ? UnitHelper.formatTime(today1!.sunset!, is24Hour: _is24Hour) : '—',
            val2: today2?.sunset != null ? UnitHelper.formatTime(today2!.sunset!, is24Hour: _is24Hour) : '—',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow({
    required String label,
    required IconData icon,
    required String val1,
    required String val2,
    bool highlight1 = false,
    bool highlight2 = false,
    Color? highlightColor1,
    Color? highlightColor2,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // City 1 Value
          Expanded(
            child: Text(
              val1,
              style: TextStyle(
                color: highlightColor1 ?? (highlight1 ? Colors.amberAccent : Colors.white),
                fontSize: 12,
                fontWeight: highlight1 || highlightColor1 != null ? FontWeight.bold : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Central Label
          Container(
            width: 130,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white60, size: 14),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // City 2 Value
          Expanded(
            child: Text(
              val2,
              style: TextStyle(
                color: highlightColor2 ?? (highlight2 ? Colors.amberAccent : Colors.white),
                fontSize: 12,
                fontWeight: highlight2 || highlightColor2 != null ? FontWeight.bold : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.white.withValues(alpha: 0.06), height: 1);
  }

  String _getUvLabel(double uv) {
    if (uv <= 2) return 'منخفض';
    if (uv <= 5) return 'معتدل';
    if (uv <= 7) return 'مرتفع';
    return 'شديد';
  }
}

// Interactive City Picker Modal Sheet
class _CityPickerSheet extends StatefulWidget {
  final String title;
  final List<LocationData> favorites;
  final WeatherService weatherService;
  final Function(LocationData) onCitySelected;

  const _CityPickerSheet({
    required this.title,
    required this.favorites,
    required this.weatherService,
    required this.onCitySelected,
  });

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<LocationData> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Center(
            child: Text(
              widget.title,
              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),

          // Search Field
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'ابحث عن اسم مدينة للمقارنة...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (query) async {
              if (query.trim().length >= 2) {
                setState(() => _isSearching = true);
                final res = await widget.weatherService.searchCities(query);
                if (mounted) {
                  setState(() {
                    _searchResults = res;
                    _isSearching = false;
                  });
                }
              } else {
                setState(() => _searchResults = []);
              }
            },
          ),
          const SizedBox(height: 16),

          if (_isSearching)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: Colors.amberAccent),
              ),
            )
          else if (_searchResults.isNotEmpty) ...[
            const Text(
              'نتائج البحث:',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, i) {
                  final loc = _searchResults[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    leading: const Icon(Icons.location_city_rounded, color: Colors.amberAccent),
                    title: Text(loc.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(loc.country, style: const TextStyle(color: Colors.white54)),
                    trailing: const Icon(Icons.chevron_left_rounded, color: Colors.white54),
                    onTap: () => widget.onCitySelected(loc),
                  );
                },
              ),
            ),
          ] else ...[
            const Text(
              'المدن المفضلة المقترحة:',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: widget.favorites.length,
                itemBuilder: (context, i) {
                  final loc = widget.favorites[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    leading: const Icon(Icons.star_rounded, color: Colors.amberAccent),
                    title: Text(loc.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(loc.country, style: const TextStyle(color: Colors.white54)),
                    trailing: const Icon(Icons.chevron_left_rounded, color: Colors.white54),
                    onTap: () => widget.onCitySelected(loc),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
