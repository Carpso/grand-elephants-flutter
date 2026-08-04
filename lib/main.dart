import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants/app_config.dart';
import 'constants/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/config_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/wishlist_provider.dart';
import 'providers/collection_number_provider.dart';
import 'services/lipila_payment_service.dart';
import 'screens/admin/collection_numbers_screen.dart' as admin_collections;
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_shell.dart';
import 'screens/product/product_detail_screen.dart';
import 'screens/cart/checkout_screen.dart' as cart_checkout;
import 'screens/cart/receipt_screen.dart';
import 'screens/checkout/success_screen.dart';
import 'screens/orders/order_tracking_screen.dart';
import 'screens/orders/order_list_screen.dart';
import 'screens/orders/order_detail_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/settings_screen.dart';
import 'screens/profile/wishlist_screen.dart';
import 'screens/profile/addresses_screen.dart';
import 'screens/profile/notifications_screen.dart' as profile_notif;
import 'screens/profile/help_screen.dart';
import 'screens/scan/scan_screen.dart';
import 'screens/tryon/try_on_screen.dart';
import 'screens/support/chat_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/admin/dashboard_screen.dart' as admin_dash;
import 'screens/admin/users_screen.dart';
import 'screens/admin/riders_screen.dart';
import 'screens/admin/employees_screen.dart';
import 'screens/admin/categories_screen.dart';
import 'screens/admin/banners_screen.dart';
import 'screens/admin/inventory_screen.dart';
import 'screens/admin/sales_screen.dart';
import 'screens/admin/finance_screen.dart';
import 'screens/admin/marketing_screen.dart';
import 'screens/admin/admin_notifications_screen.dart';
import 'screens/admin/admin_settings_screen.dart' as admin_settings;
import 'screens/superadmin/collection_numbers_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runZonedGuarded(() {
    runApp(const SellOnApp());
  }, (error, stack) {
    debugPrint('Uncaught error: $error');
  });
}

class SellOnApp extends StatelessWidget {
  const SellOnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ConfigProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (_) => CartProvider(),
          update: (_, auth, cart) => cart!..loadForUser(auth.user?.uid),
        ),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => CollectionNumberProvider()),
        Provider(create: (_) => LipilaPaymentService()..initialize(apiKey: AppConfig.lipilaSecretKey, useSandbox: AppConfig.lipilaUseSandbox)),
      ],
      child: MaterialApp(
        title: 'Sell On App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: '/splash',
        onGenerateRoute: (settings) {
          final routes = <String, WidgetBuilder>{
            '/splash': (_) => const SplashScreen(),
            '/onboarding': (_) => const OnboardingScreen(),
            '/login': (_) => const LoginScreen(),
            '/signup': (_) => const SignupScreen(),
            '/home': (_) => const HomeShell(),
            '/profile': (_) => const ProfileScreen(),
            '/profile/settings': (_) => const SettingsScreen(),
            '/profile/wishlist': (_) => const WishlistScreen(),
            '/profile/addresses': (_) => const AddressesScreen(),
            '/profile/notifications': (_) => const profile_notif.NotificationsScreen(),
            '/profile/help': (_) => const HelpScreen(),
            '/orders': (_) => const OrderListScreen(),
            '/orders/track': (_) => const OrderTrackingScreen(),
            '/cart/checkout': (_) => const cart_checkout.CheckoutScreen(),
            '/cart/receipt': (_) => const ReceiptScreen(),
            '/cart/checkout/success': (_) => const CheckoutSuccessScreen(),
            '/scan': (_) => const ScanScreen(),
            '/try-on': (_) => const TryOnScreen(),
            '/support': (_) => const ChatScreen(),
            '/admin': (_) => const AdminHomeScreen(),
            '/admin/dashboard': (_) => const admin_dash.DashboardScreen(),
            '/admin/users': (_) => const UsersScreen(),
            '/admin/riders': (_) => const RidersScreen(),
            '/admin/employees': (_) => const EmployeesScreen(),
            '/admin/categories': (_) => const CategoriesScreen(),
            '/admin/banners': (_) => const BannersScreen(),
            '/admin/inventory': (_) => const InventoryScreen(),
            '/admin/sales': (_) => const SalesScreen(),
            '/admin/finance': (_) => const FinanceScreen(),
            '/admin/marketing': (_) => const MarketingScreen(),
            '/admin/notifications': (_) => const AdminNotificationsScreen(),
            '/admin/settings': (_) => const admin_settings.AdminSettingsScreen(),
            '/superadmin/collection-numbers': (_) => const CollectionNumbersScreen(),
            '/admin/collection-numbers': (_) => const admin_collections.AdminCollectionNumbersScreen(),
          };

          final builder = routes[settings.name];
          if (builder != null) return MaterialPageRoute(builder: builder, settings: settings);

          if (settings.name != null && settings.name!.startsWith('/product/')) {
            final id = settings.name!.split('/').last;
            return MaterialPageRoute(
              builder: (_) => ProductDetailScreen(productId: id),
              settings: settings,
            );
          }

          if (settings.name != null && settings.name!.startsWith('/orders/')) {
            final id = settings.name!.split('/').last;
            if (id != 'track') {
              return MaterialPageRoute(
                builder: (_) => const OrderDetailScreen(),
                settings: RouteSettings(name: settings.name, arguments: id),
              );
            }
          }

          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Route not found')),
            ),
            settings: settings,
          );
        },
      ),
    );
  }
}
