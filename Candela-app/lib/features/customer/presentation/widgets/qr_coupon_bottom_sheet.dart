import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';

/// Dynamic, Time-Sensitive QR Coupon Bottom Sheet Modal
/// Fetches an encrypted HMAC-SHA256 hash valid for 30–60 seconds from the backend,
/// auto-refreshing in real-time to prevent screenshot fraud.
class QrCouponBottomSheet extends StatefulWidget {
  final List<dynamic> activeCoupons;
  final String userId;
  final dynamic initialCoupon;

  const QrCouponBottomSheet({
    super.key,
    required this.activeCoupons,
    required this.userId,
    this.initialCoupon,
  });

  static Future<void> show(
    BuildContext context, {
    required List<dynamic> activeCoupons,
    required String userId,
    dynamic initialCoupon,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QrCouponBottomSheet(
        activeCoupons: activeCoupons,
        userId: userId,
        initialCoupon: initialCoupon,
      ),
    );
  }

  @override
  State<QrCouponBottomSheet> createState() => _QrCouponBottomSheetState();
}

class _QrCouponBottomSheetState extends State<QrCouponBottomSheet> {
  final ApiClient _apiClient = ApiClient();
  Map<String, dynamic>? _selectedCoupon;
  String? _qrCodeHash;
  int _totalValiditySeconds = 45;
  int _remainingSeconds = 45;
  bool _isLoadingHash = false;
  String? _hashError;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialCoupon != null) {
      _selectedCoupon = Map<String, dynamic>.from(widget.initialCoupon);
    } else if (widget.activeCoupons.isNotEmpty) {
      _selectedCoupon = Map<String, dynamic>.from(widget.activeCoupons.first);
    }
    _fetchLiveQrHash();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLiveQrHash() async {
    final coupon = _selectedCoupon;
    if (coupon == null) return;

    if (!mounted) return;
    setState(() {
      _isLoadingHash = true;
      _hashError = null;
      _qrCodeHash = null;
    });

    final couponId = coupon['coupon_id'] ?? coupon['id'];

    try {
      final response = await _apiClient.dio.post(
        '/qr/generate',
        data: {
          'coupon_id': couponId,
          'valid_seconds': 45,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final hash = data['qr_code_hash'] ?? data['qr_token'];
        final validSecs = (data['valid_seconds'] as num?)?.toInt() ?? 45;

        if (hash == null || hash.toString().isEmpty) {
          throw Exception('Missing QR hash from server');
        }

        if (mounted) {
          setState(() {
            _qrCodeHash = hash.toString();
            _totalValiditySeconds = validSecs;
            _remainingSeconds = validSecs;
            _isLoadingHash = false;
            _hashError = null;
          });
          _startCountdown();
          return;
        }
      }
    } catch (e) {
      _countdownTimer?.cancel();
      if (mounted) {
        setState(() {
          _qrCodeHash = null;
          _isLoadingHash = false;
          _hashError = 'تعذّر إنشاء رمز QR. تحقق من الاتصال وحاول مجدداً.';
        });
      }
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds > 1) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        // Auto-refresh when timer reaches 0 to prevent screenshot fraud
        _fetchLiveQrHash();
      }
    });
  }

  void _selectCoupon(Map<String, dynamic> coupon) {
    setState(() {
      _selectedCoupon = coupon;
    });
    _fetchLiveQrHash();
  }

  String _formatTimer(int seconds) {
    final mins = (seconds / 60).floor();
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final coupon = _selectedCoupon;
    final progress = _totalValiditySeconds > 0 ? (_remainingSeconds / _totalValiditySeconds) : 0.0;

    return Directionality(
      textDirection: loc.textDirection,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.darkSlateSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
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
                // Drag Handle
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 16),

                // Header Title & Anti-Fraud Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.darkAmberAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.qr_code_2_rounded,
                        color: AppColors.darkSlateSurface,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      loc.tr('qr_pass_title'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  loc.tr('qr_pass_subtitle'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),

                // Anti-Fraud Shield Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.darkSlateCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.darkAmberAccent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.security_rounded,
                        color: AppColors.darkAmberAccent,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          loc.tr('qr_anti_fraud_badge'),
                          style: const TextStyle(
                            color: AppColors.darkAmberAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // QR Code Surface
                if (coupon == null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.darkSlateCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.darkSlateBorder),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.confirmation_number_outlined,
                          color: AppColors.darkAmberAccent,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          loc.tr('no_active_coupon_selected'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          loc.tr('select_coupon_from_wallet'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.darkTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.darkSlateCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.darkAmberAccent.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.darkAmberAccent.withValues(alpha: 0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Coupon Info Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.darkSlateSurface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  coupon['store_name'] ?? coupon['store'] ?? 'Candela Store',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.darkAmberAccent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  coupon['discount'] ?? coupon['discount_badge'] ?? 'خصم',
                                  style: const TextStyle(
                                    color: AppColors.darkSlateSurface,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // QR Code Render Canvas
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _isLoadingHash
                              ? const SizedBox(
                                  width: 200,
                                  height: 200,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.darkAmberAccent,
                                    ),
                                  ),
                                )
                              : _hashError != null
                                  ? SizedBox(
                                      width: 200,
                                      height: 200,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.error_outline_rounded,
                                            color: AppColors.errorRed,
                                            size: 36,
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            _hashError!,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: AppColors.darkTextSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          TextButton.icon(
                                            onPressed: _fetchLiveQrHash,
                                            icon: const Icon(
                                              Icons.refresh_rounded,
                                              size: 16,
                                            ),
                                            label: Text(loc.tr('qr_refresh_now')),
                                          ),
                                        ],
                                      ),
                                    )
                                  : QrImageView(
                                      data: _qrCodeHash!,
                                      version: QrVersions.auto,
                                      size: 200.0,
                                      backgroundColor: Colors.white,
                                      eyeStyle: const QrEyeStyle(
                                        eyeShape: QrEyeShape.square,
                                        color: AppColors.darkSlateSurface,
                                      ),
                                      dataModuleStyle: const QrDataModuleStyle(
                                        dataModuleShape:
                                            QrDataModuleShape.square,
                                        color: AppColors.darkSlateSurface,
                                      ),
                                      errorCorrectionLevel:
                                          QrErrorCorrectLevel.M,
                                    ),
                        ),
                        const SizedBox(height: 14),

                        // Coupon Code Badge
                        Text(
                          coupon['code'] ?? 'CPN-${coupon['id']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Countdown Progress Bar & Timer
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.timer_rounded,
                                      color: AppColors.darkAmberAccent,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${loc.tr('qr_refreshing_in')} ${_formatTimer(_remainingSeconds)}',
                                      style: const TextStyle(
                                        color: AppColors.darkAmberAccent,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                InkWell(
                                  onTap: _isLoadingHash ? null : _fetchLiveQrHash,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.refresh_rounded,
                                          color: Colors.white70,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          loc.tr('qr_refresh_now'),
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                backgroundColor: AppColors.darkSlateSurface,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _remainingSeconds <= 10 ? AppColors.errorRed : AppColors.darkAmberAccent,
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Active Coupons Switcher Carousel
                if (widget.activeCoupons.length > 1) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${loc.tr('wallet_title')} (${widget.activeCoupons.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.activeCoupons.length,
                      itemBuilder: (ctx, idx) {
                        final c = widget.activeCoupons[idx];
                        final isSelected = (_selectedCoupon?['id'] == c['id'] || _selectedCoupon?['code'] == c['code']);

                        return GestureDetector(
                          onTap: () => _selectCoupon(Map<String, dynamic>.from(c)),
                          child: Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.darkAmberAccent : AppColors.darkSlateCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? AppColors.darkAmberAccent : AppColors.darkSlateBorder,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              c['store_name'] ?? c['store'] ?? 'كوبون #${idx + 1}',
                              style: TextStyle(
                                color: isSelected ? AppColors.darkSlateSurface : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Close Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkSlateCard,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.darkSlateBorder),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    loc.tr('cancel'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
