import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/customer_feed_provider.dart';
import 'widgets/category_filter_pills.dart';
import 'widgets/hero_promo_banner.dart';
import 'widgets/offer_card.dart';
import 'widgets/qr_coupon_bottom_sheet.dart';
import 'widgets/custom_bottom_nav_bar.dart';

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
  final ApiClient _apiClient = ApiClient();

  void _claimOffer(BuildContext context, offer) {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final feedProvider = Provider.of<CustomerFeedProvider>(context, listen: false);

    feedProvider.markOfferClaimed(offer.id);

    walletProvider.claimCoupon({
      'id': offer.id,
      'title': offer.storeName,
      'store_name': offer.storeName,
      'discount': offer.discountBadge,
      'valid_until': offer.validUntil.toIso8601String().substring(0, 10),
    });

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
                '${offer.storeName} offer added to your Wallet Pass Cards!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
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
                  // Bell Notification Icon Button
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
                      icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 22),
                      onPressed: () {},
                    ),
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
                  _buildOffersTab(),
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
  // TAB 1: OFFERS & DISCOUNTS VIEW (Matching Screenshot 5)
  // ---------------------------------------------------------------------------
  Widget _buildOffersTab() {
    return Consumer<CustomerFeedProvider>(
      builder: (context, feedProvider, _) {
        final offers = feedProvider.filteredOffers;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Header
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'العروض والتخفيضات',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.borderGrey),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Icon(Icons.tune_rounded, color: AppColors.textMuted, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'ابحث عن عرض...',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          ),
                          Icon(Icons.search_rounded, color: AppColors.copperOrange, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category Filter Pills
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildFilterPill('الكل', isSelected: true),
                        const SizedBox(width: 8),
                        _buildFilterPill('% تخفيضات'),
                        const SizedBox(width: 8),
                        _buildFilterPill('كوبونات'),
                        const SizedBox(width: 8),
                        _buildFilterPill('انخفاض سعر'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Grid/List Count Toggle Bar
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
                          '${offers.length} عرض متاح',
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

                  // Offers Cards Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: offers.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(32),
                            alignment: Alignment.center,
                            child: const Text('لا توجد عروض متاحة حالياً', style: TextStyle(color: AppColors.textMuted)),
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.82,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: offers.length,
                            itemBuilder: (context, idx) {
                              final offer = offers[idx];
                              return _buildOfferGridCard(offer);
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

  Widget _buildOfferGridCard(dynamic offer) {
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
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    offer.storeName,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  offer.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${(offer.originalPrice * 1.5).toStringAsFixed(0)} د.ل',
                          style: const TextStyle(
                            color: Colors.white54,
                            decoration: TextDecoration.lineThrough,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '${offer.finalPrice.toStringAsFixed(0)} د.ل',
                          style: const TextStyle(
                            color: Color(0xFFFF9E66),
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bookmark_border_rounded, color: AppColors.darkSlate, size: 16),
            ),
          ),
        ],
      ),
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
}
