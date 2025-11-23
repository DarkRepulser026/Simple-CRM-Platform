import '../models/invitation.dart';
import '../utils/result.dart';
import 'api/api_client.dart';
import 'api/api_config.dart';
import 'auth/auth_service.dart';

class InvitationsService {
  final ApiClient _apiClient;
  final AuthService _authService;

  InvitationsService({required ApiClient apiClient, required AuthService authService})
      : _apiClient = apiClient,
        _authService = authService;

  Future<Result<List<Invitation>, dynamic>> getInvitesForOrganization(String orgId) async {
    if (!_authService.isAuthenticated) return Result.error('unauthorized');
    final url = ApiConfig.organizationInvites(orgId);
    final res = await _apiClient.get(url, headers: await _getAuthHeaders());
    if (res.isError) return Result.error(res.error);
    final value = res.value as List<dynamic>;
    final invites = value.map((e) => Invitation.fromJson(e as Map<String, dynamic>)).toList();
    return Result.success(invites);
  }

  Future<Result<void, dynamic>> revokeInvitation(String inviteId) async {
    if (!_authService.isAuthenticated) return Result.error('unauthorized');
    final url = ApiConfig.adminRevokeInvitation(inviteId);
    final res = await _apiClient.post<void>(url, headers: await _getAuthHeaders(), fromJson: (_) => null);
    return res.isSuccess ? Result.success(null) : Result.error(res.error);
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
