import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:delx/services/wishlist_service.dart';
import 'package:delx/services/cart_service.dart';
import 'package:delx/widgets/product_card.dart';
import 'package:delx/widgets/app_header.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wishlistService = context.watch<WishlistService>();
    final cartService = context.read<CartService>();

return Scaffold(
      body: Column(
        children: [
          AppHeader(
            showBackButton: true,
            onBackTap: () => context.go('/'),
          ),
          Expanded(
            child: wishlistService.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border, size: 100, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text('Your wishlist is empty', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 8),
                        Text('Save items you love for later', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => context.go('/'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Start Shopping'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
Expanded(
                        child: wishlistService.items.isEmpty
                            ? const SizedBox.shrink()
                            : GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.68,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: wishlistService.items.length,
                                itemBuilder: (context, index) {
                                  if (index >= wishlistService.items.length) return const SizedBox.shrink();
                                  final product = wishlistService.items[index];
                                  if (product == null) return const SizedBox.shrink();
                                  return ProductCard(product: product);
                                },
                              ),
                      ),
                      if (wishlistService.items.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                          ),
                          child: SafeArea(
                            top: false,
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  for (final product in wishlistService.items) {
                                    await cartService.addToCart(product);
                                  }
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All items added to cart')));
                                    context.push('/cart');
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.secondary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text('Add All to Cart', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
