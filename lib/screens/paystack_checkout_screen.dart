import 'dart:async';
import 'package:delx/models/order.dart';
import 'package:delx/services/order_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

/// Result returned from Paystack checkout screen
/// Contains the status of payment completion
class PaystackCheckoutResult {
  final bool completed;
  final String status; // 'success', 'failed', 'canceled', 'closed'
  final String? message;

  PaystackCheckoutResult({
    required this.completed,
    required this.status,
    this.message,
  });
}

/// Screen that displays Paystack checkout in an in-app WebView
/// Uses URL detection to determine actual payment completion status
class PaystackCheckoutScreen extends StatefulWidget {
  final String authorizationUrl;
  final String reference;
  final String orderId;
  final double? amount;
  final String? paymentMethod;

  const PaystackCheckoutScreen({
    super.key,
    required this.authorizationUrl,
    required this.reference,
    required this.orderId,
    this.amount,
    this.paymentMethod,
  });

  @override
  State<PaystackCheckoutScreen> createState() => _PaystackCheckoutScreenState();
}

class _PaystackCheckoutScreenState extends State<PaystackCheckoutScreen> {
  late InAppWebViewController _webViewController;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _statusCheckTimer;
  String? _initialUrl;
  int _pollCount = 0;
  static const int _maxPollCount = 300; // ~10 minutes max (300 * 2 seconds)

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  /// Format amount as Ghana Cedis
  String _formatAmount(double? amount) {
    if (amount == null) return '';
    return 'GH₵${amount.toStringAsFixed(2)}';
  }

  /// Get payment method display text
  String _getPaymentMethodText() {
    final method = widget.paymentMethod?.toLowerCase() ?? '';
    if (method.contains('card')) {
      return 'Credit/Debit Card';
    } else if (method.contains('mobile')) {
      return 'Mobile Money';
    }
    return widget.paymentMethod ?? 'Payment';
  }

  /// Inject JavaScript to handle payment completion
  Future<void> _injectPaymentScript() async {
    final script = '''
    (function() {
      // Store reference in window for access
      window.paymentReference = '${widget.reference}';
      
      // Listen for Paystack close event (when user closes without paying or payment is made)
      if (typeof PaystackPop !== 'undefined') {
        console.log('Paystack is available');
      }
      
      // Create a bridge to notify the Flutter app
      window.flutterChannel = {
        paymentSuccess: function() {
          window.flutter.messageHandlers.paymentCompleted.postMessage({
            status: 'success',
            reference: window.paymentReference
          });
        },
        paymentClosed: function() {
          window.flutter.messageHandlers.paymentCompleted.postMessage({
            status: 'closed',
            reference: window.paymentReference
          });
        }
      };
      
      console.log('Flutter bridge initialized for payment');
    })();
    ''';

    await _webViewController.evaluateJavascript(source: script);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Complete Payment',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Column(
        children: [
          // Loading indicator
          if (_isLoading)
            LinearProgressIndicator(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),

// Error message
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.errorContainer,
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Payment Summary Card
          if (widget.amount != null || widget.paymentMethod != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Summary',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Amount:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _formatAmount(widget.amount),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  if (widget.paymentMethod != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Method:',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          _getPaymentMethodText(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

// WebView
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri.uri(Uri.parse(widget.authorizationUrl)),
              ),
              initialSettings: InAppWebViewSettings(
                isInspectable: true,
                javaScriptEnabled: true,
                supportZoom: true,
                clearCache: false,
                useShouldOverrideUrlLoading: true,
                transparentBackground: false,
                thirdPartyCookiesEnabled: true,
                allowsInlineMediaPlayback: true,
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
                debugPrint(
                    'Paystack WebView created with URL: ${widget.authorizationUrl}');
              },
              onLoadStart: (controller, url) {
                setState(() => _isLoading = true);
                debugPrint('Paystack WebView load start: $url');
              },
              onLoadStop: (controller, url) {
                setState(() {
                  _isLoading = false;
                  // Store the initial URL for comparison
                  _initialUrl = url?.toString();
                  _pollCount = 0;
                });
                debugPrint('Paystack WebView load stop: $url');
                debugPrint(
                    'Stored initial URL for payment tracking: $_initialUrl');

                // Inject payment script when page loads
                _injectPaymentScript();

                // Set up polling to check payment status every 2 seconds
                _statusCheckTimer?.cancel();
                _statusCheckTimer = Timer.periodic(
                  const Duration(seconds: 2),
                  (_) => _checkPaymentStatus(),
                );
              },
              onLoadError: (controller, url, code, message) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = 'Failed to load payment page: $message';
                });
                debugPrint(
                    'Paystack WebView load error: $message (code: $code)');
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final url = navigationAction.request.url?.toString() ?? '';
                debugPrint('Paystack URL loading: $url');
                return NavigationActionPolicy.ALLOW;
              },
              onConsoleMessage: (controller, consoleMessage) {
                debugPrint('WebView console: ${consoleMessage.message}');
              },
            ),
          ),

          // Bottom instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Text(
                    'Order ID: ${widget.orderId}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Completion Steps:',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '1. Complete payment with your preferred method\n2. Confirm your phone number if prompted\n3. Wait for success confirmation\n4. Your order will be verified automatically',
                          textAlign: TextAlign.left,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Do NOT close this screen until payment is complete.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
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

/// Check payment status by polling the current URL
  /// Paystack redirects to success/cancel URLs after payment completion
  /// KEY FIX: Only detect SUCCESS redirects to confirm payment was completed
  /// Don't treat modal close as success - user might have abandoned!
  Future<void> _checkPaymentStatus() async {
    try {
      _pollCount++;

      // Check for timeout (max 10 minutes of polling)
      if (_pollCount > _maxPollCount) {
        debugPrint('Payment polling timeout after $_pollCount checks');
        _statusCheckTimer?.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Payment timeout. Please check your orders for payment status.'),
              backgroundColor: Colors.orange,
            ),
          );
          // Return as "closed" - not confirmed as success
          Navigator.of(context).pop(
            PaystackCheckoutResult(
              completed: false,
              status: 'closed',
              message: 'Payment timed out',
            ),
          );
        }
        return;
      }

      // Get the current URL from the WebView to check for redirects
      final currentUrl = await _webViewController.getUrl();
      final urlString = currentUrl?.toString() ?? '';

      // Log every few checks
      if (_pollCount % 5 == 0) {
        debugPrint('Payment status check #$_pollCount: $urlString');
      }

      // Check if URL has changed from initial (indicates navigation/redirect)
      final urlChanged = _initialUrl != null && urlString != _initialUrl;

      // CRITICAL FIX: Check for SPECIFIC Paystack SUCCESS redirects
      // These are the ONLY patterns that indicate SUCCESSFUL payment:
      // - paystack.com/payment/callback
      // - paystack.com/payment/verify/:reference
      // - Contains both "trx" AND "reference" in query params (success callback)
      final isSuccessRedirect = urlString.contains('payment/callback') ||
          urlString.contains('payment/verify') ||
          (urlString.contains('trx') && urlString.contains('reference'));

      // === Backend truth polling (robust) ===
      // Your WebView success detection can be fragile depending on Paystack redirects.
      // Use backend order status as the source of truth.
      if (_pollCount % 5 == 0) {
        try {
          final orderService = context.read<OrderService>();
          final order = await orderService.getOrderByOrderId(widget.orderId);

          if (!mounted) return;

          if (order != null && order.status == OrderStatus.confirmed) {
            _statusCheckTimer?.cancel();
            debugPrint('Payment SUCCESS detected via backend order status. '
                'orderId=${widget.orderId} poll=$_pollCount');
            await _handlePaymentCompletion(success: true);
            return;
          }

          if (order != null && order.status == OrderStatus.cancelled) {
            _statusCheckTimer?.cancel();
            debugPrint('Order cancelled detected via backend. orderId=${widget.orderId}');
            if (mounted) {
              Navigator.of(context).pop(
                PaystackCheckoutResult(
                  completed: false,
                  status: 'canceled',
                  message: 'Order was canceled',
                ),
              );
            }
            return;
          }
        } catch (e) {
          debugPrint('Backend order polling failed: $e');
        }
      }

      // Some Paystack flows show success in-page without changing the URL.
      // Detect that by scanning visible text content occasionally.
      bool isSuccessByContent = false;
      if (!isSuccessRedirect && _pollCount % 10 == 0) {
        try {
          final dynamic pageTextDyn = await _webViewController.evaluateJavascript(
            source: 'document.body && document.body.innerText ? document.body.innerText : ""',
          );

          final pageText = pageTextDyn?.toString().toLowerCase() ?? '';
          final hasSuccessWords =
              (pageText.contains('payment') && pageText.contains('success')) ||
              (pageText.contains('transaction') && pageText.contains('success')) ||
              (pageText.contains('payment successful')) ||
              pageText.contains('successful');

          isSuccessByContent = hasSuccessWords;

          if (isSuccessByContent) {
            debugPrint(
              'Payment SUCCESS detected via page content (poll=$_pollCount).',
            );
          }
        } catch (e) {
          debugPrint('Error while checking Paystack page content: $e');
        }
      }

      final isSuccess = isSuccessRedirect || isSuccessByContent;

      // Check for explicit failure/cancel redirects
      // These indicate user explicitly canceled or payment failed
      final isCancelRedirect = urlString.contains('cancel') ||
          urlString.contains('close') ||
          urlString.contains('abandon');

      // If we detect a success redirect/content, process as successful payment
      if (isSuccess) {
        _statusCheckTimer?.cancel();
        debugPrint('Payment SUCCESS detected. url=$urlString poll=$_pollCount');
        await _handlePaymentCompletion(success: true);
        return;
      }

      // If user explicitly canceled, inform but don't verify payment
      // KEY: This is the correct flow - confirm before verifying!
      if (isCancelRedirect && urlChanged) {
        _statusCheckTimer?.cancel();
        debugPrint('Payment canceled by user');
        if (mounted) {
          Navigator.of(context).pop(
            PaystackCheckoutResult(
              completed: false,
              status: 'canceled',
              message: 'Payment was canceled',
            ),
          );
        }
        return;
      }
} catch (e) {
      debugPrint('Error checking payment status: $e');
    }
  }

  /// Handle payment completion after user closes Paystack checkout
  /// [success] - if true, payment was completed successfully
  /// If false, the modal was closed without completing payment
  Future<void> _handlePaymentCompletion({bool success = false}) async {
    _statusCheckTimer?.cancel();

    if (!mounted) return;

    if (success) {
      // Show brief verification notification and return success
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
                child:
                    const Icon(Icons.hourglass_top, color: Colors.blue, size: 40),
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
                'We are verifying your payment with Paystack. Please wait...',
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

      // Auto-close after a short delay to allow the dialog to display
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        // Return SUCCESS result - this will trigger verification in checkout screen
        Navigator.of(context).pop(
          PaystackCheckoutResult(
            completed: true,
            status: 'success',
            message: 'Payment completed, verifying...',
          ),
        );
      }
    } else {
      // Payment was not completed - user closed without paying
      // Return FAILED result - checkout screen should NOT verify
      Navigator.of(context).pop(
        PaystackCheckoutResult(
          completed: false,
          status: 'closed',
          message: 'Payment was not completed',
        ),
      );
    }
  }
}
