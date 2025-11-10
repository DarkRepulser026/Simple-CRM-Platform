import 'dart:io';

/// Configuration for API client
class ApiConfig {
  // Base URLs for different environments
  static const String _developmentUrl = 'https://mock.ngrok-free.app';
  static const String _productionUrl = 'https://api.mock.io';

  // Get base URL based on debug mode (can be overridden for testing)
  static String get baseUrl {
    if (const bool.hasEnvironment('API_BASE_URL')) {
      return const String.fromEnvironment('API_BASE_URL');
    }
    // Use development URL in debug mode, production otherwise
    return const bool.fromEnvironment('dart.vm.product') ? _productionUrl : _developmentUrl;
  }

  // Timeout durations
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 10);

  // Retry configuration
  static const int maxRetries = 2;
  static const Duration retryDelay = Duration(milliseconds: 500);

  // Default headers
  static const Map<String, String> defaultHeaders = {
    HttpHeaders.contentTypeHeader: 'application/json',
    HttpHeaders.acceptHeader: 'application/json',
  };

  // API endpoints
  static String get authGoogle => '$baseUrl/auth/google';
  static String get logout => '$baseUrl/auth/logout';

  static String get contacts => '$baseUrl/contacts';
  static String contactById(String id) => '$baseUrl/contacts/$id';

  static String get leads => '$baseUrl/leads';
  static String leadById(String id) => '$baseUrl/leads/$id';

  static String get tasks => '$baseUrl/tasks';
  static String taskById(String id) => '$baseUrl/tasks/$id';

  static String get tickets => '$baseUrl/tickets';
  static String ticketById(String id) => '$baseUrl/tickets/$id';

  static String get organizations => '$baseUrl/organizations';
  static String organizationById(String id) => '$baseUrl/organizations/$id';

  static String get dashboard => '$baseUrl/dashboard';
}