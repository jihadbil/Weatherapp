import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../views/city_comparison_screen.dart';
import '../views/radar_map_screen.dart';
import 'preferences_service.dart';
import 'weather_service.dart';

class AIAppAction {
  final String type;
  final Map<String, dynamic> params;

  const AIAppAction({
    required this.type,
    required this.params,
  });

  @override
  String toString() => 'AIAppAction(type: $type, params: $params)';
}

class AIAdvisorResult {
  final String text;
  final List<AIAppAction> actions;

  const AIAdvisorResult({
    required this.text,
    this.actions = const [],
  });
}

class AIActionStatus {
  final String type;
  final String description;
  final bool success;
  final IconData icon;
  final bool modifiesSettings;

  const AIActionStatus({
    required this.type,
    required this.description,
    required this.success,
    required this.icon,
    this.modifiesSettings = false,
  });
}

class AIWeatherService {
  static const String _model = 'gemini-3.6-flash';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  /// Asks Gemini with injected weather context, falling back to rule-based engine if network fails
  static Future<AIAdvisorResult> askAdvisor({
    required String question,
    required FullWeatherData weather,
    required LocationData location,
  }) async {
    final apiKey = await PreferencesService.getGeminiApiKey();

    if (apiKey.isNotEmpty) {
      try {
        final prompt = _buildContextPrompt(question, weather, location);
        final rawResponse = await _callGemini(prompt, apiKey);
        if (rawResponse != null && rawResponse.trim().isNotEmpty) {
          return parseResponse(rawResponse);
        }
      } catch (_) {
        // Network or API failure -> seamlessly fallback to rule-based advisor
      }
    }

    // Smart Offline Rule-Based Fallback
    return ruleBasedAdvisor(
      question: question,
      weather: weather,
      location: location,
    );
  }

  /// Parses model response: extracts action tags and returns clean conversational text
  static AIAdvisorResult parseResponse(String rawResponse) {
    final actionRegex = RegExp(r'<<<ACTION:(.*?)>>>', dotAll: true);
    final matches = actionRegex.allMatches(rawResponse);
    final actions = <AIAppAction>[];

    for (final match in matches) {
      final rawJson = match.group(1)?.trim();
      if (rawJson != null && rawJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
          final type = decoded['type'] as String? ?? '';
          if (type.isNotEmpty) {
            actions.add(AIAppAction(type: type, params: decoded));
          }
        } catch (_) {
          // Ignore invalid action JSON gracefully
        }
      }
    }

    final cleanText = rawResponse.replaceAll(actionRegex, '').trim();

    return AIAdvisorResult(
      text: cleanText,
      actions: actions,
    );
  }

  /// Executes app action directly and returns status for chat feedback
  static Future<AIActionStatus> executeAction(
    BuildContext context,
    AIAppAction action, {
    LocationData? currentLocation,
  }) async {
    try {
      switch (action.type) {
        case 'add_city':
          final cityName = (action.params['name'] as String? ?? '').trim();
          if (cityName.isEmpty) {
            return const AIActionStatus(
              type: 'add_city',
              description: 'اسم المدينة غير محدد',
              success: false,
              icon: Icons.error_outline_rounded,
            );
          }
          final results = await WeatherService().searchCities(cityName);
          if (results.isNotEmpty) {
            final target = results.first;
            await PreferencesService.addFavoriteCity(target);
            return AIActionStatus(
              type: 'add_city',
              description: 'تمت إضافة "${target.name}" إلى قائمة المدن المفضلة',
              success: true,
              icon: Icons.bookmark_added_rounded,
              modifiesSettings: true,
            );
          } else {
            return AIActionStatus(
              type: 'add_city',
              description: 'تعذر العثور على مدينة "$cityName" في قاعدة البيانات',
              success: false,
              icon: Icons.search_off_rounded,
            );
          }

        case 'remove_city':
          final cityName = (action.params['name'] as String? ?? '').trim();
          if (cityName.isEmpty) {
            return const AIActionStatus(
              type: 'remove_city',
              description: 'اسم المدينة غير محدد للحذف',
              success: false,
              icon: Icons.error_outline_rounded,
            );
          }
          await PreferencesService.removeFavoriteCity(cityName);
          return AIActionStatus(
            type: 'remove_city',
            description: 'تمت إزالة "$cityName" من قائمة المفضلة',
            success: true,
            icon: Icons.delete_sweep_rounded,
            modifiesSettings: true,
          );

        case 'set_temp_unit':
          final isCelsius = action.params['isCelsius'] as bool? ?? true;
          await PreferencesService.setCelsius(isCelsius);
          return AIActionStatus(
            type: 'set_temp_unit',
            description: isCelsius
                ? 'تم ضبط وحدة الحرارة إلى الدرجة المئوية (°C)'
                : 'تم ضبط وحدة الحرارة إلى الفهرنهايت (°F)',
            success: true,
            icon: Icons.thermostat_rounded,
            modifiesSettings: true,
          );

        case 'set_wind_unit':
          final useKmh = action.params['useKmh'] as bool? ?? true;
          await PreferencesService.setUseKmh(useKmh);
          return AIActionStatus(
            type: 'set_wind_unit',
            description: useKmh
                ? 'تم ضبط وحدة الرياح إلى كم/ساعة (km/h)'
                : 'تم ضبط وحدة الرياح إلى ميل/ساعة (mph)',
            success: true,
            icon: Icons.air_rounded,
            modifiesSettings: true,
          );

        case 'set_pressure_unit':
          final unit = (action.params['unit'] as String? ?? 'hPa').trim();
          await PreferencesService.setPressureUnit(unit);
          return AIActionStatus(
            type: 'set_pressure_unit',
            description: 'تم ضبط وحدة الضغط الجوي إلى $unit',
            success: true,
            icon: Icons.speed_rounded,
            modifiesSettings: true,
          );

        case 'set_prayer_times':
          final show = action.params['show'] as bool? ?? true;
          await PreferencesService.setShowPrayerTimes(show);
          return AIActionStatus(
            type: 'set_prayer_times',
            description: show ? 'تم إظهار مواقيت الصلاة في التطبيق' : 'تم إخفاء مواقيت الصلاة من الواجهة',
            success: true,
            icon: Icons.access_time_filled_rounded,
            modifiesSettings: true,
          );

        case 'set_qibla':
          final show = action.params['show'] as bool? ?? true;
          await PreferencesService.setShowQibla(show);
          return AIActionStatus(
            type: 'set_qibla',
            description: show ? 'تم إظهار بوصلة القبلة' : 'تم إخفاء بوصلة القبلة',
            success: true,
            icon: Icons.explore_rounded,
            modifiesSettings: true,
          );

        case 'set_current_location':
          final show = action.params['show'] as bool? ?? true;
          await PreferencesService.setShowCurrentLocation(show);
          return AIActionStatus(
            type: 'set_current_location',
            description: show ? 'تم إظهار بطاقة الموقع الحالي' : 'تم إخفاء بطاقة الموقع الحالي',
            success: true,
            icon: Icons.my_location_rounded,
            modifiesSettings: true,
          );

        case 'open_radar':
          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RadarMapScreen(
                  latitude: currentLocation?.latitude ?? 24.7136,
                  longitude: currentLocation?.longitude ?? 46.6753,
                  locationName: currentLocation?.name ?? 'الرياض',
                ),
              ),
            );
          }
          return const AIActionStatus(
            type: 'open_radar',
            description: 'تم فتح خريطة رادار الطقس المباشر',
            success: true,
            icon: Icons.radar_rounded,
          );

        case 'compare_cities':
          final city1Name = (action.params['city1'] as String? ?? '').trim();
          final city2Name = (action.params['city2'] as String? ?? '').trim();
          LocationData? loc1;
          LocationData? loc2;

          if (city1Name.isNotEmpty) {
            final list1 = await WeatherService().searchCities(city1Name);
            if (list1.isNotEmpty) loc1 = list1.first;
          }
          if (city2Name.isNotEmpty) {
            final list2 = await WeatherService().searchCities(city2Name);
            if (list2.isNotEmpty) loc2 = list2.first;
          }

          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CityComparisonScreen(
                  initialCity1: loc1 ?? currentLocation,
                  initialCity2: loc2,
                ),
              ),
            );
          }
          return AIActionStatus(
            type: 'compare_cities',
            description: 'تم فتح شاشة المقارنة بين المدن',
            success: true,
            icon: Icons.compare_arrows_rounded,
          );

        default:
          return AIActionStatus(
            type: action.type,
            description: 'إجراء غير معروف: ${action.type}',
            success: false,
            icon: Icons.help_outline_rounded,
          );
      }
    } catch (e) {
      return AIActionStatus(
        type: action.type,
        description: 'حدث خطأ أثناء تنفيذ الإجراء: $e',
        success: false,
        icon: Icons.error_outline_rounded,
      );
    }
  }

  static String _buildContextPrompt(
    String userQuestion,
    FullWeatherData weather,
    LocationData location,
  ) {
    final cur = weather.current;
    final today = weather.daily.isNotEmpty ? weather.daily.first : null;
    final aqi = weather.airQuality;
    final conditionDesc = WeatherCodeHelper.getDescription(cur.weatherCode, cur.isDay);

    return '''
أنت "مساعد الطقس والوكيل الذكي" (AI Weather Agent) في تطبيق WeatherApp.
مهمتك المزدوجة:
1. تقديم استشارة احترافية، ممتعة، ومفصلة ودقيقة لإجابة استفسار المستخدم بالاعتماد على بيانات الطقس الحية أدناه.
2. تنفيذ أوامر المستخدم والتحكم في إعدادات وخصائص التطبيق بشكل مستقل ومباشر!

[بيانات الطقس الحية في ${location.name} - ${location.country}]:
• درجة الحرارة الحالية: ${cur.temperature.round()}° مئوية (المحسوسة: ${cur.apparentTemperature.round()}°)
• الحالة الجوية: $conditionDesc
• سرعة الرياح: ${cur.windSpeed.round()} كم/س
• الرطوبة النسبية: ${cur.humidity}%
• فرص وهطول الأمطار: ${cur.precipitation} ملم
• مؤشر الأشعة فوق البنفسجية UV: ${today?.uvIndexMax.round() ?? 0}
• جودة الهواء: ${aqi?.aqi ?? 35} (${aqi?.statusText ?? 'جيد'})
• مستوى الغبار العالق: ${aqi?.dust.toStringAsFixed(1) ?? '0.0'} µg/m³
• خطر الحساسية: ${aqi?.allergyRiskLevel ?? 'منخفض'}
• درجات الحرارة لليوم: العظمى ${today?.tempMax.round() ?? cur.temperature.round()}° / الصغرى ${today?.tempMin.round() ?? (cur.temperature - 6).round()}°

[صلاحيات وأوامر التحكم في التطبيق (App Actions)]:
أنت لست مجرد مستشار نصي، بل تملك صلاحيات تنفيذية برمجية! إذا طلب المستخدم إجراءً معيناً في التطبيق، قم بتأكيد تنفيذه في ردك، ثم أدرج وسم الأوامر التالي بدقة في نهاية الرد:

1. لإضافة مدينة إلى قائمة المفضلة:
<<<ACTION:{"type":"add_city","name":"اسم المدينة"}>>>
(مثال عند طلب: "أضف دبي للمفضلة" أو "احفظ طوكيو")

2. لحذف مدينة من قائمة المفضلة:
<<<ACTION:{"type":"remove_city","name":"اسم المدينة"}>>>
(مثال عند طلب: "احذف لندن" أو "امسح باريس")

3. لتغيير وحدة درجات الحرارة:
<<<ACTION:{"type":"set_temp_unit","isCelsius":false}>>> (للفهرنهايت °F)
<<<ACTION:{"type":"set_temp_unit","isCelsius":true}>>> (للمئوية °C)

4. لتغيير وحدة سرعة الرياح:
<<<ACTION:{"type":"set_wind_unit","useKmh":true}>>> (لـ كم/ساعة)
<<<ACTION:{"type":"set_wind_unit","useKmh":false}>>> (لـ ميل/ساعة)

5. لتغيير وحدة الضغط الجوي:
<<<ACTION:{"type":"set_pressure_unit","unit":"hPa"}>>> (أو "mmHg")

6. لإظهار أو إخفاء مواقيت الصلاة:
<<<ACTION:{"type":"set_prayer_times","show":true}>>> (أو false للإخفاء)

7. لإظهار أو إخفاء بوصلة القبلة:
<<<ACTION:{"type":"set_qibla","show":true}>>> (أو false للإخفاء)

8. لإظهار أو إخفاء بطاقة الموقع الحالي:
<<<ACTION:{"type":"set_current_location","show":true}>>> (أو false للإخفاء)

9. لفتح خريطة الرادار المباشر:
<<<ACTION:{"type":"open_radar"}>>>

10. لمقارنة الطقس بين مدينتين:
<<<ACTION:{"type":"compare_cities","city1":"اسم المدينة 1","city2":"اسم المدينة 2"}>>>

[هيكل الرد المطلوب في الاستشارات العادية]:
عند الإجابة عن استفسارات الطقس العامة والأنشطة (مثل غسيل السيارة، الشواء، الرياضة):
1️⃣ **الإجابة الأولية المباشرة (الخلاصة)**: حكم صريح (نعم مناسب جداً / غير مناسب / يُفضّل التأجيل).
2️⃣ **تفاصيل العوامل الجوية والتحليل**: نقاط مرتبة توضح الحرارة، الرياح، الأمطار، التوقيت الأنسب، ونصيحة ذكية.

(إذا كان السؤال مجرد أمر تحكم مثل إضافة مدينة أو تبديل وحدة، أجب بأسلوب لبق وموجز يوضح تنفيذ الأمر وضع وسم الأكشن فقط في النهاية).

[سؤال أو طلب المستخدم]:
"$userQuestion"
''';
  }

  static Future<String?> _callGemini(String prompt, String apiKey) async {
    final uri = Uri.parse('$_baseUrl?key=$apiKey');
    final client = HttpClient();

    try {
      final request = await client.postUrl(uri).timeout(const Duration(seconds: 15));
      request.headers.set('Content-Type', 'application/json; charset=utf-8');

      final payload = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 3000,
        }
      });

      request.write(payload);
      final response = await request.close().timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final respBody = await response.transform(utf8.decoder).join();
        final json = jsonDecode(respBody);
        final candidates = json['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] as String?;
            return text;
          }
        }
      }
    } finally {
      client.close();
    }
    return null;
  }

  /// Offline Rule-Based Expert System with Action Detection
  static AIAdvisorResult ruleBasedAdvisor({
    required String question,
    required FullWeatherData weather,
    required LocationData location,
  }) {
    final q = question.toLowerCase().trim();
    final cur = weather.current;
    final today = weather.daily.isNotEmpty ? weather.daily.first : null;
    final aqi = weather.airQuality;
    final conditionDesc = WeatherCodeHelper.getDescription(cur.weatherCode, cur.isDay);
    final isRainy = cur.precipitation > 0 ||
        [51, 53, 55, 61, 63, 65, 80, 81, 82, 95, 96, 99].contains(cur.weatherCode);
    final isDusty = (aqi?.dust ?? 0) >= 30 || cur.windSpeed >= 32;
    final temp = cur.temperature;
    final maxTemp = today?.tempMax.round() ?? temp.round();
    final minTemp = today?.tempMin.round() ?? (temp - 6).round();

    // A. Action Detections:
    // 1. Add city
    if (q.contains('أضف') || q.contains('اضف') || q.contains('ضيف') || q.contains('حفظ مدينة')) {
      final parts = question.split(RegExp(r'\s+'));
      String targetCity = '';
      final cityIdx = parts.indexWhere((p) => p == 'مدينة');
      if (cityIdx != -1 && cityIdx + 1 < parts.length) {
        targetCity = parts.sublist(cityIdx + 1).join(' ').replaceAll(RegExp(r'[\?!.,]'), '').replaceAll('للمفضلة', '').trim();
      } else {
        final addIdx = parts.indexWhere((p) => p.startsWith('أضف') || p.startsWith('اضف') || p.startsWith('ضيف'));
        if (addIdx != -1 && addIdx + 1 < parts.length) {
          targetCity = parts.sublist(addIdx + 1).join(' ').replaceAll(RegExp(r'[\?!.,]'), '').replaceAll('للمفضلة', '').trim();
        }
      }
      if (targetCity.isNotEmpty) {
        return AIAdvisorResult(
          text: 'بالتأكيد! قمت بإضافة مدينة $targetCity إلى قائمة مدنك المفضلة. 🌟',
          actions: [AIAppAction(type: 'add_city', params: {'type': 'add_city', 'name': targetCity})],
        );
      }
    }

    // 2. Remove city
    if (q.contains('احذف') || q.contains('إزالة') || q.contains('ازالة') || q.contains('امسح')) {
      final parts = question.split(RegExp(r'\s+'));
      String targetCity = '';
      final cityIdx = parts.indexWhere((p) => p == 'مدينة');
      if (cityIdx != -1 && cityIdx + 1 < parts.length) {
        targetCity = parts.sublist(cityIdx + 1).join(' ').replaceAll(RegExp(r'[\?!.,]'), '').replaceAll('من المفضلة', '').trim();
      } else {
        final remIdx = parts.indexWhere((p) => p.startsWith('احذف') || p.startsWith('امسح') || p.startsWith('ازل'));
        if (remIdx != -1 && remIdx + 1 < parts.length) {
          targetCity = parts.sublist(remIdx + 1).join(' ').replaceAll(RegExp(r'[\?!.,]'), '').replaceAll('من المفضلة', '').trim();
        }
      }
      if (targetCity.isNotEmpty) {
        return AIAdvisorResult(
          text: 'تمت إزالة مدينة $targetCity من قائمتك المفضلة بنجاح. 🗑️',
          actions: [AIAppAction(type: 'remove_city', params: {'type': 'remove_city', 'name': targetCity})],
        );
      }
    }

    // 3. Temperature Unit
    if (q.contains('فهرنهايت') || q.contains('fahrenheit')) {
      return const AIAdvisorResult(
        text: 'تم ضبط وحدة درجات الحرارة إلى الفهرنهايت (°F) بناءً على طلبك! 🌡️',
        actions: [AIAppAction(type: 'set_temp_unit', params: {'type': 'set_temp_unit', 'isCelsius': false})],
      );
    }
    if (q.contains('مئوي') || q.contains('سيلزيوس') || q.contains('celsius')) {
      return const AIAdvisorResult(
        text: 'تم ضبط وحدة درجات الحرارة إلى الدرجة المئوية (°C) بنجاح! 🌡️',
        actions: [AIAppAction(type: 'set_temp_unit', params: {'type': 'set_temp_unit', 'isCelsius': true})],
      );
    }

    // 4. Wind Speed Unit
    if (q.contains('ميل') || q.contains('mph')) {
      return const AIAdvisorResult(
        text: 'تم تحويل وحدة سرعة الرياح إلى ميل/ساعة (mph)! 💨',
        actions: [AIAppAction(type: 'set_wind_unit', params: {'type': 'set_wind_unit', 'useKmh': false})],
      );
    }
    if (q.contains('كم') || q.contains('كيلو') || q.contains('kmh')) {
      return const AIAdvisorResult(
        text: 'تم تحويل وحدة سرعة الرياح إلى كم/ساعة (km/h)! 💨',
        actions: [AIAppAction(type: 'set_wind_unit', params: {'type': 'set_wind_unit', 'useKmh': true})],
      );
    }

    // 5. Radar Map
    if (q.contains('رادار') || q.contains('خريطة')) {
      return AIAdvisorResult(
        text: 'جاري فتح خريطة الرادار المباشر في ${location.name}... 🗺️',
        actions: const [AIAppAction(type: 'open_radar', params: {'type': 'open_radar'})],
      );
    }

    // 6. City Comparison
    if (q.contains('مقارن') || q.contains('قارن')) {
      return const AIAdvisorResult(
        text: 'جاري فتح شاشة المقارنة لمقارنة الطقس بين المدن جنباً إلى جنب... ⚖️',
        actions: [AIAppAction(type: 'compare_cities', params: {'type': 'compare_cities'})],
      );
    }

    // 7. Prayer Times
    if (q.contains('صلاة') || q.contains('مواقيت')) {
      final show = !q.contains('اخف') && !q.contains('إخفاء') && !q.contains('تعطيل') && !q.contains('إلغاء');
      return AIAdvisorResult(
        text: show ? 'تم تفعيل وعرض مواقيت الصلاة في التطبيق! 🕌' : 'تم إخفاء مواقيت الصلاة من الواجهة بنجاح. 🕌',
        actions: [AIAppAction(type: 'set_prayer_times', params: {'type': 'set_prayer_times', 'show': show})],
      );
    }

    // B. Weather Activity Advice:
    // Car Wash
    if (q.contains('سيار') || q.contains('غسيل') || q.contains('مغسل')) {
      if (isRainy) {
        return const AIAdvisorResult(
          text: '''1️⃣ **الإجابة الأولية**:
❌ غير مناسب لغسيل السيارة اليوم! هناك فرص أمطار قد تعيد اتساخها سريعاً.

2️⃣ **تفاصيل العوامل الجوية**:
• 🌧️ **الأمطار**: فرص هطول أمطار نشطة مما يترك بقعاً طينية على الطلاء.
• ⏰ **التوقيت الأمثل**: انتظر حتى تستقر الأجواء لـ 24 ساعة متواصلة.
• 💡 **نصيحة ذكية**: اكتفِ بمسح الزجاج الأمامي لضمان وضوح الرؤية أثناء القيادة.''',
        );
      } else if (isDusty) {
        return AIAdvisorResult(
          text: '''1️⃣ **الإجابة الأولية**:
⚠️ يُفضّل تأجيل غسيل السيارة اليوم! الأجواء مغبرة والرياح نشطة.

2️⃣ **تفاصيل العوامل الجوية**:
• 💨 **الرياح والغبار**: سرعة الرياح بلغت ${cur.windSpeed.round()} كم/س مع عوالق ترابية (${aqi?.dust.toStringAsFixed(1) ?? '20'} µg/m³).
• 🌡️ **الحرارة**: تسجل ${temp.round()}° مئوية.
• 💡 **نصيحة ذكية**: تجنب مسح السيارة الجافة لتفادي خدش طبقة اللمعان بحبات الرمل.''',
        );
      } else {
        return AIAdvisorResult(
          text: '''1️⃣ **الإجابة الأولية**:
✅ نعم، الجو مثالي ومناسب جداً لغسيل السيارة اليوم! 🚗✨

2️⃣ **تفاصيل العوامل الجوية**:
• 💨 **الرياح والغبار**: الرياح هادئة (${cur.windSpeed.round()} كم/س) ونقاء الجو ممتاز (AQI: ${aqi?.aqi ?? 30}).
• 🌧️ **الأمطار**: فرصة الأمطار معدومة (0.0 ملم) في ${location.name}.
• ⏰ **التوقيت الأمثل**: يُفضل الغسيل بعد العصر لتجنب حرارة الشمس المباشرة.
• 💡 **نصيحة ذكية**: جفف السيارة فوراً لتفادي بقع قطرات الماء.''',
        );
      }
    }

    // Barbecue & Gatherings
    if (q.contains('شواء') || q.contains('باربيكيو') || q.contains('جلسة') || q.contains('سهرة') || q.contains('سمر')) {
      if (isRainy) {
        return AIAdvisorResult(
          text: '''1️⃣ **الإجابة الأولية**:
❌ غير مناسب للشواء في الهواء الطلق الليلة 🌧️، يُفضل استبدالها بجلسة مغلقة دافئة.

2️⃣ **تفاصيل العوامل الجوية**:
• 🌧️ **الأمطار**: رطوبة عالية (${cur.humidity}%) مع فرص تساقط قطرات تفسد إشعال الجمر.
• 🌡️ **الحرارة ليلاً**: تصل إلى $minTemp° مئوية.
• 💡 **نصيحة ذكية**: يمكنك استخدام شواية كهربائية داخلية أو التجمع في جلسة مغلقة.''',
        );
      } else if (cur.windSpeed >= 25) {
        return AIAdvisorResult(
          text: '''1️⃣ **الإجابة الأولية**:
⚠️ احذر عند الشواء الليلة! الرياح نشطة وقد تطاير الشرر والدخان.

2️⃣ **تفاصيل العوامل الجوية**:
• 💨 **الرياح**: سرعة الرياح تبلغ ${cur.windSpeed.round()} كم/س.
• 🌡️ **الحرارة ليلاً**: الأجواء تميل للبرودة لتسجل قرابة $minTemp°.
• 💡 **نصيحة ذكية**: اختر موقعاً محمياً بجدار عازل للرياح واحتفظ بملابس إضافية.''',
        );
      } else {
        return AIAdvisorResult(
          text: '''1️⃣ **الإجابة الأولية**:
✅ الأجواء رائعة ومثالية جداً للشواء والسمر الليلة! 🔥🥩

2️⃣ **تفاصيل العوامل الجوية**:
• 💨 **الرياح**: هواء هادئ ومنعش (${cur.windSpeed.round()} كم/س).
• 🌡️ **الحرارة**: معتدلة نهاراً ($maxTemp°) وتنخفض ليلاً إلى $minTemp° لأمسية لطيفة.
• 🌧️ **الأمطار**: سماء صافية واستقرار جوي تام في ${location.name}.
• 💡 **نصيحة ذكية**: اصطحب سترة خفيفة للأمسية واحتفظ بالماء لإخماد الجمر.''',
        );
      }
    }

    // Cycling & Sports
    if (q.contains('دراج') || q.contains('جري') || q.contains('رياض') || q.contains('مشي') || q.contains('هرولة')) {
      if (cur.apparentTemperature >= 35) {
        return AIAdvisorResult(
          text: '''1️⃣ **الإجابة الأولية**:
⚠️ يُفضل تجنب الرياضة الشاقة تحت الشمس المباشرة الآن ☀️.

2️⃣ **تفاصيل العوامل الجوية**:
• 🌡️ **الحرارة المحسوسة**: مرتفعة وتسجل ${cur.apparentTemperature.round()}° مئوية.
• ☀️ **مؤشر UV**: يصل إلى ${today?.uvIndexMax.round() ?? 7}.
• ⏰ **التوقيت الأمثل**: الصباح الباكر أو بعد غروب الشمس.
• 💡 **نصيحة ذكية**: اشرب كميات وافرة من الماء وارتدِ ملابس قطنية فاتحة.''',
        );
      } else {
        return AIAdvisorResult(
          text: '''1️⃣ **الإجابة الأولية**:
✅ نعم، الأجواء مشجعة ومثالية لممارسة الرياضة والمشي! 💪🚴

2️⃣ **تفاصيل العوامل الجوية**:
• 🌡️ **الحرارة**: درجة حرارة مريحة تبلغ ${temp.round()}° (المحسوسة ${cur.apparentTemperature.round()}°).
• 💨 **الرياح**: سرعة مناسبة (${cur.windSpeed.round()} كم/س) تنعش الجسم.
• 🌿 **نقاء الهواء**: جودة هواء جيدة (${aqi?.aqi ?? 35}).
• 💡 **نصيحة ذكية**: ارتدِ حذاءً رياضياً مريحاً وواقي شمس خفيف إن كنت تتمرن نهاراً.''',
        );
      }
    }

    // Laundry
    if (q.contains('غسيل') && q.contains('نشر') || q.contains('شرفة') || q.contains('بلكونة') || q.contains('ملابس')) {
      if (isRainy || isDusty) {
        return AIAdvisorResult(
          text: '''1️⃣ **الإجابة الأولية**:
❌ تجنب نشر الغسيل في الشرفة اليوم ⚠️.

2️⃣ **تفاصيل العوامل الجوية**:
• 💨 **الرياح والأتربة**: هناك عوالق وغبار ورياح (${cur.windSpeed.round()} كم/س) قد تلوث الأقمشة.
• 🌧️ **الرطوبة**: بنسبة ${cur.humidity}% مما يبطئ عملية الجفاف.
• 💡 **نصيحة ذكية**: انشر الملابس داخل المنزل في غرفة جيدة التهوية.''',
        );
      } else {
        return AIAdvisorResult(
          text: '''1️⃣ **الإجابة الأولية**:
✅ وقت ممتاز لنشر الغسيل في الشرفة! ☀️🧺

2️⃣ **تفاصيل العوامل الجوية**:
• ☀️ **أشعة الشمس**: صافية تساعد على تعقيم وتجفيف الأقمشة سريعاً.
• 💨 **الرياح**: هواء خفيف (${cur.windSpeed.round()} كم/س) يسرع تبخر الرطوبة.
• 💡 **نصيحة ذكية**: اقلب الملابس الملونة على الوجه الداخلي لحماية ألوانها.''',
        );
      }
    }

    // Default General
    return AIAdvisorResult(
      text: '''1️⃣ **الإجابة الأولية**:
🌤️ الأجواء العامة في ${location.name} مستقرة ومناسبة لمعظم الأنشطة اليومية!

2️⃣ **تفاصيل العوامل الجوية**:
• 🌡️ **الحرارة**: ${temp.round()}° مئوية (المحسوسة ${cur.apparentTemperature.round()}°).
• 💨 **الرياح**: ${cur.windSpeed.round()} كم/س مع رطوبة ${cur.humidity}%.
• 🌤️ **الحالة**: $conditionDesc، العظمى $maxTemp° والصغرى $minTemp°.
• 💡 **نصيحة ذكية**: استمتع بيومك وتابع التطبيق لمعرفة أي تقلبات مفاجئة.''',
    );
  }
}
