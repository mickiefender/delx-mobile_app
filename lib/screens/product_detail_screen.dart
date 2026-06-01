import 'package:cached_network_image/cached_network_image.dart';
import 'package:delx/models/product.dart';
import 'package:delx/services/cart_service.dart';
import 'package:delx/services/product_service.dart';
import 'package:delx/services/wishlist_service.dart';
import 'package:delx/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final PageController _imageController = PageController();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_GH',
    symbol: 'GH₵',
    decimalDigits: 2,
  );

  int _quantity = 1;
  int _selectedImageIndex = 0;
  Product? _product;
  bool _isLoading = true;
  String? _error;
  List<Product> _relatedProducts = [];

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

try {
      final productId = int.tryParse(widget.productId) ?? int.parse(widget.productId);
      final productService = context.read<ProductService>();
      final product = await productService.getProductById(productId);

      if (!mounted) return;

      setState(() {
        _product = product;
        _isLoading = false;
        _selectedImageIndex = 0;
        if (product == null) {
          _error = 'Product not found';
        } else {
          // Load related products from the same category
          _relatedProducts = productService.getRelatedProductsSync(product.id, limit: 6);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load product';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wishlistService = context.watch<WishlistService>();

if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _product == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Product not found',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadProduct,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final product = _product!;
    final images = product.resolvedImages;
    final hasImages = images.isNotEmpty;
    final isWishlisted = wishlistService.isInWishlist(product.id);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 440,
                  backgroundColor: theme.colorScheme.surface,
leading: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        onPressed: () => context.go('/'),
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                      ),
                    ),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: IconButton(
                          onPressed: () => wishlistService.toggleWishlist(product),
                          icon: Icon(
                            isWishlisted ? Icons.favorite : Icons.favorite_border,
                            color: isWishlisted ? Colors.red : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      children: [
                        Positioned.fill(
                          child: hasImages
                              ? PageView.builder(
                                  controller: _imageController,
                                  itemCount: images.length,
                                  onPageChanged: (index) {
                                    setState(() => _selectedImageIndex = index);
                                  },
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                      onTap: () => _openImageViewer(context, images, index),
                                      child: _buildImage(context, images[index]),
                                    );
                                  },
                                )
                              : _buildPlaceholder(context),
                        ),
                        if (product.hasDiscount)
                          Positioned(
                            top: 92,
                            left: 20,
                            child: _DiscountBadge(
                              text: '-${product.discountPercentage.round()}% OFF',
                              theme: theme,
                            ),
                          ),
                        if (hasImages && images.length > 1)
                          Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: SmoothPageIndicator(
                                controller: _imageController,
                                count: images.length,
                                effect: WormEffect(
                                  dotHeight: 8,
                                  dotWidth: 8,
                                  activeDotColor: theme.colorScheme.primary,
                                  dotColor: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.categoryName != null)
                          Text(
                            product.categoryName!,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          product.name,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${product.reviewCount} reviews)',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _currencyFormat.format(product.price),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            if (product.hasDiscount) ...[
                              const SizedBox(width: 12),
                              Text(
                                _currencyFormat.format(product.originalPrice ?? product.oldPrice ?? product.price),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        _InfoPill(
                          icon: product.inStock ? Icons.inventory_2_outlined : Icons.block_outlined,
                          label: product.inStock
                              ? 'In Stock • ${product.stockQuantity > 0 ? product.stockQuantity : product.stock} available'
                              : 'Out of Stock',
                          backgroundColor: product.inStock
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.errorContainer,
                          foregroundColor: product.inStock
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onErrorContainer,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Images',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        if (hasImages)
                          SizedBox(
                            height: 92,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: images.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                final isSelected = index == _selectedImageIndex;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedImageIndex = index);
                                    _imageController.animateToPage(
                                      index,
                                      duration: const Duration(milliseconds: 250),
                                      curve: Curves.easeOut,
                                    );
                                    _openImageViewer(context, images, index);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 92,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                                        width: isSelected ? 2.5 : 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(13),
                                      child: _buildImage(context, images[index]),
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        else
                          Text(
                            'No additional images uploaded for this product.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        const SizedBox(height: 24),
                        Text(
                          'Description',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _plainDescription(product),
                          style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Quantity',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _QuantityButton(
                              icon: Icons.remove,
                              onPressed: _quantity > 1 ? () => setState(() => _quantity -= 1) : null,
                              filled: false,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                '$_quantity',
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ),
_QuantityButton(
                              icon: Icons.add,
                              onPressed: _quantity < product.stock ? () => setState(() => _quantity += 1) : null,
                              filled: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Related Products Section
                        if (_relatedProducts.isNotEmpty) ...[
                          Text(
                            'Related Products',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 280,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _relatedProducts.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                if (index >= _relatedProducts.length) return const SizedBox.shrink();
final relatedProduct = _relatedProducts[index];
                                return SizedBox(
                                  width: 160,
                                  child: ProductCard(product: relatedProduct),
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: product.inStock
                          ? () async {
                              final cartService = context.read<CartService>();
                              await cartService.addToCart(product, quantity: _quantity);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Added ${product.name} to cart')),
                                );
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Add to Cart',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: product.inStock
                        ? () async {
                            final cartService = context.read<CartService>();
                            await cartService.addToCart(product, quantity: _quantity);
                            if (context.mounted) context.push('/checkout');
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Buy Now',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openImageViewer(BuildContext context, List<String> images, int initialIndex) {
    showDialog<void>(
      context: context,
      builder: (context) {
        final controller = PageController(initialPage: initialIndex);
        int currentIndex = initialIndex;
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              backgroundColor: Colors.black,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 520,
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: controller,
                        itemCount: images.length,
                        onPageChanged: (index) {
                          setState(() => currentIndex = index);
                        },
                        itemBuilder: (context, index) {
                          return InteractiveViewer(
                            minScale: 1,
                            maxScale: 3,
                            child: Container(
                              color: Colors.black,
                              alignment: Alignment.center,
                              child: _buildImage(context, images[index], fit: BoxFit.contain),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
child: CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.92),
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, color: Colors.black),
                          ),
                        ),
                      ),
                      if (images.length > 1)
                        Positioned(
                          bottom: 14,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${currentIndex + 1} / ${images.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildImage(BuildContext context, String imagePath, {BoxFit fit = BoxFit.cover}) {
    final theme = Theme.of(context);

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.broken_image, size: 48),
        ),
      );
    }

    return Image.asset(
      imagePath,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.broken_image, size: 48),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(Icons.image_outlined, size: 72),
      ),
    );
  }

  String _plainDescription(Product product) {
    final raw = product.description.trim();
    if (raw.isEmpty) {
      return product.shortDescription?.trim().isNotEmpty == true
          ? product.shortDescription!.trim()
          : 'No description available for this product.';
    }

    final withLineBreaks = raw
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</h[1-6]\s*>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</li\s*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</ol\s*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</ul\s*>', caseSensitive: false), '\n');

    final stripped = withLineBreaks.replaceAll(RegExp(r'<[^>]*>'), '');
    return stripped
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&', '&')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}

class _DiscountBadge extends StatelessWidget {
  final String text;
  final ThemeData theme;

  const _DiscountBadge({required this.text, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: foregroundColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;

  const _QuantityButton({
    required this.icon,
    required this.onPressed,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: filled ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
        foregroundColor: filled ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
