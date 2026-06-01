import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:delx/nav.dart';
import 'package:delx/services/auth_service.dart';
import 'package:delx/services/cart_service.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Widget child;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _onItemTapped(context, index),
        backgroundColor: theme.colorScheme.surface,
        indicatorColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(
              Icons.storefront_outlined,
              size: 24,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.storefront,
              size: 24,
              color: theme.colorScheme.primary,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.local_offer_outlined,
              size: 24,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.local_offer,
              size: 24,
              color: theme.colorScheme.primary,
            ),
            label: 'Products',
          ),
          NavigationDestination(
            icon: _buildBadgeIcon(
              context,
              Icons.favorite_border,
              wishlistCount: null,
              size: 24,
            ),
            selectedIcon: _buildBadgeIcon(
              context,
              Icons.favorite,
              wishlistCount: null,
              size: 24,
            ),
            label: 'Wishlist',
          ),
          NavigationDestination(
            icon: _buildBadgeIcon(context, Icons.shopping_cart_outlined, size: 24),
            selectedIcon: _buildBadgeIcon(context, Icons.shopping_cart, size: 24),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.account_circle_outlined,
              size: 24,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.account_circle,
              size: 24,
              color: theme.colorScheme.primary,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeIcon(
    BuildContext context,
    IconData icon, {
    int? wishlistCount,
    double size = 24,
  }) {
    final theme = Theme.of(context);

    if (wishlistCount != null) {
      // For wishlist - not used currently
      if (wishlistCount > 0) {
        return Badge(
          label: Text(
            wishlistCount.toString(),
            style: const TextStyle(fontSize: 10),
          ),
          child: Icon(icon, size: size),
        );
      }
      return Icon(icon, size: size);
    }

    // For cart - use consumer
    return Consumer<CartService>(
      builder: (context, cartService, _) {
        if (cartService.itemCount > 0) {
          return Badge(
            label: Text(
              cartService.itemCount.toString(),
              style: const TextStyle(fontSize: 10),
            ),
            backgroundColor: theme.colorScheme.secondary,
            child: Icon(icon, size: size),
          );
        }
        return Icon(icon, size: size);
      },
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.products);
        break;
      case 2:
        context.go(AppRoutes.wishlist);
        break;
      case 3:
        context.go(AppRoutes.cart);
        break;
      case 4:
        _showProfileSheet(context);
        break;
    }
  }

  void _showProfileSheet(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.read<AuthService>();

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 40,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                auth.isLoggedIn ? Icons.person : Icons.person_add_alt_1,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              auth.isLoggedIn ? 'My Account' : 'Welcome to DELX',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              auth.isLoggedIn
                  ? auth.displayName
                  : 'Login or sign up to access your customer dashboard',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (auth.isLoggedIn) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    context.go(AppRoutes.dashboard);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Open Dashboard'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    context.go(AppRoutes.orders);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: theme.colorScheme.primary),
                  ),
                  child: const Text('My Orders'),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    context.go(AppRoutes.authLogin);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Login'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    context.go(AppRoutes.authSignup);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: theme.colorScheme.primary),
                  ),
                  child: const Text('Sign up'),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Helper function to get the current navigation index from a route path
int getNavIndexFromRoute(String route) {
  if (route == AppRoutes.home || route == '/') return 0;
  if (route.startsWith('/products') && !route.contains('/product/')) return 1;
  if (route == AppRoutes.wishlist) return 2;
  if (route == AppRoutes.cart) return 3;
  return 0; // Default to home
}
