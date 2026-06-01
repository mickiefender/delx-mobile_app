import 'package:go_router/go_router.dart';
import 'package:delx/screens/home_screen.dart';
import 'package:delx/screens/products_screen.dart';
import 'package:delx/screens/product_detail_screen.dart';
import 'package:delx/screens/cart_screen.dart';
import 'package:delx/screens/wishlist_screen.dart';
import 'package:delx/screens/checkout_screen.dart';
import 'package:delx/screens/order_success_screen.dart';
import 'package:delx/screens/orders_screen.dart';
import 'package:delx/screens/order_detail_screen.dart';
import 'package:delx/screens/order_tracking_detail_screen.dart';
import 'package:delx/screens/splash_screen.dart';
import 'package:delx/screens/notifications_screen.dart';
import 'package:delx/screens/auth_screen.dart';
import 'package:delx/screens/customer_dashboard_screen.dart';
import 'package:delx/widgets/bottom_nav_bar.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SplashScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) => NoTransitionPage(
          child: BottomNavBar(
            currentIndex: 0,
            child: const HomeScreen(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.products,
        name: 'products',
        pageBuilder: (context, state) => NoTransitionPage(
          child: BottomNavBar(
            currentIndex: 1,
            child: ProductsScreen(filters: state.extra as Map<String, dynamic>?),
          ),
        ),
      ),
      GoRoute(
        path: '${AppRoutes.product}/:id',
        name: 'product',
        pageBuilder: (context, state) => NoTransitionPage(
          child: ProductDetailScreen(productId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.cart,
        name: 'cart',
        pageBuilder: (context, state) => NoTransitionPage(
          child: BottomNavBar(
            currentIndex: 3,
            child: const CartScreen(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.wishlist,
        name: 'wishlist',
        pageBuilder: (context, state) => NoTransitionPage(
          child: BottomNavBar(
            currentIndex: 2,
            child: const WishlistScreen(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        name: 'checkout',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: CheckoutScreen(),
        ),
      ),
      GoRoute(
        path: '${AppRoutes.orderSuccess}/:id',
        name: 'order-success',
        pageBuilder: (context, state) => NoTransitionPage(
          child: OrderSuccessScreen(orderId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.orders,
        name: 'orders',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: OrdersScreen(),
        ),
      ),
      GoRoute(
        path: '${AppRoutes.orders}/:id',
        name: 'order-detail',
        pageBuilder: (context, state) => NoTransitionPage(
          child: OrderDetailScreen(orderId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '${AppRoutes.orders}/:id/tracking',
        name: 'order-tracking-detail',
        pageBuilder: (context, state) => NoTransitionPage(
          child: OrderTrackingDetailScreen(orderId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: NotificationsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.authLogin,
        name: 'auth-login',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: AuthScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.authSignup,
        name: 'auth-signup',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: AuthScreen(startSignup: true),
        ),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: CustomerDashboardScreen(),
        ),
      ),
    ],
  );
}

class AppRoutes {
  static const String splash = '/splash';
  static const String home = '/';
  static const String products = '/products';
  static const String product = '/product';
  static const String cart = '/cart';
  static const String wishlist = '/wishlist';
  static const String checkout = '/checkout';
  static const String orderSuccess = '/order-success';
  static const String orders = '/orders';
  static const String notifications = '/notifications';
  static const String authLogin = '/auth/login';
  static const String authSignup = '/auth/signup';
  static const String dashboard = '/account';
}
