import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoginMode = true;
  bool _isPasswordVisible = false;
  bool _rememberMe = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    bool success;
    if (_isLoginMode) {
      success = await authProvider.login(
        phone: _phoneController.text,
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );
    } else {
      success = await authProvider.register(
        name: _nameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(_isLoginMode
                  ? 'Welcome back!'
                  : 'Account created successfully!'),
            ],
          ),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 380;
    final isShortScreen = screenHeight < 700;

    final horizontalPadding = isSmallScreen ? 14.0 : 20.0;
    final verticalPadding = isShortScreen ? 16.0 : 32.0;
    final cardPadding = isSmallScreen ? 18.0 : 28.0;
    final logoSize = isSmallScreen ? 36.0 : 48.0;
    final titleFontSize = isSmallScreen ? 22.0 : 28.0;
    final subtitleFontSize = isSmallScreen ? 12.0 : 14.0;
    final logoPadding = isSmallScreen ? 12.0 : 16.0;
    final logoBottomGap = isShortScreen ? 8.0 : 12.0;
    final subtitleBottomGap = isShortScreen ? 16.0 : 28.0;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.royalNavy,
              AppColors.darkBackground,
            ],
            stops: [0.0, 0.45],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand Logo & Title Header
                    Container(
                      padding: EdgeInsets.all(logoPadding),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAmber.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color:
                                AppColors.primaryAmber.withValues(alpha: 0.4),
                            width: 2),
                      ),
                      child: Icon(
                        Icons.local_fire_department_rounded,
                        size: logoSize,
                        color: AppColors.primaryAmber,
                      ),
                    ),
                    SizedBox(height: logoBottomGap),
                    Text(
                      'CandelaSmart',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Loyalty & Digital Dynamic QR Pass',
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        color: AppColors.primaryAmber,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: subtitleBottomGap),

                    // Auth Card Container
                    Card(
                      elevation: 12,
                      shadowColor: Colors.black.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(cardPadding),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Login / Register Selector Tabs
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.inputBackground,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () =>
                                            setState(() => _isLoginMode = true),
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          decoration: BoxDecoration(
                                            color: _isLoginMode
                                                ? AppColors.royalNavy
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            'Sign In',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: _isLoginMode
                                                  ? Colors.white
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(
                                            () => _isLoginMode = false),
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          decoration: BoxDecoration(
                                            color: !_isLoginMode
                                                ? AppColors.royalNavy
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            'Register',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: !_isLoginMode
                                                  ? Colors.white
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Error Message Banner
                              if (authProvider.errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorRed
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.errorRed
                                            .withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: AppColors.errorRed, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          authProvider.errorMessage!,
                                          style: const TextStyle(
                                            color: AppColors.errorRed,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Full Name field (Register only)
                              if (!_isLoginMode) ...[
                                const Text(
                                  'Full Name',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _nameController,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter your full name',
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                  validator: (value) {
                                    if (!_isLoginMode &&
                                        (value == null ||
                                            value.trim().isEmpty)) {
                                      return 'Please enter your name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Phone Number or Email input
                              Text(
                                _isLoginMode ? 'Phone Number or Email' : 'Phone Number',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: _isLoginMode ? TextInputType.emailAddress : TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  hintText: _isLoginMode ? 'Enter phone number or email' : '+218 9X XXXXXXX',
                                  prefixIcon: Icon(_isLoginMode ? Icons.person_outline_rounded : Icons.phone_android_rounded),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return _isLoginMode ? 'Please enter phone number or email' : 'Please enter phone number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Email Optional (Register mode)
                              if (!_isLoginMode) ...[
                                const Text(
                                  'Email Address (Optional)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    hintText: 'name@example.com',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Password input
                              const Text(
                                'Password',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submitForm(),
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible =
                                            !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (!_isLoginMode && value.length < 8) {
                                    return 'Password must be at least 8 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Remember Me Checkbox (Sign In mode)
                              if (_isLoginMode) ...[
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        activeColor: AppColors.primaryAmber,
                                        checkColor: AppColors.darkBackground,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        onChanged: (val) {
                                          setState(() {
                                            _rememberMe = val ?? true;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        isSmallScreen
                                            ? 'Remember Me'
                                            : 'Remember Me (Stay logged in)',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 11.5 : 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ] else ...[
                                const SizedBox(height: 8),
                              ],

                              // Submit Button (Primary Amber)
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: authProvider.isLoading
                                      ? null
                                      : _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryAmber,
                                    foregroundColor: AppColors.darkBackground,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: authProvider.isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: AppColors.darkBackground,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Submit',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.darkBackground,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(Icons.arrow_forward_rounded,
                                                color:
                                                    AppColors.darkBackground),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
