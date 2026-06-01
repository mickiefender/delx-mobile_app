import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:delx/config/api_config.dart';
import 'package:delx/services/api_service.dart';

/// Result of a Paystack payment transaction
class PaymentResult {
  final bool success;
  final String? authorizationUrl;
  final String? accessCode;
  final String? reference;
  final String? message;
  final String? error;

  PaymentResult({
    required this.success,
    this.authorizationUrl,
    this.accessCode,
    this.reference,
    this.message,
    this.error,
  });

factory PaymentResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    
    // Handle both camelCase and snake_case keys from backend
    String? getUrl(Map<String, dynamic>? d, String key) {
      if (d == null) return null;
      // Try camelCase first (authorizationUrl)
      if (d.containsKey(key)) return d[key] as String?;
      // Try snake_case (authorization_url)
      final snakeKey = key.replaceAllMapped(
        RegExp(r'[A-Z]'),
        (m) => '_${m.group(0)!.toLowerCase()}',
      );
      if (d.containsKey(snakeKey)) return d[snakeKey] as String?;
      return null;
    }
    
    return PaymentResult(
      success: json['success'] == true,
      authorizationUrl: getUrl(data, 'authorizationUrl'),
      accessCode: getUrl(data, 'accessCode'),
      reference: getUrl(data, 'reference'),
      message: json['message'] as String?,
      error: json['error'] as String?,
    );
  }
}

/// Verification result from Paystack
class VerificationResult {
  final bool success;
  final String? message;
  final String? error;

  VerificationResult({
    required this.success,
    this.message,
    this.error,
  });

  factory VerificationResult.fromJson(Map<String, dynamic> json) {
    return VerificationResult(
      success: json['message'] == 'Payment verified successfully',
      message: json['message'] as String?,
      error: json['error'] as String?,
    );
  }
}

/// Payment status result from polling backend (webhook-based)
class PaymentStatusResult {
  final bool success;
  final String? status;
  final String? message;
  final String? error;
  final bool? isVerified;
  final String? orderId;

  PaymentStatusResult({
    required this.success,
    this.status,
    this.message,
    this.error,
    this.isVerified,
    this.orderId,
  });

  factory PaymentStatusResult.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResult(
      success: json['status'] == 'success',
      status: json['status'] as String?,
      message: json['message'] as String?,
      error: json['error'] as String?,
      isVerified: json['is_verified'] as bool?,
      orderId: json['order_id'] as String?,
    );
  }
}

/// Service to handle Paystack payment transactions using the Django backend
class PaymentService extends ChangeNotifier {
  bool _isInitialized = false;
  bool _isLoading = false;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;

  /// Initialize service
  Future<void> initialize() async {
    _isInitialized = true;
    debugPrint('Paystack Payment Service initialized');
  }

  /// Initialize a Paystack payment through the backend API
  Future<PaymentResult> initializePayment({
    required String email,
    required double amount,
    required String orderId,
    String? phone,
    String paymentMethod = 'card',
    String? mobileMoneyProvider,
    String? currency,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

// Auth is optional (backend allows guest initialization)
      final token = apiService.token;

// Build the request body - note the camelCase keys match backend serializer
      final Map<String, dynamic> body = {
        'email': email,
        'amount': amount.toStringAsFixed(2),
        'orderId': orderId,
        'paymentMethod': paymentMethod,
      };
      
      debugPrint('Payment body constructed: $body (paymentMethod: $paymentMethod)');

      if (phone != null && phone.isNotEmpty) {
        body['phone'] = phone;
      }

      if (mobileMoneyProvider != null) {
        body['mobileMoneyProvider'] = mobileMoneyProvider;
      }

      if (currency != null) {
        body['currency'] = currency;
      }

// Make API request
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Token $token';
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}${ApiConfig.paymentInitialize}'),
        headers: headers,
        body: jsonEncode(body),
      );

      debugPrint('Payment initialize request: ${ApiConfig.apiBaseUrl}${ApiConfig.paymentInitialize}');
      debugPrint('Payment initialize body sent: $body');
      debugPrint('Payment initialize response: ${response.statusCode}');
      debugPrint('Payment initialize response body: ${response.body}');

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final result = PaymentResult.fromJson(json);

        if (result.success) {
          debugPrint('Payment initialized successfully: ${result.authorizationUrl}');
        } else {
          debugPrint('Payment initialization failed: ${result.error}');
        }

        return result;
      } else if (response.statusCode == 401) {
        return PaymentResult(
          success: false,
          error: 'Authentication failed. Please log in again.',
        );
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return PaymentResult(
          success: false,
          error: json['error'] ?? 'Failed to initialize payment',
        );
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      debugPrint('Payment initialization error: $e');
      return PaymentResult(
        success: false,
        error: 'Payment error: ${e.toString()}',
      );
    }
  }

/// Verify a Paystack payment through the backend API
  Future<VerificationResult> verifyPayment(String reference) async {
    try {
      _isLoading = true;
      notifyListeners();

// Auth is optional (backend allows guest verification)
      final token = apiService.token;

// Make API request
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Token $token';
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}${ApiConfig.paymentVerify}'),
        headers: headers,
        body: jsonEncode({'reference': reference}),
      );

      debugPrint('Payment verify response: ${response.statusCode}');
      debugPrint('Payment verify body: ${response.body}');

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final result = VerificationResult.fromJson(json);
        debugPrint('Payment verified: ${result.message}');
        return result;
      } else if (response.statusCode == 401) {
        return VerificationResult(
          success: false,
          error: 'Authentication failed. Please log in again.',
        );
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return VerificationResult(
          success: false,
          error: json['error'] ?? 'Failed to verify payment',
        );
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      debugPrint('Payment verification error: $e');
      return VerificationResult(
        success: false,
        error: 'Verification error: ${e.toString()}',
      );
    }
  }

  /// Verify payment directly via Paystack API (bypasses webhook waiting)
  /// This is the key method for "pay first, then verify" flow
  /// Uses wait_for_webhook=False to call Paystack API directly
  Future<VerificationResult> verifyPaymentDirectly(String reference) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Auth is optional (backend allows guest verification)
      final token = apiService.token;

      // Make API request with wait_for_webhook=False to verify directly via Paystack API
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Token $token';
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}${ApiConfig.paymentVerify}'),
        headers: headers,
        body: jsonEncode({
          'reference': reference,
          'wait_for_webhook': false, // Key: verify directly via Paystack API
        }),
      );

      debugPrint('Payment direct verify response: ${response.statusCode}');
      debugPrint('Payment direct verify body: ${response.body}');

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final result = VerificationResult.fromJson(json);
        debugPrint('Payment directly verified: ${result.message}');
        return result;
      } else if (response.statusCode == 401) {
        return VerificationResult(
          success: false,
          error: 'Authentication failed. Please log in again.',
        );
      } else if (response.statusCode == 400) {
        // Payment failed or not found
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return VerificationResult(
          success: false,
          error: json['error'] ?? 'Payment verification failed',
        );
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return VerificationResult(
          success: false,
          error: json['error'] ?? 'Failed to verify payment',
        );
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      debugPrint('Payment direct verification error: $e');
      return VerificationResult(
        success: false,
        error: 'Verification error: ${e.toString()}',
      );
    }
  }

  /// Poll payment status from backend until webhook confirms payment
  /// This implements the correct flow: wait for webhook confirmation before verifying
  Future<PaymentStatusResult> pollPaymentStatus(
    String reference, {
    int maxAttempts = 30,
    Duration interval = const Duration(seconds: 2),
  }) async {
    int attempts = 0;
    
    while (attempts < maxAttempts) {
      attempts++;
      debugPrint('Payment status poll attempt #$attempts for reference: $reference');

      try {
        // Make API request to /payments/status/
        final response = await http.get(
          Uri.parse(
            '${ApiConfig.apiBaseUrl}${ApiConfig.paymentStatus}?reference=$reference',
          ),
          headers: {
            'Content-Type': 'application/json',
          },
        );

        debugPrint('Payment status response: ${response.statusCode}');
        debugPrint('Payment status body: ${response.body}');

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          final result = PaymentStatusResult.fromJson(json);
          
          debugPrint(
            'Payment status: ${result.status}, verified: ${result.isVerified}',
          );

          // If payment is confirmed successful via webhook, return immediately
          if (result.status == 'success') {
            return result;
          }

          // If payment failed or abandoned, return immediately
          if (result.status == 'failed' || result.status == 'abandoned') {
            return PaymentStatusResult(
              success: false,
              status: result.status,
              error: 'Payment ${result.status}',
              message: result.message,
            );
          }

          // Status is still pending, continue polling
          debugPrint(
            'Payment status still pending, waiting for webhook... (attempt $attempts/$maxAttempts)',
          );
        } else if (response.statusCode == 404) {
          // Payment not found - could be a timing issue
          debugPrint('Payment not found yet, waiting... (attempt $attempts/$maxAttempts)');
        }
      } catch (e) {
        debugPrint('Payment status poll error: $e');
      }

      // Wait before next poll
      if (attempts < maxAttempts) {
        await Future.delayed(interval);
      }
    }

    // Timeout after max attempts
    debugPrint('Payment status polling timeout after $maxAttempts attempts');
    return PaymentStatusResult(
      success: false,
      status: 'timeout',
      error: 'Payment verification timed out. Please check your orders for payment status.',
      message: 'Polling timed out after $maxAttempts attempts',
    );
  }

  /// Process a card payment - initiates payment and returns authorization URL
  /// The returned authorizationUrl can be opened in a WebView for Paystack checkout
  Future<PaymentResult> processCardPayment({
    required String email,
    required double amountInCedis,
    required String orderId,
    required String phone,
    String currency = 'GHS',
  }) async {
    return initializePayment(
      email: email,
      amount: amountInCedis,
      orderId: orderId,
      phone: phone,
      paymentMethod: 'card',
      currency: currency,
    );
  }

  /// Process mobile money payment
  Future<PaymentResult> processMobileMoneyPayment({
    required String email,
    required double amountInCedis,
    required String orderId,
    required String phone,
    required String provider, // 'mtn', 'telecel', or 'airteltigo'
    String currency = 'GHS',
  }) async {
    return initializePayment(
      email: email,
      amount: amountInCedis,
      orderId: orderId,
      phone: phone,
      paymentMethod: 'mobile_money',
      mobileMoneyProvider: provider,
      currency: currency,
    );
  }

  /// Process bank transfer payment
  Future<PaymentResult> processBankTransferPayment({
    required String email,
    required double amountInCedis,
    required String orderId,
    String currency = 'GHS',
  }) async {
    return initializePayment(
      email: email,
      amount: amountInCedis,
      orderId: orderId,
      paymentMethod: 'bank_transfer',
      currency: currency,
    );
  }
}
