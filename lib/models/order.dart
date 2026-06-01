/// Order item class for order details (different from CartItem)
/// Used specifically for displaying items in order history
class OrderItem {
  final int id;
  final int? productId;
  final String productName;
  final String? productImage;
  final String? sku;
  final double price;
  final int quantity;
  final double subtotal;
  final Map<String, dynamic>? variantAttributes;

  OrderItem({
    required this.id,
    this.productId,
    required this.productName,
    this.productImage,
    this.sku,
    required this.price,
    required this.quantity,
    required this.subtotal,
    this.variantAttributes,
  });

  /// Get item total (price * quantity)
  double get total => price * quantity;

  /// Get formatted price string
  String get priceText => 'GHS ${price.toStringAsFixed(2)}';

  /// Get formatted subtotal string
  String get subtotalText => 'GHS ${subtotal.toStringAsFixed(2)}';

  Map<String, dynamic> toJson() => {
    'id': id,
    'product': productId,
    'product_name': productName,
    'product_image': productImage,
    'sku': sku,
    'price': price,
    'quantity': quantity,
    'subtotal': subtotal,
    'variant_attributes': variantAttributes,
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Parse price (handles String from Django DecimalField)
    double itemPrice = 0.0;
    final priceValue = json['price'];
    if (priceValue is num) {
      itemPrice = priceValue.toDouble();
    } else if (priceValue is String && priceValue.isNotEmpty) {
      itemPrice = double.tryParse(priceValue) ?? 0.0;
    }

    // Parse quantity
    int itemQuantity = 1;
    final qtyValue = json['quantity'];
    if (qtyValue is int) {
      itemQuantity = qtyValue;
    } else if (qtyValue is num) {
      itemQuantity = qtyValue.toInt();
    }

    // Parse subtotal
    double itemSubtotal = 0.0;
    final subtotalValue = json['subtotal'];
    if (subtotalValue is num) {
      itemSubtotal = subtotalValue.toDouble();
    } else if (subtotalValue is String && subtotalValue.isNotEmpty) {
      itemSubtotal = double.tryParse(subtotalValue) ?? 0.0;
    }
    // If subtotal not provided, calculate from price * quantity
    if (itemSubtotal == 0.0 && itemPrice > 0) {
      itemSubtotal = itemPrice * itemQuantity;
    }

    // Parse product ID
    int? prodId;
    final prodValue = json['product'];
    if (prodValue is int) {
      prodId = prodValue;
    } else if (prodValue is String && prodValue.isNotEmpty) {
      prodId = int.tryParse(prodValue);
    }

    // Parse ID
    int itemId = 0;
    final idValue = json['id'];
    if (idValue is int) {
      itemId = idValue;
    } else if (idValue is String && idValue.isNotEmpty) {
      itemId = int.tryParse(idValue) ?? 0;
    }

    return OrderItem(
      id: itemId,
      productId: prodId,
      productName: json['product_name'] is String ? json['product_name'] as String : '',
      productImage: json['product_image'] as String?,
      sku: json['sku'] as String?,
      price: itemPrice,
      quantity: itemQuantity,
      subtotal: itemSubtotal,
      variantAttributes: json['variant_attributes'] is Map ? json['variant_attributes'] as Map<String, dynamic> : null,
    );
  }

  OrderItem copyWith({
    int? id,
    int? productId,
    String? productName,
    String? productImage,
    String? sku,
    double? price,
    int? quantity,
    double? subtotal,
    Map<String, dynamic>? variantAttributes,
  }) => OrderItem(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    productName: productName ?? this.productName,
    productImage: productImage ?? this.productImage,
    sku: sku ?? this.sku,
    price: price ?? this.price,
    quantity: quantity ?? this.quantity,
    subtotal: subtotal ?? this.subtotal,
    variantAttributes: variantAttributes ?? this.variantAttributes,
  );
}

/// Order status enum compatible with Django
enum OrderStatus { 
  pending, 
  awaitingPayment,
  processing, 
  confirmed, 
  shipped, 
  outForDelivery,
  delivered, 
  cancelled 
}

extension OrderStatusExtension on OrderStatus {
/// Convert Django status string to enum
  static OrderStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'awaiting_payment':
        return OrderStatus.awaitingPayment;
      case 'processing':
        return OrderStatus.processing;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'shipped':
        return OrderStatus.shipped;
      case 'out_for_delivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  /// Static method for parsing string to status (called on enum or class)
  static OrderStatus statusFromString(String? status) {
    return fromString(status);
  }

/// Convert enum to Django status string
  String toDjangoString() {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.awaitingPayment:
        return 'awaiting_payment';
      case OrderStatus.processing:
        return 'processing';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.shipped:
        return 'shipped';
      case OrderStatus.outForDelivery:
        return 'out_for_delivery';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }
}

/// Tracking history entry for order status timeline
class OrderTrackingEntry {
  final int id;
  final String status;
  final String message;
  final String? location;
  final DateTime timestamp;

  OrderTrackingEntry({
    required this.id,
    required this.status,
    required this.message,
    this.location,
    required this.timestamp,
  });

  factory OrderTrackingEntry.fromJson(Map<String, dynamic> json) {
    return OrderTrackingEntry(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      status: json['status'] is String ? json['status'] as String : '',
      message: json['message'] is String ? json['message'] as String : '',
      location: json['location'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
}

/// Order model compatible with Django API
class Order {
  final int id;
  final String orderId; // Django's order_id (public identifier)
  final int? userId;
  final int? guestId;
  final List<OrderItem> items;
  final double subtotal;
  final double shippingFee;
  final double total;
  final OrderStatus status;
  final String? shippingAddress;
  final String? shippingFirstName;
  final String? shippingLastName;
  final String? shippingEmail;
  final String? shippingPhone;
  final String? trackingNumber;
  final String? paymentStatus;
  final String? paymentReference;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Additional fields from detailed order response
  final String? shippingCity;
  final String? shippingState;
  final String? shippingPostalCode;
  final String? shippingCountry;
  final String? billingSameAsShipping;
  final String? billingFirstName;
  final String? billingLastName;
  final String? billingAddress;
  final String? billingCity;
  final String? billingState;
  final String? billingPostalCode;
  final String? billingCountry;
  final DateTime? estimatedDelivery;
  final double? taxAmount;
  final double? discountAmount;
  final String? couponCode;
  final String? notes;
  final List<OrderTrackingEntry>? trackingHistory;

  Order({
    required this.id,
    this.orderId = '',
    this.userId,
    this.guestId,
    required this.items,
    required this.subtotal,
    required this.shippingFee,
    required this.total,
    required this.status,
    this.shippingAddress,
    this.shippingFirstName,
    this.shippingLastName,
    this.shippingEmail,
    this.shippingPhone,
    this.trackingNumber,
    this.paymentStatus,
    this.paymentReference,
    required this.createdAt,
    required this.updatedAt,
    this.shippingCity,
    this.shippingState,
    this.shippingPostalCode,
    this.shippingCountry,
    this.billingSameAsShipping,
    this.billingFirstName,
    this.billingLastName,
    this.billingAddress,
    this.billingCity,
    this.billingState,
    this.billingPostalCode,
    this.billingCountry,
    this.estimatedDelivery,
    this.taxAmount,
    this.discountAmount,
    this.couponCode,
    this.notes,
    this.trackingHistory,
  });

String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.awaitingPayment:
        return 'Awaiting Payment';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Get full name of recipient
  String get recipientName {
    if (shippingFirstName != null || shippingLastName != null) {
      return '${shippingFirstName ?? ''} ${shippingLastName ?? ''}'.trim();
    }
    return 'Customer';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_id': orderId,
    'user': userId,
    'guest_id': guestId,
    'items': items.map((item) => item.toJson()).toList(),
    'subtotal': subtotal,
    'shipping_fee': shippingFee,
    'total_amount': total,
    'status': status.toDjangoString(),
    'shipping_address': shippingAddress,
    'shipping_first_name': shippingFirstName,
    'shipping_last_name': shippingLastName,
    'shipping_email': shippingEmail,
    'shipping_phone': shippingPhone,
    'tracking_number': trackingNumber,
    'payment_status': paymentStatus,
    'payment_reference': paymentReference,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'billing_same_as_shipping': billingSameAsShipping,
    'billing_first_name': billingFirstName,
    'billing_last_name': billingLastName,
    'billing_address': billingAddress,
    'billing_city': billingCity,
    'billing_state': billingState,
    'billing_postal_code': billingPostalCode,
    'billing_country': billingCountry,
    'estimated_delivery': estimatedDelivery?.toIso8601String(),
  };

/// Factory constructor to parse Django API response
  factory Order.fromJson(Map<String, dynamic> json) {
    // Parse status
    final statusStr = json['status'] as String?;
    OrderStatus orderStatus;
    try {
      orderStatus = OrderStatusExtension.fromString(statusStr);
    } catch (e) {
      orderStatus = OrderStatus.pending;
    }

    // ===== SAFE ID PARSING =====
    int orderId;
    final idValue = json['id'];
    if (idValue is int) {
      orderId = idValue;
    } else if (idValue is String) {
      orderId = int.tryParse(idValue) ?? 0;
    } else {
      orderId = 0;
    }

    // ===== SAFE USER ID PARSING =====
    int? userId;
    final userValue = json['user'];
    if (userValue is int) {
      userId = userValue;
    } else if (userValue is String && userValue.isNotEmpty) {
      userId = int.tryParse(userValue);
    }
    // guest checkout: user is null, which is fine

    // ===== SAFE GUEST ID PARSING =====
    // Note: Django stores guest_id as CharField (string), not int
    int? guestId;
    final guestIdValue = json['guest_id'];
    if (guestIdValue is int) {
      guestId = guestIdValue;
    } else if (guestIdValue is String && guestIdValue.isNotEmpty) {
      guestId = int.tryParse(guestIdValue);
    }
    // guest_id can be null for authenticated users

// ===== PARSE ITEMS =====
    // Use OrderItem for order items from backend
    List<OrderItem> orderItems = <OrderItem>[];
    if (json['items'] != null && json['items'] is List) {
      final itemsList = json['items'] as List;
      for (final item in itemsList) {
        if (item is Map<String, dynamic>) {
          orderItems.add(OrderItem.fromJson(item));
        }
      }
    }

// ===== SAFE DECIMAL PARSING (handles both String and num from Django DecimalField) =====
    double orderSubtotal = 0.0;
    final subtotalValue = json['subtotal'];
    if (subtotalValue is num) {
      orderSubtotal = subtotalValue.toDouble();
    } else if (subtotalValue is String && subtotalValue.isNotEmpty) {
      orderSubtotal = double.tryParse(subtotalValue) ?? 0.0;
    }

    double orderShippingFee = 0.0;
    final shippingFeeValue = json['shipping_fee'] ?? json['shipping_cost'];
    if (shippingFeeValue is num) {
      orderShippingFee = shippingFeeValue.toDouble();
    } else if (shippingFeeValue is String && shippingFeeValue.isNotEmpty) {
      orderShippingFee = double.tryParse(shippingFeeValue) ?? 0.0;
    }

    double orderTotal = 0.0;
    final totalValue = json['total_amount'] ?? json['total'];
    if (totalValue is num) {
      orderTotal = totalValue.toDouble();
    } else if (totalValue is String && totalValue.isNotEmpty) {
      orderTotal = double.tryParse(totalValue) ?? 0.0;
    }

    // Parse additional fields
    double orderTax = 0.0;
    final taxValue = json['tax_amount'];
    if (taxValue is num) {
      orderTax = taxValue.toDouble();
    } else if (taxValue is String && taxValue.isNotEmpty) {
      orderTax = double.tryParse(taxValue) ?? 0.0;
    }

double orderDiscount = 0.0;
    final discountValue = json['discount_amount'];
    if (discountValue is num) {
      orderDiscount = discountValue.toDouble();
    } else if (discountValue is String && discountValue.isNotEmpty) {
      orderDiscount = double.tryParse(discountValue) ?? 0.0;
    }

    // Parse tracking history
    List<OrderTrackingEntry> trackingEntries = <OrderTrackingEntry>[];
    if (json['tracking_history'] != null && json['tracking_history'] is List) {
      final trackingList = json['tracking_history'] as List;
      for (final entry in trackingList) {
        if (entry is Map<String, dynamic>) {
          trackingEntries.add(OrderTrackingEntry.fromJson(entry));
        }
      }
    }

    return Order(
      id: orderId,
      orderId: json['order_id'] is String 
          ? json['order_id'] as String 
          : orderId.toString(),
      userId: userId,
      guestId: guestId,
      items: orderItems,
      subtotal: orderSubtotal,
      shippingFee: orderShippingFee,
      total: orderTotal,
      status: orderStatus,
      shippingAddress: json['shipping_address'] as String?,
      shippingFirstName: json['shipping_first_name'] as String?,
      shippingLastName: json['shipping_last_name'] as String?,
      shippingEmail: json['shipping_email'] as String?,
      shippingPhone: json['shipping_phone'] as String?,
      trackingNumber: json['tracking_number'] as String?,
      paymentStatus: json['payment_status'] as String?,
      paymentReference: json['payment_reference'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      shippingCity: json['shipping_city'] as String?,
      shippingState: json['shipping_state'] as String?,
      shippingPostalCode: json['shipping_postal_code'] as String?,
      shippingCountry: json['shipping_country'] as String?,
      billingSameAsShipping: json['billing_same_as_shipping']?.toString(),
      billingFirstName: json['billing_first_name'] as String?,
      billingLastName: json['billing_last_name'] as String?,
      billingAddress: json['billing_address'] as String?,
      billingCity: json['billing_city'] as String?,
      billingState: json['billing_state'] as String?,
      billingPostalCode: json['billing_postal_code'] as String?,
      billingCountry: json['billing_country'] as String?,
      estimatedDelivery: json['estimated_delivery'] != null
          ? DateTime.tryParse(json['estimated_delivery'].toString())
          : null,
      taxAmount: orderTax > 0 ? orderTax : null,
      discountAmount: orderDiscount > 0 ? orderDiscount : null,
      couponCode: json['coupon_code'] as String?,
      notes: json['notes'] as String?,
      trackingHistory: trackingEntries.isNotEmpty ? trackingEntries : null,
    );
  }

  Order copyWith({
    int? id,
    String? orderId,
    int? userId,
    int? guestId,
    List<OrderItem>? items,
    double? subtotal,
    double? shippingFee,
    double? total,
    OrderStatus? status,
    String? shippingAddress,
    String? shippingFirstName,
    String? shippingLastName,
    String? shippingEmail,
    String? shippingPhone,
    String? trackingNumber,
    String? paymentStatus,
    String? paymentReference,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? shippingCity,
    String? shippingState,
    String? shippingPostalCode,
    String? shippingCountry,
    String? billingSameAsShipping,
    String? billingFirstName,
    String? billingLastName,
    String? billingAddress,
    String? billingCity,
    String? billingState,
    String? billingPostalCode,
    String? billingCountry,
    DateTime? estimatedDelivery,
    double? taxAmount,
    double? discountAmount,
    String? couponCode,
    String? notes,
    List<OrderTrackingEntry>? trackingHistory,
  }) => Order(
    id: id ?? this.id,
    orderId: orderId ?? this.orderId,
    userId: userId ?? this.userId,
    guestId: guestId ?? this.guestId,
    items: items ?? this.items,
    subtotal: subtotal ?? this.subtotal,
    shippingFee: shippingFee ?? this.shippingFee,
    total: total ?? this.total,
    status: status ?? this.status,
    shippingAddress: shippingAddress ?? this.shippingAddress,
    shippingFirstName: shippingFirstName ?? this.shippingFirstName,
    shippingLastName: shippingLastName ?? this.shippingLastName,
    shippingEmail: shippingEmail ?? this.shippingEmail,
    shippingPhone: shippingPhone ?? this.shippingPhone,
    trackingNumber: trackingNumber ?? this.trackingNumber,
    paymentStatus: paymentStatus ?? this.paymentStatus,
    paymentReference: paymentReference ?? this.paymentReference,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    shippingCity: shippingCity ?? this.shippingCity,
    shippingState: shippingState ?? this.shippingState,
    shippingPostalCode: shippingPostalCode ?? this.shippingPostalCode,
    shippingCountry: shippingCountry ?? this.shippingCountry,
    billingSameAsShipping: billingSameAsShipping ?? this.billingSameAsShipping,
    billingFirstName: billingFirstName ?? this.billingFirstName,
    billingLastName: billingLastName ?? this.billingLastName,
    billingAddress: billingAddress ?? this.billingAddress,
    billingCity: billingCity ?? this.billingCity,
    billingState: billingState ?? this.billingState,
    billingPostalCode: billingPostalCode ?? this.billingPostalCode,
    billingCountry: billingCountry ?? this.billingCountry,
    estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
    taxAmount: taxAmount ?? this.taxAmount,
    discountAmount: discountAmount ?? this.discountAmount,
    couponCode: couponCode ?? this.couponCode,
    notes: notes ?? this.notes,
    trackingHistory: trackingHistory ?? this.trackingHistory,
  );
}
