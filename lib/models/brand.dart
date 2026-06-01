/// Brand model for product brands
class Brand {
  final int id;
  final String name;
  final String slug;
  final String? logo;
  final bool isActive;
  final DateTime createdAt;

  Brand({
    required this.id,
    required this.name,
    required this.slug,
    this.logo,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

factory Brand.fromJson(Map<String, dynamic> json) {
    // Safe ID parsing
    int brandId;
    final idValue = json['id'];
    if (idValue is int) {
      brandId = idValue;
    } else if (idValue is String) {
      brandId = int.tryParse(idValue) ?? 0;
    } else {
      brandId = 0;
    }

    // Safe is_active parsing
    bool brandIsActive = true;
    final isActiveValue = json['is_active'];
    if (isActiveValue is bool) {
      brandIsActive = isActiveValue;
    } else if (isActiveValue is int) {
      brandIsActive = isActiveValue != 0;
    }

    return Brand(
      id: brandId,
      name: json['name'] is String ? json['name'] as String : 'Unknown Brand',
      slug: json['slug'] is String ? json['slug'] as String : '',
      logo: json['logo'] as String?,
      isActive: brandIsActive,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'logo': logo,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Get the display logo URL (supports both network and local assets)
  String? get displayLogo => logo;

  /// Check if the logo is a network URL
  bool get isNetworkLogo {
    final logoUrl = displayLogo;
    if (logoUrl == null) return false;
    return logoUrl.startsWith('http://') || logoUrl.startsWith('https://');
  }

  /// Fallback brands for when API is unavailable
  static List<Brand> getFallbackBrands() {
    final now = DateTime.now();
    return [
      Brand(id: 1, name: 'Apple', slug: 'apple', logo: null, createdAt: now),
      Brand(id: 2, name: 'Samsung', slug: 'samsung', logo: null, createdAt: now),
      Brand(id: 3, name: 'Sony', slug: 'sony', logo: null, createdAt: now),
      Brand(id: 4, name: 'Nike', slug: 'nike', logo: null, createdAt: now),
      Brand(id: 5, name: 'Adidas', slug: 'adidas', logo: null, createdAt: now),
      Brand(id: 6, name: 'Levi\'s', slug: 'levis', logo: null, createdAt: now),
    ];
  }
}
