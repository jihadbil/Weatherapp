import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_model.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String _airQualityUrl = 'https://air-quality-api.open-meteo.com/v1/air-quality';
  static const String _geocodingUrl = 'https://geocoding-api.open-meteo.com/v1/search';

  /// Fetch full weather data with offline caching, AQI, and prayer times
  Future<FullWeatherData> fetchWeather(
    double latitude,
    double longitude, {
    String locationName = 'موقعي الحالي',
  }) async {
    final cacheKey = 'cache_weather_${latitude.toStringAsFixed(2)}_${longitude.toStringAsFixed(2)}';
    final cacheTimeKey = 'cache_time_${latitude.toStringAsFixed(2)}_${longitude.toStringAsFixed(2)}';

    final uri = Uri.parse(
      '$_baseUrl?latitude=$latitude&longitude=$longitude'
      '&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,surface_pressure,wind_speed_10m,wind_direction_10m'
      '&hourly=temperature_2m,weather_code,precipitation_probability'
      '&daily=weather_code,temperature_2m_max,temperature_2m_min,uv_index_max,sunrise,sunset'
      '&timezone=auto',
    );

    try {
      // Parallel fetch for weather and air quality
      final responses = await Future.wait([
        http.get(uri).timeout(const Duration(seconds: 8)),
        fetchAirQuality(latitude, longitude),
      ]);

      final weatherResponse = responses[0] as http.Response;
      final airQuality = responses[1] as AirQualityModel?;

      if (weatherResponse.statusCode == 200) {
        final json = jsonDecode(weatherResponse.body);

        // Cache the successful response
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, weatherResponse.body);
        await prefs.setString(cacheTimeKey, DateTime.now().toIso8601String());

        // Calculate prayer times
        final prayerTimes = calculatePrayerTimes(latitude, longitude, DateTime.now());

        return FullWeatherData.fromOpenMeteoJson(
          json,
          locationName,
          airQuality: airQuality,
          prayerTimes: prayerTimes,
          isOffline: false,
        );
      } else {
        throw Exception('فشل استجابة السيرفر (${weatherResponse.statusCode})');
      }
    } catch (e) {
      // Offline fallback: try reading from cache
      final cachedData = await _getCachedWeather(cacheKey, cacheTimeKey, locationName, latitude, longitude);
      if (cachedData != null) {
        return cachedData;
      }
      rethrow;
    }
  }

  Future<FullWeatherData?> _getCachedWeather(
    String cacheKey,
    String cacheTimeKey,
    String locationName,
    double latitude,
    double longitude,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJsonStr = prefs.getString(cacheKey);
      final cachedTimeStr = prefs.getString(cacheTimeKey);

      if (cachedJsonStr != null) {
        final json = jsonDecode(cachedJsonStr);
        final cachedAt = cachedTimeStr != null ? DateTime.tryParse(cachedTimeStr) : null;
        final prayerTimes = calculatePrayerTimes(latitude, longitude, DateTime.now());

        return FullWeatherData.fromOpenMeteoJson(
          json,
          locationName,
          prayerTimes: prayerTimes,
          isOffline: true,
          cachedAt: cachedAt,
        );
      }
    } catch (_) {}
    return null;
  }

  /// Fetch Air Quality Index, Dust, and Pollens from Open-Meteo Air Quality API
  Future<AirQualityModel?> fetchAirQuality(double latitude, double longitude) async {
    try {
      final uri = Uri.parse(
        '$_airQualityUrl?latitude=$latitude&longitude=$longitude'
        '&current=european_aqi,us_aqi,pm10,pm2_5,dust,grass_pollen,birch_pollen,alder_pollen,olive_pollen,ragweed_pollen'
        '&timezone=auto',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final current = json['current'];
        if (current != null) {
          final aqi = (current['european_aqi'] as num?)?.toInt() ?? 30;
          final pm25 = (current['pm2_5'] as num?)?.toDouble() ?? 12.0;
          final pm10 = (current['pm10'] as num?)?.toDouble() ?? 20.0;
          final dust = (current['dust'] as num?)?.toDouble() ?? 0.0;
          final grass = (current['grass_pollen'] as num?)?.toDouble() ?? 0.0;
          final birch = (current['birch_pollen'] as num?)?.toDouble() ?? 0.0;
          final alder = (current['alder_pollen'] as num?)?.toDouble() ?? 0.0;
          final olive = (current['olive_pollen'] as num?)?.toDouble() ?? 0.0;
          final ragweed = (current['ragweed_pollen'] as num?)?.toDouble() ?? 0.0;
          final treePollen = birch + alder;

          return AirQualityModel(
            aqi: aqi,
            pm2_5: pm25,
            pm10: pm10,
            dust: dust,
            grassPollen: grass,
            treePollen: treePollen,
            olivePollen: olive,
            ragweedPollen: ragweed,
          );
        }
      }
    } catch (_) {}
    return null;
  }

  /// Accurate astronomical calculation of Islamic prayer times
  static PrayerTimesModel calculatePrayerTimes(double lat, double lon, DateTime date) {
    final tzOffset = date.timeZoneOffset.inMinutes / 60.0;
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;

    // Fractional year in radians
    final gamma = 2 * math.pi / 365.0 * (dayOfYear - 1 + (12 - 12) / 24.0);

    // Equation of time in minutes
    final eqTime = 229.18 * (
      0.000075 +
      0.001868 * math.cos(gamma) -
      0.032077 * math.sin(gamma) -
      0.004089 * math.cos(2 * gamma) -
      0.001259 * math.sin(2 * gamma)
    );

    // Solar declination in radians
    final decl = 0.006918 -
      0.399912 * math.cos(gamma) +
      0.070257 * math.sin(gamma) -
      0.006758 * math.cos(2 * gamma) +
      0.000907 * math.sin(2 * gamma) -
      0.002697 * math.cos(3 * gamma) +
      0.00148 * math.sin(3 * gamma);

    // Solar noon (Dhuhr) in local hours
    final noonHours = 12.0 + tzOffset - (lon / 15.0) - (eqTime / 60.0);

    final latRad = lat * math.pi / 180.0;

    // Hour angle for a given zenith angle (in degrees)
    double? hourAngle(double angleDeg) {
      final angleRad = angleDeg * math.pi / 180.0;
      final cosHa = (math.sin(angleRad) - math.sin(latRad) * math.sin(decl)) /
          (math.cos(latRad) * math.cos(decl));
      if (cosHa < -1.0 || cosHa > 1.0) return null;
      return math.acos(cosHa) * 180.0 / math.pi;
    }

    // Sunrise / Sunset: angle = -0.833°
    final haSun = hourAngle(-0.833) ?? 90.0;
    final sunriseHours = noonHours - (haSun / 15.0);
    final sunsetHours = noonHours + (haSun / 15.0);

    // Fajr: angle = -18.0°
    final haFajr = hourAngle(-18.0) ?? 108.0;
    final fajrHours = noonHours - (haFajr / 15.0);

    // Isha: angle = -17.5°
    final haIsha = hourAngle(-17.5) ?? 107.0;
    final ishaHours = noonHours + (haIsha / 15.0);

    // Asr (Shafi'i shadow length = 1 + tan(|lat - decl|))
    final asrAngleRad = math.atan(1.0 / (1.0 + math.tan((latRad - decl).abs())));
    final asrAngleDeg = asrAngleRad * 180.0 / math.pi;
    final haAsr = hourAngle(asrAngleDeg) ?? 45.0;
    final asrHours = noonHours + (haAsr / 15.0);

    DateTime toDateTime(double hours) {
      final h = hours.floor();
      final m = ((hours - h) * 60).round();
      return DateTime(date.year, date.month, date.day, h % 24, m.clamp(0, 59));
    }

    return PrayerTimesModel(
      fajr: toDateTime(fajrHours),
      sunrise: toDateTime(sunriseHours),
      dhuhr: toDateTime(noonHours),
      asr: toDateTime(asrHours),
      maghrib: toDateTime(sunsetHours),
      isha: toDateTime(ishaHours),
    );
  }

  /// Search for cities by query text using Open-Meteo Geocoding API
  Future<List<LocationData>> searchCities(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse('$_geocodingUrl?name=${Uri.encodeComponent(query)}&count=5&language=ar&format=json');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['results'] != null) {
        final List results = json['results'];
        return results.map((item) => LocationData.fromJson(item)).toList();
      }
      return [];
    } else {
      return [];
    }
  }
}
