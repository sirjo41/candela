import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';

/// Modal dialog allowing users (Customers & Merchants) to update their personal details.
/// Merchants also get store location fields (address, latitude, longitude).
class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => const EditProfileDialog(),
    );
  }

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  // Store location fields (merchants only)
  late TextEditingController _addressController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isMerchantUser = false;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    _isMerchantUser = user?.isMerchant == true;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _addressController = TextEditingController();
    _latController = TextEditingController();
    _lngController = TextEditingController();

    // Pre-fetch store info for merchants to populate location fields
    if (_isMerchantUser) {
      _loadStoreData();
    }
  }

  Future<void> _loadStoreData() async {
    try {
      final apiClient = ApiClient();
      final res = await apiClient.dio.get('/merchant/dashboard');
      if (res.statusCode == 200 && res.data != null) {
        final store = res.data['store'] as Map<String, dynamic>?;
        if (store != null && mounted) {
          setState(() {
            _addressController.text = store['address']?.toString() ?? '';
            _latController.text = store['latitude']?.toString() ?? '';
            _lngController.text = store['longitude']?.toString() ?? '';
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final result = await auth.updateProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    // If merchant, also update the store location
    if (result['success'] == true && _isMerchantUser) {
      final address = _addressController.text.trim();
      final lat = double.tryParse(_latController.text.trim());
      final lng = double.tryParse(_lngController.text.trim());

      final hasStoreData =
          address.isNotEmpty || lat != null || lng != null;
      if (hasStoreData) {
        try {
          final apiClient = ApiClient();
          await apiClient.dio.post('/merchant/store/update', data: {
            if (address.isNotEmpty) 'address': address,
            if (lat != null) 'latitude': lat,
            if (lng != null) 'longitude': lng,
          });
        } catch (_) {
          // non-critical — profile still saved
        }
      }
    }

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (result['success'] == true) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'تم تحديث البيانات بنجاح.'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'فشل تحديث البيانات.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: loc.textDirection,
      child: AlertDialog(
        backgroundColor: isDark ? AppColors.darkSlateCard : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isDark
              ? const BorderSide(color: AppColors.darkSlateBorder)
              : BorderSide.none,
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.darkAmberAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: AppColors.darkSlateSurface,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              loc.tr('edit_profile'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.errorRed),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                            color: AppColors.errorRed, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Name Field
                  _buildLabel(loc.tr('full_name'), isDark),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      prefixIcon:
                          const Icon(Icons.badge_outlined, size: 18),
                      hintText: loc.tr('full_name'),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return loc.isArabic
                            ? 'يرجى إدخال الاسم الكامل'
                            : 'Please enter full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Email Field
                  _buildLabel(loc.tr('email'), isDark),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      prefixIcon:
                          const Icon(Icons.email_outlined, size: 18),
                      hintText: loc.tr('email'),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return loc.isArabic
                            ? 'يرجى إدخال البريد الإلكتروني'
                            : 'Please enter email';
                      }
                      if (!val.contains('@') || !val.contains('.')) {
                        return loc.isArabic
                            ? 'بريد إلكتروني غير صالح'
                            : 'Invalid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Phone Field
                  _buildLabel(loc.tr('phone'), isDark),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      prefixIcon:
                          const Icon(Icons.phone_outlined, size: 18),
                      hintText: loc.tr('phone'),
                    ),
                  ),

                  // Merchant-only: Store Location Section
                  if (_isMerchantUser) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.store_mall_directory_rounded,
                            color: AppColors.darkAmberAccent, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          loc.isArabic
                              ? 'موقع المتجر على الخريطة'
                              : 'Store Location on Map',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.isArabic
                          ? 'يظهر موقع متجرك للعملاء في قائمة "قريب منك"'
                          : 'Your store location appears to customers in "Stores Near You"',
                      style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.darkTextSecondary),
                    ),
                    const SizedBox(height: 12),

                    // Address
                    _buildLabel(
                        loc.isArabic ? 'عنوان المتجر' : 'Store Address',
                        isDark),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.location_on_outlined,
                            size: 18),
                        hintText: loc.isArabic
                            ? 'مثال: شارع الرشيد، طرابلس'
                            : 'e.g. 123 Main Street, City',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Latitude / Longitude
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(
                                  loc.isArabic
                                      ? 'خط العرض (Lat)'
                                      : 'Latitude',
                                  isDark),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _latController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true, signed: true),
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.north, size: 18),
                                  hintText: '32.8872',
                                ),
                                validator: (val) {
                                  if (val != null && val.trim().isNotEmpty) {
                                    final d = double.tryParse(val.trim());
                                    if (d == null ||
                                        d < -90 ||
                                        d > 90) {
                                      return loc.isArabic
                                          ? 'قيمة غير صالحة'
                                          : 'Invalid';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(
                                  loc.isArabic
                                      ? 'خط الطول (Lng)'
                                      : 'Longitude',
                                  isDark),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _lngController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true, signed: true),
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.east, size: 18),
                                  hintText: '13.1913',
                                ),
                                validator: (val) {
                                  if (val != null && val.trim().isNotEmpty) {
                                    final d = double.tryParse(val.trim());
                                    if (d == null ||
                                        d < -180 ||
                                        d > 180) {
                                      return loc.isArabic
                                          ? 'قيمة غير صالحة'
                                          : 'Invalid';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      loc.isArabic
                          ? '💡 احصل على الإحداثيات من خرائط جوجل: انقر على موقع المتجر، انسخ الأرقام'
                          : '💡 Get coordinates from Google Maps: tap your store location, copy the numbers',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.darkTextSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              loc.tr('cancel'),
              style: TextStyle(
                  color: isDark
                      ? Colors.white70
                      : AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkAmberAccent,
              foregroundColor: AppColors.darkSlateSurface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.darkSlateSurface),
                  )
                : Text(loc.tr('save_changes'),
                    style:
                        const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: isDark
            ? AppColors.darkTextSecondary
            : AppColors.textSecondary,
      ),
    );
  }
}
