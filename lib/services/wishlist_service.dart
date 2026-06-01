import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delx/models/product.dart';

class WishlistService extends ChangeNotifier {
  List<Product> _items = [];
  bool _isLoading = false;
  String? _userId;

  List<Product> get items => _items;
  bool get isLoading => _isLoading;
  int get itemCount => _items.length;

  /// Initialize the service
  Future<void> init(String? userId) async {
    _userId = userId;
    await loadWishlist();
  }

  Future<void> loadWishlist() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final wishlistJson = prefs.getString(_userId != null ? 'wishlist_$_userId' : 'wishlist_guest');

      if (wishlistJson != null) {
        final wishlistList = jsonDecode(wishlistJson) as List;
        _items = wishlistList.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Failed to load wishlist: $e');
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userId != null ? 'wishlist_$_userId' : 'wishlist_guest', 
          jsonEncode(_items.map((item) => item.toJson()).toList()));
    } catch (e) {
      debugPrint('Failed to save wishlist: $e');
    }
  }

  /// Sync wishlist with Django backend (authenticated user)
  Future<void> syncWithBackend(List<int> productIds) async {
    // This would call the Django API to sync user wishlist
    // For now, just save locally
    debugPrint('Syncing wishlist with backend: $productIds');
  }

  Future<void> addToWishlist(Product product) async {
    if (!_items.any((item) => item.id == product.id)) {
      _items.add(product);
      await _saveWishlist();
      notifyListeners();
    }
  }

  Future<void> removeFromWishlist(int productId) async {
    _items.removeWhere((item) => item.id == productId);
    await _saveWishlist();
    notifyListeners();
  }

  Future<void> toggleWishlist(Product product) async {
    if (isInWishlist(product.id)) {
      await removeFromWishlist(product.id);
    } else {
      await addToWishlist(product);
    }
  }

  bool isInWishlist(int productId) => _items.any((item) => item.id == productId);
  
  /// Clear entire wishlist
  Future<void> clearWishlist() async {
    _items.clear();
    await _saveWishlist();
    notifyListeners();
  }
}
