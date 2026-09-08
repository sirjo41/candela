import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// Persistent 5-Tab Responsive Navigation Bar with Center Floating QR Action Button
/// Strictly matches the architectural specifications:
/// 1. 🏠 Home / استكشف (Explore)
/// 2. 🏪 Stores / قريب منك (Near You)
/// 3. 🎟️ Center Floating QR Action Button
/// 4. 👛 Wallet / العروض
/// 5. 👤 Profile / القائمة
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onQrTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onQrTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final barColor = isDark ? AppColors.darkSlateSurface : AppColors.darkSlate;
    final activeColor = AppColors.darkAmberAccent;
    const inactiveColor = Colors.white60;

    return Directionality(
      textDirection: loc.textDirection,
      child: Container(
        decoration: BoxDecoration(
          color: barColor,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkSlateBorder : Colors.black12,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 1. Home / Explore (استكشف)
                _buildNavItem(
                  index: 0,
                  icon: Icons.explore_rounded,
                  label: loc.tr('nav_explore'),
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),

                // 2. Stores / Near You (قريب منك)
                _buildNavItem(
                  index: 1,
                  icon: Icons.storefront_rounded,
                  label: loc.tr('nav_stores'),
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),

                // 3. Center Floating Action QR Button (🎟️)
                GestureDetector(
                  onTap: onQrTap,
                  child: Container(
                    transform: Matrix4.translationValues(0, -12, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.45),
                          blurRadius: 14,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: AppColors.darkSlateSurface,
                      size: 28,
                    ),
                  ),
                ),

                // 4. Wallet (العروض)
                _buildNavItem(
                  index: 3,
                  icon: Icons.confirmation_number_rounded,
                  label: loc.tr('nav_wallet'),
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),

                // 5. Profile (القائمة)
                _buildNavItem(
                  index: 4,
                  icon: Icons.person_rounded,
                  label: loc.tr('nav_profile'),
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final isSelected = currentIndex == index;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
