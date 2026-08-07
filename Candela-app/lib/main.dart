import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/phone_login_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/customer/presentation/customer_main_navigation.dart';
import 'features/customer/providers/wallet_provider.dart';
import 'features/customer/providers/customer_feed_provider.dart';
import 'features/merchant/presentation/merchant_main_navigation.dart';
import 'features/merchant/providers/merchant_provider.dart';

import 'features/notifications/providers/notification_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CandelaApp());
}

class CandelaApp extends StatelessWidget {
  const CandelaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => CustomerFeedProvider()),
        ChangeNotifierProvider(create: (_) => MerchantProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'Candela',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isAuthenticated) {
          if (auth.activeView == 'merchant' && auth.isMerchantAccount) {
            return const MerchantMainNavigation();
          }
          return const CustomerMainNavigation();
        }
        return const PhoneLoginScreen();
      },
    );
  }
}
