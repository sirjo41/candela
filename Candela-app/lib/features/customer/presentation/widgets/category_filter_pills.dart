import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/customer_feed_provider.dart';

/// Top horizontal category filter pills widget (All, Restaurants, Cafes, Shopping, Hot Deals).
class CategoryFilterPills extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const CategoryFilterPills({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'المطاعم':
      case 'Restaurants':
        return Icons.restaurant_rounded;
      case 'الملابس':
      case 'Shopping':
        return Icons.checkroom_rounded;
      case 'الإلكترونيات':
        return Icons.devices_rounded;
      case 'الجمال':
        return Icons.face_retouching_natural_rounded;
      case 'الرياضة':
        return Icons.fitness_center_rounded;
      case 'أطفال':
        return Icons.child_care_rounded;
      case 'سفر':
        return Icons.flight_takeoff_rounded;
      case 'سيارات':
        return Icons.directions_car_rounded;
      case 'الكل':
      case 'All':
      default:
        return Icons.grid_view_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: CustomerFeedProvider.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = CustomerFeedProvider.categories[index];
          final isSelected = category == selectedCategory;
          final icon = _getCategoryIcon(category);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onCategorySelected(category),
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryAmber : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryAmberDark : AppColors.borderGrey,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primaryAmber.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected ? AppColors.darkSlate : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? AppColors.darkSlate : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
