import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:delx/models/brand.dart';

class BrandCard extends StatelessWidget {
  final Brand brand;
  final bool isCircular;

  const BrandCard({
    super.key,
    required this.brand,
    this.isCircular = true,
  });

  String? get logoUrl => brand.displayLogo;

  bool get isNetworkImage {
    final logo = logoUrl;
    if (logo == null) return false;
    return logo.startsWith('http://') || logo.startsWith('https://');
  }

  Widget _buildFallbackWidget(BuildContext context, double size) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircular ? null : BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          brand.name.isNotEmpty ? brand.name[0].toUpperCase() : 'B',
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(BuildContext context, double size) {
    if (logoUrl == null) {
      return _buildFallbackWidget(context, size);
    }

    if (isNetworkImage) {
      return CachedNetworkImage(
        imageUrl: logoUrl!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isCircular ? null : BorderRadius.circular(12),
          ),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildFallbackWidget(context, size),
      );
    }

    return Image.asset(
      logoUrl!,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          _buildFallbackWidget(context, size),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.push('/products', extra: {'brandSlug': brand.slug}),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildImageWidget(context, 66),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 90,
            child: Text(
              brand.name,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
