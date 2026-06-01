import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:delx/services/cart_service.dart';
import 'package:delx/widgets/app_header.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartService = context.watch<CartService>();

return Scaffold(
      body: Column(
        children: [
          AppHeader(
            showBackButton: true,
            onBackTap: () => context.go('/'),
          ),
          Expanded(
            child: cartService.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 100, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text('Your cart is empty', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
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
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: cartService.items.length,
                          separatorBuilder: (_, __) => const Divider(height: 24),
                          itemBuilder: (context, index) {
                            if (index >= cartService.items.length) return const SizedBox.shrink();
                            final item = cartService.items[index];
                            if (item == null || item.product == null) return const SizedBox.shrink();
                            final product = item.product;

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: product.resolvedPrimaryImage != null
                                      ? Image.network(
                                          product.resolvedPrimaryImage!,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 80,
                                            height: 80,
                                            color: theme.colorScheme.surfaceContainerHighest,
                                            child: const Icon(Icons.image),
                                          ),
                                        )
                                      : Container(
                                          width: 80,
                                          height: 80,
                                          color: theme.colorScheme.surfaceContainerHighest,
                                          child: const Icon(Icons.image),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(product.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Text('${product.currency} ${product.price.toStringAsFixed(2)}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          IconButton(
                                            onPressed: () => cartService.updateQuantity(item.id, item.quantity - 1),
                                            icon: const Icon(Icons.remove, size: 18),
                                            style: IconButton.styleFrom(
                                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                              minimumSize: const Size(32, 32),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            child: Text('${item.quantity}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                          ),
                                          IconButton(
                                            onPressed: () => cartService.updateQuantity(item.id, item.quantity + 1),
                                            icon: const Icon(Icons.add, size: 18),
                                            style: IconButton.styleFrom(
                                              backgroundColor: theme.colorScheme.primary,
                                              foregroundColor: theme.colorScheme.onPrimary,
                                              minimumSize: const Size(32, 32),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => cartService.removeFromCart(item.id),
                                  icon: const Icon(Icons.delete_outline),
                                  color: theme.colorScheme.error,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                        ),
                        child: SafeArea(
                          top: false,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Subtotal', style: theme.textTheme.bodyLarge),
                                  Text('${cartService.currency} ${cartService.subtotal.toStringAsFixed(2)}', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Shipping', style: theme.textTheme.bodyLarge),
                                  Text(cartService.shippingFee == 0 ? 'FREE' : '${cartService.currency} ${cartService.shippingFee.toStringAsFixed(2)}', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: cartService.shippingFee == 0 ? Colors.green : null)),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                  Text('${cartService.currency} ${cartService.total.toStringAsFixed(2)}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => context.push('/checkout'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.secondary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Text('Proceed to Checkout', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              ),
                            ],
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
