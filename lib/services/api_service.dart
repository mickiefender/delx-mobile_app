import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delx/config/api_config.dart';

/// Base API service for handling HTTP requests with authentication
class ApiService {
  static const String _tokenKey = 'auth_token';
  
  String? _token;
  String? _userId;

  /// Initialize the API service
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _userId = prefs.getString('user_id');
  }

  /// Set authentication token after login
  Future<void> setAuthToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Set current user ID
  Future<void> setUserId(String userId) async {
    _userId = userId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
  }

  /// Get current auth token
  String? get token => _token;

  /// Get current user ID
  String? get userId => _userId;

  /// Check if user is authenticated
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  /// Clear authentication
  Future<void> clearAuth() async {
    _token = null;
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove('user_id');
  }

  /// Get headers with optional authentication
  Map<String, String> _getHeaders({bool requiresAuth = false}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (requiresAuth && _token != null) {
      headers['Authorization'] = 'Token $_token';
    }
    
    return headers;
  }

  /// GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool requiresAuth = false,
  }) async {
    try {
      Uri uri = Uri.parse('${ApiConfig.apiBaseUrl}$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http.get(
        uri,
        headers: _getHeaders(requiresAuth: requiresAuth),
      ).timeout(const Duration(seconds: 30));

      final result = handleResponse(response);
      if (result is Map<String, dynamic>) {
        return result;
      }
      // If we got a list, return it wrapped in a map with 'results' key
      return {'results': result};
    } catch (e) {
      throw handleError(e);
    }
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}$endpoint'),
        headers: _getHeaders(requiresAuth: requiresAuth),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 30));

      final result = handleResponse(response);
      if (result is Map<String, dynamic>) {
        return result;
      }
      return {'results': result};
    } catch (e) {
      throw handleError(e);
    }
  }

  /// PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.apiBaseUrl}$endpoint'),
        headers: _getHeaders(requiresAuth: requiresAuth),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 30));

      final result = handleResponse(response);
      if (result is Map<String, dynamic>) {
        return result;
      }
      return {'results': result};
    } catch (e) {
      throw handleError(e);
    }
  }

  /// PATCH request
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.apiBaseUrl}$endpoint'),
        headers: _getHeaders(requiresAuth: requiresAuth),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 30));

      final result = handleResponse(response);
      if (result is Map<String, dynamic>) {
        return result;
      }
      return {'results': result};
    } catch (e) {
      throw handleError(e);
    }
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = false,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.apiBaseUrl}$endpoint'),
        headers: _getHeaders(requiresAuth: requiresAuth),
      ).timeout(const Duration(seconds: 30));

      final result = handleResponse(response);
      if (result is Map<String, dynamic>) {
        return result;
      }
      return {'results': result};
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Handle HTTP response - handles both Map and List responses
  dynamic handleResponse(http.Response response) {
    // Try to decode as JSON
    final decoded = jsonDecode(response.body);
    
    // If it's already a List (raw array response), return it wrapped
    if (decoded is List) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'results': decoded}; // Wrap list in standard format
      } else {
        throw ApiException('Request failed with status ${response.statusCode}', response.statusCode);
      }
    }
    
    // If it's a Map, proceed with normal handling
    if (decoded is Map<String, dynamic>) {
      final body = decoded;
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return body;
      } else if (response.statusCode == 401) {
        throw ApiException('Unauthorized. Please login again.', response.statusCode);
      } else if (response.statusCode == 403) {
        throw ApiException('Forbidden. You don\'t have permission.', response.statusCode);
      } else if (response.statusCode == 404) {
        throw ApiException('Resource not found.', response.statusCode);
      } else if (response.statusCode >= 500) {
        throw ApiException('Server error. Please try again later.', response.statusCode);
      } else {
        // Try to get detailed field errors first
        final fields = body['fields'];
        if (fields is Map && fields.isNotEmpty) {
          // Format field errors nicely
          final errorMessages = <String>[];
          fields.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              errorMessages.add('$key: ${value.first}');
            } else if (value is String) {
              errorMessages.add('$key: $value');
            }
          });
          if (errorMessages.isNotEmpty) {
            throw ApiException(errorMessages.join('\n'), response.statusCode);
          }
        }
        final detail = body['detail'] ?? body['error'] ?? 'Unknown error occurred';
        throw ApiException(detail.toString(), response.statusCode);
      }
    }
    
    // Fallback for unexpected response types
    throw ApiException('Unexpected response format from server.');
  }
  
  /// Get request that returns a List directly (bypasses Map requirement)
  Future<List<dynamic>> getList(
    String endpoint, {
    Map<String, String>? queryParams,
    bool requiresAuth = false,
  }) async {
    try {
      Uri uri = Uri.parse('${ApiConfig.apiBaseUrl}$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http.get(
        uri,
        headers: _getHeaders(requiresAuth: requiresAuth),
      ).timeout(const Duration(seconds: 30));

      final decoded = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is List) {
          return decoded;
        } else if (decoded is Map<String, dynamic>) {
          // Extract list from common keys
          if (decoded.containsKey('results')) {
            return decoded['results'] as List<dynamic>;
          } else if (decoded.containsKey('products')) {
            return decoded['products'] as List<dynamic>;
          } else if (decoded.containsKey('data')) {
            return decoded['data'] as List<dynamic>;
          }
          // Return empty list if no list found in map
          return [];
        }
        return [];
      } else if (response.statusCode == 404) {
        throw ApiException('Resource not found.', response.statusCode);
      } else {
        throw ApiException('Failed to load data.', response.statusCode);
      }
    } catch (e) {
      throw handleError(e);
    }
  }

  /// Handle errors
  Exception handleError(dynamic error) {
    if (error is ApiException) {
      return error;
    }
    debugPrint('API Error: $error');
    return ApiException('Network error. Please check your connection.');
  }
}

/// Custom API exception
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// Global API service instance
final apiService = ApiService();
