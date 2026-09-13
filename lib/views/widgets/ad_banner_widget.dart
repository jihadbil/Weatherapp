import 'package:flutter/material.dart';
import '../paywall_screen.dart';

class AdBannerWidget extends StatelessWidget {
  final bool isProUser;
  final VoidCallback? onUpgradeTap;

  const AdBannerWidget({
    super.key,
    required this.isProUser,
    this.onUpgradeTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isProUser) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amberAccent.withOpacity(0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amberAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.star_rounded, color: Colors.amberAccent, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'إعلان تجاري',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.info_outline, color: Colors.white38, size: 12),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  'استمتع بالتطبيق بدون إعلانات وتطبيقات الرادار الاحترافية',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaywallScreen()),
              ).then((_) {
                if (onUpgradeTap != null) onUpgradeTap!();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amberAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('إزالة الإعلانات', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
