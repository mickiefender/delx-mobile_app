import 'package:delx/config/api_config.dart';

/// Product model compatible with Django API
class Product {
  final int id;
  final String name;
  final String slug;
  final String? shortDescription;
  final String description;
  final double price;
  final String currency; // Currency code (GHS, USD, EUR, GBP)
  final double? originalPrice;
  final double? oldPrice; // Computed from original_price if discounted
  final int categoryId; // Maps to Django's 'category' (FK id)
  final String? categoryName;
  final String? brandName;
  final String? sku; // Stock Keeping Unit (required for order items)
  final List<String> images;
  final String? image; // Primary image URL
  final double rating;
  final int reviewCount;
  final int stock; // Maps to Django's 'stock_quantity'
  final int stockQuantity;
  final bool isInStock;
  final bool isFeatured;
  final String? collection;
  final String? tags; // Stored as comma-separated in Flutter
  final List<String> tagsList;
  final String? status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    this.slug = '',
    this.shortDescription,
    this.description = '',
    required this.price,
    this.currency = 'GHS',
    this.originalPrice,
    this.oldPrice,
    required this.categoryId,
    this.categoryName,
    this.brandName,
    this.sku,
    this.images = const [],
    this.image,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.stock,
    this.stockQuantity = 0,
    this.isInStock = true,
    this.isFeatured = false,
    this.collection,
    this.tags,
    this.tagsList = const [],
    this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate discount percentage from original_price
  double get discountPercentage {
    if (originalPrice == null || originalPrice! <= price) return 0;
    return ((originalPrice! - price) / originalPrice! * 100);
  }

  bool get hasDiscount => originalPrice != null && originalPrice! > price;
  bool get inStock => stock > 0 || stockQuantity > 0;

Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'short_description': shortDescription,
    'description': description,
    'price': price,
    'currency': currency,
    'original_price': originalPrice,
    'oldPrice': oldPrice,
    'category': categoryId,
    'categoryId': categoryId,
    'category_name': categoryName,
    'brand_name': brandName,
    'sku': sku,
    'images': images,
    'image': image,
    'rating': rating,
    'review_count': reviewCount,
    'stock': stock,
    'stock_quantity': stockQuantity,
    'is_in_stock': isInStock,
    'is_featured': isFeatured,
    'collection': collection,
    'tags': tags ?? tagsList.join(','),
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  /// Factory constructor to parse Django API response
  factory Product.fromJson(Map<String, dynamic> json) {
    // ===== SAFE ID PARSING =====
    int productId;
    final idValue = json['id'];
    if (idValue is int) {
      productId = idValue;
    } else if (idValue is String) {
      productId = int.tryParse(idValue) ?? 0;
    } else {
      productId = 0;
    }

    // ===== HANDLE IMAGES =====
    List<String> productImages = [];
    if (json['images'] != null) {
      if (json['images'] is List) {
        productImages = (json['images'] as List)
            .map((img) {
              if (img is Map<String, dynamic>) {
                return img['image']?.toString() ?? '';
              } else if (img is String) {
                return img;
              }
              return '';
            })
            .where((url) => url.isNotEmpty)
            .toList();
      }
    }
    
    // Fallback to primary image if no additional images
    if (productImages.isEmpty && json['image'] != null) {
      final imageVal = json['image'];
      if (imageVal is String && imageVal.isNotEmpty) {
        productImages.add(imageVal);
      }
    }

    // ===== SAFE PRICE PARSING =====
    double productPrice;
    final priceValue = json['price'];
    if (priceValue is num) {
      productPrice = priceValue.toDouble();
    } else if (priceValue is String) {
      productPrice = double.tryParse(priceValue) ?? 0.0;
    } else {
      productPrice = 0.0;
    }

    // ===== SAFE CURRENCY PARSING =====
    String productCurrency = 'GHS';
    final currencyValue = json['currency'];
    if (currencyValue is String && currencyValue.isNotEmpty) {
      productCurrency = currencyValue;
    }

    double? originalPrice;
    final origPriceValue = json['original_price'];
    if (origPriceValue != null) {
      if (origPriceValue is num) {
        originalPrice = origPriceValue.toDouble();
      } else if (origPriceValue is String) {
        originalPrice = double.tryParse(origPriceValue);
      }
    }

// Safe oldPrice parsing - handles String, num, null
    double? oldPrice;
    final oldPriceValue = json['oldPrice'];
    if (oldPriceValue != null) {
      if (oldPriceValue is num) {
        oldPrice = oldPriceValue.toDouble();
      } else if (oldPriceValue is String && oldPriceValue.isNotEmpty) {
        oldPrice = double.tryParse(oldPriceValue);
      }
    }

    // ===== SAFE RATING PARSING =====
    double productRating;
    final ratingValue = json['rating'];
    if (ratingValue is num) {
      productRating = ratingValue.toDouble();
    } else if (ratingValue is String) {
      productRating = double.tryParse(ratingValue) ?? 0.0;
    } else {
      productRating = 0.0;
    }

    // ===== SAFE REVIEW COUNT =====
    int productReviewCount;
    final reviewValue = json['review_count'];
    if (reviewValue is int) {
      productReviewCount = reviewValue;
    } else if (reviewValue is num) {
      productReviewCount = reviewValue.toInt();
    } else {
      productReviewCount = 0;
    }

    // ===== SAFE STOCK PARSING =====
    int productStock;
    final stockValue = json['stock_quantity'] ?? json['stock'];
    if (stockValue is int) {
      productStock = stockValue;
    } else if (stockValue is num) {
      productStock = stockValue.toInt();
    } else {
      productStock = 0;
    }

    // ===== SAFE CATEGORY ID =====
    int catId;
    final categoryValue = json['category'] ?? json['categoryId'];
    if (categoryValue is int) {
      catId = categoryValue;
    } else if (categoryValue is String) {
      catId = int.tryParse(categoryValue) ?? 0;
    } else {
      catId = 0;
    }

    // ===== SAFE BOOLEAN PARSING =====
    bool isFeatured = false;
    final featuredValue = json['is_featured'];
    if (featuredValue is bool) {
      isFeatured = featuredValue;
    } else if (featuredValue is int) {
      isFeatured = featuredValue != 0;
    }

    bool isInStock = true;
    final inStockValue = json['is_in_stock'];
    if (inStockValue is bool) {
      isInStock = inStockValue;
    } else if (inStockValue is int) {
      isInStock = inStockValue != 0;
    }

    // ===== SAFE DATE PARSING =====
    DateTime createdAt, updatedAt;
    try {
      final createdStr = json['created_at']?.toString();
      createdAt = createdStr != null && createdStr.isNotEmpty 
          ? DateTime.parse(createdStr) 
          : DateTime.now();
    } catch (_) {
      createdAt = DateTime.now();
    }
    try {
      final updatedStr = json['updated_at']?.toString();
      updatedAt = updatedStr != null && updatedStr.isNotEmpty 
          ? DateTime.parse(updatedStr) 
          : DateTime.now();
    } catch (_) {
      updatedAt = DateTime.now();
    }

    // ===== PARSE TAGS =====
    final tagsString = json['tags']?.toString() ?? '';
    final tagsList = tagsString.isNotEmpty 
        ? tagsString.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList()
        : <String>[];

    // Map collection field to tags if no tags provided
    final collection = json['collection']?.toString() ?? '';
    if (collection.isNotEmpty && tagsList.isEmpty) {
      switch (collection) {
        case 'new_arrival':
          tagsList.add('new');
          break;
        case 'best_seller':
          tagsList.add('bestseller');
          break;
        case 'special_offer':
          tagsList.add('sale');
          break;
      }
    }

return Product(
      id: productId,
      name: json['name']?.toString() ?? 'Unknown Product',
      slug: json['slug']?.toString() ?? '',
      shortDescription: json['short_description']?.toString(),
      description: json['description']?.toString() ?? '',
      price: productPrice,
      currency: productCurrency,
      originalPrice: originalPrice,
      oldPrice: oldPrice,
      categoryId: catId,
      categoryName: json['category_name']?.toString(),
      brandName: json['brand_name']?.toString(),
      sku: json['sku']?.toString(),
      images: productImages,
      image: json['image']?.toString(),
      rating: productRating,
      reviewCount: productReviewCount,
      stock: productStock,
      stockQuantity: productStock,
      isInStock: isInStock,
      isFeatured: isFeatured,
      collection: collection,
      tags: tagsString,
      tagsList: tagsList,
      status: json['status']?.toString(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

Product copyWith({
    int? id,
    String? name,
    String? slug,
    String? shortDescription,
    String? description,
    double? price,
    String? currency,
    double? originalPrice,
    double? oldPrice,
    int? categoryId,
    String? categoryName,
    String? brandName,
    String? sku,
    List<String>? images,
    String? image,
    double? rating,
    int? reviewCount,
    int? stock,
    int? stockQuantity,
    bool? isInStock,
    bool? isFeatured,
    String? collection,
    String? tags,
    List<String>? tagsList,
String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        slug: slug ?? this.slug,
        shortDescription: shortDescription ?? this.shortDescription,
        description: description ?? this.description,
        price: price ?? this.price,
        currency: currency ?? this.currency,
        originalPrice: originalPrice ?? this.originalPrice,
        oldPrice: oldPrice ?? this.oldPrice,
        categoryId: categoryId ?? this.categoryId,
        categoryName: categoryName ?? this.categoryName,
        brandName: brandName ?? this.brandName,
        sku: sku ?? this.sku,
        images: images ?? this.images,
        image: image ?? this.image,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        stock: stock ?? this.stock,
        stockQuantity: stockQuantity ?? this.stockQuantity,
        isInStock: isInStock ?? this.isInStock,
        isFeatured: isFeatured ?? this.isFeatured,
        collection: collection ?? this.collection,
        tags: tags ?? this.tags,
        tagsList: tagsList ?? this.tagsList,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  List<String> get resolvedImages {
    final sourceImages = images.isNotEmpty
        ? images
        : (image != null && image!.isNotEmpty ? [image!] : <String>[]);
    return sourceImages
        .map(_normalizeImageUrl)
        .where((url) => url.isNotEmpty)
        .toList();
  }

  String? get resolvedPrimaryImage {
    if (resolvedImages.isNotEmpty) {
      return resolvedImages.first;
    }
    if (image == null || image!.isEmpty) {
      return null;
    }
    return _normalizeImageUrl(image!);
  }

  static String _normalizeImageUrl(String value) {
    final imageValue = value.trim();
    if (imageValue.isEmpty) return '';
    if (imageValue.startsWith('http://') || imageValue.startsWith('https://')) {
      return imageValue;
    }
    if (imageValue.startsWith('assets/')) {
      return imageValue;
    }
    if (imageValue.startsWith('/')) {
      return '${ApiConfig.baseUrl}$imageValue';
    }
    return '${ApiConfig.baseUrl}/$imageValue';
  }
}
