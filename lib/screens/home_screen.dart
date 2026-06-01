import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:delx/models/brand.dart';
import 'package:delx/models/hero_banner.dart';
import 'package:delx/models/home_ad.dart';
import 'package:delx/services/product_service.dart';
import 'package:delx/widgets/app_header.dart';
import 'package:delx/widgets/brand_card.dart';
import 'package:delx/widgets/category_card.dart';
import 'package:delx/widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _bannerController = PageController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _bannerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch() {
    if (_searchController.text.isNotEmpty) {
      context.push('/products', extra: {'search': _searchController.text});
    }
  }

  Future<void> _handleRefresh() async {
    final productService = context.read<ProductService>();
    await productService.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productService = context.watch<ProductService>();

    if (productService.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (productService.error != null && productService.categories.isEmpty) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text('Failed to load data', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Please check your internet connection',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _handleRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final categories = productService.categories;
    final brands = productService.brands.where((brand) => brand.isActive).toList();
    final featuredProducts = productService.featuredProducts;
final newProducts = productService.newArrivals;
    final bestSellers = productService.bestSellers;
    final isLoadingFeatured = productService.isLoadingFeatured;
    final isLoadingNewArrivals = productService.isLoadingNewArrivals;
    final isLoadingBestSellers = productService.isLoadingBestSellers;
    final isLoadingBrands = productService.isLoadingBrands;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Column(
          children: [
            AppHeader(
              searchController: _searchController,
              onSearchSubmitted: _handleSearch,
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
const SizedBox(height: 20),
                    SizedBox(
                      height: 180,
                      child: Stack(
                        children: [
                          productService.heroBanners.isEmpty
                              ? _buildBannerSkeleton(context)
                              : PageView(
                                  controller: _bannerController,
                                  children: productService.heroBanners
                                      .map(
                                        (banner) =>
                                            _buildBannerFromModel(context, banner),
                                      )
                                      .toList(),
                                ),
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: SmoothPageIndicator(
                                controller: _bannerController,
                                count: productService.heroBanners.isEmpty
                                    ? 0
                                    : productService.heroBanners.length,
                                effect: WormEffect(
                                  dotHeight: 8,
                                  dotWidth: 8,
                                  activeDotColor: theme.colorScheme.secondary,
                                  dotColor: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Browse Categories',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
SizedBox(
                      height: 140,
                      child: categories.isEmpty
                          ? const SizedBox.shrink()
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: categories.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                if (index >= categories.length) return const SizedBox.shrink();
                                final category = categories[index];
                                if (category == null) return const SizedBox.shrink();
                                return CategoryCard(category: category);
                              },
                            ),
                    ),
                    const SizedBox(height: 32),
Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Featured Brands',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () => context.push('/products'),
                            child: Text(
                              'View All',
                              style: TextStyle(color: theme.colorScheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFeaturedBrandsSection(
                      brands,
                      isLoadingBrands,
                      theme,
                    ),
                    const SizedBox(height: 32),
Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Featured Products',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () => context.push('/products'),
                            child: Text(
                              'View All',
                              style: TextStyle(color: theme.colorScheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFeaturedSection(featuredProducts, isLoadingFeatured, theme),
                    const SizedBox(height: 32),
Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'New Arrivals',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
_buildNewArrivalsSection(
                      newProducts,
                      isLoadingNewArrivals,
                      theme,
                    ),
                    const SizedBox(height: 32),
                    // Home Ads Banner Section
Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
_buildHomeAdsSection(
                      productService.homeAds,
                      productService.isLoadingHomeAds,
                      theme,
                    ),
                    const SizedBox(height: 32),
                    // Best Sellers Section
Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Best Sellers',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () => context.push('/products'),
                            child: Text(
                              'View All',
                              style: TextStyle(color: theme.colorScheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildBestSellersSection(
                      bestSellers,
                      isLoadingBestSellers,
                      theme,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedBrandsSection(
    List<Brand> brands,
    bool isLoading,
    ThemeData theme,
  ) {
    if (isLoading && brands.isEmpty) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                'Loading featured brands...',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (brands.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'No featured brands available',
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

// Guard against empty list
    if (brands.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayBrands = brands.take(8).toList();

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: displayBrands.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          if (index >= displayBrands.length) return const SizedBox.shrink();
          final brand = displayBrands[index];
          if (brand == null) return const SizedBox.shrink();
          return BrandCard(brand: brand);
        },
      ),
    );
  }

  Widget _buildFeaturedSection(
    List featuredProducts,
    bool isLoading,
    ThemeData theme,
  ) {
    if (isLoading && featuredProducts.isEmpty) {
      return SizedBox(
        height: 280,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                'Loading featured products...',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (featuredProducts.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No featured products available',
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

// Guard against empty list to prevent sliver rendering errors
    if (featuredProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayProducts = featuredProducts.take(4).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 340,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: displayProducts.length,
          itemBuilder: (context, index) {
            if (index >= displayProducts.length) return const SizedBox.shrink();
            final product = displayProducts[index];
            if (product == null) return const SizedBox.shrink();
            return ProductCard(product: product, isGridView: true);
          },
        ),
      ),
    );
  }

  Widget _buildNewArrivalsSection(
    List newProducts,
    bool isLoading,
    ThemeData theme,
  ) {
    if (isLoading && newProducts.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                'Loading new arrivals...',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (newProducts.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No new arrivals available',
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

// Guard against empty list
    if (newProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 260,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: newProducts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index >= newProducts.length) return const SizedBox.shrink();
          final product = newProducts[index];
          if (product == null) return const SizedBox.shrink();
          return SizedBox(
            width: 160,
            child: ProductCard(product: product, isGridView: false),
          );
        },
      ),
    );
  }

  /// Build best sellers section with horizontal scrolling products
  Widget _buildBestSellersSection(
    List bestSellers,
    bool isLoading,
    ThemeData theme,
  ) {
    if (isLoading && bestSellers.isEmpty) {
      return SizedBox(
        height: 260,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                'Loading best sellers...',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (bestSellers.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No best sellers available',
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

// Guard against empty list
    if (bestSellers.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 260,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: bestSellers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index >= bestSellers.length) return const SizedBox.shrink();
          final product = bestSellers[index];
          if (product == null) return const SizedBox.shrink();
          return SizedBox(
            width: 160,
            child: ProductCard(product: product, isGridView: false),
          );
        },
      ),
    );
  }

  /// Build home ads section with two banner images side by side
  Widget _buildHomeAdsSection(
    List<HomeAd> homeAds,
    bool isLoading,
    ThemeData theme,
  ) {
    if (isLoading && homeAds.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                'Loading offers...',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (homeAds.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'No special offers available',
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    // Display up to 2 ads side by side
    final adsToShow = homeAds.take(2).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(adsToShow.length, (index) {
          final ad = adsToShow[index];
          final isFirst = index == 0;
          final isLast = index == adsToShow.length - 1;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: isFirst && !isLast ? 12 : 0,
              ),
              child: _buildHomeAdBanner(context, ad, theme),
            ),
          );
        }),
      ),
    );
  }

  /// Build a single home ad banner
  Widget _buildHomeAdBanner(BuildContext context, HomeAd ad, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        if (ad.linkUrl.isNotEmpty) {
          context.push(ad.linkUrl);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 2 / 1,
          child: ad.imageUrl.startsWith('assets/')
              ? Image.asset(
                  ad.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Icon(
                        Icons.image,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : Image.network(
                  ad.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Icon(
                        Icons.image,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

/// Overflow-safe banner builder from HeroBanner model.
  /// Shows only the picture without text or CTA.
  Widget _buildBannerFromModel(BuildContext context, HeroBanner banner) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: banner.imageUrl.startsWith('assets/')
            ? Image.asset(
                banner.imageUrl,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
              )
            : Image.network(
                banner.imageUrl,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
      ),
    );
  }

  /// Skeleton placeholder while hero banners are loading.
  Widget _buildBannerSkeleton(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
    );
  }
}
