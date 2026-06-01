import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthService>();
    final orders = context.watch<OrderService>().orders;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom Profile Header
            _buildProfileHeader(theme, auth),
            const SizedBox(height: 16),
            // Navigation List
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
              ),
              const Spacer(),
              Text(
                'My Account',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 48), // Balance the back button
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.2),
                child: Text(
                  auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : 'C',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.displayName.isNotEmpty ? auth.displayName : 'Customer',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      auth.userEmail ?? 'customer@delx.com',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary.withOpacity(0.8),
                      ),
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withOpacity(0.15)
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

        return Card(
          child: ListTile(
            onTap: order.orderId.isNotEmpty
                ? () => context.push('${AppRoutes.orders}/${order.orderId}/tracking')
                : null,
            leading: const Icon(Icons.local_shipping),
            title: Text('Order ${order.orderId.isNotEmpty ? order.orderId : '#${order.id}'}'),
            subtitle: Text('Status: ${order.statusText}'),
            trailing: Text(DateFormat('MMM d').format(order.createdAt)),
          ),
        );
      },
    );
  }

  Widget _buildInfoTab(ThemeData theme, AuthService auth) {
    final user = auth.user ?? const <String, dynamic>{};
    final phone = (user['phone_number'] ?? '').toString();
    final currency = (user['preferred_currency'] ?? 'GHS').toString();
    final language = (user['preferred_language'] ?? 'en').toString();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _InfoCard(
          title: 'Customer information',
          children: [
            _InfoRow(label: 'Name', value: auth.displayName),
            _InfoRow(label: 'Email', value: auth.userEmail ?? '-'),
            _InfoRow(label: 'Phone', value: phone.isNotEmpty ? phone : '-'),
          ],
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Preferences',
          children: [
            _InfoRow(label: 'Currency', value: currency),
            _InfoRow(label: 'Language', value: language),
            _InfoRow(label: 'Account type', value: 'Customer'),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsTab(ThemeData theme, AuthService auth) {
    final themeService = context.watch<ThemeService>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        // Theme Switcher Section
        _InfoCard(
          title: 'Appearance',
          children: [
            _ThemeOption(
              title: 'Light mode',
              subtitle: 'Bright white theme',
              icon: Icons.light_mode,
              isSelected: themeService.isLightMode,
              onTap: () => themeService.setLightMode(),
            ),
            const Divider(),
            _ThemeOption(
              title: 'Dark mode',
              subtitle: 'Easy on the eyes',
              icon: Icons.dark_mode,
              isSelected: themeService.isDarkMode,
              onTap: () => themeService.setDarkMode(),
            ),
            const Divider(),
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
        _InfoCard(
          title: 'Notifications',
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: true,
              onChanged: (_) {},
              title: const Text('Order updates'),
              subtitle: const Text('Get notified about order status'),
            ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: true,
              onChanged: (_) {},
              title: const Text('Promotions'),
              subtitle: const Text('Receive promotional offers'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _InfoCard(
          title: 'Sync',
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: true,
              onChanged: (_) {},
              title: const Text('Wishlist sync'),
              subtitle: const Text('Keep wishlist available on this device'),
),
          ],
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: auth.isLoading
              ? null
              : () async {
                  final navigator = GoRouter.of(context);
                  await context.read<AuthService>().logout();
                  if (!mounted) return;
                  navigator.go(AppRoutes.authLogin);
                },
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }

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
            Icon(icon, size: 72, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}

class _OrderTile extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;

  const _OrderTile({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: const Icon(Icons.receipt_long),
        ),
        title: Text(order.orderId.isNotEmpty ? 'Order ${order.orderId}' : 'Order #${order.id}'),
        subtitle: Text('${order.statusText} • ${DateFormat('MMM dd, yyyy').format(order.createdAt)}'),
        trailing: Text('GHS ${order.total.toStringAsFixed(2)}'),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 120,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withOpacity(0.15)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
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
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
