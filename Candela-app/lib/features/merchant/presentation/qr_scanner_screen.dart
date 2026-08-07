import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/merchant_provider.dart';

/// QR Verification Scanner Screen matching reference screenshot IMG-20260725-WA0015.jpg
/// Includes camera overlay, manual token input fallback, and instant feedback modal sheet in RTL mode.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final TextEditingController _manualInputController = TextEditingController();
  MobileScannerController? _cameraController;
  bool _isScannerActive = true;
  bool _isProcessing = false;

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
    _manualInputController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScannerActive || _isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String token = barcodes.first.rawValue!;
      _processQrVerification(token);
    }
  }

  Future<void> _processQrVerification(String token) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _isScannerActive = false;
    });

    final merchant = Provider.of<MerchantProvider>(context, listen: false);
    final result = await merchant.verifyQrToken(token);

    if (!mounted) return;

    _showFeedbackBottomSheet(result);

    setState(() {
      _isProcessing = false;
    });
  }

  void _showFeedbackBottomSheet(VerificationResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: result.isSuccess ? AppColors.darkSlate : AppColors.darkBackground,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: result.isSuccess ? AppColors.successGreen : AppColors.errorRed,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // Icon Indicator
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (result.isSuccess ? AppColors.successGreen : AppColors.errorRed).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    result.isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                    color: result.isSuccess ? AppColors.successGreen : AppColors.errorRed,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 14),

                // Title
                Text(
                  result.isSuccess ? 'تم التحقق بنجاح!' : 'فشل عملية التحقق',
                  style: TextStyle(
                    color: result.isSuccess ? AppColors.successGreen : AppColors.errorRed,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Message Text
                Text(
                  result.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 16),

                // Details Card if Success
                if (result.isSuccess && result.redemptionData != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.darkBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('العميل:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            Text(
                              result.redemptionData!['customer_name'] ?? result.redemptionData!['customer_user']?['name'] ?? 'عميل واجهة',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('النقاط المكتسبة:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            Text('+50 PTS', style: TextStyle(color: AppColors.primaryAmber, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('رسوم العملية الخصومة:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            Text('5.00 د.ل', style: TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Close / Scan Next Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: result.isSuccess ? AppColors.primaryAmber : AppColors.errorRed,
                    foregroundColor: AppColors.darkSlate,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _isScannerActive = true;
                      _manualInputController.clear();
                    });
                  },
                  child: Text(
                    result.isSuccess ? 'مسح كوبون آخر' : 'إغلاق المحاولة',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      setState(() {
        _isScannerActive = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: AppColors.darkSlate,
          title: const Text(
            'مسح الكود / التحقق من الكوبون',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19),
          ),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  // Camera Scanner Frame Overlay
                  Container(
                    height: 320,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.darkSlate,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.primaryAmber, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.darkBackground.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_cameraController != null)
                            MobileScanner(
                              controller: _cameraController,
                              onDetect: _onDetect,
                            ),

                          // Scanner Bounding Overlay Box
                          Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.primaryAmber, width: 3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),

                          if (_isProcessing)
                            Container(
                              color: Colors.black54,
                              child: const Center(
                                child: CircularProgressIndicator(color: AppColors.primaryAmber),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'قم بتوجيه الكاميرا نحو رمز QR الخاص بالعميل للتحقق التلقائي.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // Manual Input Section Header
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'أو أدخل كود الكوبون يدويًا:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkSlate,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Manual Input Field & Submit Button
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualInputController,
                          decoration: const InputDecoration(
                            hintText: 'مثال: CPN-SUMMER25',
                            prefixIcon: Icon(Icons.qr_code_2_rounded, color: AppColors.darkSlate),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAmber,
                          foregroundColor: AppColors.darkSlate,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          if (_manualInputController.text.trim().isNotEmpty) {
                            _processQrVerification(_manualInputController.text.trim());
                          }
                        },
                        child: const Text(
                          'التحقق',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
