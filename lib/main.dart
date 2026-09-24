import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/config_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/wishlist_provider.dart';
import 'providers/collection_number_provider.dart';
import 'providers/rider_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/app_data_provider.dart';
import 'screens/admin/collection_numbers_screen.dart' as admin_collections;
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_shell.dart';
import 'screens/explore/explore_screen.dart';
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
import 'screens/rider/apply_screen.dart';
import 'screens/business/business_apply_screen.dart';
import 'screens/business/business_home_screen.dart';
import 'screens/business/business_dashboard_screen.dart';
import 'screens/business/tax_screen.dart';
import 'screens/employee/employee_stock_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/admin/add_product_screen.dart';
import 'screens/admin/businesses_screen.dart';
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
import 'screens/superadmin/superadmin_dashboard_screen.dart';
import 'widgets/toast.dart';

/// Global navigator used for programmatic navigation (e.g. forced logout)
/// that must not depend on a widget context.
final navigatorKey = GlobalKey<NavigatorState>();

/// Name of the most recently generated route; lets providers that have no
/// BuildContext (like [AuthProvider]) avoid navigating when pointless.
String currentRouteName = '/splash';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }
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
        ChangeNotifierProvider(create: (_) => AuthProvider(), lazy: false),
        ChangeNotifierProvider(create: (_) => ConfigProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (_) => CartProvider(),
          update: (_, auth, cart) => cart!..loadForUser(auth.user?.uid),
        ),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => CollectionNumberProvider()),
        ChangeNotifierProvider(create: (_) => RiderProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => AppDataProvider()),
      ],
      child: MaterialApp(
        title: 'Grand Elephants',
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: '/splash',
        onGenerateRoute: (settings) {
          if (settings.name != null && settings.name!.isNotEmpty) {
            currentRouteName = settings.name!;
          }

          final routes = <String, WidgetBuilder>{
            '/': (_) => const HomeShell(),
            '/splash': (_) => const SplashScreen(),
            '/onboarding': (_) => const OnboardingScreen(),
            '/login': (_) => const LoginScreen(),
            '/signup': (_) => const SignupScreen(),
            '/home': (_) => const HomeShell(),
            '/explore': (_) => const ExploreScreen(),
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
            '/support/chat': (_) => const ChatScreen(),
            '/rider/apply': (_) => const ApplyScreen(),
            '/business/apply': (_) => const BusinessApplyScreen(),
            '/business/dashboard': (_) => const BusinessDashboardScreen(),
            '/business/home': (_) => const BusinessHomeScreen(),
            '/business/tax': (_) => const TaxScreen(),
            '/business/collection-numbers': (_) => const CollectionNumbersScreen(),
            '/business/products/add': (_) => const AddProductScreen(),
            '/employee/stock': (_) => const EmployeeStockScreen(),
            '/admin': (_) => const AdminHomeScreen(),
            '/admin/businesses': (_) => const BusinessesScreen(),
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
            '/superadmin/dashboard': (_) => const SuperadminDashboardScreen(),
            '/superadmin/collection-numbers': (_) => const CollectionNumbersScreen(),
            '/admin/collection-numbers': (_) => const admin_collections.AdminCollectionNumbersScreen(),
          };

          final adminOnlyRoutes = {
            '/admin',
            '/admin/businesses',
            '/admin/dashboard',
            '/admin/users',
            '/admin/riders',
            '/admin/employees',
            '/admin/categories',
            '/admin/banners',
            '/admin/inventory',
            '/admin/sales',
            '/admin/finance',
            '/admin/marketing',
            '/admin/notifications',
            '/admin/settings',
            '/admin/collection-numbers',
            '/superadmin/collection-numbers',
            '/superadmin/dashboard',
          };

          if (adminOnlyRoutes.contains(settings.name)) {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            final role = auth.role;
            if (role != 'admin' && role != 'superadmin') {
              ToastProvider.of(context).show('You need admin access for that page', ToastType.error);
              return MaterialPageRoute(
                builder: (_) => const HomeShell(),
                settings: settings,
              );
            }
          }

          // Team-facing screens: staff and shop owners only (enforced for real
          // by the API, this just keeps the shell honest).
          final teamRoutes = {
            '/business/dashboard',
            '/business/home',
            '/business/tax',
            '/business/collection-numbers',
            '/business/products/add',
            '/employee/stock',
          };
          if (teamRoutes.contains(settings.name)) {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            const allowed = {'business', 'employee', 'admin', 'superadmin'};
            if (!allowed.contains(auth.role)) {
              ToastProvider.of(context).show('That page is for shop teams', ToastType.error);
              return MaterialPageRoute(
                builder: (_) => const HomeShell(),
                settings: settings,
              );
            }
          }

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
