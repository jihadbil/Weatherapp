import 'package:flutter/material.dart';
import '../../models/weather_model.dart';
import '../../theme/weather_colors.dart';

class AllergyPollenWidget extends StatelessWidget {
  final AirQualityModel? airQuality;

  const AllergyPollenWidget({
    super.key,
    this.airQuality,
  });

  @override
  Widget build(BuildContext context) {
    // Provide safe defaults if air quality is null
    final aqi = airQuality ??
        AirQualityModel(
          aqi: 32,
          pm2_5: 12.0,
          pm10: 22.0,
          dust: 4.0,
          grassPollen: 1.0,
          treePollen: 2.0,
          olivePollen: 0.0,
          ragweedPollen: 0.5,
        );

    final riskLevel = aqi.allergyRiskLevel;
    final riskColor = aqi.allergyRiskColor;
    final riskScore = aqi.allergyRiskScore;
    final dustValue = aqi.dust;
    final treePollenValue = aqi.treePollen + aqi.olivePollen;
    final grassPollenValue = aqi.grassPollen + aqi.ragweedPollen;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: WeatherColors.glassDecoration(borderRadius: 24, opacity: 0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.health_and_safety_rounded, color: Color(0xFF34D399), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'مؤشر الحساسية والغبار وحبوب اللقاح',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: riskColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: riskColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      riskLevel,
                      style: TextStyle(
                        color: riskColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'موجّه لمرضى الجيوب الأنفية، الحساسية الصدرية، والربو',
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 16),

          // Overall Risk Gauge Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'مستوى التحسس التنفسي الإجمالي',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '${(riskScore * 100).round()}%',
                      style: TextStyle(
                        color: riskColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: riskScore,
                    minHeight: 8,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('آمن (0%)', style: TextStyle(color: Colors.white38, fontSize: 10)),
                    const Text('معتدل (40%)', style: TextStyle(color: Colors.white38, fontSize: 10)),
                    Text('خطر شديد (100%)', style: TextStyle(color: Colors.redAccent.withValues(alpha: 0.8), fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Breakdown Metrics (Dust, Tree Pollen, Grass Pollen)
          _buildPollenMetricBar(
            title: 'الأتربة والغبار العالق (Airborne Dust)',
            icon: Icons.grain_rounded,
            value: '${dustValue.toStringAsFixed(1)} µg/m³',
            progress: (dustValue / 50.0).clamp(0.05, 1.0),
            status: _getDustStatus(dustValue),
            color: _getDustColor(dustValue),
          ),
          const SizedBox(height: 10),
          _buildPollenMetricBar(
            title: 'حبوب لقاح الأشجار والزيتون (Tree Pollen)',
            icon: Icons.park_rounded,
            value: '${treePollenValue.toStringAsFixed(1)} حبة/م³',
            progress: (treePollenValue / 40.0).clamp(0.05, 1.0),
            status: _getPollenStatus(treePollenValue),
            color: _getPollenColor(treePollenValue),
          ),
          const SizedBox(height: 10),
          _buildPollenMetricBar(
            title: 'حبوب لقاح الحشائش والأعشاب (Grass Pollen)',
            icon: Icons.grass_rounded,
            value: '${grassPollenValue.toStringAsFixed(1)} حبة/م³',
            progress: (grassPollenValue / 30.0).clamp(0.05, 1.0),
            status: _getPollenStatus(grassPollenValue),
            color: _getPollenColor(grassPollenValue),
          ),
          const SizedBox(height: 16),

          // Medical Action Advice Badges (Mask, Windows, Outdoors)
          Row(
            children: [
              Expanded(
                child: _buildActionBadge(
                  icon: Icons.masks_rounded,
                  label: aqi.shouldWearMask ? 'ارتدِ كمامة 😷' : 'الكمامة غير ضرورية',
                  subtitle: aqi.shouldWearMask ? 'أتربة أو لقاح عالق' : 'الهواء نقي',
                  color: aqi.shouldWearMask ? const Color(0xFFF97316) : const Color(0xFF34D399),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionBadge(
                  icon: Icons.window_rounded,
                  label: aqi.canVentilateHome ? 'هوِّ المنزل 🪟' : 'أغلق النوافذ 🔒',
                  subtitle: aqi.canVentilateHome ? 'تجديد هواء آمن' : 'تجنب دخول العوالق',
                  color: aqi.canVentilateHome ? const Color(0xFF34D399) : const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionBadge(
                  icon: Icons.directions_run_rounded,
                  label: aqi.safeForOutdoorExercise ? 'رياضة خارجية 🏃' : 'رياضة داخلية 🧘',
                  subtitle: aqi.safeForOutdoorExercise ? 'تنفس آمن' : 'يُفضل الصالات',
                  color: aqi.safeForOutdoorExercise ? const Color(0xFF38BDF8) : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Smart Medical Health Tips List
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.medical_services_rounded, color: Color(0xFF34D399), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'نصائح الأطباء لمرضى الحساسية اليوم',
                      style: TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...aqi.allergyTips.map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          Expanded(
                            child: Text(
                              tip,
                              style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollenMetricBar({
    required String title,
    required IconData icon,
    required String value,
    required double progress,
    required String status,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                value,
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBadge({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getDustStatus(double dust) {
    if (dust < 10) return 'نقي ومثالي';
    if (dust < 25) return 'معتدل';
    if (dust < 45) return 'مرتفع';
    return 'غبار كثيف';
  }

  Color _getDustColor(double dust) {
    if (dust < 10) return const Color(0xFF10B981);
    if (dust < 25) return const Color(0xFFFBBF24);
    if (dust < 45) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  String _getPollenStatus(double pollen) {
    if (pollen < 10) return 'منخفض';
    if (pollen < 25) return 'معتدل';
    if (pollen < 40) return 'نشط';
    return 'شديد';
  }

  Color _getPollenColor(double pollen) {
    if (pollen < 10) return const Color(0xFF10B981);
    if (pollen < 25) return const Color(0xFFFBBF24);
    if (pollen < 40) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }
}
