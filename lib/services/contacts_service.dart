import '../models/contact.dart';
import '../models/pagination.dart';
import '../utils/result.dart';
import 'api/api_client.dart';
import 'api/api_config.dart';
import 'api/api_exceptions.dart';
import 'auth/auth_service.dart';

/// Response wrapper for paginated contacts
class ContactsResponse {
  final List<Contact> contacts;
  final Pagination? pagination;

  const ContactsResponse({
    required this.contacts,
    this.pagination,
  });

  factory ContactsResponse.fromJson(Map<String, dynamic> json) {
    return ContactsResponse(
      contacts: (json['contacts'] as List<dynamic>?)
              ?.map((contactJson) => Contact.fromJson(contactJson as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Service for managing contacts operations
class ContactsService {
  final ApiClient _apiClient;
  final AuthService _authService;

  ContactsService({
    required ApiClient apiClient,
    required AuthService authService,
  })  : _apiClient = apiClient,
        _authService = authService;

  /// Get paginated list of contacts
  Future<Result<ContactsResponse, ApiError>> getContacts({
    int page = 1,
    int limit = 9,
    String? search,
    String? ownerId,
    String? city,
    String? department,
  }) async {
    // Check authentication
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null && search.isNotEmpty) {
      queryParams['q'] = search;
    }
    if (ownerId != null && ownerId.isNotEmpty) queryParams['ownerId'] = ownerId;
    if (city != null && city.isNotEmpty) queryParams['city'] = city;
    if (department != null && department.isNotEmpty) queryParams['department'] = department;

    final uri = Uri.parse(ApiConfig.contacts).replace(queryParameters: queryParams);

    // Support both legacy array response and paginated response { contacts, pagination }
    final res = await _apiClient.get(uri.toString(), headers: await _getAuthHeaders());
    if (res.isError) return Result.error(res.error);
    final jsonValue = res.value;

    if (jsonValue is Map<String, dynamic>) {
      // Parse paginated response
      return Result.success(ContactsResponse.fromJson(jsonValue));
    }

    if (jsonValue is List) {
      final contacts = jsonValue.map((c) => Contact.fromJson(c as Map<String, dynamic>)).toList();
      return Result.success(ContactsResponse(contacts: contacts));
    }

    return Result.error(ApiError.unknown('Unexpected response format'));
  }

  /// Get a single contact by ID
  Future<Result<Contact, ApiError>> getContact(String contactId) async {
    // Check authentication
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final url = '${ApiConfig.contacts}/$contactId';

    return _apiClient.get<Contact>(
      url,
      headers: await _getAuthHeaders(),
      fromJson: Contact.fromJson,
    );
  }

  /// Create a new contact
  Future<Result<Contact, ApiError>> createContact(Contact contact) async {
    // Check authentication
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final contactData = contact.toJson();
    // Remove read-only fields
    contactData.remove('id');
    contactData.remove('createdAt');
    contactData.remove('updatedAt');

    return _apiClient.post<Contact>(
      ApiConfig.contacts,
      headers: await _getAuthHeaders(),
      body: contactData,
      fromJson: Contact.fromJson,
    );
  }

  /// Update an existing contact
  Future<Result<Contact, ApiError>> updateContact(Contact contact) async {
    // Check authentication
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final url = '${ApiConfig.contacts}/${contact.id}';
    final contactData = contact.toJson();
    // Remove read-only fields
    contactData.remove('id');
    contactData.remove('createdAt');
    contactData.remove('updatedAt');

    return _apiClient.put<Contact>(
      url,
      headers: await _getAuthHeaders(),
      body: contactData,
      fromJson: Contact.fromJson,
    );
  }

  /// Delete a contact
  Future<Result<void, ApiError>> deleteContact(String contactId) async {
    // Check authentication
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final url = '${ApiConfig.contacts}/$contactId';

    final result = await _apiClient.delete(
      url,
      headers: await _getAuthHeaders(),
    );

    return result.isSuccess 
      ? Result.success(null) 
      : Result.error(result.error);
  }

  /// Search contacts
  Future<Result<ContactsResponse, ApiError>> searchContacts(
    String query, {
    int page = 1,
    int limit = 9,
  }) async {
    // Check authentication
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final queryParams = <String, String>{
      'q': query,
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final uri = Uri.parse('${ApiConfig.contacts}/search').replace(queryParameters: queryParams);

    final res = await _apiClient.get(uri.toString(), headers: await _getAuthHeaders());
    if (res.isError) return Result.error(res.error);
    final jsonList = res.value as List<dynamic>;
    final contacts = jsonList.map((c) => Contact.fromJson(c as Map<String, dynamic>)).toList();
    return Result.success(ContactsResponse(contacts: contacts));
  }

  /// Get authentication headers
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = _authService.jwtToken;
    final orgId = _authService.selectedOrganizationId;

    final headers = <String, String>{};

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (orgId != null) {
      headers['X-Organization-ID'] = orgId;
    }

    return headers;
  }
}