import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/merchant_provider.dart';

/// Merchant Store QR Screen
/// The merchant displays this QR at checkout — the customer scans it to redeem a coupon.
class MerchantStoreQrScreen extends StatefulWidget {
  const MerchantStoreQrScreen({super.key});

  @override
  State<MerchantStoreQrScreen> createState() => _MerchantStoreQrScreenState();
}

class _MerchantStoreQrScreenState extends State<MerchantStoreQrScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  Timer? _pollTimer;
  bool _hasNewRedemption = false;
  int _lastRedemptionCount = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final m = Provider.of<MerchantProvider>(context, listen: false);
      m.fetchStoreQrData();
      m.fetchRedemptionHistory().then((_) {
        _lastRedemptionCount =
            (m.historySummary['total_redemptions'] ?? 0) as int;
      });
    });

    // Poll every 15s for new redemptions
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      final m = Provider.of<MerchantProvider>(context, listen: false);
      m.fetchRedemptionHistory().then((_) {
        if (!mounted) return;
        final newCount = (m.historySummary['total_redemptions'] ?? 0) as int;
        if (newCount > _lastRedemptionCount) {
          _lastRedemptionCount = newCount;
          setState(() => _hasNewRedemption = true);
          HapticFeedback.mediumImpact();
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) setState(() => _hasNewRedemption = false);
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MerchantProvider>(
      builder: (context, merchant, _) {
        final qrData = merchant.storeQrData;
        final isLoading = merchant.isLoadingStoreQr;
        final qrPayload = qrData['qr_data'] as String?;
        final storeName = (qrData['store_name'] as String?) ?? merchant.storeName;
        final balance =
            (qrData['wallet_balance'] as num?)?.toDouble() ?? merchant.walletBalance;
        final redemptionFee = (qrData['redemption_fee'] as num?)?.toDouble() ?? 5.0;
        final totalRedemptions =
            merchant.historySummary['total_redemptions'] ?? merchant.totalRedemptions;
        final todayRedemptions = merchant.historySummary['today_redemptions'] ?? 0;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: AppColors.darkBackground,
            body: RefreshIndicator(
              color: AppColors.primaryAmber,
              backgroundColor: AppColors.darkSlateCard,
              onRefresh: () async {
                await merchant.fetchStoreQrData();
                await merchant.fetchRedemptionHistory();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [
                              AppColors.primaryAmber,
                              AppColors.copperOrange,
                            ]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.store_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'رمز QR المتجر',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(storeName,
                                  style: const TextStyle(
                                    color: AppColors.darkTextSecondary,
                                    fontSize: 12,
                                  )),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            merchant.fetchStoreQrData();
                            merchant.fetchRedemptionHistory();
                          },
                          icon: const Icon(Icons.refresh_rounded,
                              color: AppColors.primaryAmber),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // New Redemption Alert
                    if (_hasNewRedemption)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.successGreen, width: 1.5),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: AppColors.successGreen, size: 22),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'تم استرداد كوبون جديد! ✅',
                                style: TextStyle(
                                  color: AppColors.successGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // QR Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 32, horizontal: 24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.primaryAmber.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryAmber.withValues(alpha: 0.07),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Pill label
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAmber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.primaryAmber
                                      .withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.touch_app_rounded,
                                    color: AppColors.primaryAmber, size: 15),
                                SizedBox(width: 6),
                                Text(
                                  'وجّه العميل لمسح هذا الرمز',
                                  style: TextStyle(
                                    color: AppColors.primaryAmber,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // QR Code widget
                          if (isLoading)
                            Container(
                              width: 240,
                              height: 240,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primaryAmber),
                              ),
                            )
                          else if (qrPayload != null && qrPayload.isNotEmpty)
                            ScaleTransition(
                              scale: _pulseAnim,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryAmber
                                          .withValues(alpha: 0.22),
                                      blurRadius: 24,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: QrImageView(
                                  data: qrPayload,
                                  version: QrVersions.auto,
                                  size: 210,
                                  eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: Color(0xFF0F172A),
                                  ),
                                  dataModuleStyle: const QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            )
                          else
                            Column(
                              children: [
                                const Icon(Icons.qr_code_2_rounded,
                                    color: AppColors.darkTextSecondary,
                                    size: 80),
                                const SizedBox(height: 12),
                                const Text('لم يتم تحميل رمز QR',
                                    style: TextStyle(
                                        color: AppColors.darkTextSecondary)),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: merchant.fetchStoreQrData,
                                  icon: const Icon(Icons.refresh_rounded,
                                      size: 18),
                                  label: const Text('إعادة المحاولة'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryAmber,
                                    foregroundColor: AppColors.darkSlateSurface,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 20),
                          Text(storeName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 4),
                          Text(
                            'رسوم الاسترداد: ${redemptionFee.toStringAsFixed(2)} د.ل / كوبون',
                            style: const TextStyle(
                              color: AppColors.darkTextSecondary,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Status pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.successGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.successGreen
                                      .withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.successGreen,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'جاهز للاسترداد',
                                  style: TextStyle(
                                    color: AppColors.successGreen,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _stat(
                            'رصيد المحفظة',
                            '${balance.toStringAsFixed(2)} د.ل',
                            Icons.account_balance_wallet_rounded,
                            AppColors.primaryAmber,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _stat(
                            'اليوم',
                            '$todayRedemptions',
                            Icons.today_rounded,
                            AppColors.successGreen,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _stat(
                            'الإجمالي',
                            '$totalRedemptions',
                            Icons.receipt_long_rounded,
                            AppColors.copperOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // How it works
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.darkSlateCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.darkSlateBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  color: AppColors.primaryAmber, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'كيف يعمل؟',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _step('1', 'اعرض هذا الرمز للعميل عند الدفع.'),
                          _step('2',
                              'العميل يفتح تطبيق كانديلا ويضغط زر المسح.'),
                          _step('3',
                              'يختار الكوبون ويؤكد الاسترداد.'),
                          _step('4',
                              'تصلك إشعار فوري بتفاصيل الكوبون المستبدل.'),
                        ],
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

  Widget _stat(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.darkSlateCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkSlateBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 11),
              textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(title,
              style: const TextStyle(
                  color: AppColors.darkTextSecondary, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _step(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.primaryAmber.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.primaryAmber.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Text(num,
                  style: const TextStyle(
                    color: AppColors.primaryAmber,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  )),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 12,
                    height: 1.5)),
          ),
        ],
      ),
    );
  }
}

