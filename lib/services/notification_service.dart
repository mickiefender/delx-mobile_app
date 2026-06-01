import 'package:flutter/foundation.dart';
import 'package:delx/config/api_config.dart';
import 'package:delx/models/notification.dart';
import 'package:delx/services/api_service.dart';

/// Service for managing notifications with real-time support
class NotificationService extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;
  bool get hasUnread => _unreadCount > 0;

/// Load notifications from API
  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Check if user is authenticated first
    if (!apiService.isAuthenticated) {
      _error = 'Unauthorized. Please login first.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final response = await apiService.get(
        ApiConfig.notifications,
        requiresAuth: true,
      );

      // Parse notifications from response
      final results = response['results'] as List<dynamic>? ?? [];
      _notifications = results
          .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
          .toList();

      // Calculate unread count
      _unreadCount = _notifications.where((n) => !n.isRead).length;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Failed to load notifications: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark a single notification as read
  Future<void> markAsRead(int notificationId) async {
    try {
      await apiService.patch(
        '${ApiConfig.notifications}$notificationId/',
        body: {'is_read': true},
        requiresAuth: true,
      );

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await apiService.patch(
        ApiConfig.notifications,
        body: {'mark_all_read': true},
        requiresAuth: true,
      );

      // Update local state
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to mark all notifications as read: $e');
    }
  }

  /// Refresh notifications (pull to refresh)
  Future<void> refresh() async {
    await loadNotifications();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get notifications by type
  List<AppNotification> getByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  /// Get unread notifications
  List<AppNotification> get unreadNotifications {
    return _notifications.where((n) => !n.isRead).toList();
  }
}

/// Global notification service instance
final notificationService = NotificationService();
