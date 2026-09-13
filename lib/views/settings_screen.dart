import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import 'paywall_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onSettingsChanged;

  const SettingsScreen({
    super.key,
    required this.onSettingsChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isCelsius = true;
  bool _useKmh = true;
  String _pressureUnit = 'hPa';
  bool _is24Hour = false;

  bool _showCurrentLocation = true;
  bool _showPrayerTimes = true;
  bool _showQibla = true;

  bool _isPro = false;
  String _geminiApiKey = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final celsius = await PreferencesService.isCelsius();
    final kmh = await PreferencesService.useKmh();
    final pressure = await PreferencesService.getPressureUnit();
    final is24 = await PreferencesService.is24Hour();

    final showLoc = await PreferencesService.showCurrentLocation();
    final showPrayers = await PreferencesService.showPrayerTimes();
    final showQiblaCompass = await PreferencesService.showQibla();

    final pro = await PreferencesService.isProUser();
    final apiKey = await PreferencesService.getGeminiApiKey();

    setState(() {
      _isCelsius = celsius;
      _useKmh = kmh;
      _pressureUnit = pressure;
      _is24Hour = is24;

      _showCurrentLocation = showLoc;
      _showPrayerTimes = showPrayers;
      _showQibla = showQiblaCompass;

      _isPro = pro;
      _geminiApiKey = apiKey;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('إعدادات التطبيق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Pro Subscription Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isPro
                    ? [const Color(0xFFB45309), const Color(0xFFF59E0B)]
                    : [const Color(0xFF1E293B), const Color(0xFF334155)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  _isPro ? Icons.workspace_premium_rounded : Icons.star_border_rounded,
                  color: _isPro ? Colors.amberAccent : Colors.white70,
                  size: 36,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isPro ? 'حساب ممتاز (WeatherApp Pro)' : 'النسخة المجانية',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isPro ? 'جميع الميزات مفعلة وبدون إعلانات' : 'ترقية لـ Pro لإزالة الإعلانات وفتح الخرائط',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (!_isPro)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PaywallScreen()),
                      ).then((_) => _loadSettings());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amberAccent,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('ترقية', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 1: Units System
          _buildSectionHeader('نظام الوحدات والقياسات', Icons.straighten_rounded),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                // Temperature Unit Switch
                SwitchListTile(
                  secondary: const Icon(Icons.thermostat_rounded, color: Colors.amberAccent),
                  title: const Text('وحدة قياس الحرارة', style: TextStyle(color: Colors.white, fontSize: 15)),
                  subtitle: Text(_isCelsius ? 'سيليزيوس (°C)' : 'فهرنهايت (°F)', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  value: _isCelsius,
                  activeThumbColor: Colors.amberAccent,
                  onChanged: (val) async {
                    await PreferencesService.setCelsius(val);
                    setState(() => _isCelsius = val);
                    widget.onSettingsChanged();
                  },
                ),
                Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),

                // Wind Speed Unit Switch
                SwitchListTile(
                  secondary: const Icon(Icons.air_rounded, color: Colors.amberAccent),
                  title: const Text('وحدة سرعة الرياح', style: TextStyle(color: Colors.white, fontSize: 15)),
                  subtitle: Text(_useKmh ? 'كيلومتر/ساعة (كم/س)' : 'ميل/ساعة (mph)', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  value: _useKmh,
                  activeThumbColor: Colors.amberAccent,
                  onChanged: (val) async {
                    await PreferencesService.setUseKmh(val);
                    setState(() => _useKmh = val);
                    widget.onSettingsChanged();
                  },
                ),
                Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),

                // Pressure Unit Toggle
                ListTile(
                  leading: const Icon(Icons.compress_rounded, color: Colors.amberAccent),
                  title: const Text('وحدة الضغط الجوي', style: TextStyle(color: Colors.white, fontSize: 15)),
                  subtitle: Text(_pressureUnit == 'hPa' ? 'هكتوباسكال (hPa)' : 'ميليمتر زئبق (mmHg)', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'hPa', label: Text('hPa', style: TextStyle(fontSize: 11))),
                      ButtonSegment(value: 'mmHg', label: Text('mmHg', style: TextStyle(fontSize: 11))),
                    ],
                    selected: {_pressureUnit},
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.amberAccent;
                        }
                        return Colors.white10;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.black;
                        }
                        return Colors.white70;
                      }),
                    ),
                    onSelectionChanged: (selection) async {
                      final unit = selection.first;
                      await PreferencesService.setPressureUnit(unit);
                      setState(() => _pressureUnit = unit);
                      widget.onSettingsChanged();
                    },
                  ),
                ),
                Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),

                // 12h vs 24h Time Format
                SwitchListTile(
                  secondary: const Icon(Icons.access_time_rounded, color: Colors.amberAccent),
                  title: const Text('صيغة الوقت', style: TextStyle(color: Colors.white, fontSize: 15)),
                  subtitle: Text(_is24Hour ? 'نظام 24 ساعة (مثال: 18:30)' : 'نظام 12 ساعة (مثال: 06:30 م)', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  value: _is24Hour,
                  activeThumbColor: Colors.amberAccent,
                  onChanged: (val) async {
                    await PreferencesService.set24Hour(val);
                    setState(() => _is24Hour = val);
                    widget.onSettingsChanged();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: Display & Interface Customization
          _buildSectionHeader('تخصيص الواجهة والظهور', Icons.dashboard_customize_rounded),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                // Show / Hide Current Location
                SwitchListTile(
                  secondary: const Icon(Icons.near_me_rounded, color: Colors.amberAccent),
                  title: const Text('بطاقة موقعي الحالي', style: TextStyle(color: Colors.white, fontSize: 15)),
                  subtitle: const Text('إظهار أو إخفاء بطاقة الموقع الجغرافي من الصفحة الرئيسية', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  value: _showCurrentLocation,
                  activeThumbColor: Colors.amberAccent,
                  onChanged: (val) async {
                    await PreferencesService.setShowCurrentLocation(val);
                    setState(() => _showCurrentLocation = val);
                    widget.onSettingsChanged();
                  },
                ),
                Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),

                // Show / Hide Prayer Times
                SwitchListTile(
                  secondary: const Icon(Icons.mosque_rounded, color: Colors.amberAccent),
                  title: const Text('مواقيت الصلاة', style: TextStyle(color: Colors.white, fontSize: 15)),
                  subtitle: const Text('عرض أوقات الصلوات الخمس في تفاصيل طقس المدينة', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  value: _showPrayerTimes,
                  activeThumbColor: Colors.amberAccent,
                  onChanged: (val) async {
                    await PreferencesService.setShowPrayerTimes(val);
                    setState(() => _showPrayerTimes = val);
                    widget.onSettingsChanged();
                  },
                ),
                Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),

                // Show / Hide Qibla Compass
                SwitchListTile(
                  secondary: const Icon(Icons.explore_rounded, color: Colors.amberAccent),
                  title: const Text('بوصلة اتجاه القبلة', style: TextStyle(color: Colors.white, fontSize: 15)),
                  subtitle: Text(
                    !_showPrayerTimes
                        ? 'ملاحظة: يتطلب تفعيل مواقيت الصلاة لتظهر البطاقة'
                        : 'عرض اتجاه الكعبة المشرفة في بطاقة الصلاة',
                    style: TextStyle(
                      color: !_showPrayerTimes ? Colors.amberAccent.withValues(alpha: 0.7) : Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  value: _showQibla,
                  activeThumbColor: Colors.amberAccent,
                  onChanged: (val) async {
                    await PreferencesService.setShowQibla(val);
                    setState(() => _showQibla = val);
                    widget.onSettingsChanged();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 3: AI Weather Advisor (Gemini)
          _buildSectionHeader('مساعد الطقس الذكي (AI Advisor)', Icons.auto_awesome_rounded),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.key_rounded, color: Colors.amberAccent),
                  title: const Text('مفتاح Google Gemini API', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text(
                    _geminiApiKey.isEmpty
                        ? 'المفتاح التلقائي نشط'
                        : 'نشط (••••••••${_geminiApiKey.length > 6 ? _geminiApiKey.substring(_geminiApiKey.length - 6) : ""})',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.edit_outlined, color: Colors.white54, size: 18),
                  onTap: _showEditApiKeyDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 4: About & Support
          _buildSectionHeader('عن التطبيق والدعم', Icons.info_outline_rounded),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.share_rounded, color: Colors.white70),
                  title: const Text('مشاركة التطبيق', style: TextStyle(color: Colors.white, fontSize: 14)),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('شكراً لمشاركة تطبيق WeatherApp مع أصدقائك!')),
                    );
                  },
                ),
                Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_rounded, color: Colors.white70),
                  title: const Text('سياسة الخصوصية واستخدام الموقع', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('بيانات موقعك تُستخدم فقط لجلب حالة الطقس المحلي ولا يتم تخزينها على سيرفر خارجي.', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.amberAccent, size: 16),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.amberAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditApiKeyDialog() {
    final controller = TextEditingController(text: _geminiApiKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: Colors.amberAccent, size: 20),
            SizedBox(width: 8),
            Text('تعديل مفتاح Gemini API', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أدخل مفتاح Google AI Studio API الخاص بك لتشغيل المساعد الذكي:',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'AQ.Ab8... أو AIzaSy...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: const Color(0xFF0F172A)),
            onPressed: () async {
              final newKey = controller.text.trim();
              final nav = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);
              await PreferencesService.setGeminiApiKey(newKey);
              if (mounted) {
                setState(() => _geminiApiKey = newKey);
              }
              nav.pop();
              messenger.showSnackBar(
                const SnackBar(content: Text('تم حفظ مفتاح Gemini بنجاح ✨')),
              );
            },
            child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
