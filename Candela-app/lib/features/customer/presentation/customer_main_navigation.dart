import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/customer_feed_provider.dart';
import 'widgets/category_filter_pills.dart';
import 'widgets/hero_promo_banner.dart';
import 'widgets/offer_card.dart';
import 'widgets/qr_coupon_bottom_sheet.dart';
import 'widgets/custom_bottom_nav_bar.dart';
import 'widgets/edit_profile_dialog.dart';
import 'widgets/change_password_dialog.dart';
import 'customer_scan_merchant_screen.dart';
import '../../notifications/providers/notification_provider.dart';
import '../models/campaign_model.dart';

/// Comprehensive Customer Main Navigation Scaffold
/// Features 5-tab responsive navigation:
/// 0: 🏠 Home / استكشف (Explore)
/// 1: 🏪 Stores / قريب منك (Near You)
/// 2: 🎟️ Center Dynamic QR Pass Floating Action Button
/// 3: 👛 Wallet / العروض (Active, Used, Expired)
/// 4: 👤 Profile / القائمة (Personal details, Loyalty Tier, Support, Settings)
class CustomerMainNavigation extends StatefulWidget {
  const CustomerMainNavigation({super.key});

  @override
  State<CustomerMainNavigation> createState() => _CustomerMainNavigationState();
}

class _CustomerMainNavigationState extends State<CustomerMainNavigation> {
  int _currentIndex = 0;
  int _walletSubTab = 0; // 0: Active, 1: Used, 2: Expired

  // Search controllers for real-time responsive filtering
  final TextEditingController _exploreSearchController =
      TextEditingController();
  final TextEditingController _storesSearchController = TextEditingController();
  String _exploreSearchQuery = '';
  String _storesSearchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WalletProvider>(context, listen: false).fetchWallet();
      final feedProvider =
          Provider.of<CustomerFeedProvider>(context, listen: false);
      feedProvider.fetchFeedData();
      feedProvider.fetchCampaigns();
      feedProvider.fetchStores();
    });
  }

  @override
  void dispose() {
    _exploreSearchController.dispose();
    _storesSearchController.dispose();
    super.dispose();
  }

  void _claimOffer(BuildContext context, dynamic offer) async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final feedProvider =
        Provider.of<CustomerFeedProvider>(context, listen: false);
    final loc = AppLocalizations.of(context);

    final success = await walletProvider.claimCoupon({
      'id': offer.id,
      'title': offer.title,
      'store_name': offer.storeName,
      'store_logo_url': offer.storeLogoUrl,
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    loc.isArabic
                        ? 'تم إضافة عرض ${offer.storeName} إلى بطاقات محفظتك بنجاح!'
                        : 'Offer from ${offer.storeName} added to wallet successfully!',
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(walletProvider.errorMessage ??
                (loc.isArabic
                    ? 'العرض موجود بالفعل في محفظتك.'
                    : 'Offer is already in your wallet.')),
          ),
        );
      }
    }
  }

  void _openQrModalSheet({dynamic initialCoupon}) {
    // Show choice: scan merchant QR or view wallet passes
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Icon(Icons.qr_code_scanner_rounded,
                      color: AppColors.primaryAmber, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'رمز QR',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Option 1: Scan Merchant QR
              _qrOption(
                ctx: ctx,
                icon: Icons.storefront_rounded,
                title: 'مسح رمز QR المتجر',
                subtitle: 'امسح رمز المتجر لاسترداد كوبونك والحصول على الخصم',
                color: AppColors.primaryAmber,
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CustomerScanMerchantScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              // Option 2: Show wallet QR pass
              _qrOption(
                ctx: ctx,
                icon: Icons.confirmation_number_rounded,
                title: 'عرض بطاقات المحفظة',
                subtitle: 'اعرض QR كوبون للتاجر إذا طلبه منك',
                color: AppColors.copperOrange,
                onTap: () {
                  Navigator.pop(ctx);
                  final auth =
                      Provider.of<AuthProvider>(context, listen: false);
                  final walletProvider =
                      Provider.of<WalletProvider>(context, listen: false);
                  final userId = auth.user?.id;
                  if (userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('يجب تسجيل الدخول لعرض بطاقات المحفظة.'),
                      ),
                    );
                    return;
                  }
                  if (walletProvider.activeCoupons.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('لا توجد كوبونات نشطة في محفظتك.'),
                      ),
                    );
                    return;
                  }
                  QrCouponBottomSheet.show(
                    context,
                    activeCoupons: walletProvider.activeCoupons,
                    userId: userId.toString(),
                    initialCoupon: initialCoupon,
                  );
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء',
                    style: TextStyle(color: AppColors.darkTextSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _qrOption({
    required BuildContext ctx,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.darkTextSecondary, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  void _showCustomerSupportSheet(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Directionality(
          textDirection: loc.textDirection,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSlateCard : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border:
                  isDark ? Border.all(color: AppColors.darkSlateBorder) : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white30 : Colors.black26,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.darkAmberAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.support_agent_rounded,
                          color: AppColors.darkSlateSurface, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.tr('customer_support'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          loc.isArabic
                              ? 'فريق خدمة عملاء كانديلا متاح على مدار الساعة'
                              : 'Candela support team is available 24/7',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.darkTextSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSupportOption(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: loc.isArabic
                      ? 'محادثة مباشرة عبر واتساب'
                      : 'Direct WhatsApp Chat',
                  subtitle: '+218 91 000 0000',
                  color: AppColors.successGreen,
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(loc.isArabic
                              ? 'جاري فتح محادثة الدعم عبر واتساب...'
                              : 'Opening WhatsApp support...')),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildSupportOption(
                  icon: Icons.phone_in_talk_rounded,
                  title: loc.isArabic
                      ? 'الاتصال المباشر بالرقم المجاني'
                      : 'Toll-Free Phone Call',
                  subtitle: '800-CANDELA (800-2263352)',
                  color: AppColors.darkAmberAccent,
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(loc.isArabic
                              ? 'جاري الاتصال بخدمة العملاء...'
                              : 'Calling customer support...')),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildSupportOption(
                  icon: Icons.mail_outline_rounded,
                  title: loc.isArabic
                      ? 'الدعم الفني عبر البريد الإلكتروني'
                      : 'Email Support Desk',
                  subtitle: 'support@candela.app',
                  color: AppColors.royalNavy,
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(loc.isArabic
                              ? 'تم نسخ بريد الدعم: support@candela.app'
                              : 'Copied support email')),
                    );
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.darkSlateSurface
                        : Colors.grey.shade200,
                    foregroundColor:
                        isDark ? Colors.white : AppColors.textPrimary,
                    minimumSize: const Size.fromHeight(46),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(loc.tr('cancel'),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSupportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSlateSurface : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark ? AppColors.darkSlateBorder : AppColors.borderGrey),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.darkTextSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: isDark ? Colors.white38 : Colors.black38),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: loc.textDirection,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // Merchant Preview Banner if merchant user
              if (auth.isMerchantAccount)
                Material(
                  color: AppColors.copperOrange,
                  child: InkWell(
                    onTap: () => auth.switchRole('merchant'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.storefront_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              loc.isArabic
                                  ? 'أنت الآن في وضع معاينة العميل. اضغط هنا للعودة إلى لوحة تحكم التاجر.'
                                  : 'Previewing Customer Mode. Tap to switch back to Merchant Portal.',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              color: Colors.white, size: 14),
                        ],
                      ),
                    ),
                  ),
                ),

              // Main App Bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSlateSurface : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? AppColors.darkSlateBorder
                          : AppColors.borderGrey,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand Logo
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.darkAmberAccent,
                                AppColors.copperOrange
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.local_fire_department_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'CANDELA',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),

                    // Actions: Notifications & Avatar
                    Row(
                      children: [
                        Consumer<NotificationProvider>(
                          builder: (context, notifProvider, _) {
                            final unread = notifProvider.unreadCount;
                            return Stack(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    unread > 0
                                        ? Icons.notifications_active_rounded
                                        : Icons.notifications_none_rounded,
                                    color: unread > 0
                                        ? AppColors.darkAmberAccent
                                        : (isDark
                                            ? Colors.white70
                                            : AppColors.textSecondary),
                                  ),
                                  onPressed: () {
                                    notifProvider.fetchNotifications();
                                  },
                                ),
                                if (unread > 0)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                          color: AppColors.errorRed,
                                          shape: BoxShape.circle),
                                      constraints: const BoxConstraints(
                                          minWidth: 16, minHeight: 16),
                                      child: Text(
                                        '$unread',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        InkWell(
                          onTap: () => setState(() => _currentIndex = 4),
                          borderRadius: BorderRadius.circular(20),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.darkAmberAccent,
                            child: Text(
                              user?.name.isNotEmpty == true
                                  ? user!.name[0].toUpperCase()
                                  : 'C',
                              style: const TextStyle(
                                color: AppColors.darkSlateSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 5-Tab Content Body
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: [
                    // Tab 0: Home / Explore (استكشف)
                    _buildExploreTab(),

                    // Tab 1: Stores / Near You (قريب منك)
                    _buildNearYouStoresTab(),

                    // Tab 2: Sized box dummy for center QR FAB
                    const SizedBox.shrink(),

                    // Tab 3: Wallet / المحفظة
                    _buildWalletTab(),

                    // Tab 4: Profile / القائمة
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
          onQrTap: () => _openQrModalSheet(),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 0: HOME / EXPLORE (استكشف)
  // ---------------------------------------------------------------------------
  Widget _buildExploreTab() {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<CustomerFeedProvider>(
      builder: (context, feedProvider, _) {
        final offers = feedProvider.filteredOffers.where((o) {
          if (_exploreSearchQuery.isEmpty) return true;
          final q = _exploreSearchQuery.toLowerCase();
          return o.title.toLowerCase().contains(q) ||
              o.storeName.toLowerCase().contains(q) ||
              o.description.toLowerCase().contains(q);
        }).toList();

        final campaigns = feedProvider.campaigns.where((c) {
          if (_exploreSearchQuery.isEmpty) return true;
          final q = _exploreSearchQuery.toLowerCase();
          return c.title.toLowerCase().contains(q) ||
              c.storeName.toLowerCase().contains(q);
        }).toList();

        return RefreshIndicator(
          onRefresh: () async {
            await feedProvider.fetchFeedData();
            await feedProvider.fetchCampaigns();
            await feedProvider.fetchStores();
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
                    // Live Responsive Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color:
                              isDark ? AppColors.darkSlateCard : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: isDark
                                  ? AppColors.darkSlateBorder
                                  : AppColors.borderGrey),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded,
                                color: AppColors.darkAmberAccent, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _exploreSearchController,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontSize: 13.5,
                                ),
                                decoration: InputDecoration(
                                  hintText: loc.tr('search_placeholder'),
                                  hintStyle: TextStyle(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _exploreSearchQuery = val.trim();
                                  });
                                },
                              ),
                            ),
                            if (_exploreSearchQuery.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _exploreSearchController.clear();
                                  setState(() {
                                    _exploreSearchQuery = '';
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Hero Promo Banner
                    HeroPromoBanner(onQrPassTap: () => _openQrModalSheet()),
                    const SizedBox(height: 16),

                    // Active Campaigns Carousel
                    _buildSectionHeader(
                      loc.tr('exclusive_promos'),
                      onSeeAll: () => setState(() => _currentIndex = 1),
                    ),
                    SizedBox(
                      height: 145,
                      child: feedProvider.isLoadingCampaigns
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.darkAmberAccent))
                          : campaigns.isEmpty
                              ? Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkSlateCard
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: isDark
                                            ? AppColors.darkSlateBorder
                                            : AppColors.borderGrey),
                                  ),
                                  child: Center(
                                    child: Text(
                                      loc.tr('no_active_campaigns'),
                                      style: const TextStyle(
                                          color: AppColors.darkTextSecondary,
                                          fontSize: 13),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  itemCount: campaigns.length,
                                  itemBuilder: (ctx, idx) {
                                    final campaign = campaigns[idx];
                                    return _buildCampaignCard(campaign);
                                  },
                                ),
                    ),
                    const SizedBox(height: 18),

                    // Categories Filter Pills
                    _buildSectionHeader(loc.isArabic ? 'الفئات' : 'Categories'),
                    CategoryFilterPills(
                      selectedCategory: feedProvider.selectedCategory,
                      onCategorySelected: (cat) =>
                          feedProvider.selectCategory(cat),
                    ),
                    const SizedBox(height: 18),

                    // Top Offers Section
                    _buildSectionHeader(loc.tr('top_offers')),
                    feedProvider.isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(
                                  color: AppColors.darkAmberAccent),
                            ),
                          )
                        : offers.isEmpty
                            ? Center(
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    loc.tr('no_active_offers'),
                                    style: const TextStyle(
                                        color: AppColors.darkTextSecondary,
                                        fontSize: 13),
                                  ),
                                ),
                              )
                            : Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: offers.length,
                                  itemBuilder: (context, index) {
                                    final offer = offers[index];
                                    return OfferCard(
                                      offer: offer,
                                      onClaim: () =>
                                          _claimOffer(context, offer),
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

  Widget _buildCampaignCard(CampaignModel campaign) {
    return GestureDetector(
      onTap: () => _showCampaignCouponsModal(context, campaign),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(left: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(campaign.imageColor), AppColors.darkSlateSurface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.local_fire_department_rounded,
                          color: AppColors.darkAmberAccent, size: 14),
                      SizedBox(width: 4),
                      Text('حملة نشطة',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Text(
                  campaign.discountBadge,
                  style: const TextStyle(
                      color: AppColors.darkAmberAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 12),
                ),
              ],
            ),
            Text(
              campaign.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'احجز الآن',
                    style: TextStyle(
                        color: AppColors.darkSlateSurface,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: STORES / NEAR YOU (قريب منك)
  // ---------------------------------------------------------------------------
  Widget _buildNearYouStoresTab() {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<CustomerFeedProvider>(
      builder: (context, feedProvider, _) {
        final stores = feedProvider.stores.where((store) {
          if (_storesSearchQuery.isEmpty) return true;
          final q = _storesSearchQuery.toLowerCase();
          final name = (store['store_name'] ?? store['name'] ?? '')
              .toString()
              .toLowerCase();
          final addr = (store['address'] ?? '').toString().toLowerCase();
          return name.contains(q) || addr.contains(q);
        }).toList();

        return RefreshIndicator(
          onRefresh: () async {
            await feedProvider.fetchStores();
            await feedProvider.fetchFeedData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.darkAmberAccent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.storefront_rounded,
                                  color: AppColors.darkSlateSurface, size: 22),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              loc.tr('stores_title'),
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSlateCard
                                : AppColors.primaryAmberLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${stores.length} ${loc.isArabic ? 'متاجر' : 'stores'}',
                            style: const TextStyle(
                              color: AppColors.darkAmberAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Search Stores Bar
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSlateCard : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isDark
                                ? AppColors.darkSlateBorder
                                : AppColors.borderGrey),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: AppColors.darkAmberAccent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _storesSearchController,
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontSize: 13),
                              decoration: InputDecoration(
                                hintText: loc.isArabic
                                    ? 'ابحث عن متجر بالاسم أو المنطقة...'
                                    : 'Search stores by name or location...',
                                hintStyle: TextStyle(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textMuted,
                                    fontSize: 13),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _storesSearchQuery = val.trim();
                                });
                              },
                            ),
                          ),
                          if (_storesSearchQuery.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _storesSearchController.clear();
                                setState(() {
                                  _storesSearchQuery = '';
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stores Directory List
                    if (feedProvider.isLoadingStores)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(
                              color: AppColors.darkAmberAccent),
                        ),
                      )
                    else if (stores.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color:
                              isDark ? AppColors.darkSlateCard : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: isDark
                                  ? AppColors.darkSlateBorder
                                  : AppColors.borderGrey),
                        ),
                        child: Center(
                          child: Text(
                            loc.tr('no_stores_found'),
                            style: const TextStyle(
                                color: AppColors.darkTextSecondary,
                                fontSize: 14),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: stores.length,
                        itemBuilder: (context, index) {
                          final store = stores[index];
                          final name = store['store_name'] ??
                              store['name'] ??
                              'متجر كانديلا';
                          final address = store['address'] ?? 'طرابلس، ليبيا';
                          final distance = store['distance'] ?? '1.2 km away';
                          final openHours =
                              store['open_hours'] ?? '9:00 AM - 11:00 PM';
                          final rating = store['rating'] ?? 4.9;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSlateCard
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: isDark
                                      ? AppColors.darkSlateBorder
                                      : AppColors.borderGrey),
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
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: isDark
                                          ? AppColors.darkSlateSurface
                                          : AppColors.primaryAmberLight,
                                      child: Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : 'S',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: AppColors.darkAmberAccent,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(
                                                  Icons.location_on_rounded,
                                                  size: 14,
                                                  color: AppColors
                                                      .darkAmberAccent),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  address,
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors
                                                          .darkTextSecondary),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.darkAmberAccent
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.star_rounded,
                                              color: AppColors.darkAmberAccent,
                                              size: 14),
                                          const SizedBox(width: 3),
                                          Text(
                                            '$rating',
                                            style: const TextStyle(
                                              color: AppColors.darkAmberAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(
                                    height: 1, color: AppColors.borderGrey),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.near_me_rounded,
                                            size: 14,
                                            color: AppColors.successGreen),
                                        const SizedBox(width: 4),
                                        Text(
                                          distance,
                                          style: const TextStyle(
                                            color: AppColors.successGreen,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.access_time_rounded,
                                            size: 14,
                                            color: AppColors.darkTextSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          openHours,
                                          style: const TextStyle(
                                              color:
                                                  AppColors.darkTextSecondary,
                                              fontSize: 11.5),
                                        ),
                                      ],
                                    ),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.darkAmberAccent,
                                        foregroundColor:
                                            AppColors.darkSlateSurface,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                      onPressed: () => _showStoreCouponsModal(
                                          context, store),
                                      icon: const Icon(
                                          Icons.local_offer_rounded,
                                          size: 14),
                                      label: Text(
                                        loc.tr('view_offers'),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
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
  // TAB 3: WALLET (العروض) - ACTIVE, USED, EXPIRED
  // ---------------------------------------------------------------------------
  Widget _buildWalletTab() {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<WalletProvider>(
      builder: (context, walletProvider, _) {
        List<dynamic> currentList = [];
        if (_walletSubTab == 0) {
          currentList = walletProvider.activeCoupons;
        } else if (_walletSubTab == 1) {
          currentList = walletProvider.usedCoupons;
        } else {
          currentList = walletProvider.expiredCoupons;
        }

        return RefreshIndicator(
          onRefresh: () async {
            await walletProvider.fetchWallet();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.darkAmberAccent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                  Icons.confirmation_number_rounded,
                                  color: AppColors.darkSlateSurface,
                                  size: 22),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              loc.tr('wallet_title'),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.darkAmberAccent
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${currentList.length} ${loc.isArabic ? 'كوبون' : 'coupons'}',
                            style: const TextStyle(
                              color: AppColors.darkAmberAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Sub-Tab Switcher Pills
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSlateCard : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isDark
                                ? AppColors.darkSlateBorder
                                : AppColors.borderGrey),
                      ),
                      child: Row(
                        children: [
                          _buildWalletSubTabPill(0,
                              '${loc.tr('tab_active')} (${walletProvider.activeCoupons.length})'),
                          _buildWalletSubTabPill(1,
                              '${loc.tr('tab_used')} (${walletProvider.usedCoupons.length})'),
                          _buildWalletSubTabPill(2,
                              '${loc.tr('tab_expired')} (${walletProvider.expiredCoupons.length})'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Coupons List
                    if (walletProvider.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(
                              color: AppColors.darkAmberAccent),
                        ),
                      )
                    else if (currentList.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(36),
                        decoration: BoxDecoration(
                          color:
                              isDark ? AppColors.darkSlateCard : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isDark
                                  ? AppColors.darkSlateBorder
                                  : AppColors.borderGrey),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.confirmation_number_outlined,
                                  color: AppColors.darkTextSecondary, size: 48),
                              const SizedBox(height: 10),
                              Text(
                                loc.tr('no_coupons_in_tab'),
                                style: const TextStyle(
                                    color: AppColors.darkTextSecondary,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: currentList.length,
                        itemBuilder: (context, index) {
                          final coupon = currentList[index];
                          final isActive = _walletSubTab == 0;
                          final isUsed = _walletSubTab == 1;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSlateCard
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isActive
                                    ? AppColors.darkAmberAccent
                                        .withValues(alpha: 0.5)
                                    : (isDark
                                        ? AppColors.darkSlateBorder
                                        : AppColors.borderGrey),
                              ),
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
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        coupon['store_name'] ??
                                            coupon['store'] ??
                                            'Candela Partner Store',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? AppColors.successGreen
                                                .withValues(alpha: 0.15)
                                            : (isUsed
                                                ? Colors.grey
                                                    .withValues(alpha: 0.2)
                                                : AppColors.errorRed
                                                    .withValues(alpha: 0.15)),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isActive
                                            ? loc.tr('tab_active')
                                            : (isUsed
                                                ? loc.tr('tab_used')
                                                : loc.tr('tab_expired')),
                                        style: TextStyle(
                                          color: isActive
                                              ? AppColors.successGreen
                                              : (isUsed
                                                  ? Colors.grey
                                                  : AppColors.errorRed),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  coupon['title'] ?? 'قسيمة تخفيض خاصة',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white70
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${loc.tr('expires_at')} ${coupon['expires'] ?? '2026-12-31'}',
                                      style: const TextStyle(
                                          color: AppColors.darkTextSecondary,
                                          fontSize: 11.5),
                                    ),
                                    if (coupon['code'] != null)
                                      Text(
                                        coupon['code'],
                                        style: const TextStyle(
                                          color: AppColors.darkAmberAccent,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                        ),
                                      ),
                                  ],
                                ),
                                if (isActive) ...[
                                  const SizedBox(height: 14),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          AppColors.darkAmberAccent,
                                      foregroundColor:
                                          AppColors.darkSlateSurface,
                                      minimumSize: const Size.fromHeight(42),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                    icon: const Icon(Icons.qr_code_2_rounded,
                                        size: 18),
                                    label: Text(
                                      loc.tr('show_qr_code'),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                    ),
                                    onPressed: () => _openQrModalSheet(
                                        initialCoupon: coupon),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
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

  Widget _buildWalletSubTabPill(int tabIndex, String label) {
    final isSelected = _walletSubTab == tabIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _walletSubTab = tabIndex),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.darkAmberAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? AppColors.darkSlateSurface
                  : (isDark ? Colors.white70 : AppColors.textPrimary),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 4: PROFILE & SETTINGS (القائمة)
  // ---------------------------------------------------------------------------
  Widget _buildProfileTab(dynamic user, AuthProvider auth) {
    final loc = AppLocalizations.of(context);
    final theme = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final points = user?.loyaltyPoints ?? 250;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSlateCard : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                      color: isDark
                          ? AppColors.darkSlateBorder
                          : AppColors.borderGrey),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.darkAmberAccent,
                      child: Text(
                        user?.name.isNotEmpty == true
                            ? user!.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkSlateSurface),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'عميل كانديلا',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? user?.phone ?? 'user@candela.app',
                            style: const TextStyle(
                                color: AppColors.darkTextSecondary,
                                fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.darkAmberAccent
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              points >= 500
                                  ? loc.tr('tier_gold')
                                  : loc.tr('tier_silver'),
                              style: const TextStyle(
                                color: AppColors.darkAmberAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Loyalty Rewards Gold Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.darkAmberAccent, AppColors.copperOrange],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.darkAmberAccent.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc.tr('loyalty_center'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                        const Icon(Icons.star_rounded,
                            color: Colors.white, size: 24),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$points',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900),
                    ),
                    Text(
                      loc.tr('candela_points'),
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (points / 500.0).clamp(0.0, 1.0),
                        backgroundColor: Colors.white30,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Profile & Security Actions
              _buildSectionHeader(loc.isArabic
                  ? 'إعدادات الحساب والأمان'
                  : 'Account & Security Settings'),
              _buildSettingsTile(
                icon: Icons.edit_note_rounded,
                title: loc.tr('edit_profile'),
                onTap: () => EditProfileDialog.show(context),
              ),
              _buildSettingsTile(
                icon: Icons.lock_outline_rounded,
                title: loc.tr('change_password'),
                onTap: () => ChangePasswordDialog.show(context),
              ),

              const SizedBox(height: 16),
              // App Preferences
              _buildSectionHeader(
                  loc.isArabic ? 'تفضيلات التطبيق' : 'App Preferences'),
              // Dark Mode Toggle
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSlateCard : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: isDark
                          ? AppColors.darkSlateBorder
                          : AppColors.borderGrey),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.dark_mode_rounded,
                            color: AppColors.darkAmberAccent, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          loc.tr('dark_mode'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: theme.isDarkMode,
                      activeThumbColor: AppColors.darkAmberAccent,
                      onChanged: (val) => theme.toggleTheme(),
                    ),
                  ],
                ),
              ),

              // Language Switcher
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSlateCard : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: isDark
                          ? AppColors.darkSlateBorder
                          : AppColors.borderGrey),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.translate_rounded,
                            color: AppColors.darkAmberAccent, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          loc.tr('language'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => localeProvider.toggleLocale(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color:
                              AppColors.darkAmberAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.darkAmberAccent),
                        ),
                        child: Text(
                          localeProvider.isArabic ? 'English' : 'العربية',
                          style: const TextStyle(
                              color: AppColors.darkAmberAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Customer Support Ghost Button
              _buildSettingsTile(
                icon: Icons.support_agent_rounded,
                title: loc.tr('customer_support'),
                color: AppColors.successGreen,
                onTap: () => _showCustomerSupportSheet(context),
              ),

              // Switch to Merchant Portal (if eligible)
              if (auth.isMerchantAccount) ...[
                const SizedBox(height: 8),
                _buildSettingsTile(
                  icon: Icons.storefront_rounded,
                  title: loc.tr('switch_to_merchant'),
                  color: AppColors.darkAmberAccent,
                  onTap: () => auth.switchRole('merchant'),
                ),
              ],

              const SizedBox(height: 16),
              // Logout Button
              _buildSettingsTile(
                icon: Icons.logout_rounded,
                title: loc.tr('logout'),
                color: AppColors.errorRed,
                onTap: () => auth.logout(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    Color? color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemColor = color ?? (isDark ? Colors.white : AppColors.textPrimary);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSlateCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.darkSlateBorder : AppColors.borderGrey),
      ),
      child: ListTile(
        leading:
            Icon(icon, color: color ?? AppColors.darkAmberAccent, size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: itemColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: isDark ? Colors.white38 : Colors.black38),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          if (onSeeAll != null)
            InkWell(
              onTap: onSeeAll,
              child: Text(
                loc.tr('see_all'),
                style: const TextStyle(
                  color: AppColors.darkAmberAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
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
        return Consumer<CustomerFeedProvider>(
          builder: (context, feedProvider, _) {
            final offers = feedProvider.offers
                .where((o) =>
                    o.campaignId == campaign.id ||
                    o.storeName == campaign.storeName)
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: AppColors.darkSlateSurface,
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
                          color: Colors.white30,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    campaign.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    campaign.storeName,
                    style: const TextStyle(
                        color: AppColors.darkAmberAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: offers.isEmpty
                        ? const Center(
                            child: Text('لا توجد عروض مخصصة لهذه الحملة حالياً',
                                style: TextStyle(color: Colors.white60)),
                          )
                        : ListView.builder(
                            itemCount: offers.length,
                            itemBuilder: (context, idx) {
                              final offer = offers[idx];
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
        return Consumer<CustomerFeedProvider>(
          builder: (context, feedProvider, _) {
            final storeOffers = feedProvider.offers
                .where((o) =>
                    o.storeName.toLowerCase() ==
                    storeName.toString().toLowerCase())
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: AppColors.darkSlateSurface,
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
                          color: Colors.white30,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.darkAmberAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.storefront_rounded,
                            color: AppColors.darkSlateSurface, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              storeName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              address,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'كوبونات وعروض المتجر المتاحة',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: storeOffers.isEmpty
                        ? const Center(
                            child: Text(
                                'لا توجد كوبونات مخصصة لهذا المتجر حالياً.',
                                style: TextStyle(
                                    color: Colors.white60, fontSize: 13)),
                          )
                        : ListView.builder(
                            itemCount: storeOffers.length,
                            itemBuilder: (context, index) {
                              final offer = storeOffers[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
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
        );
      },
    );
  }
}
