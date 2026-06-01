import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delx/models/order.dart';
import 'package:delx/models/cart_item.dart';
import 'package:delx/config/api_config.dart';
import 'package:delx/services/api_service.dart';

/// Order service that communicates with Django backend
class OrderService extends ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load orders from API
  Future<void> loadOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

try {
      final dynamic response = await apiService.get(ApiConfig.orders, requiresAuth: true);
      
      // Parse paginated or direct response
      List<dynamic> ordersList = [];
      if (response is List) {
        ordersList = response;
      } else if (response is Map) {
        final results = response['results'];
        if (results is List) {
          ordersList = results;
        }
      }

      _orders = ordersList
          .map((json) => Order.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Failed to load orders: $e');
      await _loadLocalOrders();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load orders from local storage (fallback)
  Future<void> _loadLocalOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ordersJson = prefs.getString('orders');
      if (ordersJson != null) {
        final ordersList = jsonDecode(ordersJson) as List;
        _orders = ordersList.map((json) => Order.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Failed to load local orders: $e');
    }
  }

/// Create order for authenticated user
  Future<Order?> createOrder({
    required List<CartItem> items,
    required double subtotal,
    required double shippingFee,
    required String shippingAddress,
    String? shippingCity,
    String? shippingState,
    String? shippingPostalCode,
    String? shippingCountry,
    String? shippingFirstName,
    String? shippingLastName,
    String? shippingEmail,
    String? shippingPhone,
  }) async {
    try {
      // Convert CartItem to OrderItem for the API request
      final itemsData = items.map((item) => {
        'product': item.product.id,
        'quantity': item.quantity,
        'price': item.unitPrice,
        'product_name': item.product.name,
        'product_image': item.product.image ?? '',
        'sku': (item.product.sku ?? '').trim().isNotEmpty ? item.product.sku!.trim() : 'SKU-${item.product.id}',
        'subtotal': item.unitPrice * item.quantity,
      }).toList();

final body = {
        'items': itemsData,
        'subtotal': subtotal,
        'shipping_cost': shippingFee,
        'tax_amount': 0,  // No tax - removed from system
        'total_amount': subtotal + shippingFee,
        'shipping_address': shippingAddress,
        if (shippingCity != null) 'shipping_city': shippingCity,
        if (shippingState != null) 'shipping_state': shippingState,
        if (shippingPostalCode != null) 'shipping_postal_code': shippingPostalCode,
        if (shippingCountry != null) 'shipping_country': shippingCountry,
        if (shippingFirstName != null) 'shipping_first_name': shippingFirstName,
        if (shippingLastName != null) 'shipping_last_name': shippingLastName,
        if (shippingEmail != null) 'shipping_email': shippingEmail,
        if (shippingPhone != null) 'shipping_phone': shippingPhone,
      };

      final response = await apiService.post(ApiConfig.orders, body: body, requiresAuth: true);
      final order = Order.fromJson(response);
      _orders.insert(0, order);
      await _saveOrdersLocal();
      notifyListeners();
      return order;
    } catch (e) {
      debugPrint('Failed to create order: $e');
      _error = e.toString();
      
      // Handle 401 Unauthorized - token might be invalid/expired
      // Check if error message contains 'Unauthorized' or status code is 401
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
        // Clear invalid session and notify the caller to prompt re-login
        // This will be handled by the UI to show login screen
        _error = 'Session expired. Please login again to place your order.';
      }
      
      return null;
    }
  }

/// Create order for guest user
  Future<Order?> createGuestOrder({
    required List<CartItem> items,
    required double subtotal,
    required double shippingFee,
    required String shippingAddress,
    String? shippingCity,
    String? shippingState,
    String? shippingPostalCode,
    String? shippingCountry,
    required String shippingFirstName,
    required String shippingLastName,
    required String shippingEmail,
    required String shippingPhone,
  }) async {
    try {
      // Convert CartItem to OrderItem for the API request
      final itemsData = items.map((item) => {
        'product': item.product.id,
        'quantity': item.quantity,
        'price': item.unitPrice,
        'product_name': item.product.name,
        'product_image': item.product.image ?? '',
        'sku': (item.product.sku ?? '').trim().isNotEmpty ? item.product.sku!.trim() : 'SKU-${item.product.id}',
        'subtotal': item.unitPrice * item.quantity,
      }).toList();

final body = {
        'items': itemsData,
        'subtotal': subtotal,
        'shipping_cost': shippingFee,
        'tax_amount': 0,  // No tax - removed from system
        'total_amount': subtotal + shippingFee,
        'shipping_address': shippingAddress,
        if (shippingCity != null) 'shipping_city': shippingCity,
        if (shippingState != null) 'shipping_state': shippingState,
        if (shippingPostalCode != null) 'shipping_postal_code': shippingPostalCode,
        if (shippingCountry != null) 'shipping_country': shippingCountry,
        'shipping_first_name': shippingFirstName,
        'shipping_last_name': shippingLastName,
        'shipping_email': shippingEmail,
        'shipping_phone': shippingPhone,
      };

      final response = await apiService.post(ApiConfig.orders, body: body);
      final order = Order.fromJson(response);
      _orders.insert(0, order);
      await _saveOrdersLocal();
      notifyListeners();
      return order;
    } catch (e) {
      debugPrint('Failed to create guest order: $e');
      _error = e.toString();
      
      // Handle any error - might be server issue or network problem
      // Check for unauthorized errors
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
        _error = 'Unable to create order. Please try again.';
      }
      
      return null;
    }
  }

  /// Save orders to local storage
  Future<void> _saveOrdersLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('orders', jsonEncode(_orders.map((o) => o.toJson()).toList()));
    } catch (e) {
      debugPrint('Failed to save orders locally: $e');
    }
  }

  /// Update order status (admin only)
  Future<bool> updateOrderStatus(int orderId, String status) async {
    try {
      await apiService.post(
        '${ApiConfig.orders}$orderId/update-status/',
        body: {'status': status},
        requiresAuth: true,
      );
      
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index >= 0) {
        final newStatus = OrderStatusExtension.statusFromString(status);
        _orders[index] = _orders[index].copyWith(status: newStatus);
        await _saveOrdersLocal();
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Failed to update order status: $e');
      return false;
    }
  }

  /// Get order by ID
  Future<Order?> getOrderById(int id) async {
    try {
      final response = await apiService.get(
        '${ApiConfig.orders}$id/',
        requiresAuth: true,
      );
      return Order.fromJson(response);
    } catch (e) {
      debugPrint('Failed to get order: $e');
      return getOrderByIdSync(id);
    }
  }

  /// Get order by ID from local cache
  Order? getOrderByIdSync(int id) {
    try {
      return _orders.firstWhere((order) => order.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get order by public order ID (guest-safe)
  /// Backend supports guest lookup via query param: ?order_id=<public order_id>
  Future<Order?> getOrderByOrderId(String orderId) async {
    try {
      // Prefer backend so status is fresh after payment/webhook.
      final response = await apiService.get(
        ApiConfig.orders,
        queryParams: {'order_id': orderId},
        requiresAuth: false,
      );

      // ApiService.get wraps lists in {results: [...]}
      final List<dynamic> results = response['results'] is List
          ? response['results'] as List<dynamic>
          : (response is List ? response as List<dynamic> : <dynamic>[]);

      if (results.isEmpty) return null;

      // Take the first match (order_id is unique)
      return Order.fromJson(results.first as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Failed to get order by orderId: $e');

      // Fallback to local cache (may be stale, but better than nothing)
      try {
        return _orders.firstWhere((o) => o.orderId == orderId);
      } catch (_) {
        return null;
      }
    }
  }

/// Get order tracking information
  Future<List<Map<String, dynamic>>> getOrderTracking(int orderId) async {
    try {
      final dynamic response = await apiService.get('${ApiConfig.orders}$orderId/tracking/');
      
      if (response is List) {
        final List<Map<String, dynamic>> trackingList = [];
        for (final item in response) {
          if (item is Map) {
            final Map<String, dynamic> entry = {};
            item.forEach((key, value) {
              entry[key.toString()] = value;
            });
            trackingList.add(entry);
          }
        }
        return trackingList;
      }
      return [];
    } catch (e) {
      debugPrint('Failed to get order tracking: $e');
      return [];
    }
  }

/// Cancel an order
  Future<bool> cancelOrder(int orderId) async {
    try {
      await apiService.post('${ApiConfig.orders}$orderId/cancel/', requiresAuth: true);
      
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index >= 0) {
        _orders[index] = _orders[index].copyWith(status: OrderStatus.cancelled);
        await _saveOrdersLocal();
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Failed to cancel order: $e');
      return false;
    }
  }

  /// Confirm order after successful payment (calls backend to update status to 'confirmed')
  Future<bool> confirmOrder(String orderId) async {
    try {
      final response = await apiService.post(
        ApiConfig.orderConfirm,
        body: {'order_id': orderId},
        requiresAuth: false,
      );
      
      debugPrint('Order confirm response: $response');
      
      // Update local order status
      final index = _orders.indexWhere((o) => o.orderId == orderId);
      if (index >= 0) {
        _orders[index] = _orders[index].copyWith(status: OrderStatus.confirmed);
        await _saveOrdersLocal();
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Failed to confirm order: $e');
      return false;
    }
  }

  /// Refresh orders from API
  Future<void> refresh() async {
    await loadOrders();
  }
}
