import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delx/models/cart_item.dart';
import 'package:delx/models/product.dart';

/// List of all 16 Ghana regions
class CartService extends ChangeNotifier {
  static const List<String> ghanaRegions = [
    'Greater Accra',
    'Central',
    'Ashanti',
    'Western',
    'Eastern',
    'Volta',
    'Northern',
    'Bono',
    'Bono East',
    'Upper East',
    'Upper West',
    'North East',
    'Oti',
    'Western North',
    'Savannah',
    'Ahafo',
  ];

  List<CartItem> _items = [];
  bool _isLoading = false;
  String _selectedRegion = 'Greater Accra';

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.fold(0, (sum, item) => sum + item.totalPrice);
  String get selectedRegion => _selectedRegion;

  /// Calculate shipping fee based on region and subtotal
  /// - Accra (Greater Accra): GH¢50, free if subtotal > GH¢1000
  /// - Other regions: GH¢100, free if subtotal > GH¢2000
  double get shippingFee {
    // If in Greater Accra (includes Accra)
    if (_selectedRegion == 'Greater Accra') {
      // Free shipping for orders above GH¢1000 in Accra
      if (subtotal > 1000) {
        return 0;
      }
      // GH¢50 shipping in Accra
      return 50;
    } else {
      // Other regions: free shipping for orders above GH¢2000
      if (subtotal > 2000) {
        return 0;
      }
      // GH¢100 shipping for other regions
      return 100;
    }
  }

  double get total => subtotal + shippingFee;

  void setRegion(String region) {
    _selectedRegion = region;
    notifyListeners();
  }
  
  /// Get currency from the first item in cart, or default to 'GHS'
  String get currency {
    if (_items.isEmpty) return 'GHS';
    return _items.first.product.currency;
  }

  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString('cart');

if (cartJson != null && cartJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(cartJson);
          
          List<dynamic> cartList;
          if (decoded is List) {
            cartList = decoded;
          } else if (decoded is Map && decoded.containsKey('items')) {
            cartList = decoded['items'] as List;
          } else {
            debugPrint('Invalid cart format, clearing...');
            await prefs.remove('cart');
            _items = [];
            _isLoading = false;
            notifyListeners();
            return;
          }
          
          final validItems = <CartItem>[];
          for (final item in cartList) {
            try {
              if (item is Map<String, dynamic>) {
                validItems.add(CartItem.fromJson(item));
              }
            } catch (e) {
              debugPrint('Failed to parse cart item: $e');
            }
          }
          _items = validItems;
        } catch (e) {
          debugPrint('Failed to parse cart JSON: $e');
          await prefs.remove('cart');
          _items = [];
        }
      }
    } catch (e) {
      debugPrint('Failed to load cart: $e');
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cart', jsonEncode(_items.map((item) => item.toJson()).toList()));
    } catch (e) {
      debugPrint('Failed to save cart: $e');
    }
  }

  Future<void> addToCart(Product product, {int quantity = 1}) async {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
      _items[existingIndex].updatedAt = DateTime.now();
    } else {
      final now = DateTime.now();
      _items.add(CartItem(
        id: '${product.id}_${now.millisecondsSinceEpoch}',
        product: product,
        quantity: quantity,
        createdAt: now,
        updatedAt: now,
      ));
    }

    await _saveCart();
    notifyListeners();
  }

  Future<void> removeFromCart(String cartItemId) async {
    _items.removeWhere((item) => item.id == cartItemId);
    await _saveCart();
    notifyListeners();
  }

  Future<void> updateQuantity(String cartItemId, int quantity) async {
    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index >= 0) {
      if (quantity <= 0) {
        await removeFromCart(cartItemId);
      } else {
        _items[index].quantity = quantity;
        _items[index].updatedAt = DateTime.now();
        await _saveCart();
        notifyListeners();
      }
    }
  }

  Future<void> clearCart() async {
    _items.clear();
    await _saveCart();
    notifyListeners();
  }

bool isInCart(int productId) => _items.any((item) => item.product.id == productId);
}
