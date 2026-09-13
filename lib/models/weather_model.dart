import 'dart:math' as math;
import 'package:flutter/material.dart';

class LocationData {
  final String name;
  final double latitude;
  final double longitude;
  final String country;

  LocationData({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.country,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      name: json['name'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      country: json['country'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'country': country,
  };
}

class CurrentWeatherModel {
  final double temperature;
  final double apparentTemperature;
  final int humidity;
  final double windSpeed;
  final int windDirection;
  final double pressure;
  final int weatherCode;
  final bool isDay;
  final double precipitation;

  CurrentWeatherModel({
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.pressure,
    required this.weatherCode,
    required this.isDay,
    required this.precipitation,
  });

  factory CurrentWeatherModel.fromJson(Map<String, dynamic> json) {
    return CurrentWeatherModel(
      temperature: (json['temperature_2m'] as num).toDouble(),
      apparentTemperature: (json['apparent_temperature'] as num).toDouble(),
      humidity: (json['relative_humidity_2m'] as num).toInt(),
      windSpeed: (json['wind_speed_10m'] as num).toDouble(),
      windDirection: (json['wind_direction_10m'] as num?)?.toInt() ?? 0,
      pressure: (json['surface_pressure'] as num).toDouble(),
      weatherCode: (json['weather_code'] as num).toInt(),
      isDay: (json['is_day'] as num) == 1,
      precipitation: (json['precipitation'] as num).toDouble(),
    );
  }

  String get windDirectionText {
    final d = (windDirection % 360 + 360) % 360;
    if (d >= 338 || d < 23) return 'شمالية (N)';
    if (d >= 23 && d < 68) return 'شمالية شرقية (NE)';
    if (d >= 68 && d < 113) return 'شرقية (E)';
    if (d >= 113 && d < 158) return 'جنوبية شرقية (SE)';
    if (d >= 158 && d < 203) return 'جنوبية (S)';
    if (d >= 203 && d < 248) return 'جنوبية غربية (SW)';
    if (d >= 248 && d < 293) return 'غربية (W)';
    return 'شمالية غربية (NW)';
  }
}

class HourlyForecastModel {
  final DateTime time;
  final double temperature;
  final int weatherCode;
  final int precipitationProbability;

  HourlyForecastModel({
    required this.time,
    required this.temperature,
    required this.weatherCode,
    required this.precipitationProbability,
  });
}

class DailyForecastModel {
  final DateTime date;
  final int weatherCode;
  final double tempMax;
  final double tempMin;
  final double uvIndexMax;
  final DateTime? sunrise;
  final DateTime? sunset;

  DailyForecastModel({
    required this.date,
    required this.weatherCode,
    required this.tempMax,
    required this.tempMin,
    required this.uvIndexMax,
    this.sunrise,
    this.sunset,
  });
}

class AirQualityModel {
  final int aqi;
  final double pm2_5;
  final double pm10;
  final double dust;
  final double grassPollen;
  final double treePollen;
  final double olivePollen;
  final double ragweedPollen;

  AirQualityModel({
    required this.aqi,
    required this.pm2_5,
    required this.pm10,
    this.dust = 0.0,
    this.grassPollen = 0.0,
    this.treePollen = 0.0,
    this.olivePollen = 0.0,
    this.ragweedPollen = 0.0,
  });

  double get totalPollen => grassPollen + treePollen + olivePollen + ragweedPollen;

  String get statusText {
    if (aqi <= 25) return 'ممتاز جداً';
    if (aqi <= 50) return 'جيد';
    if (aqi <= 75) return 'معتدل';
    if (aqi <= 100) return 'رديء للحساسية';
    if (aqi <= 125) return 'غير صحي';
    return 'خطر شديد';
  }

  Color get statusColor {
    if (aqi <= 25) return const Color(0xFF10B981); // Emerald
    if (aqi <= 50) return const Color(0xFF34D399); // Light green
    if (aqi <= 75) return const Color(0xFFFBBF24); // Amber
    if (aqi <= 100) return const Color(0xFFF97316); // Orange
    if (aqi <= 125) return const Color(0xFFEF4444); // Red
    return const Color(0xFF9333EA); // Purple
  }

  String get healthTip {
    if (aqi <= 50) return 'جودة الهواء ممتازة والأنشطة الخارجية آمنة تماماً لجميع أفراد الأسرة.';
    if (aqi <= 75) return 'جودة هواء مقبولة، قد يشعر أصحاب الحساسية الصدرية بأعراض خفيفة.';
    if (aqi <= 100) return 'يُنصح بتقليل المجهود البدني بالخارج للمصابين بأمراض الجهاز التنفسي والربو.';
    return 'يُفضّل البقاء في الأماكن المغلقة وارتداء كمامة واقية عند الخروج.';
  }

  // Allergy & Pollen & Dust calculations
  String get allergyRiskLevel {
    if (dust >= 50 || totalPollen >= 60 || aqi >= 110 || pm10 >= 80) {
      return 'خطر شديد ⚠️';
    } else if (dust >= 30 || totalPollen >= 35 || aqi >= 75 || pm2_5 >= 30) {
      return 'مرتفع';
    } else if (dust >= 12 || totalPollen >= 12 || aqi >= 50 || pm2_5 >= 18) {
      return 'معتدل';
    } else {
      return 'منخفض وآمن';
    }
  }

  Color get allergyRiskColor {
    if (dust >= 50 || totalPollen >= 60 || aqi >= 110 || pm10 >= 80) {
      return const Color(0xFFEF4444); // Red
    } else if (dust >= 30 || totalPollen >= 35 || aqi >= 75 || pm2_5 >= 30) {
      return const Color(0xFFF97316); // Orange
    } else if (dust >= 12 || totalPollen >= 12 || aqi >= 50 || pm2_5 >= 18) {
      return const Color(0xFFFBBF24); // Amber
    } else {
      return const Color(0xFF10B981); // Emerald
    }
  }

  double get allergyRiskScore {
    double score = 0.0;
    score += (dust / 60.0).clamp(0.0, 0.4);
    score += (totalPollen / 80.0).clamp(0.0, 0.35);
    score += (aqi / 150.0).clamp(0.0, 0.25);
    return score.clamp(0.08, 1.0);
  }

  bool get shouldWearMask => dust >= 25 || totalPollen >= 30 || aqi >= 85;
  bool get canVentilateHome => dust < 25 && aqi < 70 && totalPollen < 25;
  bool get safeForOutdoorExercise => dust < 35 && aqi < 65 && totalPollen < 30;

  List<String> get allergyTips {
    final tips = <String>[];
    if (dust >= 25) {
      tips.add('هناك نسبة غبار عالق بالأجواء؛ احرص على إغلاق النوافذ وتشغيل منقي الهواء.');
    }
    if (totalPollen >= 25) {
      tips.add('نشاط لحبوب اللقاح؛ يُفضل الاستحمام وتغيير الملابس بعد العودة من الحدائق.');
    }
    if (shouldWearMask) {
      tips.add('يُنصح بارتداء كمامة طبية واقية لمرضى الجيوب الأنفية والربو عند الخروج.');
    } else {
      tips.add('أجواء مريحة ومناسبة للتنفس والأنشطة الخارجية دون قلق من الحساسية.');
    }
    if (canVentilateHome) {
      tips.add('وقت ممتاز ومثالي لتهوية المنزل وتجديد الهواء الصباحي.');
    } else {
      tips.add('يُفضّل تجنب فتح النوافذ في هذا التوقيت لتفادي دخول الأتربة وحبوب اللقاح.');
    }
    return tips;
  }
}

class PrayerTimesModel {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  PrayerTimesModel({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  Map<String, DateTime> get allPrayers => {
    'الفجر': fajr,
    'الشروق': sunrise,
    'الظهر': dhuhr,
    'العصر': asr,
    'المغرب': maghrib,
    'العشاء': isha,
  };

  Map<String, dynamic> getNextPrayer(DateTime now) {
    final prayers = allPrayers;
    for (final entry in prayers.entries) {
      if (entry.value.isAfter(now)) {
        final diff = entry.value.difference(now);
        final hours = diff.inHours;
        final minutes = diff.inMinutes % 60;
        final countdown = hours > 0 ? '$hours س و $minutes د' : '$minutes دقيقة';
        return {
          'name': entry.key,
          'time': entry.value,
          'countdown': countdown,
        };
      }
    }
    // After Isha, next is tomorrow's Fajr
    final tomorrowFajr = fajr.add(const Duration(days: 1));
    final diff = tomorrowFajr.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return {
      'name': 'الفجر',
      'time': tomorrowFajr,
      'countdown': '$hours س و $minutes د',
    };
  }
}

class FullWeatherData {
  final String locationName;
  final CurrentWeatherModel current;
  final List<HourlyForecastModel> hourly;
  final List<DailyForecastModel> daily;
  final AirQualityModel? airQuality;
  final PrayerTimesModel? prayerTimes;
  final bool isOffline;
  final DateTime? cachedAt;
  final int utcOffsetSeconds;

  FullWeatherData({
    required this.locationName,
    required this.current,
    required this.hourly,
    required this.daily,
    this.airQuality,
    this.prayerTimes,
    this.isOffline = false,
    this.cachedAt,
    this.utcOffsetSeconds = 0,
  });

  DateTime get localTime => DateTime.now().toUtc().add(Duration(seconds: utcOffsetSeconds));

  factory FullWeatherData.fromOpenMeteoJson(
    Map<String, dynamic> json,
    String locationName, {
    AirQualityModel? airQuality,
    PrayerTimesModel? prayerTimes,
    bool isOffline = false,
    DateTime? cachedAt,
  }) {
    final currentJson = json['current'];
    final currentWeather = CurrentWeatherModel.fromJson(currentJson);
    final utcOffset = (json['utc_offset_seconds'] as num?)?.toInt() ?? 0;

    // Parse Hourly
    final hourlyJson = json['hourly'];
    final List<String> times = List<String>.from(hourlyJson['time']);
    final List<dynamic> temps = hourlyJson['temperature_2m'];
    final List<dynamic> codes = hourlyJson['weather_code'];
    final List<dynamic> precipProbs = hourlyJson['precipitation_probability'] ?? [];

    List<HourlyForecastModel> hourlyList = [];
    final now = DateTime.now();
    for (int i = 0; i < times.length; i++) {
      final itemTime = DateTime.parse(times[i]);
      if (itemTime.isAfter(now.subtract(const Duration(hours: 1))) && hourlyList.length < 24) {
        hourlyList.add(HourlyForecastModel(
          time: itemTime,
          temperature: (temps[i] as num).toDouble(),
          weatherCode: (codes[i] as num).toInt(),
          precipitationProbability: (precipProbs.isNotEmpty && i < precipProbs.length)
              ? (precipProbs[i] as num).toInt()
              : 0,
        ));
      }
    }

    // Parse Daily
    final dailyJson = json['daily'];
    final List<String> dDates = List<String>.from(dailyJson['time']);
    final List<dynamic> dCodes = dailyJson['weather_code'];
    final List<dynamic> dMaxs = dailyJson['temperature_2m_max'];
    final List<dynamic> dMins = dailyJson['temperature_2m_min'];
    final List<dynamic> dUvs = dailyJson['uv_index_max'] ?? [];
    final List<dynamic> dSunrises = dailyJson['sunrise'] ?? [];
    final List<dynamic> dSunsets = dailyJson['sunset'] ?? [];

    List<DailyForecastModel> dailyList = [];
    for (int i = 0; i < dDates.length; i++) {
      dailyList.add(DailyForecastModel(
        date: DateTime.parse(dDates[i]),
        weatherCode: (dCodes[i] as num).toInt(),
        tempMax: (dMaxs[i] as num).toDouble(),
        tempMin: (dMins[i] as num).toDouble(),
        uvIndexMax: (dUvs.isNotEmpty && i < dUvs.length) ? (dUvs[i] as num).toDouble() : 0.0,
        sunrise: dSunrises.isNotEmpty && i < dSunrises.length ? DateTime.tryParse(dSunrises[i]) : null,
        sunset: dSunsets.isNotEmpty && i < dSunsets.length ? DateTime.tryParse(dSunsets[i]) : null,
      ));
    }

    return FullWeatherData(
      locationName: locationName,
      current: currentWeather,
      hourly: hourlyList,
      daily: dailyList,
      airQuality: airQuality,
      prayerTimes: prayerTimes,
      isOffline: isOffline,
      cachedAt: cachedAt,
      utcOffsetSeconds: utcOffset,
    );
  }
}

// Astronomical Qibla Direction Calculator
class QiblaHelper {
  static const double _meccaLat = 21.422487;
  static const double _meccaLon = 39.826206;

  static double calculateQibla(double lat, double lon) {
    final phiK = _meccaLat * math.pi / 180.0;
    final lambdaK = _meccaLon * math.pi / 180.0;
    final phi = lat * math.pi / 180.0;
    final lambda = lon * math.pi / 180.0;

    final psi = math.atan2(
      math.sin(lambdaK - lambda),
      math.cos(phi) * math.tan(phiK) - math.sin(phi) * math.cos(lambdaK - lambda),
    );
    return (psi * 180.0 / math.pi + 360.0) % 360.0;
  }

  static String getDirectionText(double degrees) {
    final d = (degrees % 360 + 360) % 360;
    if (d >= 338 || d < 23) return 'شمال (N)';
    if (d >= 23 && d < 68) return 'شمال شرق (NE)';
    if (d >= 68 && d < 113) return 'شرق (E)';
    if (d >= 113 && d < 158) return 'جنوب شرق (SE)';
    if (d >= 158 && d < 203) return 'جنوب (S)';
    if (d >= 203 && d < 248) return 'جنوب غرب (SW)';
    if (d >= 248 && d < 293) return 'غرب (W)';
    return 'شمال غرب (NW)';
  }
}

// Astronomical Moon Phase Calculator
class MoonPhaseHelper {
  static final DateTime _knownNewMoon = DateTime.utc(2024, 1, 11, 11, 57);
  static const double _synodicMonth = 29.53058867;

  /// Returns value from 0.0 to 1.0 (0.0 = New Moon, 0.5 = Full Moon, 1.0 = New Moon)
  static double getMoonPhase(DateTime date) {
    final diffDays = date.toUtc().difference(_knownNewMoon).inSeconds / 86400.0;
    final phase = (diffDays % _synodicMonth) / _synodicMonth;
    return phase < 0 ? phase + 1.0 : phase;
  }

  /// Illumination percentage (0% to 100%)
  static int getIllumination(DateTime date) {
    final phase = getMoonPhase(date);
    final ill = ((1 - math.cos(phase * 2 * math.pi)) / 2 * 100).round();
    return ill;
  }

  static int getDaysUntilFullMoon(DateTime date) {
    final phase = getMoonPhase(date);
    double diff = 0.5 - phase;
    if (diff < 0) diff += 1.0;
    return (diff * _synodicMonth).round();
  }

  static String getPhaseName(DateTime date) {
    final phase = getMoonPhase(date);
    if (phase < 0.03 || phase >= 0.97) return 'محاق (ولادة الهلال)';
    if (phase < 0.22) return 'هلال متزايد';
    if (phase < 0.28) return 'تربيع أول';
    if (phase < 0.47) return 'أحدب متزايد';
    if (phase < 0.53) return 'بدر مكتمل 🌕';
    if (phase < 0.72) return 'أحدب متناقص';
    if (phase < 0.78) return 'تربيع ثانٍ';
    return 'هلال متناقص';
  }

  static IconData getPhaseIcon(DateTime date) {
    final phase = getMoonPhase(date);
    if (phase < 0.05 || phase >= 0.95) return Icons.circle_outlined;
    if (phase < 0.45) return Icons.nightlight_round;
    if (phase < 0.55) return Icons.circle;
    return Icons.brightness_3_rounded;
  }
}

// Severe Weather Alert Evaluation Helper
class WeatherAlertHelper {
  static Map<String, dynamic>? checkSevereWeather(FullWeatherData data) {
    final current = data.current;
    final today = data.daily.isNotEmpty ? data.daily.first : null;

    if (current.weatherCode >= 95) {
      return {
        'title': 'تحذير عواصف رعدية نشطة ⚡',
        'desc': 'سحب ركامية نشطة مع فرصة لهطول أمطار رعدية وصواعق. تجنب الأماكن المفتوحة ومرتفعات المباني.',
        'color': const Color(0xFFEF4444),
        'icon': Icons.flash_on_rounded,
      };
    }

    if (current.weatherCode == 65 || current.weatherCode == 82) {
      return {
        'title': 'تنبيه هطول أمطار غزيرة جداً 🌧️',
        'desc': 'أمطار شديدة الغزارة قد تؤدي لضعف الرؤية وتجمع المياه في الطرقات. توخَّ الحذر أثناء القيادة.',
        'color': const Color(0xFF3B82F6),
        'icon': Icons.water_drop_rounded,
      };
    }

    if (current.windSpeed >= 40) {
      return {
        'title': 'تحذير رياح شديدة وعواصف ترابية 💨',
        'desc': 'سرعة الرياح بلغت ${current.windSpeed.round()} كم/س. يُرجى الحذر من الأجسام المتطايرة وتدني الرؤية الأفقية.',
        'color': const Color(0xFFF97316),
        'icon': Icons.air_rounded,
      };
    }

    if (today != null && today.tempMax >= 40) {
      return {
        'title': 'موجة حرارة قاسية ☀️',
        'desc': 'درجات الحرارة تتجاوز ${today.tempMax.round()}° مئوية. احرص على شرب السوائل بكثرة وتجنب التعرض المباشر للشمس وقت الظهيرة.',
        'color': const Color(0xFFDC2626),
        'icon': Icons.warning_amber_rounded,
      };
    }

    if (today != null && today.tempMin <= 3) {
      return {
        'title': 'تنبيه صقيع وبرودة شديدة ❄️',
        'desc': 'درجة الحرارة الصغرى تقترب من التجمد (${today.tempMin.round()}°). ارتدِ ملابس شتوية دافئة وتجنب التيارات الباردة.',
        'color': const Color(0xFF06B6D4),
        'icon': Icons.ac_unit_rounded,
      };
    }

    if (today != null && today.uvIndexMax >= 9) {
      return {
        'title': 'مؤشر أشعة فوق بنفسجية شديد الخطر (UV: ${today.uvIndexMax.round()})',
        'desc': 'أشعة الشمس حارقة ومضرة بالبشرة والعيون. ضع واقي الشمس وارتدِ نظارات شمسية وقبعة.',
        'color': const Color(0xFFF59E0B),
        'icon': Icons.wb_sunny_rounded,
      };
    }

    return null;
  }
}

// Helper for Weather Code Mapping to Arabic & Icons
class WeatherCodeHelper {
  static String getDescription(int code, bool isDay) {
    switch (code) {
      case 0:
        return isDay ? 'صافي ومشمِس' : 'صافي ليلاً';
      case 1:
      case 2:
        return 'غائم جزئياً';
      case 3:
        return 'غائم كلياً';
      case 45:
      case 48:
        return 'ضباب كثيف';
      case 51:
      case 53:
      case 55:
        return 'رذاذ خفيف';
      case 61:
      case 63:
        return 'أقدار أمطار متوسطة';
      case 65:
        return 'أمطار غزيرة';
      case 71:
      case 73:
      case 75:
        return 'تساقط ثلوج';
      case 80:
      case 81:
      case 82:
        return 'زخات مطر غزيرة';
      case 95:
      case 96:
      case 99:
        return 'عاصفة رعدية';
      default:
        return 'معتدل';
    }
  }

  static IconData getIcon(int code, bool isDay) {
    switch (code) {
      case 0:
        return isDay ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded;
      case 1:
      case 2:
        return isDay ? Icons.wb_cloudy_rounded : Icons.cloud_queue_rounded;
      case 3:
        return Icons.cloud_rounded;
      case 45:
      case 48:
        return Icons.blur_on_rounded;
      case 51:
      case 53:
      case 55:
      case 61:
      case 63:
      case 65:
      case 80:
      case 81:
      case 82:
        return Icons.grain_rounded;
      case 71:
      case 73:
      case 75:
        return Icons.ac_unit_rounded;
      case 95:
      case 96:
      case 99:
        return Icons.thunderstorm_rounded;
      default:
        return Icons.wb_sunny_rounded;
    }
  }
}
