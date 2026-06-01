import 'package:flutter/foundation.dart';
import 'package:delx/models/product.dart';
import 'package:delx/models/category.dart' as models;
import 'package:delx/models/brand.dart';
import 'package:delx/models/hero_banner.dart';
import 'package:delx/models/home_ad.dart';
import 'package:delx/config/api_config.dart';
import 'package:delx/services/api_service.dart';

/// Product service that fetches data from Django backend
class ProductService extends ChangeNotifier {
  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  List<Product> _newArrivals = [];
  List<Product> _bestSellers = [];
  List<models.Category> _categories = [];
  List<Brand> _brands = [];
  List<HeroBanner> _heroBanners = [];
  List<HomeAd> _homeAds = [];
  bool _isLoading = false;
  bool _isLoadingProducts = false;
  bool _isLoadingFeatured = false;
  bool _isLoadingNewArrivals = false;
  bool _isLoadingBestSellers = false;
  bool _isLoadingBrands = false;
  bool _isLoadingHeroBanners = false;
  bool _isLoadingHomeAds = false;
  String? _error;
  String? _productsError;
  String? _featuredError;
  String? _newArrivalsError;
  String? _bestSellersError;
  String? _brandsError;

  // Pagination state
  int _currentPage = 1;
  int _pageSize = 20;
  int _totalCount = 0;
  bool _hasMorePages = true;
  bool _isLoadingMore = false;
  String? _nextPageUrl;

  // Getters for pagination state
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalCount => _totalCount;
  bool get hasMorePages => _hasMorePages;
  bool get isLoadingMore => _isLoadingMore;
  int get totalPages => (_totalCount / _pageSize).ceil();

  List<Product> get products => _products;
  List<Product> get featuredProducts => _featuredProducts;
  List<Product> get newArrivals => _newArrivals;
  List<Product> get bestSellers => _bestSellers;
  List<models.Category> get categories => _categories;
  List<Brand> get brands => _brands;
  List<HeroBanner> get heroBanners => _heroBanners;
  List<HomeAd> get homeAds => _homeAds;
  bool get isLoading => _isLoading;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isLoadingFeatured => _isLoadingFeatured;
  bool get isLoadingNewArrivals => _isLoadingNewArrivals;
  bool get isLoadingBestSellers => _isLoadingBestSellers;
  bool get isLoadingBrands => _isLoadingBrands;
  bool get isLoadingHeroBanners => _isLoadingHeroBanners;
  bool get isLoadingHomeAds => _isLoadingHomeAds;
  String? get error => _error;
  String? get productsError => _productsError;
  String? get featuredError => _featuredError;
  String? get newArrivalsError => _newArrivalsError;
  String? get bestSellersError => _bestSellersError;
  String? get brandsError => _brandsError;

/// Initialize the service and load data from API
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

try {
      // Initialize API service
      await apiService.init();
      
// Load all data in parallel
await Future.wait([
        loadCategories(),
        loadBrands(),
        loadProducts(),
        loadFeaturedProducts(),
        loadNewArrivals(),
        loadBestSellers(),
        loadHeroBanners(),
        loadHomeAds(),
      ]);
    } catch (e) {
      _error = e.toString();
      debugPrint('Failed to load data: $e');
      // Fall back to sample data if API fails
      await _loadFallbackData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load categories from Django API
  Future<void> loadCategories() async {
    try {
      final response = await apiService.get(ApiConfig.categories);
      
      // Handle both list response and paginated response
      List<dynamic> categoriesList;
      if (response.containsKey('results')) {
        categoriesList = response['results'] as List<dynamic>;
      } else if (response.containsKey('categories')) {
        categoriesList = response['categories'] as List<dynamic>;
      } else {
        // Treat the entire response as a list
        categoriesList = response.entries
            .where((e) => e.value is List)
            .expand((e) => e.value as List)
            .toList();
      }

      if (categoriesList.isNotEmpty) {
        _categories = categoriesList
            .map((json) => models.Category.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        _loadFallbackCategories();
      }
    } catch (e) {
      debugPrint('Failed to load categories: $e');
      // Keep existing categories if any
      if (_categories.isEmpty) {
        _loadFallbackCategories();
      }
    }
  }

/// Load brands from Django API
  Future<void> loadBrands() async {
    _isLoadingBrands = true;
    _brandsError = null;
    notifyListeners();

    try {
      final response = await apiService.get(ApiConfig.brands);
      
      // Handle both list response and paginated response
      List<dynamic> brandsList;
      if (response.containsKey('results')) {
        brandsList = response['results'] as List<dynamic>;
      } else if (response is List) {
        brandsList = response as List<dynamic>;
      } else {
        brandsList = [];
      }

      if (brandsList.isNotEmpty) {
        _brands = brandsList
            .map((json) => Brand.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        _brands = Brand.getFallbackBrands();
      }
    } catch (e) {
      debugPrint('Failed to load brands: $e');
      _brandsError = e.toString();
      _brands = Brand.getFallbackBrands();
    } finally {
      _isLoadingBrands = false;
      notifyListeners();
    }
  }

/// Load products from Django API (first page)
  Future<void> loadProducts() async {
    _isLoadingProducts = true;
    _productsError = null;
    _currentPage = 1;
    _hasMorePages = true;
    notifyListeners();

    try {
      final response = await apiService.get(
        ApiConfig.products,
        queryParams: {'page': '1', 'page_size': _pageSize.toString()},
      );
      
      // Handle paginated response or list response
      List<dynamic> productsList;
      if (response.containsKey('results')) {
        productsList = response['results'] as List<dynamic>;
        // Extract pagination info
        _totalCount = response['count'] as int? ?? productsList.length;
        _nextPageUrl = response['next'] as String?;
        _hasMorePages = _nextPageUrl != null;
      } else if (response.containsKey('products')) {
        productsList = response['products'] as List<dynamic>;
        _totalCount = productsList.length;
        _hasMorePages = false;
      } else {
        productsList = [];
        _totalCount = 0;
        _hasMorePages = false;
      }

      if (productsList.isNotEmpty) {
        _products = productsList
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        _loadFallbackProducts();
      }
    } catch (e) {
      debugPrint('Failed to load products: $e');
      _productsError = e.toString();
      // Keep existing products if any
      if (_products.isEmpty) {
        _loadFallbackProducts();
      }
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  /// Load more products (next page) - for infinite scroll
  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !_hasMorePages) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      String url = ApiConfig.products;
      Map<String, String>? queryParams;

      // Use nextPageUrl if available, otherwise construct URL
      if (_nextPageUrl != null && _nextPageUrl!.isNotEmpty) {
        // Parse next URL to get page number
        final uri = Uri.parse(_nextPageUrl!);
        queryParams = Map<String, String>.from(uri.queryParameters);
        url = '${uri.path}?${uri.query}';
      } else {
        _currentPage++;
        queryParams = {
          'page': _currentPage.toString(),
          'page_size': _pageSize.toString(),
        };
      }

      final response = await apiService.get(url, queryParams: queryParams);
      
      // Handle paginated response
      List<dynamic> productsList;
      if (response.containsKey('results')) {
        productsList = response['results'] as List<dynamic>;
        _totalCount = response['count'] as int? ?? _totalCount;
        _nextPageUrl = response['next'] as String?;
        _hasMorePages = _nextPageUrl != null;
      } else if (response.containsKey('products')) {
        productsList = response['products'] as List<dynamic>;
        _hasMorePages = false;
      } else {
        productsList = [];
        _hasMorePages = false;
      }

      if (productsList.isNotEmpty) {
        final newProducts = productsList
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();
        _products.addAll(newProducts);
        _currentPage++;
      }
    } catch (e) {
      debugPrint('Failed to load more products: $e');
      // Don't set error - just stop loading more
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

/// Load featured products from Django API
  Future<void> loadFeaturedProducts() async {
    _isLoadingFeatured = true;
    _featuredError = null;
    notifyListeners();

    try {
      final response = await apiService.get(ApiConfig.featuredProducts);
      
      // Handle both list response and paginated response
      List<dynamic> productsList;
      if (response.containsKey('results')) {
        productsList = response['results'] as List<dynamic>;
      } else if (response.containsKey('products')) {
        productsList = response['products'] as List<dynamic>;
      } else {
        // Try to extract any list from the response
        productsList = response.entries
            .where((e) => e.value is List)
            .expand((e) => e.value as List)
            .toList();
      }

if (productsList.isNotEmpty) {
        _featuredProducts = productsList
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        // Fall back to products with is_featured flag or best sellers
        _featuredProducts = _getFallbackFeaturedProducts();
      }
      
      // Ensure we always have featured products - force fallback if still empty
      if (_featuredProducts.isEmpty) {
        _featuredProducts = _getFallbackFeaturedProducts();
      }
    } catch (e) {
      debugPrint('Failed to load featured products: $e');
      _featuredError = e.toString();
      // Always use fallback when API fails - don't leave it empty
      _featuredProducts = _getFallbackFeaturedProducts();
    } finally {
      _isLoadingFeatured = false;
      notifyListeners();
    }
  }

/// Load new arrivals from Django API
  Future<void> loadNewArrivals() async {
    _isLoadingNewArrivals = true;
    _newArrivalsError = null;
    notifyListeners();

    try {
      // Try the collection endpoint first
      List<dynamic> productsList = [];
      try {
        final response = await apiService.get(
          '${ApiConfig.products}by_collection/',
          queryParams: {'collection': 'new_arrival'},
        );
        
        if (response.containsKey('results')) {
          productsList = response['results'] as List<dynamic>;
        } else if (response.containsKey('products')) {
          productsList = response['products'] as List<dynamic>;
        }
      } catch (_) {
        // Endpoint might not exist, fall back to filtering locally
      }

      // If collection endpoint failed, filter locally from loaded products
      if (productsList.isEmpty) {
        productsList = _filterNewArrivalsLocal();
      }

      if (productsList.isNotEmpty) {
        _newArrivals = productsList
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        // Fall back to recent products
        _newArrivals = _getFallbackNewArrivals();
      }
    } catch (e) {
      debugPrint('Failed to load new arrivals: $e');
      _newArrivalsError = e.toString();
      _newArrivals = _getFallbackNewArrivals();
} finally {
      _isLoadingNewArrivals = false;
      notifyListeners();
    }
  }

  /// Load best sellers from Django API
  Future<void> loadBestSellers() async {
    _isLoadingBestSellers = true;
    _bestSellersError = null;
    notifyListeners();

    try {
      // Try the best_sellers endpoint first
      List<dynamic> productsList = [];
      try {
        final response = await apiService.get(ApiConfig.bestSellers);
        
        if (response.containsKey('results')) {
          productsList = response['results'] as List<dynamic>;
        } else if (response.containsKey('products')) {
          productsList = response['products'] as List<dynamic>;
        } else if (response is List) {
          productsList = response as List<dynamic>;
        }
      } catch (_) {
        // Endpoint might not exist, fall back to filtering locally
      }

      // If best_sellers endpoint failed, filter locally from loaded products
      if (productsList.isEmpty) {
        productsList = _filterBestSellersLocal();
      }

      if (productsList.isNotEmpty) {
        _bestSellers = productsList
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        // Fall back to high-reviewed products
        _bestSellers = _getFallbackBestSellers();
      }
    } catch (e) {
      debugPrint('Failed to load best sellers: $e');
      _bestSellersError = e.toString();
      _bestSellers = _getFallbackBestSellers();
    } finally {
      _isLoadingBestSellers = false;
      notifyListeners();
    }
  }

  /// Filter best sellers from locally loaded products
  List<dynamic> _filterBestSellersLocal() {
    if (_products.isEmpty) return [];
    
    // Convert to serializable maps - filter by collection or tags
    return _products
        .where((p) => 
          p.collection == 'best_seller' || 
          p.tagsList.contains('bestseller') ||
          p.tagsList.contains('best_seller')
        )
        .take(8)
        .map((p) => p.toJson())
        .toList();
  }

/// Load hero banners from Django API
  Future<void> loadHeroBanners() async {
    _isLoadingHeroBanners = true;
    notifyListeners();

    try {
      final response = await apiService.get(ApiConfig.heroBanners);
      
      // Handle both list response and paginated response
      List<dynamic> bannersList;
      if (response.containsKey('results')) {
        bannersList = response['results'] as List<dynamic>;
      } else if (response is List) {
        bannersList = response as List<dynamic>;
      } else {
        bannersList = [];
      }

      if (bannersList.isNotEmpty) {
        _heroBanners = bannersList
            .map((json) => HeroBanner.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        // Fall back to static banners
        _heroBanners = HeroBanner.getFallbackBanners();
      }
    } catch (e) {
      debugPrint('Failed to load hero banners: $e');
      // Always use fallback when API fails
      _heroBanners = HeroBanner.getFallbackBanners();
    } finally {
      _isLoadingHeroBanners = false;
      notifyListeners();
    }
  }

  /// Load home ads from Django API
  Future<void> loadHomeAds() async {
    _isLoadingHomeAds = true;
    notifyListeners();

    try {
      final response = await apiService.get(ApiConfig.homeAds);
      
      // Handle both list response and paginated response
      List<dynamic> adsList;
      if (response.containsKey('results')) {
        adsList = response['results'] as List<dynamic>;
      } else if (response is List) {
        adsList = response as List<dynamic>;
      } else {
        adsList = [];
      }

      if (adsList.isNotEmpty) {
        _homeAds = adsList
            .map((json) => HomeAd.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        // Fall back to static ads
        _homeAds = HomeAd.getFallbackAds();
      }
    } catch (e) {
      debugPrint('Failed to load home ads: $e');
      // Always use fallback when API fails
      _homeAds = HomeAd.getFallbackAds();
    } finally {
      _isLoadingHomeAds = false;
      notifyListeners();
    }
  }

  /// Filter new arrivals from locally loaded products
  List<dynamic> _filterNewArrivalsLocal() {
    if (_products.isEmpty) return [];
    
    // Convert to serializable maps
    return _products
        .where((p) => 
          p.collection == 'new_arrival' || 
          p.tagsList.contains('new') ||
          p.tagsList.contains('new_arrival')
        )
        .take(8)
        .map((p) => p.toJson())
        .toList();
  }

  /// Load products by category from API
  Future<List<Product>> loadProductsByCategory(int categoryId) async {
    try {
      final response = await apiService.get(
        ApiConfig.products,
        queryParams: {'category': categoryId.toString()},
      );
      
      // Handle both list response and paginated response
      List<dynamic> productsList;
      if (response.containsKey('results')) {
        productsList = response['results'] as List<dynamic>;
      } else if (response.containsKey('products')) {
        productsList = response['products'] as List<dynamic>;
      } else if (response is List) {
        productsList = response as List<dynamic>;
      } else {
        productsList = [];
      }

      return productsList
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Failed to load products by category: $e');
      // Fall back to local filtering
      return getProductsByCategorySync(categoryId);
    }
  }

  /// Get product by ID from API
  Future<Product?> getProductById(int id) async {
    try {
      final response = await apiService.get(ApiConfig.productDetailUrl(id));
      return Product.fromJson(response);
    } catch (e) {
      debugPrint('Failed to get product $id: $e');
      // Fall back to local cache
      return getProductByIdSync(id);
    }
  }

  /// Refresh data from API
  Future<void> refresh() async {
    await loadData();
  }

  /// Refresh products only
  Future<void> refreshProducts() async {
    await Future.wait([
      loadProducts(),
      loadFeaturedProducts(),
      loadNewArrivals(),
    ]);
  }

/// Get featured products synchronously (from cached data)
  List<Product> getFeaturedProductsSync() {
    // First check for is_featured flag from Django
    final featured = _products.where((p) => p.isFeatured).toList();
    if (featured.isNotEmpty) return featured.take(4).toList();
    // Fall back to best_seller collection or high review count
    final bestSellers = _products.where((p) => 
      p.collection == 'best_seller' || p.tagsList.contains('bestseller')
    ).toList();
    if (bestSellers.isNotEmpty) return bestSellers.take(4).toList();
    return _products.take(4).toList();
  }
  
  /// Get new products synchronously (from cached data)
  List<Product> getNewProductsSync() {
    // First check for collection == 'new_arrival'
    final newArrivals = _products.where((p) => p.collection == 'new_arrival').toList();
    if (newArrivals.isNotEmpty) return newArrivals.take(4).toList();
    // Fall back to 'new' tag
    final newTagged = _products.where((p) => p.tagsList.contains('new')).toList();
    if (newTagged.isNotEmpty) return newTagged.take(4).toList();
    // Return last few products as "new" (most recently created)
    return _products.take(4).toList();
  }
  
  /// Get product by ID synchronously (from cached data)
  Product? getProductByIdSync(int id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// Search products locally
  List<Product> searchProductsSync(String query) {
    if (query.isEmpty) return _products;
    final lowerQuery = query.toLowerCase();
    return _products.where((p) => 
      p.name.toLowerCase().contains(lowerQuery) || 
      p.description.toLowerCase().contains(lowerQuery)
    ).toList();
  }

/// Get products by category synchronously
  List<Product> getProductsByCategorySync(int categoryId) {
    return _products.where((p) => p.categoryId == categoryId).toList();
  }

  /// Get related products (same category, excluding current product)
  List<Product> getRelatedProductsSync(int productId, {int limit = 6}) {
    // Find the current product to get its category
    final currentProduct = getProductByIdSync(productId);
    if (currentProduct == null) return [];

    // Get products from the same category, excluding the current product
    final related = _products
        .where((p) => p.categoryId == currentProduct.categoryId && p.id != productId)
        .toList();

    // Shuffle for variety and limit the results
    related.shuffle();
    return related.take(limit).toList();
  }

  /// Get products by same brand (related products alternative)
  List<Product> getProductsByBrandSync(String brandName, {int limit = 6}) {
    if (brandName.isEmpty) return [];
    final related = _products
        .where((p) => p.brandName == brandName)
        .toList();
    related.shuffle();
    return related.take(limit).toList();
  }

  /// Load fallback categories when API is unavailable
  void _loadFallbackCategories() {
    final now = DateTime.now();
    _categories = [
      models.Category(id: 1, name: 'Electronics', slug: 'electronics', imageUrl: 'assets/images/Electronics_Gadgets_null_1778970671563.jpg', createdAt: now, updatedAt: now),
      models.Category(id: 2, name: 'Fashion', slug: 'fashion', imageUrl: 'assets/images/Fashion_Accessories_null_1778970670644.jpg', createdAt: now, updatedAt: now),
      models.Category(id: 3, name: 'Home & Kitchen', slug: 'home-kitchen', imageUrl: 'assets/images/Modern_Kitchen_Appliances_null_1778970670003.jpg', createdAt: now, updatedAt: now),
      models.Category(id: 4, name: 'Sports', slug: 'sports', imageUrl: 'assets/images/Sports_Equipment_null_1778970673426.jpg', createdAt: now, updatedAt: now),
      models.Category(id: 5, name: 'Books', slug: 'books', imageUrl: 'assets/images/Books_and_Education_null_1778970674251.jpg', createdAt: now, updatedAt: now),
      models.Category(id: 6, name: 'Home Decor', slug: 'home-decor', imageUrl: 'assets/images/Home_Decor_null_1778970672308.jpg', createdAt: now, updatedAt: now),
    ];
  }

  /// Load fallback products when API is unavailable
  void _loadFallbackProducts() {
    final now = DateTime.now();
    _products = [
      Product(id: 1, name: 'Wireless Headphones Pro', description: 'Premium noise-canceling wireless headphones with 30-hour battery life.', price: 129.99, originalPrice: 179.99, categoryId: 1, categoryName: 'Electronics', images: ['assets/images/Electronics_Gadgets_null_1778970671563.jpg'], rating: 4.5, reviewCount: 234, stock: 45, tagsList: ['bestseller', 'new'], createdAt: now, updatedAt: now),
      Product(id: 2, name: 'Smart Watch Series 5', description: 'Advanced fitness tracking with heart rate monitoring and GPS.', price: 299.99, originalPrice: 399.99, categoryId: 1, categoryName: 'Electronics', images: ['assets/images/Electronics_Gadgets_null_1778970671563.jpg'], rating: 4.7, reviewCount: 567, stock: 32, tagsList: ['bestseller'], createdAt: now, updatedAt: now),
      Product(id: 3, name: 'Leather Handbag', description: 'Elegant genuine leather handbag with multiple compartments.', price: 89.99, originalPrice: 129.99, categoryId: 2, categoryName: 'Fashion', images: ['assets/images/Fashion_Accessories_null_1778970670644.jpg'], rating: 4.3, reviewCount: 123, stock: 28, tagsList: ['trending'], createdAt: now, updatedAt: now),
      Product(id: 4, name: 'Designer Sunglasses', description: 'UV-protected polarized lenses with stylish frames.', price: 59.99, categoryId: 2, categoryName: 'Fashion', images: ['assets/images/Fashion_Accessories_null_1778970670644.jpg'], rating: 4.6, reviewCount: 89, stock: 55, createdAt: now, updatedAt: now),
      Product(id: 5, name: 'Coffee Maker Deluxe', description: 'Programmable coffee maker with thermal carafe.', price: 79.99, originalPrice: 119.99, categoryId: 3, categoryName: 'Home & Kitchen', images: ['assets/images/Modern_Kitchen_Appliances_null_1778970670003.jpg'], rating: 4.4, reviewCount: 178, stock: 41, tagsList: ['bestseller'], createdAt: now, updatedAt: now),
      Product(id: 6, name: 'Blender Pro 3000', description: 'High-performance blender with stainless steel blades.', price: 119.99, originalPrice: 159.99, categoryId: 3, categoryName: 'Home & Kitchen', images: ['assets/images/Modern_Kitchen_Appliances_null_1778970670003.jpg'], rating: 4.8, reviewCount: 312, stock: 23, tagsList: ['new'], createdAt: now, updatedAt: now),
      Product(id: 7, name: 'Yoga Mat Premium', description: 'Extra thick non-slip yoga mat with carrying strap.', price: 34.99, originalPrice: 49.99, categoryId: 4, categoryName: 'Sports', images: ['assets/images/Sports_Equipment_null_1778970673426.jpg'], rating: 4.5, reviewCount: 445, stock: 67, tagsList: ['trending'], createdAt: now, updatedAt: now),
      Product(id: 8, name: 'Dumbbell Set 20kg', description: 'Adjustable dumbbell set with rubberized coating.', price: 149.99, categoryId: 4, categoryName: 'Sports', images: ['assets/images/Sports_Equipment_null_1778970673426.jpg'], rating: 4.6, reviewCount: 267, stock: 18, createdAt: now, updatedAt: now),
      Product(id: 9, name: 'The Complete Guide to Flutter', description: 'Comprehensive guide for building mobile applications.', price: 39.99, originalPrice: 54.99, categoryId: 5, categoryName: 'Books', images: ['assets/images/Books_and_Education_null_1778970674251.jpg'], rating: 4.9, reviewCount: 892, stock: 156, tagsList: ['bestseller'], createdAt: now, updatedAt: now),
      Product(id: 10, name: 'Modern Wall Art Canvas', description: 'Contemporary abstract art print on premium canvas.', price: 69.99, categoryId: 6, categoryName: 'Home Decor', images: ['assets/images/Home_Decor_null_1778970672308.jpg'], rating: 4.4, reviewCount: 134, stock: 34, tagsList: ['new'], createdAt: now, updatedAt: now),
    ];
  }

/// Load fallback data when API is unavailable
  Future<void> _loadFallbackData() async {
    _loadFallbackCategories();
    _loadFallbackProducts();
    _brands = Brand.getFallbackBrands();
    _featuredProducts = _getFallbackFeaturedProducts();
    _newArrivals = _getFallbackNewArrivals();
    _bestSellers = _getFallbackBestSellers();
  }

/// Get fallback featured products (for API failures)
  List<Product> _getFallbackFeaturedProducts() {
    // 1. Try products with is_featured flag from Django
    final featured = _products.where((p) => p.isFeatured).toList();
    if (featured.isNotEmpty) return featured.take(4).toList();
    
    // 2. Try best sellers by collection or tags
    final bestSellers = _products.where((p) =>
      p.collection == 'best_seller' || 
      p.collection == 'bestseller' ||
      p.tagsList.contains('bestseller') ||
      p.tagsList.contains('best_seller')
    ).toList();
    if (bestSellers.isNotEmpty) return bestSellers.take(4).toList();
    
    // 3. Fall back to high-rated products
    final sorted = List<Product>.from(_products)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    if (sorted.isNotEmpty) return sorted.take(4).toList();
    
    // 4. Last resort - just return first products
    return _products.take(4).toList();
  }

/// Get fallback new arrivals (for API failures)
  List<Product> _getFallbackNewArrivals() {
    // 1. Try new_arrival collection first
    final newArrivals = _products.where((p) => p.collection == 'new_arrival').toList();
    if (newArrivals.isNotEmpty) return newArrivals.take(4).toList();
    
    // 2. Fall back to 'new' tag
    final newTagged = _products.where((p) => 
      p.tagsList.contains('new') || 
      p.tagsList.contains('new_arrival')
    ).toList();
    if (newTagged.isNotEmpty) return newTagged.take(4).toList();
    
    // 3. Return first few products as "new"
    return _products.take(4).toList();
  }

  /// Get fallback best sellers (for API failures)
  List<Product> _getFallbackBestSellers() {
    // 1. Try best_seller collection first
    final bestSellers = _products.where((p) => p.collection == 'best_seller').toList();
    if (bestSellers.isNotEmpty) return bestSellers.take(4).toList();
    
    // 2. Fall back to 'bestseller' tag
    final bestTagged = _products.where((p) => 
      p.tagsList.contains('bestseller') || 
      p.tagsList.contains('best_seller')
    ).toList();
    if (bestTagged.isNotEmpty) return bestTagged.take(4).toList();
    
    // 3. Fall back to high review count products
    final sorted = List<Product>.from(_products)
      ..sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    if (sorted.isNotEmpty) return sorted.take(4).toList();
    
    // 4. Last resort - just return first products
    return _products.take(4).toList();
  }
}
