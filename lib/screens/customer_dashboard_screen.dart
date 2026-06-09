import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delx/nav.dart';
import 'package:delx/services/auth_service.dart';
import 'package:delx/services/order_service.dart';
import 'package:delx/services/theme_service.dart';
import 'package:delx/models/order.dart';
import 'package:intl/intl.dart';

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() => _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  int _selectedIndex = 0;

  // Settings toggle states
  bool _orderUpdatesEnabled = true;
  bool _promotionsEnabled = true;
  bool _wishlistSyncEnabled = true;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.receipt_long, label: 'Orders'),
    _NavItem(icon: Icons.local_shipping, label: 'Order Tracking'),
    _NavItem(icon: Icons.person_outline, label: 'My Info'),
    _NavItem(icon: Icons.settings_outlined, label: 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderService>().loadOrders();
      _loadSettings();
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _orderUpdatesEnabled = prefs.getBool('order_updates_enabled') ?? true;
      _promotionsEnabled = prefs.getBool('promotions_enabled') ?? true;
      _wishlistSyncEnabled = prefs.getBool('wishlist_sync_enabled') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthService>();
    final orders = context.watch<OrderService>().orders;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Modern Profile Header
            _buildProfileHeader(theme, auth),
            const SizedBox(height: 16),
            // Tab Navigation
            _buildNavList(theme),
            const SizedBox(height: 16),
            // Content Area
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: switch (_selectedIndex) {
                  0 => _buildOrdersTab(theme, orders),
                  1 => _buildTrackingTab(theme, orders),
                  2 => _buildInfoTab(theme, auth),
                  _ => _buildSettingsTab(theme, auth),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, AuthService auth) {
    final displayName = auth.displayName.isNotEmpty ? auth.displayName : 'Customer';
    final initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'C';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.go(AppRoutes.home),
                icon: Icon(Icons.arrow_back, color: theme.colorScheme.onPrimary),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.12),
                ),
              ),
              const Spacer(),
              Text(
                'My Account',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.onPrimary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.15),
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 14,
                          color: theme.colorScheme.onPrimary.withOpacity(0.75),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            auth.userEmail ?? 'customer@delx.com',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimary.withOpacity(0.85),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavList(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(_navItems.length, (index) {
          final item = _navItems[index];
          final isSelected = _selectedIndex == index;

          return InkWell(
            onTap: () => setState(() => _selectedIndex = index),
            borderRadius: BorderRadius.horizontal(
              left: const Radius.circular(16),
              right: index == _navItems.length - 1 ? const Radius.circular(16) : Radius.zero,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primaryContainer.withOpacity(0.5)
                    : Colors.transparent,
                borderRadius: BorderRadius.horizontal(
                  left: const Radius.circular(16),
                  right: index == _navItems.length - 1 ? const Radius.circular(16) : Radius.zero,
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withOpacity(0.12)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.icon,
                      size: 20,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item.label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Orders Tab ───────────────────────────────────────────
  Widget _buildOrdersTab(ThemeData theme, List<Order> orders) {
    if (orders.isEmpty) {
      return _emptyState(
        theme,
        icon: Icons.shopping_bag_outlined,
        title: 'No orders yet',
        message: 'Your orders will appear here after checkout.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _OrderTile(
          order: order,
          onTap: order.orderId.isNotEmpty
              ? () => context.push('${AppRoutes.orders}/${order.orderId}')
              : null,
        );
      },
    );
  }

  // ─── Tracking Tab ─────────────────────────────────────────
  Widget _buildTrackingTab(ThemeData theme, List<Order> orders) {
    if (orders.isEmpty) {
      return _emptyState(
        theme,
        icon: Icons.local_shipping_outlined,
        title: 'Nothing to track',
        message: 'Once you place an order, tracking information will show here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        final statusColor = _statusColor(order.statusText);
        return _TrackingTile(order: order, statusColor: statusColor);
      },
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ─── Info Tab ─────────────────────────────────────────────
  Widget _buildInfoTab(ThemeData theme, AuthService auth) {
    final user = auth.user ?? const <String, dynamic>{};
    final phone = (user['phone_number'] ?? '').toString();
    final currency = (user['preferred_currency'] ?? 'GHS').toString();
    final language = (user['preferred_language'] ?? 'en').toString();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _InfoCard(
          title: 'Customer Information',
          icon: Icons.person_outline,
          children: [
            _InfoRow(label: 'Name', value: auth.displayName.isNotEmpty ? auth.displayName : '—'),
            _InfoRow(label: 'Email', value: auth.userEmail ?? '—'),
            _InfoRow(label: 'Phone', value: phone.isNotEmpty ? phone : '—'),
          ],
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Preferences',
          icon: Icons.tune_outlined,
          children: [
            _InfoRow(label: 'Currency', value: currency),
            _InfoRow(label: 'Language', value: language),
            _InfoRow(label: 'Account type', value: 'Customer'),
          ],
        ),
      ],
    );
  }

  // ─── Settings Tab ──────────────────────────────────────────
  Widget _buildSettingsTab(ThemeData theme, AuthService auth) {
    final themeService = context.watch<ThemeService>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        // Appearance
        _InfoCard(
          title: 'Appearance',
          icon: Icons.palette_outlined,
          children: [
            _ThemeOption(
              title: 'Light mode',
              subtitle: 'Bright white theme',
              icon: Icons.light_mode,
              isSelected: themeService.isLightMode,
              onTap: () => themeService.setLightMode(),
            ),
            const Divider(height: 1),
            _ThemeOption(
              title: 'Dark mode',
              subtitle: 'Easy on the eyes',
              icon: Icons.dark_mode,
              isSelected: themeService.isDarkMode,
              onTap: () => themeService.setDarkMode(),
            ),
            const Divider(height: 1),
            _ThemeOption(
              title: 'System preference',
              subtitle: 'Follow device settings',
              icon: Icons.settings_suggest,
              isSelected: themeService.isSystemMode,
              onTap: () => themeService.setSystemMode(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Notifications
        _InfoCard(
          title: 'Notifications',
          icon: Icons.notifications_outlined,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _orderUpdatesEnabled,
              onChanged: (value) {
                setState(() => _orderUpdatesEnabled = value);
                _saveSetting('order_updates_enabled', value);
              },
              title: const Text('Order updates'),
              subtitle: const Text('Get notified about order status'),
              activeColor: theme.colorScheme.primary,
            ),
            const Divider(height: 1),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _promotionsEnabled,
              onChanged: (value) {
                setState(() => _promotionsEnabled = value);
                _saveSetting('promotions_enabled', value);
              },
              title: const Text('Promotions'),
              subtitle: const Text('Receive promotional offers'),
              activeColor: theme.colorScheme.primary,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Sync
        _InfoCard(
          title: 'Sync',
          icon: Icons.sync_outlined,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _wishlistSyncEnabled,
              onChanged: (value) {
                setState(() => _wishlistSyncEnabled = value);
                _saveSetting('wishlist_sync_enabled', value);
              },
              title: const Text('Wishlist sync'),
              subtitle: const Text('Keep wishlist available on this device'),
              activeColor: theme.colorScheme.primary,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Legal & Policies Section
        _InfoCard(
          title: 'Legal & Policies',
          icon: Icons.gavel_outlined,
          children: [
            _PolicyTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'How we handle your data',
              onTap: () => _showPolicySheet(context, 'privacy'),
            ),
            const Divider(height: 1),
            _PolicyTile(
              icon: Icons.description_outlined,
              title: 'Terms & Conditions',
              subtitle: 'Rules and guidelines',
              onTap: () => _showPolicySheet(context, 'terms'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Logout
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: auth.isLoading
                ? null
                : () async {
                    final navigator = GoRouter.of(context);
                    try {
                      await context.read<AuthService>().logout();
                    } catch (e) {
                      debugPrint('Sign out failed in UI layer: $e');
                    }
                    if (!mounted) return;
                    navigator.go(AppRoutes.authLogin);
                  },
            icon: const Icon(Icons.logout, size: 20),
            label: const Text('Sign Out'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Delete Account
        Container(
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade100),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Danger Zone',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Permanently delete your account and all associated data. This action cannot be undone.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.red.shade800,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: auth.isLoading
                        ? null
                        : () => _showDeleteAccountDialog(context, auth),
                    icon: const Icon(Icons.delete_forever, size: 18),
                    label: const Text('Delete Account'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ─── Policy Sheet ──────────────────────────────────────────
  void _showPolicySheet(BuildContext context, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PolicyBottomSheet(type: type),
    );
  }

  // ─── Delete Account Dialog ─────────────────────────────────
  Future<void> _showDeleteAccountDialog(BuildContext context, AuthService auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade600, size: 24),
            const SizedBox(width: 10),
            const Text('Delete Account?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete your account? This will permanently remove all your data including orders, addresses, and wishlists. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await auth.deleteAccount();
      if (success && context.mounted) {
        final navigator = GoRouter.of(context);
        navigator.go(AppRoutes.authLogin);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Your account has been deleted.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  // ─── Empty State ────────────────────────────────────────────
  Widget _emptyState(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 52, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  MODEL CLASSES
// ═══════════════════════════════════════════════════════════════════

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ═══════════════════════════════════════════════════════════════════
//  ORDER TILE
// ═══════════════════════════════════════════════════════════════════

class _OrderTile extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;
  const _OrderTile({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencySymbol = 'GHS';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.receipt_long, color: theme.colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderId.isNotEmpty ? 'Order ${order.orderId}' : 'Order #${order.id}',
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _StatusChip(status: order.statusText),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMM dd, yyyy').format(order.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '$currencySymbol ${order.total.toStringAsFixed(2)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  TRACKING TILE
// ═══════════════════════════════════════════════════════════════════

class _TrackingTile extends StatelessWidget {
  final Order order;
  final Color statusColor;
  const _TrackingTile({required this.order, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: order.orderId.isNotEmpty
            ? () => context.push('${AppRoutes.orders}/${order.orderId}/tracking')
            : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.local_shipping, color: statusColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderId.isNotEmpty ? 'Order ${order.orderId}' : 'Order #${order.id}',
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _StatusChip(status: order.statusText, color: statusColor),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMM dd').format(order.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  STATUS CHIP
// ═══════════════════════════════════════════════════════════════════

class _StatusChip extends StatelessWidget {
  final String status;
  final Color? color;
  const _StatusChip({required this.status, this.color});

  Color _resolveColor() {
    if (color != null) return color!;
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'processing': return Colors.blue;
      case 'shipped': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _resolveColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: c,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  INFO CARD
// ═══════════════════════════════════════════════════════════════════

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  INFO ROW
// ═══════════════════════════════════════════════════════════════════

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  POLICY TILE (for legal section)
// ═══════════════════════════════════════════════════════════════════

class _PolicyTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _PolicyTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  THEME OPTION
// ═══════════════════════════════════════════════════════════════════

class _ThemeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withOpacity(0.12)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PRIVACY & TERMS BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════

class _PolicyBottomSheet extends StatelessWidget {
  final String type;
  const _PolicyBottomSheet({required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPrivacy = type == 'privacy';

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isPrivacy ? Icons.privacy_tip : Icons.description,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        isPrivacy ? 'Privacy Policy' : 'Terms & Conditions',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: Icon(Icons.close, color: theme.colorScheme.onSurfaceVariant),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              // Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  controller: scrollController,
                  children: isPrivacy ? _privacyPolicy(theme) : _termsConditions(theme),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Privacy Policy Content ──────────────────────────────
  List<Widget> _privacyPolicy(ThemeData theme) {
    return [
      _sectionTitle(theme, 'Information We Collect'),
      _body(
        'We collect information you provide directly, including your name, email address, '
        'phone number, and delivery address when you create an account or place an order. '
        'We also collect payment information, though this is processed securely by our '
        'third-party payment providers.',
      ),
      _spacing,
      _sectionTitle(theme, 'How We Use Your Information'),
      _body(
        'Your information is used to process and fulfill your orders, communicate with you '
        'about your purchases, send you promotional offers (with your consent), and improve '
        'our services. We do not sell your personal data to third parties.',
      ),
      _spacing,
      _sectionTitle(theme, 'Data Security'),
      _body(
        'We implement industry-standard security measures to protect your personal information. '
        'All payment transactions are encrypted and processed through PCI-compliant providers. '
        'Your account information is stored securely and can be deleted at any time.',
      ),
      _spacing,
      _sectionTitle(theme, 'Your Rights'),
      _body(
        'You have the right to access, update, or delete your personal data at any time. '
        'You can manage your account settings, opt out of marketing communications, '
        'or request permanent deletion of your account and associated data.',
      ),
      _spacing,
      _sectionTitle(theme, 'Cookies & Tracking'),
      _body(
        'We use essential cookies to ensure the proper functioning of our services. '
        'Analytics cookies help us understand how you use the app so we can improve it. '
        'You can manage cookie preferences through your device settings.',
      ),
      _spacing,
      _sectionTitle(theme, 'Contact Us'),
      _body(
        'If you have any questions about this Privacy Policy or how we handle your data, '
        'please contact our support team. We\'re committed to protecting your privacy '
        'and will respond to your inquiries promptly.',
      ),
      _spacing,
      _lastUpdated(theme, 'Privacy Policy • Last updated: June 2026'),
    ];
  }

  // ─── Terms & Conditions Content ──────────────────────────
  List<Widget> _termsConditions(ThemeData theme) {
    return [
      _sectionTitle(theme, 'Acceptance of Terms'),
      _body(
        'By creating an account and using our services, you agree to these Terms & Conditions. '
        'If you do not agree with any part of these terms, you should not use our services. '
        'We reserve the right to update these terms at any time.',
      ),
      _spacing,
      _sectionTitle(theme, 'Account Responsibilities'),
      _body(
        'You are responsible for maintaining the confidentiality of your account credentials '
        'and for all activities that occur under your account. You must notify us immediately '
        'of any unauthorized use of your account. You must be at least 18 years old to use our services.',
      ),
      _spacing,
      _sectionTitle(theme, 'Orders & Payments'),
      _body(
        'All orders are subject to availability and confirmation of the order price. '
        'We reserve the right to cancel any order if we suspect fraudulent activity. '
        'Payment must be made in full at the time of purchase. Prices are subject to change.',
      ),
      _spacing,
      _sectionTitle(theme, 'Shipping & Delivery'),
      _body(
        'Estimated delivery times are provided for convenience and are not guaranteed. '
        'We are not responsible for delays caused by third-party carriers or unforeseen circumstances. '
        'Risk of loss passes to you upon delivery.',
      ),
      _spacing,
      _sectionTitle(theme, 'Returns & Refunds'),
      _body(
        'You may return eligible items within the specified return period. '
        'Items must be in their original condition. Refunds will be processed to your original '
        'payment method within a reasonable timeframe. Shipping costs are non-refundable.',
      ),
      _spacing,
      _sectionTitle(theme, 'Limitation of Liability'),
      _body(
        'Our liability is limited to the maximum extent permitted by law. We are not liable for '
        'any indirect, incidental, or consequential damages arising from your use of our services. '
        'Our total liability shall not exceed the amount paid by you for the applicable product or service.',
      ),
      _spacing,
      _sectionTitle(theme, 'Termination'),
      _body(
        'We reserve the right to suspend or terminate your account if you violate these terms. '
        'You may terminate your account at any time through the account settings. Upon termination, '
        'you remain liable for any outstanding orders placed before termination.',
      ),
      _spacing,
      _lastUpdated(theme, 'Terms & Conditions • Last updated: June 2026'),
    ];
  }

  Widget get _spacing => const SizedBox(height: 16);

  Widget _sectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _body(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey.shade700,
        height: 1.5,
      ),
    );
  }

  Widget _lastUpdated(ThemeData theme, String text) {
    return Center(
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
