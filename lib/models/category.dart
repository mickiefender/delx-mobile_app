/// Category model compatible with Django API
class Category {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? image; // Django returns image URL
  final String? imageUrl; // Flutter local asset path (fallback)
  final bool isActive;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    this.slug = '',
    this.description,
    this.image,
    this.imageUrl,
    this.isActive = true,
    this.isFeatured = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get the best available image URL
  String? get displayImage => image ?? imageUrl;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'description': description,
    'image': image,
    'imageUrl': imageUrl,
    'is_active': isActive,
    'is_featured': isFeatured,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

/// Factory constructor to parse Django API response
  factory Category.fromJson(Map<String, dynamic> json) {
    // Safe ID parsing
    int categoryId;
    final idValue = json['id'];
    if (idValue is int) {
      categoryId = idValue;
    } else if (idValue is String) {
      categoryId = int.tryParse(idValue) ?? 0;
    } else {
      categoryId = 0;
    }

    // Safe boolean parsing
    bool categoryIsActive = true;
    final isActiveValue = json['is_active'];
    if (isActiveValue is bool) {
      categoryIsActive = isActiveValue;
    } else if (isActiveValue is int) {
      categoryIsActive = isActiveValue != 0;
    }

    bool categoryIsFeatured = false;
    final isFeaturedValue = json['is_featured'];
    if (isFeaturedValue is bool) {
      categoryIsFeatured = isFeaturedValue;
    } else if (isFeaturedValue is int) {
      categoryIsFeatured = isFeaturedValue != 0;
    }

    return Category(
      id: categoryId,
      name: json['name'] is String ? json['name'] as String : 'Unknown Category',
      slug: json['slug'] is String ? json['slug'] as String : '',
      description: json['description'] as String?,
      image: json['image'] as String?,
      imageUrl: json['imageUrl'] as String?,
      isActive: categoryIsActive,
      isFeatured: categoryIsFeatured,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Category copyWith({
    int? id,
    String? name,
    String? slug,
    String? description,
    String? image,
    String? imageUrl,
    bool? isActive,
    bool? isFeatured,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Category(
    id: id ?? this.id,
    name: name ?? this.name,
    slug: slug ?? this.slug,
    description: description ?? this.description,
    image: image ?? this.image,
    imageUrl: imageUrl ?? this.imageUrl,
    isActive: isActive ?? this.isActive,
    isFeatured: isFeatured ?? this.isFeatured,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
