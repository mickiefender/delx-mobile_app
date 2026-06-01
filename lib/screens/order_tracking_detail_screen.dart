import 'package:flutter/material.dart';
import 'package:delx/screens/order_detail_screen.dart';

/// Dedicated screen for order tracking.
class OrderTrackingDetailScreen extends StatelessWidget {
  final String orderId;

  const OrderTrackingDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    // Reuse the existing OrderDetailScreen which already renders:
    // - ordered products/items
    // - tracking history timeline
    return OrderDetailScreen(orderId: orderId);
  }
}
