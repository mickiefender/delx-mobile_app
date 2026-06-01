import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import 'package:go_router/go_router.dart';
import 'package:delx/services/cart_service.dart';
import 'package:delx/services/wishlist_service.dart';
import 'package:delx/services/notification_service.dart';

class AppHeader extends StatelessWidget {
  final VoidCallback? onMenuTap;
  final bool showSearch;
  final TextEditingController? searchController;
  final VoidCallback? onSearchSubmitted;
  final bool showBackButton;
  final VoidCallback? onBackTap;

  const AppHeader({
    super.key,
    this.onMenuTap,
    this.showSearch = true,
    this.searchController,
    this.onSearchSubmitted,
    this.showBackButton = false,
    this.onBackTap,
  });

@override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartService = context.watch<CartService>();
    final wishlistService = context.watch<WishlistService>();
    final notificationService = context.watch<NotificationService>();

return Container(
      color: theme.colorScheme.primary,
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: Column(
        children: [
Row(
            children: [
              if (showBackButton)
                IconButton(
                  onPressed: onBackTap,
                  icon: Icon(Icons.arrow_back, color: theme.colorScheme.onPrimary),
                ),
              if (!showBackButton)
                Row(
                  children: [
Image.asset('assets/images/delx_logo.png', width: 60, height: 40, fit: BoxFit.contain),
const SizedBox(width: 8),
                  ],
                ),
              const Spacer(),
              IconButton(
                onPressed: () => context.push('/notifications'),
                icon: badges.Badge(
                  showBadge: notificationService.hasUnread,
                  badgeContent: Text(
                    '${notificationService.unreadCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  child: Icon(Icons.notifications_outlined, color: theme.colorScheme.onPrimary),
                ),
              ),
              IconButton(
                onPressed: () => context.push('/wishlist'),
                icon: badges.Badge(
                  showBadge: wishlistService.itemCount > 0,
                  badgeContent: Text('${wishlistService.itemCount}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                  child: Icon(Icons.favorite_border, color: theme.colorScheme.onPrimary),
                ),
              ),
              IconButton(
                onPressed: () => context.push('/cart'),
                icon: badges.Badge(
                  showBadge: cartService.itemCount > 0,
                  badgeContent: Text('${cartService.itemCount}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                  child: Icon(Icons.shopping_cart_outlined, color: theme.colorScheme.onPrimary),
                ),
              ),
            ],
          ),
          if (showSearch) ...[
const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: TextField(
                      controller: searchController,
                      onSubmitted: (_) => onSearchSubmitted?.call(),
                      decoration: const InputDecoration(
                        hintText: 'Search products...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onSearchSubmitted,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.search, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
