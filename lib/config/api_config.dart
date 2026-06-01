import 'package:flutter/foundation.dart';

/// API Configuration for Flutter app (Production + Development ready)
class ApiConfig {
  // =========================
  // 🔐 ENVIRONMENT SETTINGS
  // =========================

  /// Set this to true when deploying to App Store / Play Store
  static const bool isProduction = true;

  /// Production backend (EC2 + Domain)
  static const String productionUrl = 'https://api.delx.shop';

  /// Local development URLs
  static const String localWebUrl = 'http://localhost:8000';
  static const String localAndroidUrl = 'http://10.0.2.2:8000';

  // =========================
  // 🌐 BASE URL
  // =========================

  static String get baseUrl {
    if (isProduction) {
      return productionUrl;
    }

    if (kIsWeb) {
      return localWebUrl;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return localAndroidUrl;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return localWebUrl;
    }
  }

  /// API version prefix
  static const String apiPrefix = '/api/v1';

  /// Full API base URL
  static String get apiBaseUrl => '$baseUrl$apiPrefix';

  // =========================
  // 📦 ENDPOINTS
  // =========================

  static const String products = '/products/';
  static const String categories = '/categories/';
  static const String brands = '/brands/';
  static const String orders = '/orders/';
  static const String heroBanners = '/hero-banners/';
  static const String homeAds = '/home-ads/';
  static const String featuredCategories = '/categories/featured/';
  static const String bestSellers = '/products/best_sellers/';
  static const String featuredProducts = '/products/featured/';

  // =========================
  // 👤 AUTH
  // =========================

  static const String customerLogin = '/users/login/';
  static const String customerRegister = '/users/register/';
  static const String customerProfile = '/users/me/';
  static const String customerLogout = '/users/logout/';
  static const String googleAuth = '/users/google-auth/';
  static const String appleAuth = '/users/apple-auth/';
  static const String notifications = '/notifications/';
  static const String deviceTokenRegister = '/users/device-token/';

  // =========================
  // 💳 PAYSTACK
  // =========================

  static const String paystackPublicKey = 'pk_test_your_paystack_public_key';

  static const String paymentInitialize = '/payments/initialize/';
  static const String paymentVerify = '/payments/verify/';
  static const String paymentStatus = '/payments/status/';

  // =========================
  // 📦 ORDERS
  // =========================

  static const String orderConfirm = '/orders/confirm-by-id/';

  // =========================
  // 🔧 HELPER METHODS
  // =========================

  /// Products list (optional category filter)
  static String productsUrl({int? categoryId}) {
    if (categoryId != null) {
      return '$apiBaseUrl$products?category=$categoryId';
    }
    return '$apiBaseUrl$products';
  }

  /// Category products
  static String categoryProductsUrl(int categoryId) {
    return '$apiBaseUrl$categories$categoryId/products/';
  }

  /// Product detail
  static String productDetailUrl(int id) {
    return '$apiBaseUrl$products$id/';
  }

  /// Order detail
  static String orderDetailUrl(int id) {
    return '$apiBaseUrl$orders$id/';
  }

  /// Order tracking
  static String orderTrackingUrl(int id) {
    return '$apiBaseUrl$orders$id/tracking/';
  }

  /// Tracking by order ID
  static String trackingByOrderIdUrl(String orderId) {
    return '$apiBaseUrl$orders/tracking-by-order-id/?order_id=$orderId';
  }
}