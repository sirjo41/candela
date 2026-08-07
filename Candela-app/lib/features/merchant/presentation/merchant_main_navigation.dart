import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/merchant_provider.dart';
import 'merchant_dashboard_screen.dart';
import 'manage_offers_screen.dart';
import 'launch_offer_screen.dart';
import 'qr_scanner_screen.dart';
import '../../notifications/providers/notification_provider.dart';

/// Main Navigation Scaffold for Merchant / Store Owner App
/// Integrates Dashboard (WA0001), Manage Offers & Analytics, Launch Offer (WA0014), and QR Scanner (WA0015) in RTL mode.
class MerchantMainNavigation extends StatefulWidget {
  const MerchantMainNavigation({super.key});

  @override
  State<MerchantMainNavigation> createState() => _MerchantMainNavigationState();
}

class _MerchantMainNavigationState extends State<MerchantMainNavigation> {
  int _currentIndex = 0;

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openLaunchOfferScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LaunchOfferScreen()),
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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: AppColors.darkSlate,
          elevation: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryAmber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.storefront_rounded, color: AppColors.darkBackground, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'واجهة للشركاء والتجار',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          actions: [
            Consumer<NotificationProvider>(
              builder: (context, notifProvider, _) {
                final unread = notifProvider.unreadCount;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        unread > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                        color: unread > 0 ? AppColors.primaryAmber : Colors.white,
                      ),
                      tooltip: 'الإشعارات والإعلانات',
                      onPressed: () {
                        notifProvider.fetchNotifications(role: 'merchant');
                        _showMerchantNotifications(context);
                      },
                    ),
                    if (unread > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: AppColors.errorRed, shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '$unread',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            // Switch back to Customer Mode button
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.primaryAmber),
              tooltip: 'الانتقال إلى واجهة العميل',
              onPressed: () => auth.switchRole('customer'),
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white70),
              tooltip: 'تسجيل الخروج',
              onPressed: () => auth.logout(),
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            // 0. Dashboard (IMG-20260725-WA0001.jpg)
            MerchantDashboardScreen(
              onNavigateTab: _navigateToTab,
              onLaunchOffer: _openLaunchOfferScreen,
            ),

            // 1. Manage Offers & Analytics (إدارة العروض والتحليلات)
            ManageOffersScreen(
              onCreateNewOffer: _openLaunchOfferScreen,
            ),

            // 2. QR Verification Scanner (IMG-20260725-WA0015.jpg)
            const QrScannerScreen(),

            // 3. Wallet & Financial History
            _buildWalletTab(),

            // 4. Settings & Store Profile
            _buildStoreProfileTab(user, auth),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.darkSlate,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _navigateToTab,
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.darkSlate,
            selectedItemColor: AppColors.primaryAmber,
            unselectedItemColor: Colors.white60,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                label: 'الرئيسية',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.campaign_rounded),
                label: 'إدارة العروض',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.qr_code_scanner_rounded),
                label: 'مسح الكود',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_rounded),
                label: 'المحفظة',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_rounded),
                label: 'الإعدادات',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletTab() {
    return Consumer<MerchantProvider>(
      builder: (context, merchant, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'محفظة التاجر والرصيد المنصرف',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                  ),
                  const SizedBox(height: 14),

                  // Wallet Card Surface
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.darkSlate, AppColors.darkBackground],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('الرصيد المتاح حالياً', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 6),
                        Text(
                          '${merchant.walletBalance.toStringAsFixed(2)} د.ل',
                          style: const TextStyle(color: AppColors.primaryAmber, fontWeight: FontWeight.w900, fontSize: 28),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryAmber,
                            foregroundColor: AppColors.darkSlate,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('شحن المحفظة متاح عبر خدمات البنك الإلكتروني.')),
                            );
                          },
                          icon: const Icon(Icons.add_card_rounded, size: 18),
                          label: const Text('شحن المحفظة الآن', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
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

  Widget _buildStoreProfileTab(dynamic user, AuthProvider auth) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              const SizedBox(height: 10),
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primaryAmber,
                child: Text(
                  user?.name != null && user!.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : 'M',
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.darkBackground),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                user?.name ?? 'متجر واجهة الشريك',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
              ),
              const SizedBox(height: 4),
              Text(user?.email ?? user?.phone ?? 'merchant@candela.app', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: AppColors.darkSlate,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('التبديل إلى واجهة العملاء'),
                onPressed: () => auth.switchRole('customer'),
              ),
              const SizedBox(height: 14),

              TextButton.icon(
                icon: const Icon(Icons.logout_rounded, color: AppColors.errorRed),
                label: const Text('تسجيل الخروج', style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold)),
                onPressed: () => auth.logout(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMerchantNotifications(BuildContext context) {
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
                            Icon(Icons.notifications_active_rounded, color: AppColors.primaryAmber),
                            SizedBox(width: 8),
                            Text(
                              'إشعارات وتنبيهات الإدارة',
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
                                          const Icon(Icons.campaign_rounded, color: AppColors.primaryAmber, size: 20),
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
                    color: AppColors.primaryAmber.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.campaign_rounded, color: AppColors.primaryAmber, size: 24),
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
                  backgroundColor: AppColors.primaryAmber,
                  foregroundColor: AppColors.darkSlate,
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
