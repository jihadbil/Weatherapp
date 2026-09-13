import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather_model.dart';
import '../services/preferences_service.dart';
import '../services/unit_helper.dart';
import '../services/weather_service.dart';
import '../theme/weather_colors.dart';
import 'paywall_screen.dart';
import 'widgets/ad_banner_widget.dart';
import 'widgets/air_quality_wind_widget.dart';
import 'widgets/daily_forecast_widget.dart';
import 'widgets/hero_weather_card.dart';
import 'widgets/hourly_chart_widget.dart';
import 'widgets/hourly_forecast_widget.dart';
import 'widgets/lifestyle_recommendations_widget.dart';
import 'widgets/prayer_times_widget.dart';
import 'widgets/sun_moon_widget.dart';
import 'widgets/weather_alert_banner.dart';
import 'widgets/weather_details_grid.dart';
import 'widgets/weather_particles_widget.dart';
import 'widgets/outfit_planner_widget.dart';
import 'widgets/allergy_pollen_widget.dart';
import 'widgets/ai_advisor_sheet.dart';
import 'city_comparison_screen.dart';

class CityDetailsScreen extends StatefulWidget {
  final LocationData location;
  final FullWeatherData? initialWeatherData;
  final bool isCurrentLocation;

  const CityDetailsScreen({
    super.key,
    required this.location,
    this.initialWeatherData,
    this.isCurrentLocation = false,
  });

  @override
  State<CityDetailsScreen> createState() => _CityDetailsScreenState();
}

class _CityDetailsScreenState extends State<CityDetailsScreen> {
  final WeatherService _weatherService = WeatherService();
  FullWeatherData? _weatherData;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isProUser = false;
  bool _isFavorite = false;
  bool _showPrayerTimes = true;
  bool _showQibla = true;
  bool _isCelsius = true;
  bool _useKmh = true;
  String _pressureUnit = 'hPa';
  bool _is24Hour = false;

  @override
  void initState() {
    super.initState();
    _weatherData = widget.initialWeatherData;
    _checkStatus();
    if (_weatherData == null) {
      _fetchWeatherData();
    }
  }

  Future<void> _checkStatus() async {
    final isPro = await PreferencesService.isProUser();
    final favorites = await PreferencesService.getFavoriteCities();
    final isFav = favorites.any((c) => c.name == widget.location.name);
    final showPrayers = await PreferencesService.showPrayerTimes();
    final showQibla = await PreferencesService.showQibla();
    final celsius = await PreferencesService.isCelsius();
    final kmh = await PreferencesService.useKmh();
    final pressure = await PreferencesService.getPressureUnit();
    final is24 = await PreferencesService.is24Hour();

    if (mounted) {
      setState(() {
        _isProUser = isPro;
        _isFavorite = isFav;
        _showPrayerTimes = showPrayers;
        _showQibla = showQibla;
        _isCelsius = celsius;
        _useKmh = kmh;
        _pressureUnit = pressure;
        _is24Hour = is24;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (widget.isCurrentLocation) return;

    if (_isFavorite) {
      await PreferencesService.removeFavoriteCity(widget.location.name);
      if (mounted) {
        setState(() => _isFavorite = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تمت إزالة ${widget.location.name} من المدن المحفوظة'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF1E293B),
          ),
        );
      }
    } else {
      await PreferencesService.addFavoriteCity(widget.location);
      if (mounted) {
        setState(() => _isFavorite = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تمت إضافة ${widget.location.name} إلى المدن المحفوظة'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF1E293B),
          ),
        );
      }
    }
  }

  Future<void> _fetchWeatherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isPro = await PreferencesService.isProUser();
      final data = await _weatherService.fetchWeather(
        widget.location.latitude,
        widget.location.longitude,
        locationName: widget.location.name,
      );

      if (mounted) {
        setState(() {
          _weatherData = data;
          _isProUser = isPro;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'تعذر تحديث بيانات الطقس. يرجى التحقق من الاتصال بالإنترنت.';
          _isLoading = false;
        });
      }
    }
  }

  void _showShareModal() {
    if (_weatherData == null) return;
    final current = _weatherData!.current;
    final today = _weatherData!.daily.isNotEmpty ? _weatherData!.daily.first : null;
    final desc = WeatherCodeHelper.getDescription(current.weatherCode, current.isDay);

    final shareText = '''
🌤️ تقرير طقس ${widget.location.name} اليوم:
🌡️ درجة الحرارة: ${UnitHelper.formatTemp(current.temperature, isCelsius: _isCelsius, includeLetter: true)} ($desc)
📈 العظمى: ${today != null ? UnitHelper.formatTemp(today.tempMax, isCelsius: _isCelsius) : '-'} | 📉 الصغرى: ${today != null ? UnitHelper.formatTemp(today.tempMin, isCelsius: _isCelsius) : '-'}
💧 الرطوبة: ${current.humidity}% | 💨 الرياح: ${UnitHelper.formatWind(current.windSpeed, useKmh: _useKmh)} (${current.windDirectionText})
☀️ مؤشر الأشعة UV: ${today?.uvIndexMax.round() ?? '-'}
🌿 جودة الهواء: ${_weatherData!.airQuality?.statusText ?? 'جيد'}
تمت المشاركة عبر تطبيق WeatherApp 🌦️
''';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.share_rounded, color: Colors.amberAccent, size: 22),
              const SizedBox(width: 8),
              Text(
                'مشاركة طقس ${widget.location.name}',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              shareText,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم نسخ تقرير الطقس وجاهز للمشاركة!'),
                    backgroundColor: Color(0xFF1E293B),
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('نسخ التقرير'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amberAccent,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _weatherData?.current;
    final gradientColors = current != null
        ? WeatherColors.getThemeGradient(current.weatherCode, current.isDay)
        : [const Color(0xFF1E293B), const Color(0xFF0F172A)];

    final todayForecast = _weatherData != null && _weatherData!.daily.isNotEmpty
        ? _weatherData!.daily.first
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          ),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          widget.location.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
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
            tooltip: 'مساعد الطقس الذكي (AI)',
            onPressed: () {
              if (_weatherData != null) {
                AIAdvisorSheet.show(
                  context,
                  weather: _weatherData!,
                  location: widget.location,
                  onAppNeedsRefresh: () => _checkStatus(),
                );
              }
            },
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.compare_arrows_rounded, color: Colors.amberAccent, size: 18),
            ),
            tooltip: 'مقارنة مع مدينة أخرى',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CityComparisonScreen(
                    initialCity1: widget.location,
                    initialWeather1: _weatherData,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
            ),
            tooltip: 'مشاركة الطقس',
            onPressed: _showShareModal,
          ),
          if (!widget.isCurrentLocation)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: _isFavorite ? Colors.amberAccent : Colors.white,
                  size: 20,
                ),
              ),
              tooltip: _isFavorite ? 'محفوظة' : 'حفظ المدينة',
              onPressed: _toggleFavorite,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: WeatherParticlesWidget(
        weatherCode: current?.weatherCode ?? 0,
        isDay: current?.isDay ?? true,
        windSpeed: current?.windSpeed ?? 10.0,
        windDirection: current?.windDirection ?? 45,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors,
            ),
          ),
          child: SafeArea(
            child: _isLoading && _weatherData == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.amberAccent),
                        SizedBox(height: 16),
                        Text(
                          'جاري جلب تفاصيل الطقس...',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  )
                : _errorMessage != null && _weatherData == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.amberAccent, size: 64),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _fetchWeatherData,
                                icon: const Icon(Icons.refresh),
                                label: const Text('إعادة المحاولة'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white24,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchWeatherData,
                        color: Colors.amberAccent,
                        backgroundColor: Colors.black54,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Column(
                            children: [
                              // Offline Status Banner
                              if (_weatherData != null && _weatherData!.isOffline) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.cloud_off_rounded, color: Colors.amberAccent, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        _weatherData!.cachedAt != null
                                            ? 'وضع دون اتصال • آخر تحديث ${DateFormat('hh:mm a').format(_weatherData!.cachedAt!)}'
                                            : 'عرض البيانات المحفوظة محلياً (دون اتصال)',
                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // Severe Weather Alert Banner
                              if (_weatherData != null)
                                WeatherAlertBanner(weatherData: _weatherData!),

                              // Commercial Ad Banner for Free Users
                              AdBannerWidget(
                                isProUser: _isProUser,
                                onUpgradeTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const PaywallScreen()),
                                  ).then((_) => _checkStatus());
                                },
                              ),

                              if (_weatherData != null) ...[
                                // Main Hero Weather Card
                                HeroWeatherCard(
                                  weatherData: _weatherData!,
                                  isCelsius: _isCelsius,
                                ),
                                const SizedBox(height: 20),

                                // Interactive Spline Hourly Temperature & Rain Chart
                                HourlyChartWidget(
                                  hourlyForecast: _weatherData!.hourly,
                                  isDay: _weatherData!.current.isDay,
                                  isCelsius: _isCelsius,
                                  is24Hour: _is24Hour,
                                ),
                                const SizedBox(height: 20),

                                // Hourly Forecast Horizontal Tiles
                                HourlyForecastWidget(
                                  hourlyForecast: _weatherData!.hourly,
                                  isDay: _weatherData!.current.isDay,
                                  isCelsius: _isCelsius,
                                  is24Hour: _is24Hour,
                                ),
                                const SizedBox(height: 20),

                                // Smart Wardrobe Guide ("ماذا أرتدي اليوم؟")
                                OutfitPlannerWidget(
                                  current: _weatherData!.current,
                                  todayForecast: todayForecast,
                                  isCelsius: _isCelsius,
                                ),
                                const SizedBox(height: 20),

                                // Sun Trajectory Arc & Moon Phase
                                SunMoonWidget(
                                  sunrise: todayForecast?.sunrise,
                                  sunset: todayForecast?.sunset,
                                ),
                                const SizedBox(height: 20),

                                // Air Quality Index (AQI) & Wind Compass
                                AirQualityWindWidget(
                                  airQuality: _weatherData!.airQuality,
                                  current: _weatherData!.current,
                                  useKmh: _useKmh,
                                ),
                                const SizedBox(height: 20),

                                // Allergy, Pollen & Dust Index
                                AllergyPollenWidget(
                                  airQuality: _weatherData!.airQuality,
                                ),
                                const SizedBox(height: 20),

                                // Prayer Times & Qibla Compass
                                if (_showPrayerTimes) ...[
                                  PrayerTimesWidget(
                                    prayerTimes: _weatherData!.prayerTimes,
                                    latitude: widget.location.latitude,
                                    longitude: widget.location.longitude,
                                    showQibla: _showQibla,
                                    is24Hour: _is24Hour,
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                // AI Weather Advisor Interactive Banner
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF38BDF8).withValues(alpha: 0.15),
                                        Colors.amberAccent.withValues(alpha: 0.12),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF38BDF8), Colors.amberAccent],
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF0F172A), size: 18),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'اسأل مساعد الطقس الذكي (AI) ✨',
                                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'استشر الذكاء الاصطناعي حول غسيل السيارة، الشواء، أو الرياضة',
                                              style: TextStyle(color: Colors.white60, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => AIAdvisorSheet.show(
                                          context,
                                          weather: _weatherData!,
                                          location: widget.location,
                                          onAppNeedsRefresh: () => _checkStatus(),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.amberAccent,
                                          foregroundColor: const Color(0xFF0F172A),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                        child: const Text('استشر الآن', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Lifestyle & Health Activity Recommendations
                                LifestyleRecommendationsWidget(
                                  current: _weatherData!.current,
                                  uvIndex: todayForecast?.uvIndexMax ?? 0.0,
                                ),
                                const SizedBox(height: 20),

                                // Bento Details Grid (Humidity, Pressure, UV, Wind)
                                WeatherDetailsGrid(
                                  current: _weatherData!.current,
                                  uvIndex: todayForecast?.uvIndexMax ?? 0.0,
                                  isCelsius: _isCelsius,
                                  useKmh: _useKmh,
                                  pressureUnit: _pressureUnit,
                                ),
                                const SizedBox(height: 20),

                                // Daily 7-Day Forecast List
                                DailyForecastWidget(
                                  dailyForecast: _weatherData!.daily,
                                  isCelsius: _isCelsius,
                                  is24Hour: _is24Hour,
                                ),
                                const SizedBox(height: 32),
                              ],
                            ],
                          ),
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}
