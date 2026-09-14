import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/wallet_provider.dart';

/// Customer Scan Merchant QR Screen
/// Customer points their camera at the Merchant Store QR Code, selects
/// an active coupon, and confirms redemption with one tap.
class CustomerScanMerchantScreen extends StatefulWidget {
  const CustomerScanMerchantScreen({super.key});

  @override
  State<CustomerScanMerchantScreen> createState() =>
      _CustomerScanMerchantScreenState();
}

class _CustomerScanMerchantScreenState
    extends State<CustomerScanMerchantScreen> {
  MobileScannerController? _cameraController;
  final TextEditingController _manualCtrl = TextEditingController();

  bool _scannerActive = true;
  bool _processing = false;
  String? _scannedQrData; // raw base64 store QR payload
  String? _storeName;
  dynamic _selectedCoupon;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_scannerActive || _processing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    _handleScannedPayload(raw);
  }

  Map<String, dynamic>? _decodeStoreQrPayload(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    for (final candidate in [trimmed, trimmed.replaceAll(RegExp(r'\s+'), '')]) {
      try {
        final decoded = jsonDecode(utf8.decode(base64Decode(candidate)));
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}

      try {
        final decoded = jsonDecode(candidate);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }

    return null;
  }

  void _handleScannedPayload(String raw) {
    if (_processing) return;

    final payload = _decodeStoreQrPayload(raw);
    if (payload == null ||
        payload['type'] != 'store' ||
        payload['store_id'] == null) {
      _showErrorSheet('رمز QR للمتجر غير صالح أو تالف.');
      return;
    }

    setState(() {
      _scannedQrData = raw.trim();
      _storeName = payload['store_name'] as String?;
      _scannerActive = false;
    });
    _showCouponSelectionSheet();
  }

  void _showCouponSelectionSheet() {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final activeCoupons = walletProvider.activeCoupons;

    if (activeCoupons.isEmpty) {
      _showNoActiveCouponsSheet();
      return;
    }

    // Pre-select first coupon
    _selectedCoupon = activeCoupons.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (ctx) => _CouponSelectSheet(
        activeCoupons: activeCoupons,
        storeName: _storeName ?? 'المتجر',
        onCouponSelected: (coupon) => setState(() => _selectedCoupon = coupon),
        onConfirm: () {
          Navigator.pop(ctx);
          _redeemCoupon();
        },
        onCancel: () {
          Navigator.pop(ctx);
          setState(() {
            _scannerActive = true;
            _scannedQrData = null;
          });
        },
      ),
    );
  }

  void _showNoActiveCouponsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: const BoxDecoration(
            color: AppColors.darkSlateCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.confirmation_number_outlined,
                  color: AppColors.darkTextSecondary, size: 56),
              const SizedBox(height: 16),
              const Text(
                'لا يوجد كوبونات نشطة',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'احصل على كوبونات من صفحة استكشف أولاً.',
                style: TextStyle(color: AppColors.darkTextSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _scannerActive = true;
                    _scannedQrData = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAmber,
                  foregroundColor: AppColors.darkSlateSurface,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('حسناً',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _redeemCoupon() async {
    if (_scannedQrData == null || _selectedCoupon == null) return;

    final couponIdRaw = _selectedCoupon['coupon_id'];
    final couponId = couponIdRaw is int
        ? couponIdRaw
        : int.tryParse(couponIdRaw?.toString() ?? '');
    if (couponId == null || couponId <= 0) {
      _showErrorSheet('معرّف الكوبون غير صالح.');
      return;
    }

    setState(() => _processing = true);

    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    final result = await walletProvider.redeemCouponAtStore(
      storeQrData: _scannedQrData!,
      couponId: couponId,
    );

    if (!mounted) return;
    setState(() => _processing = false);

    if (result['success'] == true) {
      _showSuccessSheet(result['data']);
    } else {
      _showErrorSheet(result['message'] ?? 'فشل الاسترداد');
    }
  }

  void _showSuccessSheet(Map<String, dynamic>? data) {
    final redemption = data?['redemption'] as Map<String, dynamic>? ?? {};
    final customer = data?['customer'] as Map<String, dynamic>? ?? {};
    final couponTitle = redemption['coupon_title'] as String? ??
        _selectedCoupon?['title'] as String? ??
        'كوبون خصم';
    final discountType = redemption['discount_type'] as String? ?? 'percentage';
    final discountValue =
        (redemption['discount_value'] as num?)?.toDouble() ?? 0.0;
    final pointsAwarded = redemption['points_awarded'] as int?;
    final storeName =
        redemption['store_name'] as String? ?? _storeName ?? 'المتجر';
    final newPoints = customer['new_loyalty_points'] as int?;

    final discountLabel = discountType == 'percentage'
        ? '${discountValue.toStringAsFixed(0)}% خصم'
        : '${discountValue.toStringAsFixed(2)} د.ل خصم';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: AppColors.successGreen, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(height: 20),
              // Success Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.successGreen, width: 2),
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppColors.successGreen, size: 40),
              ),
              const SizedBox(height: 14),
              const Text(
                'تم الاسترداد بنجاح! 🎉',
                style: TextStyle(
                  color: AppColors.successGreen,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                storeName,
                style: const TextStyle(
                    color: AppColors.darkTextSecondary, fontSize: 14),
              ),
              const SizedBox(height: 20),
              // Coupon Detail Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.darkSlateSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.darkSlateBorder),
                ),
                child: Column(
                  children: [
                    _successRow(Icons.confirmation_number_rounded, 'الكوبون',
                        couponTitle, AppColors.primaryAmber),
                    const Divider(color: AppColors.darkSlateBorder, height: 20),
                    _successRow(Icons.discount_rounded, 'الخصم المطبق',
                        discountLabel, AppColors.successGreen),
                    if (pointsAwarded != null) ...[
                      const Divider(
                          color: AppColors.darkSlateBorder, height: 20),
                      _successRow(Icons.stars_rounded, 'نقاط مكتسبة',
                          '+$pointsAwarded نقطة', AppColors.primaryAmber),
                    ],
                    if (newPoints != null) ...[
                      const Divider(
                          color: AppColors.darkSlateBorder, height: 20),
                      _successRow(
                          Icons.account_balance_wallet_rounded,
                          'رصيد النقاط',
                          '$newPoints نقطة',
                          AppColors.copperOrange),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.successGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text(
                  'ممتاز! العودة للرئيسية',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _scannerActive = true;
          _scannedQrData = null;
          _selectedCoupon = null;
        });
      }
    });
  }

  void _showErrorSheet(String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.darkSlateCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: AppColors.errorRed, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.errorRed, size: 52),
              const SizedBox(height: 12),
              const Text(
                'فشل الاسترداد',
                style: TextStyle(
                    color: AppColors.errorRed,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                    color: AppColors.darkTextSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _scannerActive = true;
                    _scannedQrData = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorRed,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('حاول مجدداً',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      if (mounted) setState(() => _scannerActive = true);
    });
  }

  Widget _successRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.darkTextSecondary, fontSize: 13)),
        ),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: AppColors.darkSlateSurface,
          elevation: 0,
          title: const Text(
            'مسح رمز QR المتجر',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            // Camera View
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  if (_scannerActive)
                    MobileScanner(
                      controller: _cameraController,
                      onDetect: _onDetect,
                    )
                  else
                    Container(
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primaryAmber),
                      ),
                    ),

                  // Scanner overlay
                  if (_scannerActive)
                    Center(
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppColors.primaryAmber, width: 2.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),

                  // Label above frame
                  if (_scannerActive)
                    Positioned(
                      top: 40,
                      left: 0,
                      right: 0,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'وجّه الكاميرا نحو رمز QR المعلق في المتجر',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                  // Processing overlay
                  if (_processing)
                    Container(
                      color: Colors.black.withValues(alpha: 0.7),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                                color: AppColors.primaryAmber),
                            SizedBox(height: 16),
                            Text('جاري المعالجة...',
                                style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Manual entry area
            Container(
              color: AppColors.darkSlateSurface,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'أو أدخل كود المتجر يدوياً',
                    style: TextStyle(
                        color: AppColors.darkTextSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'أدخل كود المتجر...',
                            hintStyle: const TextStyle(
                                color: AppColors.darkTextSecondary),
                            filled: true,
                            fillColor: AppColors.darkSlateCard,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.qr_code_2_rounded,
                                color: AppColors.primaryAmber),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          final val = _manualCtrl.text.trim();
                          if (val.isNotEmpty) {
                            _handleScannedPayload(val);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAmber,
                          foregroundColor: AppColors.darkSlateSurface,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('تحقق',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Coupon selection bottom sheet
class _CouponSelectSheet extends StatefulWidget {
  final List<dynamic> activeCoupons;
  final String storeName;
  final ValueChanged<dynamic> onCouponSelected;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _CouponSelectSheet({
    required this.activeCoupons,
    required this.storeName,
    required this.onCouponSelected,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<_CouponSelectSheet> createState() => _CouponSelectSheetState();
}

class _CouponSelectSheetState extends State<_CouponSelectSheet> {
  late dynamic _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.activeCoupons.first;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
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
            // Handle
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(height: 16),
            // Title
            Row(
              children: [
                const Icon(Icons.store_rounded,
                    color: AppColors.primaryAmber, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'اختر كوبون للاسترداد',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      Text(widget.storeName,
                          style: const TextStyle(
                              color: AppColors.darkTextSecondary,
                              fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Coupon list
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.35,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.activeCoupons.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final c = widget.activeCoupons[i];
                  final isSelected = c == _selected;
                  final title = c['title'] ?? 'كوبون خصم';
                  final storeName = c['store_name'] ?? c['store'] ?? '';
                  final discount = c['discount'] ?? '';
                  final expires = c['expires'] ?? c['expires_at'] ?? '';

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selected = c);
                      widget.onCouponSelected(c);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryAmber.withValues(alpha: 0.1)
                            : AppColors.darkSlateCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryAmber
                              : AppColors.darkSlateBorder,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAmber
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.confirmation_number_rounded,
                                color: AppColors.primaryAmber, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                if (storeName.isNotEmpty)
                                  Text(storeName,
                                      style: const TextStyle(
                                          color: AppColors.darkTextSecondary,
                                          fontSize: 11)),
                                if (discount.isNotEmpty)
                                  Text(discount,
                                      style: const TextStyle(
                                          color: AppColors.primaryAmber,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          if (expires.isNotEmpty)
                            Text(
                              'ينتهي: $expires',
                              style: const TextStyle(
                                  color: AppColors.darkTextSecondary,
                                  fontSize: 10),
                            ),
                          const SizedBox(width: 8),
                          Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isSelected
                                ? AppColors.primaryAmber
                                : AppColors.darkTextSecondary,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Confirm Button
            ElevatedButton(
              onPressed: widget.onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAmber,
                foregroundColor: AppColors.darkSlateSurface,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text(
                'تطبيق الخصم والاسترداد',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: widget.onCancel,
              child: const Text(
                'إلغاء',
                style: TextStyle(color: AppColors.darkTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
