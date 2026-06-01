import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:delx/models/category.dart' as models;

class CategoryCard extends StatelessWidget {
  final models.Category category;

  const CategoryCard({super.key, required this.category});

  /// Get the image URL (supports both network and local assets)
  String? get imageUrl => category.displayImage;

  /// Check if the image is a network URL
  bool get isNetworkImage {
    final image = imageUrl;
    if (image == null) return false;
    return image.startsWith('http://') || image.startsWith('https://');
  }

  /// Build the appropriate image widget
  Widget _buildImageWidget(double height, double width) {
    if (imageUrl == null) {
      return Container(
        height: height,
        width: width,
        color: Colors.grey[200],
        child: Icon(
          Icons.category,
          size: 40,
          color: Colors.grey[400],
        ),
      );
    }

    if (isNetworkImage) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        height: height,
        width: width,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: height,
          width: width,
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: height,
          width: width,
          color: Colors.grey[200],
          child: Icon(
            Icons.category,
            size: 40,
            color: Colors.grey[400],
          ),
        ),
      );
    }

    // Local asset
    return Image.asset(
      imageUrl!,
      height: height,
      width: width,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        height: height,
        width: width,
        color: Colors.grey[200],
        child: Icon(
          Icons.category,
          size: 40,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.push('/products', extra: {'categoryId': category.id}),
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: _buildImageWidget(80, 120),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                category.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
