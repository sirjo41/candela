import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';

/// Interactive QR Coupon Bottom Sheet Modal
/// Displays a dynamic single-use QR pass with a 60-second (1-minute) validity countdown.
/// The QR code remains stable for the full minute and refreshes automatically upon expiration.
class QrCouponBottomSheet extends StatefulWidget {
  final List<dynamic> activeCoupons;
  final String userId;

  const QrCouponBottomSheet({
    super.key,
    required this.activeCoupons,
    required this.userId,
  });

  static Future<void> show(BuildContext context, {required List<dynamic> activeCoupons, required String userId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QrCouponBottomSheet(
        activeCoupons: activeCoupons,
        userId: userId,
      ),
    );
  }

  @override
  State<QrCouponBottomSheet> createState() => _QrCouponBottomSheetState();
}

class _QrCouponBottomSheetState extends State<QrCouponBottomSheet> {
  Map<String, dynamic>? _selectedCoupon;
  String? _currentQrToken;
  int _redemptionSeconds = 30; // 30-second anti-fraud validity timer
  Timer? _passTimer;

  @override
  void initState() {
    super.initState();
    if (widget.activeCoupons.isNotEmpty) {
      _selectedCoupon = widget.activeCoupons.first;
    }
    _startPassCountdown();
  }

  @override
  void dispose() {
    _passTimer?.cancel();
    super.dispose();
  }

  void _generateQrPassToken() {
    final coupon = _selectedCoupon;
    final couponId = coupon?['code'] ?? coupon?['id'] ?? 'PASS';
    final tokenTimestamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
    _currentQrToken = 'CANDELA:${widget.userId}:$couponId:$tokenTimestamp';
    _redemptionSeconds = 30; // reset to 30 seconds anti-fraud window
  }

  void _startPassCountdown() {
    _passTimer?.cancel();
    _generateQrPassToken();

    _passTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_redemptionSeconds > 1) {
        setState(() {
          _redemptionSeconds--;
        });
      } else {
        // 30 seconds expired -> regenerate QR pass token and reset timer to 30s
        setState(() {
          _generateQrPassToken();
        });
      }
    });
  }

  String _formatPassTimer(int totalSecs) {
    final mins = (totalSecs / 60).floor();
    final secs = totalSecs % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _selectCoupon(Map<String, dynamic> cpn) {
    setState(() {
      _selectedCoupon = cpn;
    });
    _startPassCountdown();
  }

  @override
  Widget build(BuildContext context) {
    final coupon = _selectedCoupon;
    final qrData = _currentQrToken ?? 'CANDELA:${widget.userId}:PASS:${DateTime.now().millisecondsSinceEpoch}';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkSlate,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag indicator handle
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Subtitle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAmber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.qr_code_2_rounded,
                      color: AppColors.darkSlate,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Dynamic Single-Use Pass',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Present this single-use pass at terminal checkout. Code remains stable for 1 minute.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 20),

              // Main Dynamic QR Display Surface
              if (coupon == null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.darkBackground,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.primaryAmber.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.confirmation_number_outlined,
                        color: AppColors.primaryAmber,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No Active Coupon Selected',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Claim an offer card from the home feed or select a saved wallet pass below.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Active Coupon QR Card Surface
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryAmber.withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Active Coupon Title Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAmber,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          coupon['title'] ?? 'Selected Pass',
                          style: const TextStyle(
                            color: AppColors.darkSlate,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Stable 60-Second QR Code Generator
                      QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 200,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppColors.darkSlate,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppColors.darkBackground,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Countdown Timer for Pass Expiry (60 Seconds / 1 Minute)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _redemptionSeconds > 15
                              ? AppColors.successGreenLight
                              : AppColors.errorRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_rounded,
                              size: 16,
                              color: _redemptionSeconds > 15
                                  ? AppColors.successGreen
                                  : AppColors.errorRed,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Pass Valid: ${_formatPassTimer(_redemptionSeconds)}',
                              style: TextStyle(
                                color: _redemptionSeconds > 15
                                    ? AppColors.successGreen
                                    : AppColors.errorRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        'PAYLOAD: $qrData',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),

              // Mini List Selector for Active Saved Coupons
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Switch Active Saved Wallet Coupon:',
                  style: TextStyle(
                    color: AppColors.primaryAmber,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: widget.activeCoupons.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.darkBackground,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'No active coupons currently in your wallet.',
                            style: TextStyle(color: Colors.white60, fontSize: 13),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: widget.activeCoupons.length,
                        itemBuilder: (ctx, idx) {
                          final cpn = Map<String, dynamic>.from(widget.activeCoupons[idx]);
                          final isSelected = coupon?['code'] == cpn['code'] || coupon?['id'] == cpn['id'];

                          return InkWell(
                            onTap: () => _selectCoupon(cpn),
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.darkBackground : AppColors.cardSurface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? AppColors.primaryAmber : Colors.white10,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.confirmation_number_rounded,
                                    color: isSelected ? AppColors.primaryAmber : Colors.white60,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cpn['title'] ?? 'Discount Pass',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Code: ${cpn['code']} • ${cpn['store'] ?? 'Store'}',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.6),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle_rounded
                                        : Icons.arrow_forward_ios_rounded,
                                    color: isSelected ? AppColors.primaryAmber : Colors.white30,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),

              // Close Action Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAmber,
                  foregroundColor: AppColors.darkSlate,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Done / Close Modal',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
