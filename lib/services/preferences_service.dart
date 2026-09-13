import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_model.dart';

class PreferencesService {
  static const String _keyIsPro = 'is_pro_user';
  static const String _keyIsCelsius = 'is_celsius';
  static const String _keyUseKmh = 'use_kmh';
  static const String _keyFavoriteCities = 'favorite_cities';

  static const String _keyShowPrayerTimes = 'show_prayer_times';
  static const String _keyShowQibla = 'show_qibla';
  static const String _keyShowCurrentLocation = 'show_current_location';
  static const String _keyPressureUnit = 'pressure_unit';
  static const String _keyIs24Hour = 'is_24_hour';
  static const String _keyGeminiApiKey = 'gemini_api_key';
  static const String defaultGeminiApiKey = 'AQ.Ab8RN6LiJT6Ki4B_wqx4x5mLn__g4oH8S3q_WT7GmFmGsJcCNQ';

  // Gemini API Key
  static Future<String> getGeminiApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGeminiApiKey) ?? defaultGeminiApiKey;
  }

  static Future<void> setGeminiApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGeminiApiKey, key.trim());
  }

  // Pro Subscription Status
  static Future<bool> isProUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsPro) ?? false;
  }

  static Future<void> setProUser(bool isPro) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsPro, isPro);
  }

  // Temperature Unit (°C vs °F)
  static Future<bool> isCelsius() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsCelsius) ?? true;
  }

  static Future<void> setCelsius(bool isCelsius) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsCelsius, isCelsius);
  }

  // Wind Unit (km/h vs mph)
  static Future<bool> useKmh() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUseKmh) ?? true;
  }

  static Future<void> setUseKmh(bool useKmh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseKmh, useKmh);
  }

  // Pressure Unit (hPa vs mmHg)
  static Future<String> getPressureUnit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPressureUnit) ?? 'hPa';
  }

  static Future<void> setPressureUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPressureUnit, unit);
  }

  // Time Format (12h vs 24h)
  static Future<bool> is24Hour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIs24Hour) ?? false;
  }

  static Future<void> set24Hour(bool is24) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIs24Hour, is24);
  }

  // Show / Hide Current Location Card on Home
  static Future<bool> showCurrentLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowCurrentLocation) ?? true;
  }

  static Future<void> setShowCurrentLocation(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowCurrentLocation, show);
  }

  // Show / Hide Prayer Times
  static Future<bool> showPrayerTimes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowPrayerTimes) ?? true;
  }

  static Future<void> setShowPrayerTimes(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowPrayerTimes, show);
  }

  // Show / Hide Qibla Compass
  static Future<bool> showQibla() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowQibla) ?? true;
  }

  static Future<void> setShowQibla(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowQibla, show);
  }

  // Favorite Cities Management
  static Future<List<LocationData>> getFavoriteCities() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList = prefs.getStringList(_keyFavoriteCities);
    if (jsonList == null || jsonList.isEmpty) {
      // Default initial favorite cities
      return [
        LocationData(name: 'مكّة المكرّمة', latitude: 21.3891, longitude: 39.8579, country: 'السعودية'),
        LocationData(name: 'دبي', latitude: 25.2048, longitude: 55.2708, country: 'الإمارات'),
        LocationData(name: 'القاهرة', latitude: 30.0444, longitude: 31.2357, country: 'مصر'),
      ];
    }
    return jsonList.map((item) => LocationData.fromJson(jsonDecode(item))).toList();
  }

  static Future<void> addFavoriteCity(LocationData location) async {
    final cities = await getFavoriteCities();
    if (!cities.any((c) => c.name == location.name)) {
      cities.add(location);
      await saveCitiesList(cities);
    }
  }

  static Future<void> removeFavoriteCity(String cityName) async {
    final cities = await getFavoriteCities();
    cities.removeWhere((c) => c.name == cityName);
    await saveCitiesList(cities);
  }

  static Future<void> saveCitiesList(List<LocationData> cities) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonList = cities.map((c) => jsonEncode({
      'name': c.name,
      'latitude': c.latitude,
      'longitude': c.longitude,
      'country': c.country,
    })).toList();
    await prefs.setStringList(_keyFavoriteCities, jsonList);
  }
}
