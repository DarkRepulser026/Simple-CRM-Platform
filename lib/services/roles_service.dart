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

  /// Create a role from a template with default permissions for a given role type
  Future<Result<UserRole, ApiError>> createRoleFromTemplate(
    String name,
    String? description,
    UserRoleType roleType, {
    List<Permission>? additionalPermissions,
  }) async {
    if (!_authService.isAuthenticated) return Result.error(ApiError.unauthorized());

    final permissions = UserRole.getDefaultPermissions(roleType);
    final allPermissions = additionalPermissions != null
        ? [...permissions, ...additionalPermissions]
            .toSet()
            .toList()
        : permissions;

    final role = UserRole(
      id: '',
      name: name,
      description: description,
      roleType: roleType,
      permissions: allPermissions,
      organizationId: _authService.selectedOrganizationId ?? '',
      isDefault: false,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return createRole(role);
  }

  /// Get all roles sorted by creation date (most recent first)
  Future<Result<List<UserRole>, ApiError>> getAllRolesSorted() async {
    if (!_authService.isAuthenticated) return Result.error(ApiError.unauthorized());

    try {
      final roles = <UserRole>[];
      int page = 1;
      bool hasMore = true;

      while (hasMore) {
        final result = await getRoles(page: page, limit: 100);
        if (!result.isSuccess) return Result.error(result.error);

        roles.addAll(result.value.roles);
        hasMore = result.value.pagination?.hasNext ?? false;
        page++;
      }

      roles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Result.success(roles);
    } catch (e) {
      return Result.error(ApiError.unknown('Failed to fetch all roles: $e'));
    }
  }

  /// Get active roles only
  Future<Result<List<UserRole>, ApiError>> getActiveRoles({
    int page = 1,
    int limit = 20,
  }) async {
    if (!_authService.isAuthenticated) return Result.error(ApiError.unauthorized());

    final result = await getRoles(page: page, limit: limit);
    if (!result.isSuccess) return Result.error(result.error);

    final activeRoles = result.value.roles.where((r) => r.isActive).toList();
    return Result.success(activeRoles);
  }

  /// Get default roles (Admin, Manager, Agent, Viewer)
  Future<Result<List<UserRole>, ApiError>> getDefaultRoles() async {
    if (!_authService.isAuthenticated) return Result.error(ApiError.unauthorized());

    try {
      final allRoles = await getAllRolesSorted();
      if (!allRoles.isSuccess) return Result.error(allRoles.error);

      final defaultRoles =
          allRoles.value.where((r) => r.isDefault).toList();
      return Result.success(defaultRoles);
    } catch (e) {
      return Result.error(ApiError.unknown('Failed to fetch default roles: $e'));
    }
  }

  /// Search roles by name or description
  Future<Result<List<UserRole>, ApiError>> searchRoles(String query) async {
    if (!_authService.isAuthenticated) return Result.error(ApiError.unauthorized());

    try {
      final result = await getAllRolesSorted();
      if (!result.isSuccess) return Result.error(result.error);

      final lowerQuery = query.toLowerCase();
      final filtered = result.value
          .where((r) =>
              r.name.toLowerCase().contains(lowerQuery) ||
              (r.description?.toLowerCase().contains(lowerQuery) ?? false))
          .toList();

      return Result.success(filtered);
    } catch (e) {
      return Result.error(ApiError.unknown('Failed to search roles: $e'));
    }
  }

  /// Clone an existing role with a new name
  Future<Result<UserRole, ApiError>> cloneRole(
    UserRole sourceRole,
    String newName,
  ) async {
    if (!_authService.isAuthenticated) return Result.error(ApiError.unauthorized());

    final clonedRole = UserRole(
      id: '',
      name: newName,
      description: sourceRole.description != null
          ? '${sourceRole.description} (cloned from ${sourceRole.name})'
          : 'Cloned from ${sourceRole.name}',
      roleType: sourceRole.roleType,
      permissions: List.from(sourceRole.permissions),
      organizationId: _authService.selectedOrganizationId ?? '',
      isDefault: false,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return createRole(clonedRole);
  }

  /// Get roles with specific permission
  Future<Result<List<UserRole>, ApiError>> getRolesWithPermission(
    Permission permission,
  ) async {
    if (!_authService.isAuthenticated) return Result.error(ApiError.unauthorized());

    try {
      final result = await getAllRolesSorted();
      if (!result.isSuccess) return Result.error(result.error);

      final filtered = result.value
          .where((r) => r.hasPermission(permission))
          .toList();

      return Result.success(filtered);
    } catch (e) {
      return Result.error(
        ApiError.unknown('Failed to fetch roles with permission: $e'),
      );
    }
  }

  /// Get roles missing specific permission
  Future<Result<List<UserRole>, ApiError>> getRolesMissingPermission(
    Permission permission,
  ) async {
    if (!_authService.isAuthenticated) return Result.error(ApiError.unauthorized());

    try {
      final result = await getAllRolesSorted();
      if (!result.isSuccess) return Result.error(result.error);

      final filtered = result.value
          .where((r) => !r.hasPermission(permission))
          .toList();

      return Result.success(filtered);
    } catch (e) {
      return Result.error(
        ApiError.unknown('Failed to fetch roles missing permission: $e'),
      );
    }
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
