import '../models/lead.dart';
import '../models/pagination.dart';
import '../utils/result.dart';
import 'api/api_client.dart';
import 'api/api_config.dart';
import 'api/api_exceptions.dart';
import 'auth/auth_service.dart';

/// Response wrapper for paginated leads
class LeadsResponse {
  final List<Lead> leads;
  final Pagination? pagination;

  const LeadsResponse({
    required this.leads,
    this.pagination,
  });

  factory LeadsResponse.fromJson(Map<String, dynamic> json) {
    return LeadsResponse(
      leads: (json['leads'] as List<dynamic>?)
              ?.map((leadJson) => Lead.fromJson(leadJson as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Service for managing leads operations
class LeadsService {
  final ApiClient _apiClient;
  final AuthService _authService;

  LeadsService({
    required ApiClient apiClient,
    required AuthService authService,
  })  : _apiClient = apiClient,
        _authService = authService;

  /// Get paginated list of leads
  Future<Result<LeadsResponse, ApiError>> getLeads({
    int page = 1,
    int limit = 20,
    String? status,
    String? leadSource,
    String? industry,
    String? search,
  }) async {
    // Check authentication
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    if (leadSource != null && leadSource.isNotEmpty) {
      queryParams['leadSource'] = leadSource;
    }
    if (industry != null && industry.isNotEmpty) {
      queryParams['industry'] = industry;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final uri = Uri.parse(ApiConfig.leads).replace(queryParameters: queryParams);

    return _apiClient.get<LeadsResponse>(
      uri.toString(),
      headers: await _getAuthHeaders(),
      fromJson: LeadsResponse.fromJson,
    );
  }

  /// Get a single lead by ID
  Future<Result<Lead, ApiError>> getLead(String leadId) async {
    // Check authentication
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final url = '${ApiConfig.leads}/$leadId';

    return _apiClient.get<Lead>(
      url,
      headers: await _getAuthHeaders(),
      fromJson: Lead.fromJson,
    );
  }

  /// Create a new lead
  Future<Result<Lead, ApiError>> createLead(Lead lead) async {
    // Check authentication
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final leadData = lead.toJson();
    // Remove read-only fields
    leadData.remove('id');
    leadData.remove('createdAt');
    leadData.remove('updatedAt');
    leadData.remove('isConverted');
    leadData.remove('convertedAt');
    leadData.remove('convertedAccountId');
    leadData.remove('convertedContactId');
    leadData.remove('convertedOpportunityId');

    return _apiClient.post<Lead>(
      ApiConfig.leads,
      headers: await _getAuthHeaders(),
      body: leadData,
      fromJson: Lead.fromJson,
    );
  }

  /// Update an existing lead
  Future<Result<Lead, ApiError>> updateLead(Lead lead) async {
    // Check authentication
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final url = '${ApiConfig.leads}/${lead.id}';
    final leadData = lead.toJson();
    // Remove read-only fields
    leadData.remove('id');
    leadData.remove('createdAt');
    leadData.remove('updatedAt');
    leadData.remove('isConverted');
    leadData.remove('convertedAt');
    leadData.remove('convertedAccountId');
    leadData.remove('convertedContactId');
    leadData.remove('convertedOpportunityId');

    return _apiClient.put<Lead>(
      url,
      headers: await _getAuthHeaders(),
      body: leadData,
      fromJson: Lead.fromJson,
    );
  }

  /// Delete a lead
  Future<Result<void, ApiError>> deleteLead(String leadId) async {
    // Check authentication
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final url = '${ApiConfig.leads}/$leadId';

    final result = await _apiClient.delete(
      url,
      headers: await _getAuthHeaders(),
    );

    return result.isSuccess
        ? Result.success(null)
        : Result.error(result.error);
  }

  /// Convert a lead to contact/account/opportunity
  Future<Result<Lead, ApiError>> convertLead(
    String leadId, {
    String? accountId,
    String? contactId,
    String? opportunityId,
  }) async {
    // Check authentication
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final url = '${ApiConfig.leads}/$leadId/convert';
    final convertData = <String, dynamic>{};

    if (accountId != null) convertData['accountId'] = accountId;
    if (contactId != null) convertData['contactId'] = contactId;
    if (opportunityId != null) convertData['opportunityId'] = opportunityId;

    return _apiClient.post<Lead>(
      url,
      headers: await _getAuthHeaders(),
      body: convertData,
      fromJson: Lead.fromJson,
    );
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