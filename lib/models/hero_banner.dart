/// Hero banner model matching backend HeroBanner model
class HeroBanner {
  final int id;
  final String title;
  final String subtitle;
  final String ctaText;
  final String ctaUrl;
  final String imageUrl;
  final int sortOrder;
  final int durationSeconds;

  HeroBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.ctaText,
    required this.ctaUrl,
    required this.imageUrl,
    this.sortOrder = 0,
    this.durationSeconds = 6,
  });

  factory HeroBanner.fromJson(Map<String, dynamic> json) {
    return HeroBanner(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      ctaText: json['cta_text']?.toString() ?? 'Shop Now',
      ctaUrl: json['cta_url']?.toString() ?? '',
      imageUrl: json['image']?.toString() ?? '',
      sortOrder: json['sort_order'] is int ? json['sort_order'] : 0,
      durationSeconds: json['duration_seconds'] is int ? json['duration_seconds'] : 6,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'cta_text': ctaText,
      'cta_url': ctaUrl,
      'image': imageUrl,
      'sort_order': sortOrder,
      'duration_seconds': durationSeconds,
    };
  }

  /// Fallback static banners when API fails
  static List<HeroBanner> getFallbackBanners() {
    return [
      HeroBanner(
        id: 1,
        title: 'MODERN ELECTRICAL APPLIANCES',
        subtitle: 'Transform Your Home with Latest Technology',
        ctaText: 'SHOP NOW',
        ctaUrl: '/products',
        imageUrl: 'assets/images/Modern_Kitchen_Appliances_null_1778970670003.jpg',
        sortOrder: 0,
      ),
      HeroBanner(
        id: 2,
        title: 'FASHION ESSENTIALS',
        subtitle: 'Style Meets Comfort',
        ctaText: 'SHOP NOW',
        ctaUrl: '/products',
        imageUrl: 'assets/images/Fashion_Accessories_null_1778970670644.jpg',
        sortOrder: 1,
      ),
      HeroBanner(
        id: 3,
        title: 'TECH GADGETS',
        subtitle: 'Upgrade Your Digital Life',
        ctaText: 'SHOP NOW',
        ctaUrl: '/products',
        imageUrl: 'assets/images/Electronics_Gadgets_null_1778970671563.jpg',
        sortOrder: 2,
      ),
    ];
  }
}
