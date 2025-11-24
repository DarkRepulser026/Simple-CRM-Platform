import '../models/interaction.dart';
import '../models/pagination.dart';
import '../utils/result.dart';
import 'api/api_client.dart';
import 'api/api_config.dart';
import 'api/api_exceptions.dart';
import 'auth/auth_service.dart';

class InteractionsResponse {
  final List<Interaction> interactions;
  final Pagination? pagination;

  InteractionsResponse({required this.interactions, this.pagination});

  factory InteractionsResponse.fromJson(Map<String, dynamic> json) {
    return InteractionsResponse(
      interactions: (json['interactions'] as List<dynamic>?)
              ?.map((i) => Interaction.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination'] as Map<String, dynamic>) : null,
    );
  }
}

class InteractionService {
  final ApiClient _apiClient;
  final AuthService _authService;

  InteractionService({required ApiClient apiClient, required AuthService authService})
      : _apiClient = apiClient,
        _authService = authService;

  Future<Result<InteractionsResponse, ApiError>> getInteractions({
    int page = 1,
    int limit = 20,
    String? contactId,
    String? leadId,
    String? ticketId,
    String? search,
  }) async {
    if (!_authService.isAuthenticated) return Result.error(ApiError.unauthorized());
    final queryParams = <String, String>{'page': page.toString(), 'limit': limit.toString()};
    if (contactId != null) queryParams['contactId'] = contactId;
    if (leadId != null) queryParams['leadId'] = leadId;
    if (ticketId != null) queryParams['ticketId'] = ticketId;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    final uri = Uri.parse(ApiConfig.interactions).replace(queryParameters: queryParams);
    return _apiClient.get<InteractionsResponse>(uri.toString(), headers: await _getAuthHeaders(), fromJson: InteractionsResponse.fromJson);
  }

  Future<Result<Interaction, ApiError>> createInteraction(Interaction interaction) async {
    if (!_authService.isAuthenticated) return Result.error(ApiError.unauthorized());
    final data = interaction.toJson();
    data.remove('id');
    return _apiClient.post<Interaction>(ApiConfig.interactions, headers: await _getAuthHeaders(), body: data, fromJson: Interaction.fromJson);
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
