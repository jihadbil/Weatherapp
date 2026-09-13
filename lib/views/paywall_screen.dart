import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _selectedPlan = 1; // 0 = Monthly, 1 = Yearly (Default Recommended)
  bool _isLoading = false;

  Future<void> _handleSubscription() async {
    setState(() => _isLoading = true);

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 1));
    await PreferencesService.setProUser(true);

    if (!mounted) return;
    setState(() => _isLoading = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: Colors.amberAccent, size: 28),
            SizedBox(width: 8),
            Text('تهانينا! تم تفعيل Pro', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'أصبحت الآن مشتركاً في النسخة الممتازة WeatherApp Pro. استمتع بجميع الميزات وبدون إعلانات!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close Dialog
              Navigator.pop(context); // Close Paywall Screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amberAccent,
              foregroundColor: Colors.black,
            ),
            child: const Text('بدء الاستمتاع بـ Pro', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E1B4B),
              Color(0xFF311042),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Close Button
              Positioned(
                top: 12,
                right: 16,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),

              // Content Scrollable
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Crown & Title
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.amberAccent.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amberAccent.withOpacity(0.4), width: 2),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        size: 64,
                        color: Colors.amberAccent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'WeatherApp Pro',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'افتح الإمكانات الكاملة لتطبيق الطقس التجاري بدون حدود',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 32),

                    // Features List
                    _buildFeatureTile(Icons.block_rounded, 'إزالة جميع الإعلانات بالكامل (100% Ad-Free)'),
                    _buildFeatureTile(Icons.map_rounded, 'خرائط رادار حية وتفاعلية لحركة السحب والأمطار'),
                    _buildFeatureTile(Icons.date_range_rounded, 'توقعات ممتدة لـ 14 يوماً مع تفاصيل دقيقة'),
                    _buildFeatureTile(Icons.notifications_active_rounded, 'تنبيهات طقس طارئة غير محدودة للمدن المفضلة'),
                    _buildFeatureTile(Icons.favorite_rounded, 'إضافة مدن مفضلة غير محدودة'),

                    const SizedBox(height: 32),

                    // Subscription Plans Selection
                    _buildPlanCard(
                      index: 1,
                      title: 'الاشتراك السنوي (توفير 45%)',
                      price: '19.99 دولار / سنوياً',
                      subtitle: 'تجربة مجانية لمدة 3 أيام، ثم 1.66 دولار شهرياً',
                      isRecommended: true,
                    ),
                    const SizedBox(height: 12),
                    _buildPlanCard(
                      index: 0,
                      title: 'الاشتراك الشهري',
                      price: '2.99 دولار / شهرياً',
                      subtitle: 'إلغاء في أي وقت بدون التزام',
                      isRecommended: false,
                    ),

                    const SizedBox(height: 32),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubscription,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amberAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 8,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.black)
                            : Text(
                                _selectedPlan == 1 ? 'ابدأ التجربة المجانية (3 أيام)' : 'اشترك الآن',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'يمكنك الإلغاء في أي وقت من إعدادات المتجر بدون أي رسوم إضافية',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.amberAccent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.amberAccent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required int index,
    required String title,
    required String price,
    required String subtitle,
    required bool isRecommended,
  }) {
    final isSelected = _selectedPlan == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.amberAccent.withOpacity(0.2) : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.amberAccent : Colors.white24,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? Colors.amberAccent : Colors.white54,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          if (isRecommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('الموصى به', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                ),
                Text(
                  price,
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
