import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:delx/services/product_service.dart';
import 'package:delx/models/product.dart';
import 'package:delx/widgets/app_header.dart';
import 'package:delx/widgets/product_card.dart';

class ProductsScreen extends StatefulWidget {
  final Map<String, dynamic>? filters;

  const ProductsScreen({super.key, this.filters});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isGridView = true;
  bool _showFilters = true;
String _sortBy = 'Shuffle';
  double _lastScrollPosition = 0;
  List<Product> _filteredProducts = [];
  
  // Filter state variables
  int? _selectedCategoryId;
  int? _selectedBrandId;
  double _minPrice = 0;
  double _maxPrice = 500;
  double _minRating = 0;
  bool _priceFilterActive = false;
  bool _ratingFilterActive = false;
  
  // Pagination state
  bool _isLoadingMore = false;

  // Ensure we only attach the ProductService listener once
  bool _didAttachProductListener = false;

@override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
    if (widget.filters?['search'] != null) {
      _searchController.text = widget.filters!['search'];
    }
    _scrollController.addListener(_onScroll);
  }

void _onScroll() {
    final currentPosition = _scrollController.position.pixels;
    final maxScrollPosition = _scrollController.position.maxScrollExtent;
    
    // Handle filter visibility
    if (currentPosition > _lastScrollPosition && currentPosition > 50) {
      if (_showFilters) {
        setState(() => _showFilters = false);
      }
    } else if (currentPosition < _lastScrollPosition || currentPosition < 50) {
      if (!_showFilters) {
        setState(() => _showFilters = true);
      }
    }
    _lastScrollPosition = currentPosition;
    
    // Infinite scroll: load more when near bottom (within 200px)
    final productService = context.read<ProductService>();
    if (!_isLoadingMore && 
        productService.hasMorePages && 
        currentPosition >= maxScrollPosition - 200) {
      _loadMoreProducts();
    }
  }
  
  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore) return;
    
    setState(() => _isLoadingMore = true);
    
    final productService = context.read<ProductService>();
    await productService.loadMoreProducts();
    
    if (mounted) {
      setState(() => _isLoadingMore = false);
      // Update filtered products with new data
      _loadProducts();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Listen for product service changes to reload when data updates
    final productService = context.read<ProductService>();
    if (_didAttachProductListener) return;

    _didAttachProductListener = true;
    productService.addListener(_onProductServiceUpdate);
  }

@override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    if (_didAttachProductListener) {
      final productService = context.read<ProductService>();
      productService.removeListener(_onProductServiceUpdate);
    }

    super.dispose();
  }

  void _onProductServiceUpdate() {
    if (mounted) {
      _loadProducts();
    }
  }

void _loadProducts() {
  if (!mounted) return;

  final productService = context.read<ProductService>();

  // Sync route-based filters into local state (so pagination doesn't wipe them)
  final routeCategoryId = widget.filters?['categoryId'];
  final routeSearch = widget.filters?['search'];
  final routeBrandSlug = widget.filters?['brandSlug'];

  if (routeBrandSlug != null && _selectedBrandId == null) {
    final matchedBrand = productService.brands.where((b) => b.slug == routeBrandSlug).toList();
    if (matchedBrand.isNotEmpty) {
      _selectedBrandId = matchedBrand.first.id;
    }
  }

  // Base list (route filters OR search text)
  List<Product> baseProducts;
  if (routeCategoryId != null) {
    baseProducts = productService.getProductsByCategorySync(routeCategoryId);
  } else if (routeSearch != null) {
    baseProducts = productService.searchProductsSync(routeSearch.toString());
  } else if (_searchController.text.isNotEmpty) {
    baseProducts = productService.searchProductsSync(_searchController.text);
  } else {
    baseProducts = productService.products;
  }

  // Apply local filters (selected chips / bottom sheet)
  var filtered = List<Product>.from(baseProducts);

  if (_selectedCategoryId != null) {
    filtered = filtered.where((p) => p.categoryId == _selectedCategoryId).toList();
  }

  if (_selectedBrandId != null) {
    if (productService.brands.isNotEmpty) {
      final selectedBrand = productService.brands.firstWhere(
        (b) => b.id == _selectedBrandId,
        orElse: () => productService.brands.first,
      );
      filtered = filtered.where((p) => p.brandName == selectedBrand.name).toList();
    }
  }

  if (_priceFilterActive) {
    filtered = filtered.where((p) => p.price >= _minPrice && p.price <= _maxPrice).toList();
  }

  if (_ratingFilterActive) {
    filtered = filtered.where((p) => p.rating >= _minRating).toList();
  }

  setState(() {
    _filteredProducts = filtered;
  });

  // Keep sort consistent after pagination/loading more
  _sortProducts();
}

Future<void> _handleRefresh() async {
    final productService = context.read<ProductService>();
    await productService.refreshProducts();
    if (mounted) {
      _loadProducts();
    }
  }

  void _handleSearch() {
    _loadProducts();
  }

void _sortProducts() {
    setState(() {
      if (_sortBy == 'Price: Low to High') {
        _filteredProducts.sort((a, b) => a.price.compareTo(b.price));
      } else if (_sortBy == 'Price: High to Low') {
        _filteredProducts.sort((a, b) => b.price.compareTo(a.price));
      } else if (_sortBy == 'Rating') {
        _filteredProducts.sort((a, b) => b.rating.compareTo(a.rating));
      } else if (_sortBy == 'Shuffle') {
        // Random shuffle for fresh look on each refresh
        _filteredProducts.shuffle();
      } else {
        _filteredProducts.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
      }
    });
  }

  void _showFilterBottomSheet() {
    final theme = Theme.of(context);
    final productService = context.read<ProductService>();
    final categories = productService.categories;
    final brands = productService.brands;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Filters', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedCategoryId = null;
                              _selectedBrandId = null;
                              _minPrice = 0;
                              _maxPrice = 500;
                              _minRating = 0;
                              _priceFilterActive = false;
                              _ratingFilterActive = false;
                            });
                          },
                          child: Text('Clear All', style: TextStyle(color: theme.colorScheme.error)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Categories
                    Text('Categories', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((category) {
                        final isSelected = _selectedCategoryId == category.id;
                        return FilterChip(
                          label: Text(category.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() {
                              _selectedCategoryId = selected ? category.id : null;
                            });
                          },
                          selectedColor: theme.colorScheme.primaryContainer,
                          checkmarkColor: theme.colorScheme.onPrimaryContainer,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    
                    // Brands
                    Text('Brands', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: brands.map((brand) {
                        final isSelected = _selectedBrandId == brand.id;
                        return FilterChip(
                          label: Text(brand.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() {
                              _selectedBrandId = selected ? brand.id : null;
                            });
                          },
                          selectedColor: theme.colorScheme.primaryContainer,
                          checkmarkColor: theme.colorScheme.onPrimaryContainer,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    
                    // Price Range
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Price Range', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        Switch(
                          value: _priceFilterActive,
                          onChanged: (value) {
                            setModalState(() => _priceFilterActive = value);
                          },
                        ),
                      ],
                    ),
                    if (_priceFilterActive) ...[
                      const SizedBox(height: 12),
                      RangeSlider(
                        values: RangeValues(_minPrice, _maxPrice),
                        min: 0,
                        max: 500,
                        divisions: 20,
                        labels: RangeLabels('\$${_minPrice.toInt()}', '\$${_maxPrice.toInt()}'),
                        onChanged: (values) {
                          setModalState(() {
                            _minPrice = values.start;
                            _maxPrice = values.end;
                          });
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('\$${_minPrice.toInt()}', style: theme.textTheme.bodyMedium),
                          Text('\$${_maxPrice.toInt()}', style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    
                    // Minimum Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Minimum Rating', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        Switch(
                          value: _ratingFilterActive,
                          onChanged: (value) {
                            setModalState(() => _ratingFilterActive = value);
                          },
                        ),
                      ],
                    ),
                    if (_ratingFilterActive) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                _minRating = index + 1.0;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                index < _minRating ? Icons.star : Icons.star_border,
                                color: index < _minRating ? Colors.amber : theme.colorScheme.onSurfaceVariant,
                                size: 32,
                              ),
                            ),
                          );
                        }),
                      ),
                      Text('${_minRating.toInt()} stars & up', style: theme.textTheme.bodySmall),
                    ],
                    const SizedBox(height: 32),
                    
                    // Apply Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _loadProducts();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Apply Filters'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

@override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productService = context.watch<ProductService>();
    final categories = productService.categories;
    final brands = productService.brands;

    // Determine loading and error states
    final isLoading = productService.isLoading || productService.isLoadingProducts;
    final hasError = productService.productsError != null && productService.products.isEmpty;

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            searchController: _searchController,
            onSearchSubmitted: _handleSearch,
            onMenuTap: () => context.go('/'),
          ),
          // Compact filter section that hides on scroll
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _showFilters ? null : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _showFilters ? 1.0 : 0.0,
              child: Container(
                color: theme.colorScheme.surface,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row with filters, sort, and view toggle
                    Row(
                      children: [
OutlinedButton.icon(
                          onPressed: _showFilterBottomSheet,
                          icon: Icon(Icons.filter_list, size: 16, color: theme.colorScheme.onSurface),
                          label: Text('Filters', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: theme.colorScheme.outline),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: theme.colorScheme.outline),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<String>(
                              value: _sortBy,
                              isExpanded: true,
                              underline: const SizedBox(),
                              style: theme.textTheme.bodySmall,
items: ['Shuffle', 'Popularity', 'Price: Low to High', 'Price: High to Low', 'Rating'].map((String value) => DropdownMenuItem<String>(value: value, child: Text(value, style: theme.textTheme.bodySmall))).toList(),
                              onChanged: (String? value) {
                                if (value != null) {
                                  setState(() => _sortBy = value);
                                  _sortProducts();
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // View toggle buttons
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => setState(() => _isGridView = true),
                                icon: Icon(Icons.grid_view, size: 18, color: _isGridView ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                              ),
                              IconButton(
                                onPressed: () => setState(() => _isGridView = false),
                                icon: Icon(Icons.view_list, size: 18, color: !_isGridView ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
// Categories horizontal scroll
                    if (categories.isNotEmpty) ...[
                      Text('Categories', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            if (index >= categories.length) return const SizedBox.shrink();
                            final category = categories[index];
                            if (category == null) return const SizedBox.shrink();
                            return GestureDetector(
                              onTap: () {
                                _selectedCategoryId = (_selectedCategoryId == category.id) ? null : category.id;
                                _loadProducts();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Text(
                                  category.name,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
// Brands horizontal scroll
                    if (brands.isNotEmpty) ...[
                      Text('Brands', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 50,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: brands.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            if (index >= brands.length) return const SizedBox.shrink();
                            final brand = brands[index];
                            if (brand == null) return const SizedBox.shrink();
                            return GestureDetector(
                              onTap: () {
                                context.push('/products', extra: {'brandSlug': brand.slug});
                              },
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                                ),
                                child: ClipOval(
                                  child: brand.displayLogo != null && brand.displayLogo!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: brand.displayLogo!,
                                          fit: BoxFit.cover,
                                          width: 50,
                                          height: 50,
                                          placeholder: (context, url) => Center(
                                            child: Text(
                                              brand.name.isNotEmpty ? brand.name[0].toUpperCase() : 'B',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) => Center(
                                            child: Text(
                                              brand.name.isNotEmpty ? brand.name[0].toUpperCase() : 'B',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            brand.name.isNotEmpty ? brand.name[0].toUpperCase() : 'B',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (_showFilters) const Divider(height: 1),
          // Product count when filters hidden
          if (!_showFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text('${_filteredProducts.length} products', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const Spacer(),
                  Text('Sort: $_sortBy', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          Expanded(
            child: _buildProductList(theme, isLoading, hasError),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(ThemeData theme, bool isLoading, bool hasError) {
    if (isLoading && _filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Loading products...', style: theme.textTheme.bodyLarge),
          ],
        ),
      );
    }

    if (hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Failed to load products', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Please check your internet connection and try again', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _handleRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('No products found', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Try adjusting your search or filters', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

// Filter out any null products to prevent rendering errors
    final validProducts = _filteredProducts.where((p) => p.id > 0).toList();
    final productService = context.read<ProductService>();

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: _isGridView
          ? GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.62,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: validProducts.length + (productService.hasMorePages ? 1 : 0),
              itemBuilder: (context, index) {
                // Show loading indicator at the bottom
                if (index >= validProducts.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final product = validProducts[index];
                return ProductCard(product: product);
              },
            )
          : ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: validProducts.length + (productService.hasMorePages ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                // Show loading indicator at the bottom
                if (index >= validProducts.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final product = validProducts[index];
                return ProductCard(product: product, isGridView: false);
              },
            ),
    );
  }
}
