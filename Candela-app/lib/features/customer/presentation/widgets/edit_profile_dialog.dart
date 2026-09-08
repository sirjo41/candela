import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';

/// Modal dialog allowing users (Customers & Merchants) to update their personal details.
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
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
          side: isDark ? const BorderSide(color: AppColors.darkSlateBorder) : BorderSide.none,
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
                        style: const TextStyle(color: AppColors.errorRed, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Name Field
                  Text(
                    loc.tr('full_name'),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                      hintText: loc.tr('full_name'),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return loc.isArabic ? 'يرجى إدخال الاسم الكامل' : 'Please enter full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Email Field
                  Text(
                    loc.tr('email'),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.email_outlined, size: 18),
                      hintText: loc.tr('email'),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return loc.isArabic ? 'يرجى إدخال البريد الإلكتروني' : 'Please enter email';
                      }
                      if (!val.contains('@') || !val.contains('.')) {
                        return loc.isArabic ? 'بريد إلكتروني غير صالح' : 'Invalid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Phone Field
                  Text(
                    loc.tr('phone'),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                      hintText: loc.tr('phone'),
                    ),
                  ),
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
              style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkAmberAccent,
              foregroundColor: AppColors.darkSlateSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkSlateSurface),
                  )
                : Text(loc.tr('save_changes'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
