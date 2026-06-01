import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:delx/theme.dart';
import 'package:delx/nav.dart';
import 'package:delx/services/product_service.dart';
import 'package:delx/services/cart_service.dart';
import 'package:delx/services/wishlist_service.dart';
import 'package:delx/services/order_service.dart';
import 'package:delx/services/auth_service.dart';
import 'package:delx/services/notification_service.dart';
import 'package:delx/services/theme_service.dart';
import 'package:delx/services/payment_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider(create: (_) => ProductService()..loadData()),
        ChangeNotifierProvider(create: (_) => CartService()..loadCart()),
        ChangeNotifierProvider(create: (_) => WishlistService()..loadWishlist()),
ChangeNotifierProvider(create: (_) => OrderService()..loadOrders()),
        ChangeNotifierProvider(create: (_) => NotificationService()..loadNotifications()),
        ChangeNotifierProvider(create: (_) => PaymentService()..initialize()),
        ChangeNotifierProvider.value(value: themeService),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          return MaterialApp.router(
            title: 'Delx - Your Shopping Destination',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeService.themeMode,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
