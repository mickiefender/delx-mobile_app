import 'package:delx/models/order.dart';
import 'package:delx/models/product.dart';
import 'package:delx/services/order_service.dart';
import 'package:delx/services/product_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_GH',
    symbol: 'GH₵',
    decimalDigits: 2,
  );
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final DateFormat _dateTimeFormat = DateFormat('MMM dd, yyyy • hh:mm a');

  Order? _order;
  bool _isLoading = true;
  String? _error;
  final Map<int, Product> _productCache = {};

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orderService = context.read<OrderService>();

      // Route param is the public order_id (e.g. ORD-...)
      final fetchedOrder = await orderService.getOrderByOrderId(widget.orderId);

      if (!mounted) return;

      if (fetchedOrder == null) {
        // Fallback to local cache (may be stale, but better than nothing)
        Order? cached;
        try {
          cached = orderService.orders.firstWhere((o) => o.orderId == widget.orderId);
        } catch (_) {
          cached = null;
        }

        if (cached == null) {
          setState(() {
            _error = 'Order not found';
            _isLoading = false;
          });
          return;
        }

        setState(() {
          _order = cached;
        });
      } else {
        setState(() {
          _order = fetchedOrder;
        });
      }

      final currentOrder = _order!;
      final products = await _loadRelatedProducts(currentOrder);
      if (!mounted) return;

      setState(() {
        _productCache
          ..clear()
          ..addAll(products);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<Map<int, Product>> _loadRelatedProducts(Order order) async {
    final productService = context.read<ProductService>();
    final productIds = order.items
        .map((item) => item.productId)
        .whereType<int>()
        .toSet();

    final result = <int, Product>{};

    await Future.wait(
      productIds.map((id) async {
        Product? product = productService.getProductByIdSync(id);
        product ??= await productService.getProductById(id);

        if (product != null) {
          result[id] = product;
        }
      }),
    );

    return result;
  }

  Future<void> _refresh() async {
    await _loadOrder();
  }

Color _statusColor(OrderStatus status, ColorScheme scheme) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.awaitingPayment:
        return Colors.amber;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.confirmed:
        return Colors.teal;
      case OrderStatus.shipped:
        return Colors.purple;
      case OrderStatus.outForDelivery:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return scheme.error;
    }
  }

  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.awaitingPayment:
        return 'Awaiting Payment';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.outForDelivery:
        return 'Out for delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
appBar: AppBar(
          title: const Text('Order Details'),
          leading: IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                // Fallback to home if there's nothing to pop
                context.go('/');
              }
            },
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _order == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Details'),
          leading: IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 72,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Order not found',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final order = _order!;
    final hasTrackingHistory = order.trackingHistory != null && order.trackingHistory!.isNotEmpty;
    final billingSameAsShipping = order.billingSameAsShipping?.toLowerCase() == 'true';

return Scaffold(
      appBar: AppBar(
        title: Text(order.orderId.isNotEmpty ? 'Order #${order.orderId}' : 'Order #${order.id}'),
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.orderId.isNotEmpty ? 'Order #${order.orderId}' : 'Order #${order.id}',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Placed on ${_dateFormat.format(order.createdAt)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (order.updatedAt != order.createdAt) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Updated ${_dateTimeFormat.format(order.updatedAt)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _StatusChip(
                        label: _statusLabel(order.status),
                        color: _statusColor(order.status, theme.colorScheme),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SummaryRow(label: 'Payment status', value: order.paymentStatus?.capitalize() ?? 'Unknown'),
                  if (order.paymentReference != null && order.paymentReference!.isNotEmpty)
                    _SummaryRow(label: 'Payment reference', value: order.paymentReference!),
                  if (order.trackingNumber != null && order.trackingNumber!.isNotEmpty)
                    _SummaryRow(label: 'Tracking number', value: order.trackingNumber!),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Items',
              child: Column(
                children: order.items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final product = item.productId == null ? null : _productCache[item.productId];
                  final imageUrl = product?.resolvedImages.isNotEmpty == true
                      ? product!.resolvedImages.first
                      : item.productImage;

                  return Padding(
                    padding: EdgeInsets.only(bottom: index == order.items.length - 1 ? 0 : 14),
                    child: InkWell(
                      onTap: product?.id != null ? () => context.push('/product/${product!.id}') : null,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: theme.dividerColor.withOpacity(0.35)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _buildProductImage(
                                context,
                                imageUrl,
                                width: 72,
                                height: 72,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName.isNotEmpty ? item.productName : 'Product',
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  if (product != null)
                                    Text(
                                      _plainDescription(product),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        height: 1.4,
                                      ),
                                    )
                                  else if (item.productImage != null && item.productImage!.isNotEmpty)
                                    Text(
                                      'Product image available in this order.',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 8,
                                    children: [
                                      _MiniInfoChip(label: 'Qty ${item.quantity}'),
                                      _MiniInfoChip(label: _currencyFormat.format(item.price)),
                                      _MiniInfoChip(label: _currencyFormat.format(item.subtotal)),
                                    ],
                                  ),
                                  if (item.sku != null && item.sku!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'SKU: ${item.sku}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                  if (item.variantAttributes != null && item.variantAttributes!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Variants: ${item.variantAttributes!.entries.map((e) => '${e.key}: ${e.value}').join(', ')}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Shipping details',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryRow(label: 'Recipient', value: order.recipientName),
                  if (order.shippingEmail != null && order.shippingEmail!.isNotEmpty)
                    _SummaryRow(label: 'Email', value: order.shippingEmail!),
                  if (order.shippingPhone != null && order.shippingPhone!.isNotEmpty)
                    _SummaryRow(label: 'Phone', value: order.shippingPhone!),
                  if (order.shippingAddress != null && order.shippingAddress!.isNotEmpty)
                    _SummaryRow(label: 'Address', value: order.shippingAddress!),
                  if (order.shippingCity != null && order.shippingCity!.isNotEmpty)
                    _SummaryRow(label: 'City', value: order.shippingCity!),
                  if (order.shippingState != null && order.shippingState!.isNotEmpty)
                    _SummaryRow(label: 'State', value: order.shippingState!),
                  if (order.shippingPostalCode != null && order.shippingPostalCode!.isNotEmpty)
                    _SummaryRow(label: 'Postal code', value: order.shippingPostalCode!),
                  if (order.shippingCountry != null && order.shippingCountry!.isNotEmpty)
                    _SummaryRow(label: 'Country', value: order.shippingCountry!),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Billing details',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (billingSameAsShipping) ...[
                    Text(
                      'Billing address is the same as shipping address.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ] else ...[
                    _SummaryRow(
                      label: 'Recipient',
                      value: _billingName(order),
                    ),
                    if (order.billingAddress != null && order.billingAddress!.isNotEmpty)
                      _SummaryRow(label: 'Address', value: order.billingAddress!),
                    if (order.billingCity != null && order.billingCity!.isNotEmpty)
                      _SummaryRow(label: 'City', value: order.billingCity!),
                    if (order.billingState != null && order.billingState!.isNotEmpty)
                      _SummaryRow(label: 'State', value: order.billingState!),
                    if (order.billingPostalCode != null && order.billingPostalCode!.isNotEmpty)
                      _SummaryRow(label: 'Postal code', value: order.billingPostalCode!),
                    if (order.billingCountry != null && order.billingCountry!.isNotEmpty)
                      _SummaryRow(label: 'Country', value: order.billingCountry!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Order summary',
              child: Column(
                children: [
                  _SummaryRow(label: 'Subtotal', value: _currencyFormat.format(order.subtotal)),
                  _SummaryRow(label: 'Shipping', value: _currencyFormat.format(order.shippingFee)),
                  if (order.taxAmount != null && order.taxAmount! > 0)
                    _SummaryRow(label: 'Tax', value: _currencyFormat.format(order.taxAmount!)),
                  if (order.discountAmount != null && order.discountAmount! > 0)
                    _SummaryRow(label: 'Discount', value: '-${_currencyFormat.format(order.discountAmount!)}'),
                  const Divider(height: 24),
                  _SummaryRow(
                    label: 'Total',
                    value: _currencyFormat.format(order.total),
                    valueStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  if (order.couponCode != null && order.couponCode!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _SummaryRow(label: 'Coupon', value: order.couponCode!),
                  ],
                  if (order.notes != null && order.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _SummaryRow(label: 'Notes', value: order.notes!),
                  ],
                  if (order.estimatedDelivery != null) ...[
                    const SizedBox(height: 8),
                    _SummaryRow(
                      label: 'Estimated delivery',
                      value: _dateFormat.format(order.estimatedDelivery!),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Shipping status',
              child: hasTrackingHistory
                  ? Column(
                      children: order.trackingHistory!.map((entry) {
                        return _TimelineTile(
                          title: entry.message,
                          subtitle: [
                            entry.status.capitalize(),
                            if (entry.location != null && entry.location!.isNotEmpty) entry.location!,
                            _dateTimeFormat.format(entry.timestamp),
                          ].join(' • '),
                          isLast: entry == order.trackingHistory!.last,
                          statusColor: _statusColor(
                            OrderStatusExtension.fromString(entry.status),
                            theme.colorScheme,
                          ),
                        );
                      }).toList(),
                    )
                  : _TimelineTile(
                      title: _statusLabel(order.status),
                      subtitle: _dateTimeFormat.format(order.updatedAt),
                      isLast: true,
                      statusColor: _statusColor(order.status, theme.colorScheme),
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _billingName(Order order) {
    final name = '${order.billingFirstName ?? ''} ${order.billingLastName ?? ''}'.trim();
    return name.isEmpty ? 'N/A' : name;
  }

  Widget _buildProductImage(
    BuildContext context,
    String? imageUrl, {
    required double width,
    required double height,
  }) {
    final theme = Theme.of(context);

    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(Icons.image_outlined, color: theme.colorScheme.onSurfaceVariant),
      );
    }

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          color: theme.colorScheme.surfaceContainerHighest,
          child: Icon(Icons.broken_image_outlined, color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    return Image.asset(
      imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(Icons.broken_image_outlined, color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }

  String _plainDescription(Product product) {
    final raw = product.description.trim();
    if (raw.isEmpty) {
      return product.shortDescription?.trim().isNotEmpty == true
          ? product.shortDescription!.trim()
          : 'No product description available.';
    }

    final withLineBreaks = raw
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</li\s*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</ul\s*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</ol\s*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</h[1-6]\s*>', caseSensitive: false), '\n\n');

    return withLineBreaks
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}

class _SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;

  const _SectionCard({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: valueStyle ?? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfoChip extends StatelessWidget {
  final String label;

  const _MiniInfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isLast;
  final Color statusColor;

  const _TimelineTile({
    required this.title,
    required this.subtitle,
    required this.isLast,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: statusColor.withOpacity(0.35),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
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
}

extension _StringCaps on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
