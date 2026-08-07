import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/merchant_provider.dart';
import 'merchant_dashboard_screen.dart';
import 'manage_offers_screen.dart';
import 'launch_offer_screen.dart';
import 'qr_scanner_screen.dart';

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
                'قنديل للشركاء والتجار',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          actions: [
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
                user?.name ?? 'متجر قنديل الشريك',
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
}
