import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/merchant_provider.dart';
import 'widgets/quick_action_card.dart';

/// Merchant Dashboard Screen matching screenshot reference IMG-20260725-WA0001.jpg
/// Displays store status, summary cards, and mobile-responsive 6-tile quick actions grid in RTL mode.
class MerchantDashboardScreen extends StatelessWidget {
  final Function(int) onNavigateTab;
  final VoidCallback onLaunchOffer;

  const MerchantDashboardScreen({
    super.key,
    required this.onNavigateTab,
    required this.onLaunchOffer,
  });

  void _showPricingPlansModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.darkSlate,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'الأسعار وباقات اشتراكات التجار',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'اختر الباقة المناسبة لنشاطك التجاري لزيادة نسبة المبيعات وتخفيض رسوم الإنشاء.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  _buildPlanCard(
                    title: 'الباقة الأساسية (Standard)',
                    price: 'مجاناً',
                    features: ['رسوم إنشاء العرض: 50.00 د.ل', 'رسوم التحقق: 5.00 د.ل', 'دعم الفروع حتى 3 فروع'],
                    isCurrent: true,
                    onSelect: () => Navigator.pop(ctx),
                  ),
                  const SizedBox(height: 12),

                  _buildPlanCard(
                    title: 'الباقة الذهبية (Gold Partner)',
                    price: '250.00 د.ل / شهرياً',
                    features: ['خصم 50% على رسوم الإنشاء (25.00 د.ل)', 'أولوية الظهور في الصفحة الرئيسية للعملاء', 'فروع غير محدودة وشارات التاجر المعتمد'],
                    isCurrent: false,
                    onSelect: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم إرسال طلب الاشتراك في الباقة الذهبية إلى خدمة العملاء.')),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAmber,
                      foregroundColor: AppColors.darkSlate,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('إغلاق', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEventsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.darkSlate,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'الفعاليات والحملات الموسمية',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'انضم للحملات الترويجية الكبرى لزيادة وصول عروضك لآلاف العملاء.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  _buildEventItem(
                    title: 'مهرجان الصيف للتذوق والتسوق 2026',
                    dates: '1 أغسطس - 31 أغسطس',
                    badge: 'نشط حالياً',
                    onJoin: () {
                      Navigator.pop(ctx);
                      onLaunchOffer();
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildEventItem(
                    title: 'حملة العودة للمدارس والجامعات',
                    dates: '15 سبتمبر - 30 سبتمبر',
                    badge: 'قريباً',
                    onJoin: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم تسجيل اهتمامك بالحملة! سيتم إشعاراتك عند فتح باب الاشتراك.')),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAmber,
                      foregroundColor: AppColors.darkSlate,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('إغلاق', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required List<String> features,
    required bool isCurrent,
    required VoidCallback onSelect,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? AppColors.primaryAmber : Colors.white24,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              Text(price, style: const TextStyle(color: AppColors.primaryAmber, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 16),
                  const SizedBox(width: 8),
                  Text(f, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: isCurrent ? AppColors.successGreen : AppColors.primaryAmber,
                side: BorderSide(color: isCurrent ? AppColors.successGreen : AppColors.primaryAmber),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onSelect,
              child: Text(isCurrent ? 'باقتك الحالية' : 'الاشتراك في الباقة'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem({
    required String title,
    required String dates,
    required String badge,
    required VoidCallback onJoin,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryAmber.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.stars_rounded, color: AppColors.primaryAmber, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(dates, style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAmber,
              foregroundColor: AppColors.darkSlate,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: onJoin,
            child: const Text('المشاركة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: Consumer<MerchantProvider>(
          builder: (context, merchant, _) {
            return RefreshIndicator(
              onRefresh: () async {
                await merchant.fetchDashboardMetrics();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isMobile ? 14 : 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Merchant Profile Header ("متجري")
                        Container(
                          padding: EdgeInsets.all(isMobile ? 14 : 20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.darkSlate, AppColors.darkBackground],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.darkBackground.withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 26,
                                backgroundColor: AppColors.primaryAmber,
                                child: Icon(
                                  Icons.storefront_rounded,
                                  color: AppColors.darkBackground,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            merchant.storeName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        // Active Status Indicator Pill (النشط)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.successGreenLight,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircleAvatar(
                                                radius: 3,
                                                backgroundColor: AppColors.successGreen,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'النشط',
                                                style: TextStyle(
                                                  color: AppColors.successGreen,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'لوحة تحكم التاجر وإدارة الفروع',
                                      style: TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 2. Summary Metrics Cards Row (Mobile Responsive)
                        Row(
                          children: [
                            // Card 1: Active Offers Count
                            Expanded(
                              child: _buildMetricCard(
                                title: 'العروض النشطة',
                                value: '${merchant.activeOffersCount}',
                                icon: Icons.local_offer_rounded,
                                color: AppColors.primaryAmber,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Card 2: Total Redemptions
                            Expanded(
                              child: _buildMetricCard(
                                title: 'إجمالي العمليات',
                                value: '${merchant.totalRedemptions}',
                                icon: Icons.qr_code_scanner_rounded,
                                color: AppColors.successGreen,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Card 3: Wallet Balance in D.L
                            Expanded(
                              child: _buildMetricCard(
                                title: 'رصيد المحفظة',
                                value: CurrencyFormatter.format(merchant.walletBalance, isArabic: true),
                                icon: Icons.account_balance_wallet_rounded,
                                color: AppColors.primaryAmberDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Launch New Offer Quick Banner Callout
                        Container(
                          padding: EdgeInsets.all(isMobile ? 14 : 16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAmber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.primaryAmber.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryAmber,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.add_circle_rounded, color: AppColors.darkBackground, size: 22),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'إطلاق عرض جديد للعملاء',
                                      style: TextStyle(
                                        color: AppColors.darkSlate,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'قم بإنشاء خصم ترويجي ونشره فوراً للعملاء.',
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryAmber,
                                  foregroundColor: AppColors.darkSlate,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14, vertical: 10),
                                ),
                                onPressed: onLaunchOffer,
                                child: const Text(
                                  'إطلاق الآن',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 3. Quick Actions Menu Header
                        const Text(
                          'الخدمات والإجراءات السريعة',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkSlate,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 6-Card Grid Layout (Mobile Responsive 2 vs 3 columns)
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: isMobile ? 2 : 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: isMobile ? 1.15 : 1.05,
                          children: [
                            // 1. My Store (متجري) -> Navigates to Settings & Store Profile (Tab index 4)
                            QuickActionCard(
                              title: 'متجري',
                              subtitle: 'إدارة البيانات والفروع',
                              icon: Icons.storefront_rounded,
                              onTap: () => onNavigateTab(4),
                            ),
                            // 2. Manage Offers (إدارة العروض) -> Opens Manage Offers & Analytics (Tab index 1)
                            QuickActionCard(
                              title: 'إدارة العروض',
                              subtitle: 'تعديل وإنشاء العروض',
                              icon: Icons.campaign_rounded,
                              onTap: () => onNavigateTab(1),
                            ),
                            // 3. Scan QR (مسح الكود / التحقق) -> Navigates to QR Scanner (Tab index 2)
                            QuickActionCard(
                              title: 'مسح الكود',
                              subtitle: 'التحقق من الكوبونات',
                              icon: Icons.qr_code_scanner_rounded,
                              onTap: () => onNavigateTab(2),
                            ),
                            // 4. Pricing & Plans (الأسعار) -> Opens Pricing Plans Modal
                            QuickActionCard(
                              title: 'الأسعار',
                              subtitle: 'باقات اشتراك التجار',
                              icon: Icons.sell_rounded,
                              onTap: () => _showPricingPlansModal(context),
                            ),
                            // 5. Events & Campaigns (الفعاليات) -> Opens Events Modal
                            QuickActionCard(
                              title: 'الفعاليات',
                              subtitle: 'الحملات الموسمية',
                              icon: Icons.event_rounded,
                              onTap: () => _showEventsModal(context),
                            ),
                            // 6. Merchant Wallet (المحفظة) -> Navigates to Wallet Tab (Tab index 3)
                            QuickActionCard(
                              title: 'المحفظة',
                              subtitle: 'شحن ورصيد العمليات',
                              icon: Icons.account_balance_wallet_rounded,
                              onTap: () => onNavigateTab(3),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.darkSlate,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
