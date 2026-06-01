import 'package:delx/models/order.dart';
import 'package:delx/screens/paystack_checkout_screen.dart';
import 'package:delx/services/auth_service.dart';
import 'package:delx/services/cart_service.dart';
import 'package:delx/services/order_service.dart';
import 'package:delx/services/payment_service.dart';
import 'package:delx/widgets/app_header.dart';
import 'package:delx/widgets/checkout_step_indicator.dart';
import 'package:delx/widgets/enhanced_form_field.dart';
import 'package:delx/widgets/payment_method_card.dart';
import 'package:delx/widgets/professional_section_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController(text: 'Ghana');

  int _currentStep = 0;
  String _paymentMethod = 'Mobile Money';
  bool _isSubmitting = false;
  String _selectedRegion = 'Greater Accra';

  final List<String> _steps = ['Shipping', 'Payment', 'Review'];

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'name': 'Mobile Money',
      'description': 'Pay via MTN, Vodafone, or AirtelTigo',
      'icon': Icons.phone_android_outlined,
      'recommended': true,
    },
    {
      'name': 'Credit Card',
      'description': 'Visa, Mastercard, or American Express',
      'icon': Icons.credit_card_outlined,
      'recommended': false,
    },
   
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  String _money(double value) => 'GH₵${value.toStringAsFixed(2)}';

  void _nextStep() {
    if (_currentStep == 0 && _formKey.currentState!.validate()) {
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      setState(() => _currentStep = 2);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep = _currentStep - 1);
    }
  }

/// Store shipping info temporarily for order creation after payment
Map<String, dynamic> _buildShippingInfo() {
  final shippingAddress =
      '${_addressController.text.trim()}, ${_cityController.text.trim()}, ${_stateController.text.trim()}, ${_postalCodeController.text.trim()}, ${_countryController.text.trim()}';

  final nameParts = _nameController.text.trim().split(RegExp(r'\s+'));
  final firstName = (nameParts.isNotEmpty && nameParts.first.trim().isNotEmpty)
      ? nameParts.first.trim()
      : 'Customer';
  final lastNameRaw = (nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '').trim();
  final lastName = lastNameRaw.isNotEmpty ? lastNameRaw : 'Customer';

  return {
    'shippingAddress': shippingAddress,
    'shippingCity': _cityController.text.trim(),
    'shippingState': _stateController.text.trim(),
    'shippingPostalCode': _postalCodeController.text.trim(),
    'shippingCountry': _countryController.text.trim(),
    'shippingFirstName': firstName,
    'shippingLastName': lastName,
    'shippingEmail': _emailController.text.trim(),
    'shippingPhone': _phoneController.text.trim(),
  };
}

Future<void> _placeOrder() async {
  final cartService = Provider.of<CartService>(context, listen: false);
  final orderService = Provider.of<OrderService>(context, listen: false);
  final authService = Provider.of<AuthService>(context, listen: false);
  final paymentService = Provider.of<PaymentService>(context, listen: false);

  setState(() => _isSubmitting = true);

  // Build shipping info from form
  final shippingInfo = _buildShippingInfo();
  final shippingEmail = shippingInfo['shippingEmail'] as String;
  final shippingPhone = shippingInfo['shippingPhone'] as String;

// Handle Cash on Delivery separately (order created immediately)
  if (_paymentMethod == 'Cash on Delivery') {
    Order? order;
    if (authService.isLoggedIn) {
      order = await orderService.createOrder(
        items: cartService.items,
        subtotal: cartService.subtotal,
        shippingFee: cartService.shippingFee,
        shippingAddress: shippingInfo['shippingAddress'] as String,
        shippingCity: shippingInfo['shippingCity'] as String,
        shippingState: shippingInfo['shippingState'] as String,
        shippingPostalCode: shippingInfo['shippingPostalCode'] as String,
        shippingCountry: shippingInfo['shippingCountry'] as String,
        shippingFirstName: shippingInfo['shippingFirstName'] as String,
        shippingLastName: shippingInfo['shippingLastName'] as String,
        shippingEmail: shippingEmail,
        shippingPhone: shippingPhone,
      );
    } else {
      order = await orderService.createGuestOrder(
        items: cartService.items,
        subtotal: cartService.subtotal,
        shippingFee: cartService.shippingFee,
        shippingAddress: shippingInfo['shippingAddress'] as String,
        shippingCity: shippingInfo['shippingCity'] as String,
        shippingState: shippingInfo['shippingState'] as String,
        shippingPostalCode: shippingInfo['shippingPostalCode'] as String,
        shippingCountry: shippingInfo['shippingCountry'] as String,
        shippingFirstName: shippingInfo['shippingFirstName'] as String,
        shippingLastName: shippingInfo['shippingLastName'] as String,
        shippingEmail: shippingEmail,
        shippingPhone: shippingPhone,
      );
    }

    if (!mounted) return;

    if (order == null) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create order. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    await cartService.clearCart();
    setState(() => _isSubmitting = false);

    final displayOrderId = order.orderId.isNotEmpty ? order.orderId : '#${order.id}';
    // Navigate to order success page for Cash on Delivery
    if (mounted) {
      context.go('/order-success/$displayOrderId');
    }
    return;
  }

  // Step 1: Create the order FIRST (with pending status)
  // The order must exist in the backend before payment can be initialized
  Order? order;
  if (authService.isLoggedIn) {
    order = await orderService.createOrder(
      items: cartService.items,
      subtotal: cartService.subtotal,
      shippingFee: cartService.shippingFee,
      shippingAddress: shippingInfo['shippingAddress'] as String,
      shippingCity: shippingInfo['shippingCity'] as String,
      shippingState: shippingInfo['shippingState'] as String,
      shippingPostalCode: shippingInfo['shippingPostalCode'] as String,
      shippingCountry: shippingInfo['shippingCountry'] as String,
      shippingFirstName: shippingInfo['shippingFirstName'] as String,
      shippingLastName: shippingInfo['shippingLastName'] as String,
      shippingEmail: shippingEmail,
      shippingPhone: shippingPhone,
    );
  } else {
    order = await orderService.createGuestOrder(
      items: cartService.items,
      subtotal: cartService.subtotal,
      shippingFee: cartService.shippingFee,
      shippingAddress: shippingInfo['shippingAddress'] as String,
      shippingCity: shippingInfo['shippingCity'] as String,
      shippingState: shippingInfo['shippingState'] as String,
      shippingPostalCode: shippingInfo['shippingPostalCode'] as String,
      shippingCountry: shippingInfo['shippingCountry'] as String,
      shippingFirstName: shippingInfo['shippingFirstName'] as String,
      shippingLastName: shippingInfo['shippingLastName'] as String,
      shippingEmail: shippingEmail,
      shippingPhone: shippingPhone,
    );
  }

  if (!mounted) return;

  if (order == null) {
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to create order. Please try again.'),
        backgroundColor: Colors.redAccent,
      ),
    );
    return;
  }

  // Use the real order ID from the created order for payment
  final orderId = order.orderId.isNotEmpty ? order.orderId : 'ORD-${order.id}';
  debugPrint('Order created with ID: $orderId, initializing payment...');

  // Step 2: Initialize payment with the REAL order ID
  final paystackPaymentMethod = _paymentMethod == 'Credit Card' ? 'card' : 'mobile_money';
  
  final paymentResult = await paymentService.initializePayment(
    email: shippingEmail,
    amount: cartService.total,
    orderId: orderId,
    phone: shippingPhone,
    paymentMethod: paystackPaymentMethod,
    currency: 'GHS',
  );

  if (!mounted) return;

  // Step 2: Check if payment initialization was successful
  if (!paymentResult.success || paymentResult.authorizationUrl == null) {
    setState(() => _isSubmitting = false);
    debugPrint('Payment init failed - success: ${paymentResult.success}, url: ${paymentResult.authorizationUrl}');
    debugPrint('Payment init error: ${paymentResult.error}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(paymentResult.error ?? 'Failed to initialize payment.'),
        backgroundColor: Colors.redAccent,
      ),
    );
    return;
  }

  debugPrint('Payment initialized, opening Paystack portal with URL: ${paymentResult.authorizationUrl}');
  
  // Show loading indicator while opening webview
  setState(() => _isSubmitting = false);

// Step 3: Open Paystack authorization URL in webview
  final paymentResultObj = await Navigator.of(context).push<PaystackCheckoutResult>(
    MaterialPageRoute(
      builder: (ctx) => PaystackCheckoutScreen(
        authorizationUrl: paymentResult.authorizationUrl!,
        reference: paymentResult.reference ?? orderId,
        orderId: orderId,
        amount: cartService.total,
        paymentMethod: _paymentMethod,
      ),
    ),
  );

  if (!mounted) return;

  // Step 4: CRITICAL FIX - Check if payment was actually completed before verifying
  // Only verify if checkout reports SUCCESS - don't verify if canceled/closed/abandoned!
  if (paymentResultObj == null || !paymentResultObj.completed) {
    // UI didn't detect completion reliably (URL pattern mismatch, user closed, etc).
    // We'll still verify using the Paystack reference; we only confirm/redirect on real success.
    final status = paymentResultObj?.status ?? 'unknown';
    final message = paymentResultObj?.message ?? 'Payment not completed (UI)';
    debugPrint('UI payment completion not detected. status=$status message=$message. Verifying via reference anyway...');
  } else {
    debugPrint('Payment completed in UI, verifying...');
  }

// Step 5: Verify payment directly via Paystack API (not waiting for webhook)
  // This is the key change: pay first, then verify directly
  if (paymentResult.reference != null && paymentResult.reference!.isNotEmpty) {
    setState(() => _isSubmitting = true);
    
    // Show waiting dialog while verifying payment directly
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified, color: Colors.blue, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'Verifying Payment',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Verifying your payment directly with Paystack...',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    );

    // Verify payment directly via Paystack API (bypasses webhook waiting)
    final verifyResult = await paymentService.verifyPaymentDirectly(
      paymentResult.reference!,
    );

    // Close the waiting dialog
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // Close dialog
    }

    if (!mounted) return;

    // Check if payment was verified successfully
    if (!verifyResult.success) {
      setState(() => _isSubmitting = false);
      
      // Show detailed error dialog for failed payment verification
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline, color: Colors.red, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                'Payment Verification Failed',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(verifyResult.error ?? 'We could not verify your payment with Paystack. Please check your orders.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
content: Text(verifyResult.error ?? 'Payment verification failed.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    
    debugPrint('Payment verified directly for reference: ${paymentResult.reference}');
  } else {
    // No reference to verify - this shouldn't happen
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment reference missing. Please contact support.'),
        backgroundColor: Colors.redAccent,
      ),
    );
    return;
  }

  // Step 6: Confirm order via backend to update status to 'confirmed'
  // This is critical! Without this, the order stays in 'pending' status
  setState(() => _isSubmitting = true);
  
  final confirmResult = await orderService.confirmOrder(orderId);

  if (!mounted) return;

  // If backend already confirmed the order, continue regardless of confirmResult.
  // This handles cases where the backend status is updated via webhook/verify timing.
  if (!confirmResult) {
    final refreshed = await orderService.getOrderByOrderId(orderId);
    if (refreshed != null && refreshed.status == OrderStatus.confirmed) {
      debugPrint('Order already confirmed on backend: $orderId');

      await cartService.clearCart();
      setState(() => _isSubmitting = false);

      if (mounted) {
        context.go('/order-success/$orderId');
      }
      return;
    }

    setState(() => _isSubmitting = false);

    // Order confirmation failed - show error
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_outlined, color: Colors.orange, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'Order Confirmation Issue',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your payment was verified successfully, but we encountered an issue confirming your order. Your order ID is: $orderId\n\nPlease check your orders page or contact support.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/orders/$orderId');
            },
            child: const Text('View Orders'),
          ),
        ],
      ),
    );
    return;
  }

  debugPrint('Order confirmed successfully: $orderId');

  // Clear cart and show success
  await cartService.clearCart();
  setState(() => _isSubmitting = false);

  // Navigate to order success page
  if (mounted) {
    context.go('/order-success/$orderId');
  }
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartService = context.watch<CartService>();

    if (cartService.items.isEmpty) {
      return Scaffold(
        body: Column(
          children: [
            AppHeader(
              showBackButton: true,
              onBackTap: () => context.go('/cart'),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Your cart is empty',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add items before proceeding to checkout',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: () => context.go('/'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Continue Shopping'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            showBackButton: true,
            onBackTap: () => context.go('/cart'),
            showSearch: false,
          ),
          // Step Indicator
          CheckoutStepIndicator(
            currentStep: _currentStep,
            steps: _steps,
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Security Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.verified_user,
                              color: theme.colorScheme.onPrimary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Secure & Protected',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your payment information is encrypted and secure',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Step 1: Shipping Information
                    if (_currentStep == 0) ...[
                      ProfessionalSectionCard(
                        title: 'Shipping Details',
                        icon: Icons.local_shipping_outlined,
                        child: Column(
                          children: [
                            EnhancedFormField(
                              controller: _nameController,
                              label: 'Full Name',
                              icon: Icons.person_outline,
                              textCapitalization: TextCapitalization.words,
                              validator: (value) =>
                                  value == null || value.trim().isEmpty ? 'Please enter your full name' : null,
                            ),
                            const SizedBox(height: 16),
                            EnhancedFormField(
                              controller: _emailController,
                              label: 'Email Address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            EnhancedFormField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (value) =>
                                  value == null || value.trim().isEmpty ? 'Please enter your phone number' : null,
                            ),
                            const SizedBox(height: 16),
                            EnhancedFormField(
                              controller: _addressController,
                              label: 'Street Address',
                              icon: Icons.home_outlined,
                              validator: (value) =>
                                  value == null || value.trim().isEmpty ? 'Please enter your address' : null,
                            ),
const SizedBox(height: 16),
LayoutBuilder(
                              builder: (context, constraints) {
                                // Use vertical layout when width is less than 400px
                                final isCompact = constraints.maxWidth < 400;
                                if (isCompact) {
                                  return Column(
                                    children: [
                                      EnhancedFormField(
                                        controller: _cityController,
                                        label: 'City',
                                        icon: Icons.location_city_outlined,
                                        validator: (value) =>
                                            value == null || value.trim().isEmpty ? 'Required' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      DropdownButtonFormField<String>(
                                        value: _selectedRegion,
                                        decoration: InputDecoration(
                                          labelText: 'Region',
                                          prefixIcon: const Icon(Icons.map_outlined),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                        ),
                                        items: CartService.ghanaRegions.map((region) {
                                          return DropdownMenuItem(
                                            value: region,
                                            child: Text(region),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() {
                                              _selectedRegion = value;
                                              _stateController.text = value;
                                            });
                                            final cartService = Provider.of<CartService>(context, listen: false);
                                            cartService.setRegion(value);
                                          }
                                        },
                                        validator: (value) =>
                                            value == null || value.trim().isEmpty ? 'Required' : null,
                                      ),
                                    ],
                                  );
                                }
                                return Row(
                                  children: [
                                    Expanded(
                                      child: EnhancedFormField(
                                        controller: _cityController,
                                        label: 'City',
                                        icon: Icons.location_city_outlined,
                                        validator: (value) =>
                                            value == null || value.trim().isEmpty ? 'Required' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedRegion,
                                        decoration: InputDecoration(
                                          labelText: 'Region',
                                          prefixIcon: const Icon(Icons.map_outlined),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                        ),
                                        items: CartService.ghanaRegions.map((region) {
                                          return DropdownMenuItem(
                                            value: region,
                                            child: Text(region),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() {
                                              _selectedRegion = value;
                                              _stateController.text = value;
                                            });
                                            final cartService = Provider.of<CartService>(context, listen: false);
                                            cartService.setRegion(value);
                                          }
                                        },
                                        validator: (value) =>
                                            value == null || value.trim().isEmpty ? 'Required' : null,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 16),
LayoutBuilder(
                              builder: (context, constraints) {
                                final isCompact = constraints.maxWidth < 400;
                                if (isCompact) {
                                  return Column(
                                    children: [
                                      EnhancedFormField(
                                        controller: _postalCodeController,
                                        label: 'Postal Code',
                                        icon: Icons.local_post_office_outlined,
                                        validator: (value) =>
                                            value == null || value.trim().isEmpty ? 'Required' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      EnhancedFormField(
                                        controller: _countryController,
                                        label: 'Country',
                                        icon: Icons.flag_outlined,
                                        validator: (value) =>
                                            value == null || value.trim().isEmpty ? 'Required' : null,
                                      ),
                                    ],
                                  );
                                }
                                return Row(
                                  children: [
                                    Expanded(
                                      child: EnhancedFormField(
                                        controller: _postalCodeController,
                                        label: 'Postal Code',
                                        icon: Icons.local_post_office_outlined,
                                        validator: (value) =>
                                            value == null || value.trim().isEmpty ? 'Required' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: EnhancedFormField(
                                        controller: _countryController,
                                        label: 'Country',
                                        icon: Icons.flag_outlined,
                                        validator: (value) =>
                                            value == null || value.trim().isEmpty ? 'Required' : null,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Step 2: Payment Method
                    if (_currentStep == 1) ...[
                      ProfessionalSectionCard(
                        title: 'Payment Method',
                        icon: Icons.payments_outlined,
                        child: Column(
                          children: [
                            ..._paymentMethods.map(
                              (method) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: PaymentMethodCard(
                                  method: method['name'],
                                  description: method['description'],
                                  icon: method['icon'],
                                  isSelected: _paymentMethod == method['name'],
                                  isRecommended: method['recommended'],
                                  onTap: () {
                                    setState(() => _paymentMethod = method['name']);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Phone Number for Payment Confirmation
                      ProfessionalSectionCard(
                        title: 'Phone Number for Payment',
                        icon: Icons.phone_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your phone number will be used to confirm your payment.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.phone_in_talk,
                                    color: theme.colorScheme.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Phone Number',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _phoneController.text.isEmpty
                                              ? 'Not provided'
                                              : _phoneController.text,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: _phoneController.text.isEmpty
                                                ? theme.colorScheme.error
                                                : theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_phoneController.text.isEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_outlined,
                                      color: theme.colorScheme.error,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Please go back to Step 1 to enter your phone number',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onErrorContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    // Step 3: Review & Confirm
                    if (_currentStep == 2) ...[
                      // Order Summary
                      ProfessionalSectionCard(
                        title: 'Order Summary',
                        icon: Icons.receipt_long_outlined,
                        child: Column(
                          children: [
                            ...List.generate(
                              cartService.items.length,
                              (index) {
                                final item = cartService.items[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.product.name,
                                              style: theme.textTheme.bodyLarge?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              'Qty: ${item.quantity}',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        _money(item.product.price * item.quantity),
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            Divider(
                              height: 24,
                              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                            ),
                            _buildSummaryRow(theme, 'Subtotal', _money(cartService.subtotal)),
                            const SizedBox(height: 8),
                            _buildSummaryRow(
                              theme,
                              'Shipping',
                              cartService.shippingFee == 0 ? 'FREE' : _money(cartService.shippingFee),
                              valueColor: cartService.shippingFee == 0 ? Colors.green : null,
                            ),
                            Divider(
                              height: 24,
                              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                            ),
                            _buildSummaryRow(
                              theme,
                              'Total',
                              _money(cartService.total),
                              emphasize: true,
                              valueColor: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Shipping & Payment Details Review
                      ProfessionalSectionCard(
                        title: 'Confirm Details',
                        icon: Icons.check_circle_outline,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow(theme, 'Name:', _nameController.text),
                            const SizedBox(height: 12),
                            _buildDetailRow(theme, 'Email:', _emailController.text),
                            const SizedBox(height: 12),
                            _buildDetailRow(theme, 'Phone:', _phoneController.text),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              theme,
                              'Address:',
                              '${_addressController.text}, ${_cityController.text}, ${_stateController.text}',
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(theme, 'Payment:', _paymentMethod),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // Navigation & Action Buttons
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 14,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: TextButton(
                        onPressed: _previousStep,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _currentStep < 2
                        ? ElevatedButton(
                            onPressed: _nextStep,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Continue'),
                          )
                        : ElevatedButton(
                            onPressed: _isSubmitting ? null : _placeOrder,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Place Order • ${_money(cartService.total)}',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
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

  Widget _buildSummaryRow(
    ThemeData theme,
    String label,
    String value, {
    bool emphasize = false,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
