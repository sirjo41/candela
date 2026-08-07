import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/customer_feed_provider.dart';
import 'widgets/category_filter_pills.dart';
import 'widgets/hero_promo_banner.dart';
import 'widgets/offer_card.dart';
import 'widgets/qr_coupon_bottom_sheet.dart';
import 'widgets/custom_bottom_nav_bar.dart';
import '../../notifications/providers/notification_provider.dart';
import '../models/campaign_model.dart';

/// Main Customer Navigation Scaffold
/// Includes 1-tap role switching back to Merchant Portal for merchant users.
class CustomerMainNavigation extends StatefulWidget {
  const CustomerMainNavigation({super.key});

  @override
  State<CustomerMainNavigation> createState() => _CustomerMainNavigationState();
}

class _CustomerMainNavigationState extends State<CustomerMainNavigation> {
  int _currentIndex = 0;
  int _walletSubTab = 0;

  void _claimOffer(BuildContext context, offer) async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final feedProvider = Provider.of<CustomerFeedProvider>(context, listen: false);

    final success = await walletProvider.claimCoupon({
      'id': offer.id,
      'title': offer.title,
      'store_name': offer.storeName,
      'discount': offer.discountBadge,
      'valid_until': offer.validUntil.toIso8601String().substring(0, 10),
    });

    if (success) {
      feedProvider.markOfferClaimed(offer.id);
    }

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تم إضافة عرض ${offer.storeName} إلى بطاقات محفظتك بنجاح!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.copperOrange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(walletProvider.errorMessage ?? 'العرض موجود بالفعل في محفظتك.'),
          ),
        );
      }
    }
  }

  void _openQrModalSheet() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final userId = auth.user?.id.toString() ?? 'USR-001';

    QrCouponBottomSheet.show(
      context,
      activeCoupons: walletProvider.activeCoupons,
      userId: userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final notifProvider = Provider.of<NotificationProvider>(context);

    final incoming = notifProvider.latestIncomingNotification;
    if (incoming != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifProvider.clearLatestIncoming();
        _showIncomingNotificationDialog(context, incoming);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Persistent Switch-Back Banner for Merchants viewing Customer Interface
            if (auth.isMerchantAccount)
              Material(
                color: AppColors.copperOrange,
                child: InkWell(
                  onTap: () => auth.switchRole('merchant'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: const Row(
                      children: [
                        Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'أنت الآن في وضع معاينة العميل. اضغط هنا للعودة إلى لوحة تحكم التاجر (متجري).',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ),
              ),

            // Top Brand Header Bar (Matching Customer Screenshot 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Bell Notification Icon Button with Live Unread Badge
                  Consumer<NotificationProvider>(
                    builder: (context, notifProvider, _) {
                      final unread = notifProvider.unreadCount;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                unread > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                                color: unread > 0 ? AppColors.copperOrange : AppColors.textPrimary,
                                size: 22,
                              ),
                              onPressed: () => _showNotificationsBottomSheet(context),
                            ),
                          ),
                          if (unread > 0)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.errorRed,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                child: Text(
                                  '$unread',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  // Brand Title: CANDELA ✦
                  Row(
                    children: [
                      const Text(
                        'CANDELA',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.copperOrange,
                        size: 18,
                      ),
                    ],
                  ),

                  // Profile Avatar Button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentIndex = 4; // Navigate to Profile / Menu tab
                      });
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryAmberLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppColors.copperOrange,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Body Stack
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  _buildHomeTab(),
                  _buildCampaignsTab(),
                  const SizedBox.shrink(),
                  _buildWalletTab(),
                  _buildProfileTab(user, auth),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            _openQrModalSheet();
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        onQrTap: _openQrModalSheet,
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryAmberLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: InkWell(
              onTap: onSeeAll,
              child: const Text(
                'عرض الكل',
                style: TextStyle(
                  color: AppColors.copperOrange,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 0: HOME FEED VIEW (Matching Screenshot 1 & 2)
  // ---------------------------------------------------------------------------
  Widget _buildHomeTab() {
    return Consumer<CustomerFeedProvider>(
      builder: (context, feedProvider, _) {
        final offers = feedProvider.filteredOffers;

        return RefreshIndicator(
          onRefresh: () async {
            await feedProvider.fetchFeedData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar Widget
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(23),
                          border: Border.all(color: AppColors.borderGrey),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(Icons.tune_rounded, color: AppColors.textMuted, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'ابحث عن العروض، المتاجر...',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                              ),
                            ),
                            Icon(Icons.search_rounded, color: AppColors.copperOrange, size: 22),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Hero Banner Cards (Silver Level + Exclusive Offer)
                    HeroPromoBanner(
                      onQrPassTap: _openQrModalSheet,
                    ),
                    const SizedBox(height: 16),

                    // Top Active Campaigns Carousel
                    _buildSectionHeader('العروض الترويجية المميزة ✦', onSeeAll: () {
                      setState(() {
                        _currentIndex = 1;
                      });
                    }),
                    SizedBox(
                      height: 140,
                      child: feedProvider.isLoadingCampaigns
                          ? const Center(child: CircularProgressIndicator(color: AppColors.copperOrange))
                          : feedProvider.campaigns.isEmpty
                              ? Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.borderGrey),
                                  ),
                                  child: const Center(
                                    child: Text('لا توجد حملات موسمية نشطة حالياً', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                                  ),
                                )
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: feedProvider.campaigns.length,
                                  itemBuilder: (ctx, idx) {
                                    final campaign = feedProvider.campaigns[idx];
                                    return GestureDetector(
                                      onTap: () => _showCampaignCouponsModal(context, campaign),
                                      child: Container(
                                        width: 270,
                                        margin: const EdgeInsets.only(left: 12),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [AppColors.copperOrange, AppColors.copperOrangeDark],
                                            begin: Alignment.topRight,
                                            end: Alignment.bottomLeft,
                                          ),
                                          borderRadius: BorderRadius.circular(18),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.copperOrange.withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withValues(alpha: 0.2),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Row(
                                                    children: [
                                                      Icon(Icons.local_fire_department_rounded, color: Colors.amber, size: 13),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'حملة نشطة',
                                                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                  campaign.discountBadge,
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11.5),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              campaign.title,
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    campaign.storeName,
                                                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: const Text(
                                                    'العروض',
                                                    style: TextStyle(color: AppColors.copperOrangeDark, fontSize: 11, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                    const SizedBox(height: 16),

                    // Categories Section
                    _buildSectionHeader('الفئات'),
                    CategoryFilterPills(
                      selectedCategory: feedProvider.selectedCategory,
                      onCategorySelected: (cat) => feedProvider.selectCategory(cat),
                    ),
                    const SizedBox(height: 16),

                    // Featured Stores Section (المتاجر المتميزة وفروعها)
                    _buildSectionHeader('المتاجر المتميزة وفروعها'),
                    SizedBox(
                      height: 140,
                      child: feedProvider.isLoadingStores
                          ? const Center(child: CircularProgressIndicator(color: AppColors.copperOrange))
                          : feedProvider.stores.isEmpty
                              ? const Center(child: Text('لا توجد متاجر مضافة حالياً', style: TextStyle(color: AppColors.textMuted)))
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: feedProvider.stores.length,
                                  itemBuilder: (ctx, idx) {
                                    final store = feedProvider.stores[idx];
                                    final name = store['store_name'] ?? store['name'] ?? 'متجر كانديلا';
                                    final address = store['address'] ?? 'طرابلس، ليبيا';
                                    final distance = store['distance'] ?? 'قريب منك';

                                    return GestureDetector(
                                      onTap: () => _showStoreCouponsModal(context, store),
                                      child: Container(
                                        width: 170,
                                        margin: const EdgeInsets.only(left: 12),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.darkSlate,
                                          borderRadius: BorderRadius.circular(18),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.15),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.copperOrange,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    distance,
                                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                                const Icon(Icons.storefront_rounded, color: Colors.white70, size: 22),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.location_on_rounded, color: AppColors.copperOrange, size: 12),
                                                    const SizedBox(width: 2),
                                                    Expanded(
                                                      child: Text(
                                                        address,
                                                        style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                    const SizedBox(height: 16),

                    // Top Offers Section (أبرز العروض)
                    _buildSectionHeader('أبرز العروض'),
                    feedProvider.isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(color: AppColors.copperOrange),
                            ),
                          )
                        : offers.isEmpty
                            ? Center(
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  child: const Text(
                                    'لا توجد عروض نشطة حالياً',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: offers.length,
                                  itemBuilder: (context, index) {
                                    final offer = offers[index];
                                    return OfferCard(
                                      offer: offer,
                                      onClaim: () => _claimOffer(context, offer),
                                    );
                                  },
                                ),
                              ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: CAMPAIGNS VIEW (الحملات الإعلانية والترويجية)
  // ---------------------------------------------------------------------------
  Widget _buildCampaignsTab() {
    return Consumer<CustomerFeedProvider>(
      builder: (context, feedProvider, _) {
        final campaigns = feedProvider.filteredCampaigns;

        return RefreshIndicator(
          onRefresh: () async {
            await feedProvider.fetchCampaigns();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.copperOrange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.campaign_rounded, color: AppColors.copperOrange, size: 24),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'العروض الترويجية المميزة',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'تصفح أحدث الحملات التسويقية والعروض الحصرية من شركائنا',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),

                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(23),
                          border: Border.all(color: AppColors.borderGrey),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: const Row(
                          children: [
                            Icon(Icons.tune_rounded, color: AppColors.textMuted, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'ابحث عن حملة إعلانية أو متجر...',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                              ),
                            ),
                            Icon(Icons.search_rounded, color: AppColors.copperOrange, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Category Filter Pills
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _buildFilterPill('الكل', isSelected: true),
                          const SizedBox(width: 8),
                          _buildFilterPill('الحملات النشطة'),
                          const SizedBox(width: 8),
                          _buildFilterPill('خصومات خيالية'),
                          const SizedBox(width: 8),
                          _buildFilterPill('متاجر مميزة'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Campaign Count Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.copperOrange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 16),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.borderGrey),
                                ),
                                child: const Icon(Icons.view_list_rounded, color: AppColors.textMuted, size: 16),
                              ),
                            ],
                          ),
                          Text(
                            '${campaigns.length} حملة إعلانية نشطة',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Campaigns List / Grid View
                    feedProvider.isLoadingCampaigns
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(color: AppColors.copperOrange),
                            ),
                          )
                        : campaigns.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(32),
                                alignment: Alignment.center,
                                child: const Text(
                                  'لا توجد حملات إعلانية متاحة حالياً',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: campaigns.length,
                                  separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                                  itemBuilder: (context, idx) {
                                    final campaign = campaigns[idx];
                                    return _buildCampaignCard(context, campaign);
                                  },
                                ),
                              ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterPill(String label, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.copperOrange : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.copperOrangeDark : AppColors.borderGrey,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCampaignCard(BuildContext context, CampaignModel campaign) {
    final daysLeft = campaign.remainingTime.inDays;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSlate,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Color Header with Badges
          Container(
            height: 90,
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(campaign.imageColor),
                  AppColors.darkSlate,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Store Name Pill
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Text(
                        campaign.storeName.isNotEmpty ? campaign.storeName[0] : 'S',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkSlate, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      campaign.storeName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),

                // Discount Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.copperOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    campaign.discountBadge,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Content Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campaign.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (campaign.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    campaign.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 14),

                // Expiry & Claim Action Button Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: AppColors.primaryAmber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          daysLeft > 0 ? 'ينتهي خلال $daysLeft أيام' : 'ينتهي اليوم',
                          style: const TextStyle(color: AppColors.primaryAmber, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.copperOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _showCampaignCouponsModal(context, campaign),
                      icon: const Icon(
                        Icons.local_offer_rounded,
                        size: 16,
                      ),
                      label: const Text(
                        'العروض',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCampaignCouponsModal(BuildContext context, CampaignModel campaign) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Consumer<CustomerFeedProvider>(
            builder: (context, feedProvider, _) {
              final campaignOffers = feedProvider.offers
                  .where((o) => o.category == campaign.category || o.storeName.toLowerCase() == campaign.storeName.toLowerCase())
                  .toList();
              final displayOffers = campaignOffers.isNotEmpty ? campaignOffers : feedProvider.offers;

              return Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.darkSlate,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.all(20),
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

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAmber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.campaign_rounded, color: AppColors.primaryAmber, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                campaign.title,
                                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'عروض وأكواد خصم ${campaign.storeName}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white60),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Colors.white12),

                    const Text(
                      'الكوبونات والعروض المتاحة داخل هذه الحملة:',
                      style: TextStyle(color: AppColors.primaryAmber, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: displayOffers.isEmpty
                          ? const Center(
                              child: Text('لا توجد عروض مخصصة لهذه الحملة حالياً', style: TextStyle(color: Colors.white60)),
                            )
                          : ListView.builder(
                              itemCount: displayOffers.length,
                              itemBuilder: (context, idx) {
                                final offer = displayOffers[idx];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: OfferCard(
                                    offer: offer,
                                    onClaim: () {
                                      _claimOffer(context, offer);
                                      Navigator.pop(ctx);
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showStoreCouponsModal(BuildContext context, dynamic store) {
    final storeName = store['store_name'] ?? store['name'] ?? 'المتجر';
    final address = store['address'] ?? 'طرابلس، ليبيا';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Consumer<CustomerFeedProvider>(
            builder: (context, feedProvider, _) {
              final storeOffers = feedProvider.offers
                  .where((o) => o.storeName.toLowerCase() == storeName.toString().toLowerCase())
                  .toList();

              return Container(
                height: MediaQuery.of(context).size.height * 0.75,
                decoration: const BoxDecoration(
                  color: AppColors.darkSlate,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryAmber,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.storefront_rounded, color: AppColors.darkSlate, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                storeName,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, color: AppColors.primaryAmber, size: 13),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      address,
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'كوبونات وعروض المتجر المتاحة',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: storeOffers.isEmpty
                          ? const Center(
                              child: Text(
                                'لا توجد كوبونات مخصصة لهذا المتجر حالياً.',
                                style: TextStyle(color: Colors.white60, fontSize: 13),
                              ),
                            )
                          : ListView.builder(
                              itemCount: storeOffers.length,
                              itemBuilder: (context, index) {
                                final offer = storeOffers[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              offer.title,
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              offer.discountBadge,
                                              style: const TextStyle(color: AppColors.primaryAmber, fontSize: 12, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primaryAmber,
                                          foregroundColor: AppColors.darkSlate,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        onPressed: () async {
                                          final success = await feedProvider.claimCoupon(int.tryParse(offer.id) ?? 1);
                                          if (ctx.mounted) {
                                            Navigator.pop(ctx);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                backgroundColor: success ? AppColors.successGreen : AppColors.primaryAmber,
                                                content: Text(success ? 'تم حجز الكوبون وإضافته لمحفظتك بنجاح!' : 'الكوبون محجوز بالفعل في محفظتك.'),
                                              ),
                                            );
                                          }
                                        },
                                        child: const Text('احجز الكوبون', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: WALLET VIEW (المحفظة - Active, Used, Expired Coupons)
  // ---------------------------------------------------------------------------
  Widget _buildWalletTab() {
    return Consumer<CustomerFeedProvider>(
      builder: (context, feedProvider, _) {
        List<dynamic> currentList = [];
        if (_walletSubTab == 0) {
          currentList = feedProvider.activeCoupons;
        } else if (_walletSubTab == 1) {
          currentList = feedProvider.usedCoupons;
        } else {
          currentList = feedProvider.expiredCoupons;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 28, top: 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.copperOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${currentList.length} كوبون',
                            style: const TextStyle(color: AppColors.copperOrange, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        const Text(
                          'محفظة الكوبونات',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sub-Tab Switcher Pills
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderGrey),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _walletSubTab = 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _walletSubTab == 0 ? AppColors.copperOrange : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'النشطة (${feedProvider.activeCoupons.length})',
                                  style: TextStyle(
                                    color: _walletSubTab == 0 ? Colors.white : AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _walletSubTab = 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _walletSubTab == 1 ? AppColors.copperOrange : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'المستعملة (${feedProvider.usedCoupons.length})',
                                  style: TextStyle(
                                    color: _walletSubTab == 1 ? Colors.white : AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _walletSubTab = 2),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _walletSubTab == 2 ? AppColors.copperOrange : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'المنتهية (${feedProvider.expiredCoupons.length})',
                                  style: TextStyle(
                                    color: _walletSubTab == 2 ? Colors.white : AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Coupons List Body
                  feedProvider.isLoadingWallet
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(color: AppColors.copperOrange),
                          ),
                        )
                      : currentList.isEmpty
                          ? Center(
                              child: Container(
                                padding: const EdgeInsets.all(40),
                                child: Column(
                                  children: [
                                    Icon(Icons.confirmation_number_outlined, size: 56, color: AppColors.textMuted.withValues(alpha: 0.4)),
                                    const SizedBox(height: 12),
                                    Text(
                                      _walletSubTab == 0
                                          ? 'لا توجد كوبونات نشطة في محفظتك حالياً'
                                          : (_walletSubTab == 1 ? 'لم تقم باستخدام أي كوبونات بعد' : 'لا توجد كوبونات منتهية الصلاحية'),
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: currentList.length,
                                itemBuilder: (context, idx) {
                                  final item = currentList[idx];
                                  final title = item['title'] ?? 'كوبون خصم مميز';
                                  final store = item['store'] ?? item['store_name'] ?? 'متجر كانديلا';
                                  final code = item['code'] ?? 'CPN-2026';
                                  final expires = item['expires'] ?? '2026-12-31';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _walletSubTab == 0 ? AppColors.copperOrange.withValues(alpha: 0.5) : AppColors.borderGrey,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _walletSubTab == 0 ? AppColors.successGreenLight : Colors.grey.shade200,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                _walletSubTab == 0 ? 'نشط' : (_walletSubTab == 1 ? 'تم الاستخدام' : 'منتهي'),
                                                style: TextStyle(
                                                  color: _walletSubTab == 0 ? AppColors.successGreen : Colors.grey.shade700,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              store,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          title,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'ينتهي في: $expires',
                                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                            ),
                                            Text(
                                              'الكود: $code',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.copperOrange),
                                            ),
                                          ],
                                        ),
                                        if (_walletSubTab == 0) ...[
                                          const SizedBox(height: 12),
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              minimumSize: const Size.fromHeight(40),
                                              backgroundColor: AppColors.copperOrange,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                            icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                                            label: const Text('عرض رمز QR للاستخدام بالمتجر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                            onPressed: _openQrModalSheet,
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }



  // ---------------------------------------------------------------------------
  // TAB 4: POINTS & REWARDS CENTER / PROFILE VIEW (Matching Screenshot 3)
  // ---------------------------------------------------------------------------
  Widget _buildProfileTab(dynamic user, AuthProvider auth) {
    final points = user?.loyaltyPoints ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 28, top: 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Header Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                      onPressed: () {
                        setState(() {
                          _currentIndex = 0;
                        });
                      },
                    ),
                    const Text(
                      'مركز النقاط والمكافآت',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Main Gold Points Card (Matching Screenshot 3)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFE86014),
                      Color(0xFFFF8A00),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE86014).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFE86014),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'رصيد نقاطك الحالي',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$points',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'نقطة كانديلا الذهبية',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section: كيف تكسب النقاط؟
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'كيف تكسب النقاط؟',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: _buildEarnCard('أحضر أصدقاء', '50 نقطة لكل دعوة', Icons.person_add_outlined)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildEarnCard('استخدم الكوبونات', 'نقاط إضافية عند الاستخدام', Icons.confirmation_number_outlined)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildEarnCard('تسوق من المتاجر', 'اكسب نقطة لكل دينار', Icons.shopping_bag_outlined)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const SizedBox(height: 24),

              // Switch to Merchant Portal & Logout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    if (auth.isMerchantAccount) ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: AppColors.copperOrange,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.storefront_rounded, size: 20),
                        label: const Text(
                          'العودة إلى لوحة تحكم التاجر (متجري)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        onPressed: () => auth.switchRole('merchant'),
                      ),
                      const SizedBox(height: 10),
                    ],
                    TextButton.icon(
                      icon: const Icon(Icons.logout_rounded, color: AppColors.errorRed, size: 18),
                      label: const Text(
                        'تسجيل الخروج',
                        style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: () => auth.logout(),
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

  Widget _buildEarnCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFC84605), size: 26),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  void _showNotificationsBottomSheet(BuildContext context) {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    provider.markAllAsRead();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer<NotificationProvider>(
          builder: (context, notifProvider, _) {
            final items = notifProvider.notifications;
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                decoration: const BoxDecoration(
                  color: AppColors.scaffoldBackground,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.notifications_active_rounded, color: AppColors.copperOrange),
                            SizedBox(width: 8),
                            Text(
                              'الإشعارات والإعلانات',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                            ),
                          ],
                        ),
                        Text(
                          '${items.length} إشعار',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Expanded(
                      child: items.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.notifications_off_outlined, size: 50, color: Colors.black26),
                                  SizedBox(height: 10),
                                  Text('لا توجد إشعارات جديدة حالياً', style: TextStyle(color: AppColors.textSecondary)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: items.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final notif = items[index];
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notif.title,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.darkSlate),
                                            ),
                                          ),
                                          const Icon(Icons.campaign_rounded, color: AppColors.copperOrange, size: 20),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        notif.message,
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                                      ),
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          '${notif.createdAt.hour}:${notif.createdAt.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showIncomingNotificationDialog(BuildContext context, dynamic notif) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.copperOrange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.campaign_rounded, color: AppColors.copperOrange, size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    notif.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.darkSlate),
                  ),
                ),
              ],
            ),
            content: Text(
              notif.message,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.copperOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('حسناً، فهمت', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
}
