import '../models/lead.dart';
import '../models/contact.dart';
import '../models/account.dart';
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

/// Response wrapper for lead conversion result
class LeadConversionResult {
  final Lead lead;
  final Account? account;
  final Contact? contact;
  final Map<String, dynamic>? metadata;

  const LeadConversionResult({
    required this.lead,
    this.account,
    this.contact,
    this.metadata,
  });

  factory LeadConversionResult.fromJson(Map<String, dynamic> json) {
    return LeadConversionResult(
      lead: Lead.fromJson(json['lead'] as Map<String, dynamic>? ?? {}),
      account: json['account'] != null ? Account.fromJson(json['account'] as Map<String, dynamic>) : null,
      contact: json['contact'] != null ? Contact.fromJson(json['contact'] as Map<String, dynamic>) : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
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
  /// Supports converting with an existing account ID or creating a new account
  /// Returns the conversion result with created/linked entities
  Future<Result<LeadConversionResult, ApiError>> convertLead(
    String leadId, {
    String? accountId,
    String? accountName,
    String? accountDomain,
    String? contactId,
    String? opportunityId,
  }) async {
    // Check authentication
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final url = '${ApiConfig.leads}/$leadId/convert';
    final convertData = <String, dynamic>{};

    // Add account data: either existing ID or new account details
    if (accountId != null && accountId.isNotEmpty) {
      convertData['accountId'] = accountId;
    } else if (accountName != null && accountName.isNotEmpty) {
      convertData['accountName'] = accountName;
      if (accountDomain != null && accountDomain.isNotEmpty) {
        convertData['accountDomain'] = accountDomain;
      }
    }

    if (contactId != null && contactId.isNotEmpty) convertData['contactId'] = contactId;
    if (opportunityId != null && opportunityId.isNotEmpty) convertData['opportunityId'] = opportunityId;

    final result = await _apiClient.post<Map<String, dynamic>>(
      url,
      headers: await _getAuthHeaders(),
      body: convertData,
      fromJson: (json) => json,
    );

    if (result.isError) {
      return Result.error(result.error);
    }

    try {
      final conversion = LeadConversionResult.fromJson(result.value);
      return Result.success(conversion);
    } catch (e) {
      return Result.error(ApiError.parsing('Failed to parse conversion result: $e'));
    }
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

  /// Get activity log for a specific lead
  Future<Result<List<Map<String, dynamic>>, ApiError>> getLeadActivityLog({
    required String leadId,
    int page = 1,
    int limit = 20,
  }) async {
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final url = '${ApiConfig.leads}/$leadId/activities';
    final uri = Uri.parse(url).replace(queryParameters: queryParams);

    final result = await _apiClient.get<Map<String, dynamic>>(
      uri.toString(),
      headers: await _getAuthHeaders(),
      fromJson: (json) => json,
    );

    if (result.isError) {
      return Result.error(result.error);
    }

    try {
      final activities = (result.value['activities'] as List<dynamic>?)
              ?.map((a) => a as Map<String, dynamic>)
              .toList() ??
          [];
      return Result.success(activities);
    } catch (e) {
      return Result.error(ApiError.parsing('Failed to parse activities: $e'));
    }
  }

  /// Batch get multiple leads by IDs
  Future<Result<List<Lead>, ApiError>> getLeadsByIds(List<String> leadIds) async {
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    if (leadIds.isEmpty) {
      return Result.success([]);
    }

    final leads = <Lead>[];
    for (final leadId in leadIds) {
      final res = await getLead(leadId);
      if (res.isSuccess) {
        leads.add(res.value);
      }
    }
    return Result.success(leads);
  }

  /// Get leads by source
  Future<Result<LeadsResponse, ApiError>> getLeadsBySource(
    String source, {
    int page = 1,
    int limit = 20,
  }) async {
    return getLeads(
      page: page,
      limit: limit,
      leadSource: source,
    );
  }

  /// Get leads by status
  Future<Result<LeadsResponse, ApiError>> getLeadsByStatus(
    String status, {
    int page = 1,
    int limit = 20,
  }) async {
    return getLeads(
      page: page,
      limit: limit,
      status: status,
    );
  }

  /// Get non-converted leads only
  Future<Result<List<Lead>, ApiError>> getUnconvertedLeads() async {
    final result = await getLeads(limit: 1000);
    if (result.isError) return Result.error(result.error);
    final leads = result.value.leads.where((l) => !l.isConverted).toList();
    return Result.success(leads);
  }

  /// Search leads by multiple criteria
  Future<Result<LeadsResponse, ApiError>> searchLeads(
    String query, {
    int page = 1,
    int limit = 20,
    String? status,
    String? source,
  }) async {
    return getLeads(
      page: page,
      limit: limit,
      search: query,
      status: status,
      leadSource: source,
    );
  }
}