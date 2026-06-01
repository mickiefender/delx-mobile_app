/// HomeAd model matching backend HomeAdBanner model
/// Used for displaying two ad banners under the New Arrivals section
class HomeAd {
  final int id;
  final int position; // 1 = left/first, 2 = right/second
  final String imageUrl;
  final String linkUrl;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  HomeAd({
    required this.id,
    required this.position,
    required this.imageUrl,
    this.linkUrl = '',
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory HomeAd.fromJson(Map<String, dynamic> json) {
    return HomeAd(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      position: json['position'] is int ? json['position'] : int.tryParse(json['position'].toString()) ?? 1,
      imageUrl: json['image']?.toString() ?? '',
      linkUrl: json['link_url']?.toString() ?? '',
      isActive: json['is_active'] is bool ? json['is_active'] : true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'position': position,
      'image': imageUrl,
      'link_url': linkUrl,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Fallback static home ads when API fails
  static List<HomeAd> getFallbackAds() {
    return [
      HomeAd(
        id: 1,
        position: 1,
        imageUrl: 'assets/images/Fashion_Accessories_null_1778970670644.jpg',
        linkUrl: '/products',
        isActive: true,
      ),
      HomeAd(
        id: 2,
        position: 2,
        imageUrl: 'assets/images/Electronics_Gadgets_null_1778970671563.jpg',
        linkUrl: '/products',
        isActive: true,
      ),
    ];
  }
}
