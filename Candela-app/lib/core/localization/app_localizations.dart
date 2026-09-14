import 'package:flutter/material.dart';

/// Bilingual localization manager providing Arabic & English strings.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('ar'));
  }

  bool get isArabic => locale.languageCode == 'ar';
  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  static final Map<String, Map<String, String>> _localizedValues = {
    'ar': {
      // Navigation
      'nav_explore': 'استكشف',
      'nav_stores': 'قريب منك',
      'nav_qr': 'كود الاستخدام',
      'nav_wallet': 'المحفظة',
      'nav_profile': 'القائمة',
      'merchant_dashboard': 'الرئيسية',
      'merchant_offers': 'إدارة العروض',
      'merchant_scanner': 'مسح الكود',
      'merchant_ledger': 'سجل الاسترداد',
      'merchant_settings': 'الإعدادات',

      // Home & Search
      'search_placeholder': 'ابحث عن العروض، المتاجر، الكوبونات...',
      'exclusive_promos': 'العروض الترويجية المميزة ✦',
      'featured_stores': 'المتاجر المتميزة وفروعها',
      'top_offers': 'أبرز العروض',
      'see_all': 'عرض الكل',
      'claim_coupon': 'احجز الكوبون',
      'add_to_wallet': 'إضافة إلى المحفظة',
      'coupon_claimed': 'تمت الإضافة للمحفظة بنجاح!',
      'active_campaign': 'حملة نشطة',
      'expires_in': 'ينتهي خلال',
      'days': 'أيام',
      'no_active_campaigns': 'لا توجد حملات نشطة حالياً',
      'no_active_offers': 'لا توجد عروض نشطة حالياً',

      // Near You / Stores
      'stores_title': 'المتاجر والشركاء بالقرب منك',
      'open_hours': 'ساعات العمل',
      'km_away': 'كم بالقرب منك',
      'view_offers': 'عروض المتجر',
      'no_stores_found': 'لا توجد متاجر مطابقة لبحثك',

      // QR Pass & Bottom Sheet
      'qr_pass_title': 'رمز الاستخدام الفوري',
      'qr_pass_subtitle':
          'أظهر هذا الرمز عند نقطة البيع بالمتجر. يتجدد الرمز تلقائياً كل 45 ثانية لمنع الاحتيال.',
      'qr_anti_fraud_badge': 'رمز مشفر ومحمي ضد لقطات الشاشة (HMAC-SHA256)',
      'qr_refreshing_in': 'يتجدد الكود خلال',
      'seconds': 'ثانية',
      'qr_refresh_now': 'تحديث الرمز الآن',
      'no_active_coupon_selected': 'لا يوجد كوبون نشط محدد',
      'select_coupon_from_wallet':
          'اختر كوبوناً نشطاً من محفظتك لإظهار كود الاستخدام.',

      // Wallet
      'wallet_title': 'محفظة الكوبونات',
      'tab_active': 'النشطة',
      'tab_used': 'المستعملة',
      'tab_expired': 'المنتهية',
      'show_qr_code': 'عرض كود الاستخدام',
      'redeemed_at': 'تم الاسترداد في:',
      'expires_at': 'تاريخ الانتهاء:',
      'no_coupons_in_tab': 'لا توجد كوبونات في هذا القسم',

      // Profile & Rewards
      'profile_title': 'الملف الشخصي والإعدادات',
      'loyalty_center': 'مركز النقاط والمكافآت',
      'current_points': 'رصيد نقاطك الحالي',
      'candela_points': 'نقطة كانديلا',
      'tier_gold': 'المستوى الذهبي',
      'tier_silver': 'المستوى الفضي',
      'earn_shopping': 'تسوق من المتاجر',
      'earn_coupons': 'استخدم الكوبونات',
      'earn_invite': 'دعوة الأصدقاء',
      'redeem_points': 'استبدال النقاط بمكافآت',
      'edit_profile': 'تعديل البيانات الشخصية',
      'change_password': 'تغيير كلمة المرور',
      'customer_support': 'خدمة العملاء والدعم الفني',
      'dark_mode': 'الوضع الداكن (Night Mode)',
      'language': 'اللغة (Language)',
      'switch_to_merchant': 'التبديل إلى واجهة التاجر',
      'logout': 'تسجيل الخروج',

      // Edit Profile & Password
      'full_name': 'الاسم الكامل',
      'email': 'البريد الإلكتروني',
      'phone': 'رقم الهاتف',
      'current_password': 'كلمة المرور الحالية',
      'new_password': 'كلمة المرور الجديدة',
      'confirm_password': 'تأكيد كلمة المرور الجديدة',
      'save_changes': 'حفظ التغييرات',
      'cancel': 'إلغاء',
      'password_changed_success': 'تم تغيير كلمة المرور بنجاح!',
      'profile_updated_success': 'تم تحديث البيانات بنجاح!',

      // Merchant
      'merchant_portal': 'واجهة للشركاء والتجار',
      'total_redemptions': 'إجمالي عمليات الاسترداد',
      'total_fees_charged': 'إجمالي الرسوم المقتطعة',
      'today_redemptions': 'استردادات اليوم',
      'wallet_balance': 'رصيد المحفظة المتاح',
      'charge_wallet': 'شحن المحفظة',
      'redemption_ledger_title': 'سجل الاسترداد والمحاسبة',
      'customer': 'العميل',
      'branch': 'الفرع',
      'points_awarded': 'النقاط الممنوحة',
      'fee_charged': 'الرسوم المقتطعة',
      'filter_branch': 'تصفية حسب الفرع',
      'all_branches': 'جميع الفروع',
      'scan_qr_title': 'مسح رمز الاستخدام QR',
      'scan_instructions':
          'وجّه الكاميرا نحو كود العميل للتحقق الفوري والخصم الآلي.',
      'enter_code_manually': 'أو أدخل كود الكوبون يدوياً',
      'verify_button': 'تحقق واخصم',
      'verification_success': 'تم التحقق والاسترداد بنجاح!',
      'verification_failed': 'فشلت عملية التحقق',
    },
    'en': {
      // Navigation
      'nav_explore': 'Explore',
      'nav_stores': 'Near You',
      'nav_qr': 'QR Pass',
      'nav_wallet': 'Wallet',
      'nav_profile': 'Profile',
      'merchant_dashboard': 'Dashboard',
      'merchant_offers': 'Manage Offers',
      'merchant_scanner': 'Scan QR',
      'merchant_ledger': 'Ledger',
      'merchant_settings': 'Settings',

      // Home & Search
      'search_placeholder': 'Search offers, stores, coupons...',
      'exclusive_promos': 'Exclusive Campaigns ✦',
      'featured_stores': 'Featured Partner Stores',
      'top_offers': 'Top Offers',
      'see_all': 'See All',
      'claim_coupon': 'Claim Coupon',
      'add_to_wallet': 'Add to Wallet',
      'coupon_claimed': 'Successfully added to wallet!',
      'active_campaign': 'Active Campaign',
      'expires_in': 'Expires in',
      'days': 'days',
      'no_active_campaigns': 'No active campaigns right now',
      'no_active_offers': 'No active offers right now',

      // Near You / Stores
      'stores_title': 'Partner Stores Near You',
      'open_hours': 'Operating Hours',
      'km_away': 'km away',
      'view_offers': 'Store Offers',
      'no_stores_found': 'No stores match your search',

      // QR Pass & Bottom Sheet
      'qr_pass_title': 'Dynamic Single-Use Pass',
      'qr_pass_subtitle':
          'Present this pass at merchant checkout. Token auto-refreshes every 45 seconds to prevent screenshot fraud.',
      'qr_anti_fraud_badge': 'HMAC-SHA256 Encrypted & Anti-Fraud Protected',
      'qr_refreshing_in': 'Auto-refreshing in',
      'seconds': 's',
      'qr_refresh_now': 'Refresh Pass Now',
      'no_active_coupon_selected': 'No Active Coupon Selected',
      'select_coupon_from_wallet':
          'Select an active coupon from your wallet to generate QR pass.',

      // Wallet
      'wallet_title': 'Coupon Wallet',
      'tab_active': 'Active',
      'tab_used': 'Used',
      'tab_expired': 'Expired',
      'show_qr_code': 'Show QR Pass',
      'redeemed_at': 'Redeemed on:',
      'expires_at': 'Expires on:',
      'no_coupons_in_tab': 'No coupons in this category',

      // Profile & Rewards
      'profile_title': 'Profile & Settings',
      'loyalty_center': 'Loyalty & Rewards Center',
      'current_points': 'Current Loyalty Balance',
      'candela_points': 'Candela Points',
      'tier_gold': 'Gold Tier',
      'tier_silver': 'Silver Tier',
      'earn_shopping': 'Shop at Stores',
      'earn_coupons': 'Redeem Coupons',
      'earn_invite': 'Invite Friends',
      'redeem_points': 'Redeem Points for Rewards',
      'edit_profile': 'Edit Profile Details',
      'change_password': 'Change Password',
      'customer_support': 'Customer Support & Helpdesk',
      'dark_mode': 'Night Mode (Dark Theme)',
      'language': 'Language (اللغة)',
      'switch_to_merchant': 'Switch to Merchant Portal',
      'logout': 'Log Out',

      // Edit Profile & Password
      'full_name': 'Full Name',
      'email': 'Email Address',
      'phone': 'Phone Number',
      'current_password': 'Current Password',
      'new_password': 'New Password',
      'confirm_password': 'Confirm New Password',
      'save_changes': 'Save Changes',
      'cancel': 'Cancel',
      'password_changed_success': 'Password changed successfully!',
      'profile_updated_success': 'Profile updated successfully!',

      // Merchant
      'merchant_portal': 'Partner & Merchant Terminal',
      'total_redemptions': 'Total Redemptions',
      'total_fees_charged': 'Total Fees Deducted',
      'today_redemptions': "Today's Redemptions",
      'wallet_balance': 'Available Balance',
      'charge_wallet': 'Top Up Balance',
      'redemption_ledger_title': 'Redemption Audit Ledger',
      'customer': 'Customer',
      'branch': 'Branch',
      'points_awarded': 'Points Awarded',
      'fee_charged': 'Fee Deducted',
      'filter_branch': 'Filter by Branch',
      'all_branches': 'All Branches',
      'scan_qr_title': 'Scan Customer QR Pass',
      'scan_instructions':
          'Point the camera at customer QR pass for instant atomic redemption.',
      'enter_code_manually': 'Or enter coupon token manually',
      'verify_button': 'Verify & Redeem',
      'verification_success': 'Verified and Redeemed Successfully!',
      'verification_failed': 'Verification Failed',
    }
  };

  String tr(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['ar']?[key] ??
        key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
