import '../models/user_role.dart';
import '../models/pagination.dart';
import '../utils/result.dart';
import 'api/api_client.dart';
import 'api/api_config.dart';
import 'api/api_exceptions.dart';
import 'auth/auth_service.dart';

class RolesResponse {
  final List<UserRole> roles;
  final Pagination? pagination;

  RolesResponse({required this.roles, this.pagination});

  factory RolesResponse.fromJson(Map<String, dynamic> json) {
    return RolesResponse(
      roles: (json['roles'] as List<dynamic>?)
              ?.map((r) => UserRole.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination'] as Map<String, dynamic>) : null,
    );
  }
}

class RolesService {
  final ApiClient _apiClient;
  final AuthService _authService;

  RolesService({required ApiClient apiClient, required AuthService authService})
      : _apiClient = apiClient,
        _authService = authService;

  Future<Result<RolesResponse, ApiError>> getRoles({int page = 1, int limit = 20}) async {
    if (!_authService.isAuthenticated) return Result.error(ApiError.unauthorized());
    final uri = Uri.parse(ApiConfig.userRoles).replace(queryParameters: {'page': page.toString(), 'limit': limit.toString()});
    return _apiClient.get<RolesResponse>(uri.toString(), headers: await _getAuthHeaders(), fromJson: RolesResponse.fromJson);
  }

  Future<Result<UserRole, ApiError>> createRole(UserRole role) async {
    if (!_authService.isAuthenticated) return Result.error(ApiError.unauthorized());
    final data = role.toJson()..remove('id');
    return _apiClient.post<UserRole>(ApiConfig.userRoles, headers: await _getAuthHeaders(), body: data, fromJson: UserRole.fromJson);
  }

  Future<Result<UserRole, ApiError>> updateRole(UserRole role) async {
    if (!_authService.isAuthenticated) return Result.error(ApiError.unauthorized());
    final url = ApiConfig.userRoleById(role.id);
    final data = role.toJson()..remove('id');
    return _apiClient.put<UserRole>(url, headers: await _getAuthHeaders(), body: data, fromJson: UserRole.fromJson);
  }

  Future<Result<void, ApiError>> deleteRole(String id) async {
    if (!_authService.isAuthenticated) return Result.error(ApiError.unauthorized());
    final url = ApiConfig.userRoleById(id);
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
