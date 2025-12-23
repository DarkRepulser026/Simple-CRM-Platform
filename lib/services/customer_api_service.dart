import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/customer_auth.dart';
import '../models/customer_ticket.dart';
import '../models/customer_profile.dart';
import '../utils/result.dart';
import 'api/api_config.dart';
import 'api/api_exceptions.dart';
import 'storage/secure_storage.dart';

/// Customer API Service for external/customer portal endpoints
class CustomerApiService {
  static String get _baseUrl => ApiConfig.external;
  static const Duration _timeout = Duration(seconds: 30);
  
  final SecureStorage _storage;
  final http.Client _httpClient;
  
  String? _accessToken;
  String? _refreshToken;

  CustomerApiService({
    required SecureStorage storage,
    http.Client? httpClient,
  })  : _storage = storage,
        _httpClient = httpClient ?? http.Client();

  // ==================== Authentication Endpoints ====================

  /// Register new customer account
  Future<Result<AuthResponse, ApiError>> register(RegisterRequest request) async {
    try {
      final uri = Uri.parse('$_baseUrl/auth/register');
      final response = await _httpClient
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: _encodeJson(request.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(_decodeJson(response.body));
        await _saveTokens(authResponse.token, authResponse.refreshToken ?? '');
        return Result.success(authResponse);
      }

      return Result.error(_handleErrorResponse(response));
    } catch (e) {
      return Result.error(_handleException(e));
    }
  }

  /// Login customer
  Future<Result<AuthResponse, ApiError>> login(LoginRequest request) async {
    try {
      final uri = Uri.parse('$_baseUrl/auth/login');
      final response = await _httpClient
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: _encodeJson(request.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(_decodeJson(response.body));
        await _saveTokens(authResponse.token, authResponse.refreshToken ?? '');
        return Result.success(authResponse);
      }

      return Result.error(_handleErrorResponse(response));
    } catch (e) {
      return Result.error(_handleException(e));
    }
  }

  /// Logout customer
  Future<Result<void, ApiError>> logout() async {
    try {
      final uri = Uri.parse('$_baseUrl/auth/logout');
      final headers = await _getAuthHeaders();
      
      await _httpClient
          .post(uri, headers: headers)
          .timeout(_timeout);

      // Clear tokens regardless of response
      await _clearTokens();
      return Result.success(null);
    } catch (e) {
      await _clearTokens();
      return Result.success(null); // Always succeed logout
    }
  }

  /// Refresh access token
  Future<Result<String, ApiError>> refreshAccessToken() async {
    try {
      if (_refreshToken == null) {
        _refreshToken = await _storage.readRefreshToken(); // Try loading from storage
      }

      if (_refreshToken == null) {
        return Result.error(ApiError.unauthorized('No refresh token available'));
      }

      final uri = Uri.parse('$_baseUrl/auth/refresh');
      final response = await _httpClient
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: _encodeJson({'refreshToken': _refreshToken}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final refreshResponse = RefreshTokenResponse.fromJson(_decodeJson(response.body));
        _accessToken = refreshResponse.token;
        await _storage.saveToken(refreshResponse.token);
        return Result.success(refreshResponse.token);
      }

      await _clearTokens();
      return Result.error(_handleErrorResponse(response));
    } catch (e) {
      return Result.error(_handleException(e));
    }
  }

  /// Verify current token
  Future<Result<VerifyTokenResponse, ApiError>> verifyToken() async {
    try {
      final uri = Uri.parse('$_baseUrl/auth/verify');
      final headers = await _getAuthHeaders();
      
      final response = await _httpClient
          .get(uri, headers: headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return Result.success(VerifyTokenResponse.fromJson(_decodeJson(response.body)));
      }

      return Result.error(_handleErrorResponse(response));
    } catch (e) {
      return Result.error(_handleException(e));
    }
  }

  // ==================== Ticket Endpoints ====================

  /// Get customer's tickets with optional filters
  Future<Result<PaginatedTickets, ApiError>> getTickets({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status,
      };

      final uri = Uri.parse('$_baseUrl/tickets').replace(queryParameters: queryParams);
      final headers = await _getAuthHeaders();
      
      final response = await _httpClient
          .get(uri, headers: headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return Result.success(PaginatedTickets.fromJson(_decodeJson(response.body)));
      }

      return Result.error(_handleErrorResponse(response));
    } catch (e) {
      return Result.error(_handleException(e));
    }
  }

  /// Get ticket detail by ID
  Future<Result<TicketDetail, ApiError>> getTicketDetail(String ticketId) async {
    try {
      final uri = Uri.parse('$_baseUrl/tickets/$ticketId');
      final headers = await _getAuthHeaders();
      
      final response = await _httpClient
          .get(uri, headers: headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return Result.success(TicketDetail.fromJson(_decodeJson(response.body)));
      }

      return Result.error(_handleErrorResponse(response));
    } catch (e) {
      return Result.error(_handleException(e));
    }
  }

  /// Create new ticket
  Future<Result<CustomerTicket, ApiError>> createTicket(CreateTicketRequest request) async {
    try {
      final uri = Uri.parse('$_baseUrl/tickets');
      final headers = await _getAuthHeaders();
      
      final response = await _httpClient
          .post(
            uri,
            headers: headers,
            body: _encodeJson(request.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        return Result.success(CustomerTicket.fromJson(_decodeJson(response.body)));
      }

      return Result.error(_handleErrorResponse(response));
    } catch (e) {
      return Result.error(_handleException(e));
    }
  }

  /// Update ticket (limited fields)
  Future<Result<CustomerTicket, ApiError>> updateTicket(
    String ticketId,
    UpdateTicketRequest request,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/tickets/$ticketId');
      final headers = await _getAuthHeaders();
      
      final response = await _httpClient
          .put(
            uri,
            headers: headers,
            body: _encodeJson(request.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return Result.success(CustomerTicket.fromJson(_decodeJson(response.body)));
      }

      return Result.error(_handleErrorResponse(response));
    } catch (e) {
      return Result.error(_handleException(e));
    }
  }

  // ==================== Message Endpoints ====================

  /// Get messages for a ticket
  Future<Result<PaginatedMessages, ApiError>> getTicketMessages(
    String ticketId, {
    int page = 1,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
      };

      final uri = Uri.parse('$_baseUrl/tickets/$ticketId/messages')
          .replace(queryParameters: queryParams);
      final headers = await _getAuthHeaders();
      
      final response = await _httpClient
          .get(uri, headers: headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return Result.success(PaginatedMessages.fromJson(_decodeJson(response.body)));
      }

      return Result.error(_handleErrorResponse(response));
    } catch (e) {
      return Result.error(_handleException(e));
    }
  }

  /// Add message to ticket
  Future<Result<TicketMessage, ApiError>> addMessage(
    String ticketId,
    MessageRequest request,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/tickets/$ticketId/messages');
      final headers = await _getAuthHeaders();
      
      final response = await _httpClient
          .post(
            uri,
            headers: headers,
            body: _encodeJson(request.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        return Result.success(TicketMessage.fromJson(_decodeJson(response.body)));
      }

      return Result.error(_handleErrorResponse(response));
    } catch (e) {
      return Result.error(_handleException(e));
    }
  }

  /// Update message (limited time window)
  Future<Result<TicketMessage, ApiError>> updateMessage(
    String ticketId,
    String messageId,
    UpdateMessageRequest request,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/tickets/$ticketId/messages/$messageId');
      final headers = await _getAuthHeaders();
      
      final response = await _httpClient
          .put(
            uri,
            headers: headers,
            body: _encodeJson(request.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return Result.success(TicketMessage.fromJson(_decodeJson(response.body)));
      }

      return Result.error(_handleErrorResponse(response));
    } catch (e) {
      return Result.error(_handleException(e));
    }
  }

  // ==================== Profile Endpoints ====================

  /// Get customer profile
  Future<Result<CustomerProfile, ApiError>> getProfile() async {
    try {
      final uri = Uri.parse('$_baseUrl/profile');
      final headers = await _getAuthHeaders();
      
      final response = await _httpClient
          .get(uri, headers: headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return Result.success(CustomerProfile.fromJson(_decodeJson(response.body)));
      }

      return Result.error(_handleErrorResponse(response));
    } catch (e) {
      return Result.error(_handleException(e));
    }
  }

  /// Update customer profile
  Future<Result<CustomerProfile, ApiError>> updateProfile(UpdateProfileRequest request) async {
    try {
      final uri = Uri.parse('$_baseUrl/profile');
      final headers = await _getAuthHeaders();
      
      final response = await _httpClient
          .put(
            uri,
            headers: headers,
            body: _encodeJson(request.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return Result.success(CustomerProfile.fromJson(_decodeJson(response.body)));
      }

      return Result.error(_handleErrorResponse(response));
    } catch (e) {
      return Result.error(_handleException(e));
    }
  }

  /// Change password
  Future<Result<void, ApiError>> changePassword(ChangePasswordRequest request) async {
    try {
      final uri = Uri.parse('$_baseUrl/profile/password');
      final headers = await _getAuthHeaders();
      
      final response = await _httpClient
          .put(
            uri,
            headers: headers,
            body: _encodeJson(request.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return Result.success(null);
      }

      return Result.error(_handleErrorResponse(response));
    } catch (e) {
      return Result.error(_handleException(e));
    }
  }

  // ==================== Helper Methods ====================

  /// Build authorization headers
  Future<Map<String, String>> _getAuthHeaders() async {
    if (_accessToken == null) {
      _accessToken = await _storage.readToken();
    }

    return {
      'Content-Type': 'application/json',
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    };
  }

  /// Save tokens to storage
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _storage.saveToken(accessToken);
    await _storage.saveRefreshToken(refreshToken);
  }

  /// Load tokens from storage
  Future<void> loadTokensFromStorage() async {
    _accessToken = await _storage.readToken();
    _refreshToken = await _storage.readRefreshToken();
  }

  /// Clear tokens from memory and storage
  Future<void> _clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.clearToken();
    await _storage.clearRefreshToken();
  }

  /// Encode JSON
  String _encodeJson(Map<String, dynamic> json) {
    return jsonEncode(json);
  }

  /// Decode JSON
  Map<String, dynamic> _decodeJson(String body) {
    return jsonDecode(body) as Map<String, dynamic>;
  }

  /// Handle error responses
  ApiError _handleErrorResponse(http.Response response) {
    try {
      final json = jsonDecode(response.body);
      final message = json['message'] ?? json['error'] ?? 'Request failed';
      return ApiError.http(response.statusCode, message);
    } catch (_) {
      return ApiError.http(response.statusCode, 'Request failed');
    }
  }

  /// Handle exceptions
  ApiError _handleException(Object error) {
    if (error is SocketException) {
      return ApiError.network('Network error: ${error.message}');
    } else if (error is TimeoutException) {
      return ApiError.timeout('Request timeout');
    } else if (error is FormatException) {
      return ApiError.parsing('Invalid response format');
    } else {
      return ApiError.unknown(error.toString());
    }
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
  }
}
