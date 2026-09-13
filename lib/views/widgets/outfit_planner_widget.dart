import 'package:flutter/material.dart';
import '../../models/weather_model.dart';
import '../../services/unit_helper.dart';
import '../../theme/weather_colors.dart';

class OutfitPlannerWidget extends StatefulWidget {
  final CurrentWeatherModel current;
  final DailyForecastModel? todayForecast;
  final bool isCelsius;

  const OutfitPlannerWidget({
    super.key,
    required this.current,
    this.todayForecast,
    this.isCelsius = true,
  });

  @override
  State<OutfitPlannerWidget> createState() => _OutfitPlannerWidgetState();
}

class _OutfitPlannerWidgetState extends State<OutfitPlannerWidget> {
  bool _isNightMode = false;

  @override
  void initState() {
    super.initState();
    // Default to night mode if current time is night
    _isNightMode = !widget.current.isDay;
  }

  @override
  Widget build(BuildContext context) {
    // Effective temperature based on selected mode
    final double temp = _isNightMode
        ? (widget.todayForecast?.tempMin ?? (widget.current.temperature - 5.0))
        : (widget.todayForecast?.tempMax ?? widget.current.temperature);

    final double apparentTemp = _isNightMode
        ? (temp - 1.5)
        : widget.current.apparentTemperature;

    final double uvIndex = _isNightMode ? 0.0 : (widget.todayForecast?.uvIndexMax ?? 0.0);
    final bool isRainy = widget.current.precipitation > 0 ||
        [51, 53, 55, 61, 63, 65, 80, 81, 82, 95, 96, 99].contains(widget.current.weatherCode);
    final double windSpeed = widget.current.windSpeed;
    final int humidity = widget.current.humidity;

    // Determine outfit components
    final topWear = _getTopWear(apparentTemp, windSpeed);
    final bottomWear = _getBottomWear(apparentTemp);
    final footwear = _getFootwear(apparentTemp, isRainy);
    final accessory = _getAccessory(apparentTemp, uvIndex, isRainy, windSpeed, _isNightMode);
    final comfortText = _getComfortText(apparentTemp, humidity, windSpeed);
    final summaryTip = _getSummaryTip(temp, apparentTemp, _isNightMode, isRainy, uvIndex);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: WeatherColors.glassDecoration(borderRadius: 24, opacity: 0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Day/Night Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.checkroom_rounded, color: Colors.amberAccent, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'ماذا أرتدي اليوم؟',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Day / Night Toggle Pill
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTimeTab(
                      title: 'النهار',
                      icon: Icons.wb_sunny_rounded,
                      iconColor: Colors.amber,
                      isSelected: !_isNightMode,
                      onTap: () => setState(() => _isNightMode = false),
                    ),
                    _buildTimeTab(
                      title: 'المساء',
                      icon: Icons.nights_stay_rounded,
                      iconColor: const Color(0xFF818CF8),
                      isSelected: _isNightMode,
                      onTap: () => setState(() => _isNightMode = true),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Thermal Condition & Apparent Temp Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getComfortColor(apparentTemp).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getComfortIcon(apparentTemp),
                    color: _getComfortColor(apparentTemp),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comfortText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'الحرارة المتوقعة: ${UnitHelper.formatTemp(temp, isCelsius: widget.isCelsius)} (المحسوسة: ${UnitHelper.formatTemp(apparentTemp, isCelsius: widget.isCelsius)})',
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2x2 Grid of Recommended Wardrobe
          Row(
            children: [
              Expanded(
                child: _buildWardrobeCard(
                  icon: topWear.icon,
                  category: 'الجزء العلوي',
                  item: topWear.title,
                  subtitle: topWear.desc,
                  accentColor: const Color(0xFF38BDF8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildWardrobeCard(
                  icon: bottomWear.icon,
                  category: 'الجزء السفلي',
                  item: bottomWear.title,
                  subtitle: bottomWear.desc,
                  accentColor: const Color(0xFF34D399),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildWardrobeCard(
                  icon: footwear.icon,
                  category: 'الحذاء المناسب',
                  item: footwear.title,
                  subtitle: footwear.desc,
                  accentColor: const Color(0xFFFBBF24),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildWardrobeCard(
                  icon: accessory.icon,
                  category: 'إكسسوار ذكي',
                  item: accessory.title,
                  subtitle: accessory.desc,
                  accentColor: const Color(0xFFF472B6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Smart Narrative Advice Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amberAccent.withValues(alpha: 0.12),
                  const Color(0xFF38BDF8).withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.tips_and_updates_rounded, color: Colors.amberAccent, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    summaryTip,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTab({
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWardrobeCard({
    required IconData icon,
    required String category,
    required String item,
    required String subtitle,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- Outfit Determination Rules ---

  _OutfitItem _getTopWear(double apparentTemp, double windSpeed) {
    if (apparentTemp < 8) {
      return _OutfitItem(
        icon: Icons.ac_unit_rounded,
        title: 'معطف شتوي ثقيل',
        desc: 'صوف أو ريش مبطن عازل للبرد',
      );
    } else if (apparentTemp < 15) {
      return _OutfitItem(
        icon: Icons.dry_cleaning_rounded,
        title: 'سترة دافئة أو هودي',
        desc: windSpeed > 25 ? 'معطف واقٍ من الرياح' : 'سترة قطنية ثقيلة',
      );
    } else if (apparentTemp < 22) {
      return _OutfitItem(
        icon: Icons.checkroom_rounded,
        title: 'قميص طويل الأكمام',
        desc: 'كارديجان خفيف أو بلوزة قطنية',
      );
    } else if (apparentTemp < 30) {
      return _OutfitItem(
        icon: Icons.wb_sunny_outlined,
        title: 'تيشيرت قطني مريح',
        desc: 'ملابس صيفية ناعمة تسمح بالتهوية',
      );
    } else {
      return _OutfitItem(
        icon: Icons.wb_sunny_rounded,
        title: 'ملابس خفيفة وفضفاضة',
        desc: 'كتان أو قطن بألوان فاتحة عاكسة',
      );
    }
  }

  _OutfitItem _getBottomWear(double apparentTemp) {
    if (apparentTemp < 10) {
      return _OutfitItem(
        icon: Icons.airline_seat_legroom_extra_rounded,
        title: 'بنطال شتوي سميك',
        desc: 'جينز ثقيل أو قماش مبطن حراري',
      );
    } else if (apparentTemp < 24) {
      return _OutfitItem(
        icon: Icons.straighten_rounded,
        title: 'بنطال جينز أو تشينو',
        desc: 'مريح ومناسب للحركة والعمل',
      );
    } else {
      return _OutfitItem(
        icon: Icons.beach_access_rounded,
        title: 'بنطال كتان أو شورت قطني',
        desc: 'خفيف ومرن ومقاوم للحرارة',
      );
    }
  }

  _OutfitItem _getFootwear(double apparentTemp, bool isRainy) {
    if (isRainy) {
      return _OutfitItem(
        icon: Icons.water_drop_rounded,
        title: 'حذاء مقاوم للماء',
        desc: 'نعل مانع للانزلاق ومقاوم للبلل',
      );
    } else if (apparentTemp < 10) {
      return _OutfitItem(
        icon: Icons.hiking_rounded,
        title: 'بوت شتوي مغلق',
        desc: 'جوارب صوفية دافئة',
      );
    } else if (apparentTemp > 30) {
      return _OutfitItem(
        icon: Icons.directions_walk_rounded,
        title: 'صندل مريح أو حذاء قماشي',
        desc: 'حذاء خفيف يسمح بتهوية القدمين',
      );
    } else {
      return _OutfitItem(
        icon: Icons.sports_kabaddi_rounded,
        title: 'حذاء سنيكرز رياضي',
        desc: 'مريح للمشي والأنشطة اليومية',
      );
    }
  }

  _OutfitItem _getAccessory(double apparentTemp, double uvIndex, bool isRainy, double windSpeed, bool isNight) {
    if (isRainy) {
      return _OutfitItem(
        icon: Icons.umbrella_rounded,
        title: 'مظلة مطر قوية',
        desc: 'فرص هطول أمطار نشطة',
      );
    } else if (!isNight && uvIndex >= 6) {
      return _OutfitItem(
        icon: Icons.wb_sunny_rounded,
        title: 'نظارة شمسية + واقي شمس',
        desc: 'أشعة شمس نشطة UV: ${uvIndex.round()}',
      );
    } else if (apparentTemp < 8) {
      return _OutfitItem(
        icon: Icons.severe_cold_rounded,
        title: 'وشاح وقفازات صوفية',
        desc: 'لحماية الأطراف من الصقيع',
      );
    } else if (windSpeed >= 30) {
      return _OutfitItem(
        icon: Icons.air_rounded,
        title: 'واقي رياح ونظارة حماية',
        desc: 'رياح نشطة (${windSpeed.round()} كم/س)',
      );
    } else {
      return _OutfitItem(
        icon: isNight ? Icons.nightlight_round : Icons.watch_rounded,
        title: isNight ? 'سترة احتياطية للمساء' : 'ساعة وقبعة كاجوال',
        desc: 'أجواء مستقرة ومريحة',
      );
    }
  }

  String _getComfortText(double apparentTemp, int humidity, double windSpeed) {
    if (apparentTemp <= 5) return 'صقيع وبرد قارس • تدفئة قصوى';
    if (apparentTemp <= 14) return 'أجواء شتوية باردة • تتطلب ملابس دافئة';
    if (apparentTemp <= 22) return 'أجواء لطيفة ومعتدلة • راحة حرارية تامة';
    if (apparentTemp <= 28) return 'أجواء دافئة مريحة • مناسبة للأنشطة الخفيفة';
    if (apparentTemp <= 35) return 'طقس حار صيفي • يُفضّل الأماكن المظللة';
    return 'موجة حرارة شديدة • احرص على السوائل والتهوية';
  }

  Color _getComfortColor(double apparentTemp) {
    if (apparentTemp <= 8) return const Color(0xFF38BDF8); // Ice blue
    if (apparentTemp <= 17) return const Color(0xFF60A5FA); // Blue
    if (apparentTemp <= 24) return const Color(0xFF34D399); // Green
    if (apparentTemp <= 30) return const Color(0xFFFBBF24); // Amber
    if (apparentTemp <= 36) return const Color(0xFFF97316); // Orange
    return const Color(0xFFEF4444); // Red
  }

  IconData _getComfortIcon(double apparentTemp) {
    if (apparentTemp <= 10) return Icons.ac_unit_rounded;
    if (apparentTemp <= 22) return Icons.eco_rounded;
    if (apparentTemp <= 30) return Icons.wb_sunny_rounded;
    return Icons.whatshot_rounded;
  }

  String _getSummaryTip(double temp, double apparentTemp, bool isNight, bool isRainy, double uvIndex) {
    if (isRainy) {
      return 'توقعات بهطول أمطار اليوم. احرص على حمل المظلة وارتداء حذاء مقاوم للبلل لتفادي برودة الأطراف.';
    }
    if (isNight) {
      return 'تنخفض درجات الحرارة ليلاً لتبلغ قرابة ${UnitHelper.formatTemp(temp, isCelsius: widget.isCelsius)}. إذا كنت تخطط للسهر أو الخروج، اصطحب سترة إضافية للوقاية من نسمات البرودة.';
    }
    if (uvIndex >= 7) {
      return 'أشعة الشمس قوية نهاراً (UV: ${uvIndex.round()}). ارتدِ ملابس فاتحة فضفاضة واستخدم النظارة الشمسية وواقي البشرة عند التعرض المباشر للشمس.';
    }
    if (apparentTemp < 15) {
      return 'الأجواء تميل للبرودة مع حرارة محسوسة تقارب ${UnitHelper.formatTemp(apparentTemp, isCelsius: widget.isCelsius)}. الملابس المتعددة الطبقات (Layers) تمنحك أفضل دفء ومرونة طوال اليوم.';
    }
    return 'الطقس مستقر ومريح للغاية اليوم. اختر ملابسك القطنية المفضلة واستمتع بيومك بالخارج!';
  }
}

class _OutfitItem {
  final IconData icon;
  final String title;
  final String desc;

  _OutfitItem({
    required this.icon,
    required this.title,
    required this.desc,
  });
}
