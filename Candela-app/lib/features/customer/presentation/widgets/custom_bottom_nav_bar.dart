import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Persistent 5-item Bottom Navigation Bar with Center Floating QR Action Button
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSlate,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
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
              // 1. Explore Tab (استكشف)
              _buildNavItem(
                index: 0,
                icon: Icons.explore_rounded,
                label: 'استكشف',
              ),

              // 2. Offers Tab (العروض)
              _buildNavItem(
                index: 1,
                icon: Icons.local_offer_rounded,
                label: 'العروض',
              ),

              // 3. Floating Action Center QR / Near You Button (قريب منك)
              GestureDetector(
                onTap: onQrTap,
                child: Container(
                  transform: Matrix4.translationValues(0, -12, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAmber,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryAmber.withValues(alpha: 0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppColors.darkBackground,
                    size: 28,
                  ),
                ),
              ),

              // 4. Wallet Tab (المحفظة)
              _buildNavItem(
                index: 3,
                icon: Icons.account_balance_wallet_rounded,
                label: 'المحفظة',
              ),

              // 5. Menu Tab (القائمة)
              _buildNavItem(
                index: 4,
                icon: Icons.menu_rounded,
                label: 'القائمة',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentIndex == index;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppColors.primaryAmber : Colors.white60,
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected ? AppColors.primaryAmber : Colors.white60,
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
