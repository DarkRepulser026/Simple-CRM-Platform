import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../utils/result.dart';
import '../auth/auth_service.dart';
import 'api_config.dart';
import 'api_exceptions.dart';
import '../service_locator.dart';

/// HTTP API client with typed methods, error handling, and authentication
class ApiClient {
  final http.Client _httpClient;

  ApiClient({
    http.Client? httpClient,
  })  : _httpClient = httpClient ?? http.Client() {
    // Debug: print base URL used by the client to help diagnose environment issues
    debugPrint('ApiClient initialized with baseUrl=${ApiConfig.baseUrl}');
  }

  /// Performs a GET request
  Future<Result<T, ApiError>> get<T>(
    String url, {
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    return _performRequest(
      'GET',
      url,
      headers: headers,
      fromJson: fromJson,
    );
  }

  /// Performs a POST request
  Future<Result<T, ApiError>> post<T>(
    String url, {
    Map<String, String>? headers,
    Object? body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    return _performRequest(
      'POST',
      url,
      headers: headers,
      body: body,
      fromJson: fromJson,
    );
  }

  /// Performs a PUT request
  Future<Result<T, ApiError>> put<T>(
    String url, {
    Map<String, String>? headers,
    Object? body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    return _performRequest(
      'PUT',
      url,
      headers: headers,
      body: body,
      fromJson: fromJson,
    );
  }

  /// Performs a DELETE request
  Future<Result<T, ApiError>> delete<T>(
    String url, {
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    return _performRequest(
      'DELETE',
      url,
      headers: headers,
      fromJson: fromJson,
    );
  }

  /// Core request method with error handling and retries
  Future<Result<T, ApiError>> _performRequest<T>(
    String method,
    String url, {
    Map<String, String>? headers,
    Object? body,
    T Function(Map<String, dynamic>)? fromJson,
    int retryCount = 0,
  }) async {
    try {
      debugPrint('ApiClient: Performing $method $url');
      final uri = Uri.parse(url);
      final requestHeaders = await _buildHeaders(headers);
      final requestBody = _encodeBody(body);

      final request = http.Request(method, uri)
        ..headers.addAll(requestHeaders)
        ..body = requestBody ?? '';

      final streamedResponse = await _httpClient
          .send(request)
          .timeout(ApiConfig.receiveTimeout);

      final response = await http.Response.fromStream(streamedResponse);

      // Check if we should retry on certain errors
      if (_shouldRetry(response.statusCode) && retryCount < ApiConfig.maxRetries) {
        await Future.delayed(ApiConfig.retryDelay * (retryCount + 1));
        return _performRequest(
          method,
          url,
          headers: headers,
          body: body,
          fromJson: fromJson,
          retryCount: retryCount + 1,
        );
      }

      return _handleResponse<T>(response, fromJson);
    } on SocketException catch (e) {
      // Retry on network errors
      if (retryCount < ApiConfig.maxRetries) {
        await Future.delayed(ApiConfig.retryDelay * (retryCount + 1));
        return _performRequest(
          method,
          url,
          headers: headers,
          body: body,
          fromJson: fromJson,
          retryCount: retryCount + 1,
        );
      }
      debugPrint('ApiClient network error on $url: ${e.message}');
      return Result.error(ApiError.network('Network error: ${e.message}'));
    } on TimeoutException catch (e) {
      // Retry on timeouts
      if (retryCount < ApiConfig.maxRetries) {
        await Future.delayed(ApiConfig.retryDelay * (retryCount + 1));
        return _performRequest(
          method,
          url,
          headers: headers,
          body: body,
          fromJson: fromJson,
          retryCount: retryCount + 1,
        );
      }
      debugPrint('ApiClient timeout on $url: ${e.message}');
      return Result.error(ApiError.timeout('Request timeout: ${e.message}'));
    } on FormatException catch (e) {
      return Result.error(ApiError.parsing('Invalid response format: ${e.message}'));
    } catch (e) {
      debugPrint('ApiClient unexpected error on $url: $e');
      return Result.error(ApiError.unknown('Unexpected error: $e'));
    }
  }

  /// Determines if a request should be retried based on status code
  bool _shouldRetry(int statusCode) {
    // Retry on server errors (5xx) and some client errors
    return statusCode >= 500 || statusCode == 429; // Too Many Requests
  }

  /// Builds request headers including authentication
  Future<Map<String, String>> _buildHeaders(Map<String, String>? additionalHeaders) async {
    final headers = Map<String, String>.from(ApiConfig.defaultHeaders);

    // Add authentication headers if user is logged in
    if (locator<AuthService>().isLoggedIn && locator<AuthService>().jwtToken != null) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer ${locator<AuthService>().jwtToken}';
    }

    // Add organization header if organization is selected
    if (locator<AuthService>().hasSelectedOrganization && locator<AuthService>().selectedOrganization != null) {
      headers['X-Organization-ID'] = locator<AuthService>().selectedOrganization!.id;
    }

    // Add any additional headers
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// Encodes request body to JSON if needed
  String? _encodeBody(Object? body) {
    if (body == null) return null;
    if (body is String) return body;
    return jsonEncode(body);
  }

  /// Handles HTTP response and converts to Result
  Result<T, ApiError> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    try {
      // Handle different status codes
      switch (response.statusCode) {
        case 200:
        case 201:
        case 204:
          // Success responses
          if (response.body.isEmpty) {
            // For empty responses
            return Result.success(null as T);
          }

          final jsonData = jsonDecode(response.body);
          if (fromJson != null) {
            return Result.success(fromJson(jsonData));
          } else if (jsonData is Map<String, dynamic>) {
            return Result.success(jsonData as T);
          } else {
            return Result.success(jsonData as T);
          }

        case 401:
          // Unauthorized - clear auth and return error
          locator<AuthService>().logout();
          return Result.error(ApiError.http(401, 'Unauthorized - please log in again'));

        case 403:
          return Result.error(ApiError.http(403, 'Forbidden - insufficient permissions'));

        case 404:
          return Result.error(ApiError.http(404, 'Resource not found'));

        case 422:
          return Result.error(ApiError.http(422, 'Validation error'));

        case 500:
        case 502:
        case 503:
        case 504:
          return Result.error(ApiError.http(response.statusCode, 'Server error'));

        default:
          // Other client or server errors
          String message = 'HTTP ${response.statusCode}';
          try {
            final errorData = jsonDecode(response.body);
            if (errorData is Map && errorData.containsKey('message')) {
              message = errorData['message'] as String;
            }
          } catch (_) {
            // Ignore parsing errors for error messages
          }
          return Result.error(ApiError.http(response.statusCode, message));
      }
    } catch (e) {
      return Result.error(ApiError.parsing('Failed to parse response: $e'));
    }
  }

  /// Disposes the HTTP client
  void dispose() {
    _httpClient.close();
  }
}