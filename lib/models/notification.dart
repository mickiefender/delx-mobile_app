/// Notification types for ecommerce
enum NotificationType {
  order,       // Order related notifications
  promotion,   // Promotions, sales, discounts
  system,      // System notifications
  wishlist,    // Wishlist price alerts
  review,      // Review related
  general,    // General notifications
}

extension NotificationTypeExtension on NotificationType {
  static NotificationType fromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'order':
        return NotificationType.order;
      case 'promotion':
        return NotificationType.promotion;
      case 'system':
        return NotificationType.system;
      case 'wishlist':
        return NotificationType.wishlist;
      case 'review':
        return NotificationType.review;
      default:
        return NotificationType.general;
    }
  }

  String toApiString() {
    switch (this) {
      case NotificationType.order:
        return 'order';
      case NotificationType.promotion:
        return 'promotion';
      case NotificationType.system:
        return 'system';
      case NotificationType.wishlist:
        return 'wishlist';
      case NotificationType.review:
        return 'review';
      case NotificationType.general:
        return 'general';
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.order:
        return '🛒';
      case NotificationType.promotion:
        return '💰';
      case NotificationType.system:
        return '⚙️';
      case NotificationType.wishlist:
        return '❤️';
      case NotificationType.review:
        return '⭐';
      case NotificationType.general:
        return '📢';
    }
  }
}

/// Notification model compatible with Django API
class AppNotification {
  final int id;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;
  final int? relatedId;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.data,
    this.relatedId,
  });

  /// Get icon emoji based on notification type
  String get iconEmoji => type.icon;

  /// Check if notification is from today
  bool get isToday {
    final now = DateTime.now();
    return createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day;
  }

  /// Get formatted time string
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'type': type.toApiString(),
    'is_read': isRead,
    'created_at': createdAt.toIso8601String(),
    'data': data,
    'related_id': relatedId,
  };

/// Factory constructor to parse Django API response
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    // Safe ID parsing
    int notificationId;
    final idValue = json['id'];
    if (idValue is int) {
      notificationId = idValue;
    } else if (idValue is String) {
      notificationId = int.tryParse(idValue) ?? 0;
    } else {
      notificationId = 0;
    }

    // Safe related_id parsing
    int? relatedId;
    final relatedValue = json['related_id'];
    if (relatedValue is int) {
      relatedId = relatedValue;
    } else if (relatedValue is String && relatedValue.isNotEmpty) {
      relatedId = int.tryParse(relatedValue);
    }

    // Safe is_read parsing
    bool notificationIsRead = false;
    final isReadValue = json['is_read'] ?? json['read'];
    if (isReadValue is bool) {
      notificationIsRead = isReadValue;
    } else if (isReadValue is int) {
      notificationIsRead = isReadValue != 0;
    }

    return AppNotification(
      id: notificationId,
      title: json['title'] is String ? json['title'] as String : '',
      message: json['message'] is String ? json['message'] as String : '',
      type: NotificationTypeExtension.fromString(json['type'] as String?),
      isRead: notificationIsRead,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      data: json['data'] as Map<String, dynamic>?,
      relatedId: relatedId,
    );
  }

  AppNotification copyWith({
    int? id,
    String? title,
    String? message,
    NotificationType? type,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
    int? relatedId,
  }) => AppNotification(
    id: id ?? this.id,
    title: title ?? this.title,
    message: message ?? this.message,
    type: type ?? this.type,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt ?? this.createdAt,
    data: data ?? this.data,
    relatedId: relatedId ?? this.relatedId,
  );
}
