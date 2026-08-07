import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/offer_model.dart';

/// Modular Offer Card component formatted with percentage badges, prices in D.L, countdown timers and location
class OfferCard extends StatelessWidget {
  final OfferModel offer;
  final VoidCallback onClaim;

  const OfferCard({
    super.key,
    required this.offer,
    required this.onClaim,
  });

  /// Formats remaining duration into DD:HH:MM:SS string
  String _formatTimer(Duration duration) {
    if (duration == Duration.zero) {
      return 'Expired';
    }
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours >= 24) {
      final days = duration.inDays;
      final remHours = hours.remainder(24);
      return '${days}d ${remHours}h remaining';
    }
    return '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final remaining = offer.remainingTime;
    final isExpired = remaining == Duration.zero;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: offer.isClaimed
              ? AppColors.successGreen.withValues(alpha: 0.5)
              : AppColors.borderGrey,
          width: offer.isClaimed ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header Bar: Badge + Countdown Timer Pill
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Percentage Off Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAmber,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryAmber.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    offer.discountBadge,
                    style: const TextStyle(
                      color: AppColors.darkSlate,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                // Countdown Timer Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isExpired
                        ? AppColors.errorRed.withValues(alpha: 0.1)
                        : AppColors.darkSlate.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: isExpired ? AppColors.errorRed : AppColors.darkSlate,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _formatTimer(remaining),
                        style: TextStyle(
                          color: isExpired ? AppColors.errorRed : AppColors.darkSlate,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Offer Details Body
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.storeName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkSlate,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                // Branch Location
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        offer.branchLocation,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (offer.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    offer.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 20, color: AppColors.borderGrey),

          // Footer: Price Comparison in D.L & Claim Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Clean Discount Badge Display (e.g. "وفر حتى 20%" or "وفر حتى 10 د.ل")
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: AppColors.copperOrange, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        offer.discountBadge,
                        style: const TextStyle(
                          color: AppColors.darkSlate,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Claim Action Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: offer.isClaimed
                        ? AppColors.successGreen
                        : (isExpired ? Colors.grey : AppColors.primaryAmber),
                    foregroundColor: offer.isClaimed ? Colors.white : AppColors.darkSlate,
                    elevation: offer.isClaimed ? 0 : 2,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: (offer.isClaimed || isExpired) ? null : onClaim,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        offer.isClaimed
                            ? Icons.check_circle_rounded
                            : Icons.add_to_photos_rounded,
                        size: 16,
                        color: offer.isClaimed ? Colors.white : AppColors.darkSlate,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        offer.isClaimed ? 'Claimed' : 'Claim Offer',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: offer.isClaimed ? Colors.white : AppColors.darkSlate,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
