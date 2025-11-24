import '../models/organization.dart';
import '../models/pagination.dart';
import '../utils/result.dart';
import 'api/api_client.dart';
import 'api/api_config.dart';
import 'api/api_exceptions.dart';
import 'auth/auth_service.dart';

/// Response wrapper for paginated organizations
class OrganizationsResponse {
  final List<Organization> organizations;
  final Pagination? pagination;

  const OrganizationsResponse({
    required this.organizations,
    this.pagination,
  });

  factory OrganizationsResponse.fromJson(Map<String, dynamic> json) {
    return OrganizationsResponse(
      organizations: (json['organizations'] as List<dynamic>?)
              ?.map((orgJson) => Organization.fromJson(orgJson as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Service to manage organizations
class OrganizationsService {
  final ApiClient _apiClient;
  final AuthService _authService;

  OrganizationsService({
    required ApiClient apiClient,
    required AuthService authService,
  })  : _apiClient = apiClient,
        _authService = authService;

  Future<Result<OrganizationsResponse, ApiError>> getOrganizations({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }
    final queryParams = <String, String>{'page': page.toString(), 'limit': limit.toString()};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final uri = Uri.parse(ApiConfig.organizations).replace(queryParameters: queryParams);
    final res = await _apiClient.get(uri.toString(), headers: await _getAuthHeaders());
    if (res.isError) return Result.error(res.error);
    // The backend returns an array of organizations, map to OrganizationsResponse
    final jsonList = res.value as List<dynamic>;
    final orgs = jsonList.map((o) => Organization.fromJson(o as Map<String, dynamic>)).toList();
    return Result.success(OrganizationsResponse(organizations: orgs));
  }

  Future<Result<Organization, ApiError>> getOrganization(String id) async {
    if (!_authService.isAuthenticated) return Result.error(ApiError.unauthorized());
    final url = ApiConfig.organizationById(id);
    return _apiClient.get<Organization>(
      url,
      headers: await _getAuthHeaders(),
      fromJson: Organization.fromJson,
    );
  }

  Future<Result<Organization, ApiError>> createOrganization(Organization org) async {
    if (!_authService.isAuthenticated) return Result.error(ApiError.unauthorized());
    final data = org.toJson();
    data.remove('id');
    data.remove('role');
    return _apiClient.post<Organization>(
      ApiConfig.organizations,
      headers: await _getAuthHeaders(),
      body: data,
      fromJson: Organization.fromJson,
    );
  }

  Future<Result<Organization, ApiError>> updateOrganization(Organization org) async {
    if (!_authService.isAuthenticated) return Result.error(ApiError.unauthorized());
    final url = ApiConfig.organizationById(org.id);
    final data = org.toJson();
    data.remove('id');
    return _apiClient.put<Organization>(
      url,
      headers: await _getAuthHeaders(),
      body: data,
      fromJson: Organization.fromJson,
    );
  }

  Future<Result<void, ApiError>> deleteOrganization(String id) async {
    if (!_authService.isAuthenticated) return Result.error(ApiError.unauthorized());
    final url = ApiConfig.organizationById(id);
    final result = await _apiClient.delete(url, headers: await _getAuthHeaders());
    return result.isSuccess ? Result.success(null) : Result.error(result.error);
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = _authService.jwtToken;
    final orgId = _authService.selectedOrganizationId;
    final headers = <String, String>{};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    if (orgId != null) headers['X-Organization-ID'] = orgId;
    return headers;
  }
}
