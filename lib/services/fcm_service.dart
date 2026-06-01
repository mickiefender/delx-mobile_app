import 'dart:async';

import 'package:delx/config/api_config.dart';
import 'package:delx/services/api_service.dart';
import 'package:delx/services/auth_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:delx/nav.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background isolate must initialize Firebase before using plugins that
  // depend on Firebase (firebase_messaging).
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // If native Firebase config is missing, keep the background handler safe.
    return;
  }

  // Background isolate: keep it minimal (no navigation here).
  // The foreground / opened-app handlers will handle routing.
  // ignore: avoid_print
  // print('FCM background message: ${message.messageId}');
}

class FcmService {
  FcmService._();

  static final FcmService instance = FcmService._();

  FirebaseMessaging? _messaging;

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Notification channel / id constants
  static const String _defaultChannelId = 'delx_default_channel';
  static const String _defaultChannelName = 'Delx Notifications';
  static const int _localNotificationId = 1001;

  StreamSubscription<String>? _tokenRefreshSub;

  Future<void> init({
    required String platform,
  }) async {
    if (_initialized) return;

    // Ensure Firebase is initialized before touching any firebase_messaging APIs.
    // If native Firebase config is missing on iOS, Firebase.initializeApp()
    // can throw and crash the app—so we must keep this best-effort.
    try {
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;
    } catch (_) {
      _initialized = true;
      return;
    }

    if (_messaging == null) {
      _initialized = true;
      return;
    }

    // Local notifications (for foreground messages)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;

        // Payload is expected to be a route like: /orders/{orderId}/tracking
        final route = payload;
        _navigateToRoute(route);
      },
    );

    // Set up foreground notification channel (Android)
    final androidPlugin = _localNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _defaultChannelId,
          _defaultChannelName,
          description: 'Order and account updates',
          importance: Importance.high,
        ),
      );
    }

    // iOS permission request (safe on Android too; it will no-op)
    await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Background handler registration
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground handler: show local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final title = notification?.title ?? message.data['title']?.toString();
      final body = notification?.body ?? message.data['body']?.toString();

      // Route handling: backend may send route/order_id/status in data.
      final route = _routeFromMessageData(message.data);

      if (title == null && body == null) return;

      _showLocalNotification(
        title: title ?? 'Notification',
        body: body ?? '',
        payloadRoute: route,
      );
    });

    // User tapped from notification tray while app in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final route = _routeFromMessageData(message.data);
      if (route.isEmpty) return;
      _navigateToRoute(route);
    });

    // Handle case where app is opened via a notification tap from terminated state
    final initialMessage = await _messaging!.getInitialMessage();
    if (initialMessage != null) {
      final route = _routeFromMessageData(initialMessage.data);
      if (route.isNotEmpty) {
        _navigateToRoute(route);
      }
    }

    // Token refresh
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _messaging!.onTokenRefresh.listen((newToken) async {
      await _registerDeviceToken(
        token: newToken,
        platform: platform,
      );
    });

    // Register current token
    final token = await _messaging!.getToken();
    if (token != null && token.isNotEmpty) {
      await _registerDeviceToken(
        token: token,
        platform: platform,
      );
    }

    _initialized = true;
  }

  Future<void> registerIfLoggedIn({
    required String platform,
  }) async {
    // Ensure init happened (token refresh handler may be enough, but we’ll also register right away).
    if (!_initialized) {
      await init(platform: platform);
      return;
    }

    final currentToken = await _messaging!.getToken();
    if (currentToken != null && currentToken.isNotEmpty) {
      await _registerDeviceToken(token: currentToken, platform: platform);
    }
  }

  String _routeFromMessageData(Map<String, dynamic> data) {
    // Backend (backend1/orders/views.py) sends:
    //   { type: "order", route: "/orders/{orderId}/tracking", order_id: "...", status: "..." }
    final dynamic route = data['route'] ?? data['deeplink'] ?? data['click_action'];
    if (route is String && route.isNotEmpty) return route;

    // Fallback: if order_id present, use tracking route.
    final dynamic orderId = data['order_id'];
    if (orderId != null) {
      final orderIdStr = orderId.toString();
      if (orderIdStr.isNotEmpty) {
        return '/orders/$orderIdStr/tracking';
      }
    }

    return '';
  }

  Future<void> _registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    // Only register for logged-in users.
    if (!apiService.isAuthenticated) return;
    if (!authService.isLoggedIn || !authService.isCustomer) return;

    try {
      await apiService.post(
        ApiConfig.deviceTokenRegister,
        requiresAuth: true,
        body: {
          'platform': platform,
          'token': token,
        },
      );
    } catch (_) {
      // Best-effort. Swallow to avoid breaking login flow.
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String payloadRoute,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _defaultChannelId,
        _defaultChannelName,
        channelDescription: 'Order and account updates',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _localNotificationsPlugin.show(
      _localNotificationId,
      title,
      body,
      details,
      payload: payloadRoute.isNotEmpty ? payloadRoute : null,
    );
  }

  void _navigateToRoute(String route) {
    if (route.isEmpty) return;

    // GoRouter is accessible via its global router instance.
    // We avoid needing BuildContext.
    final router = AppRouter.router;
    if (router.canPop()) {
      // do nothing; this is safe but not required
    }
    router.go(route);
  }
}
