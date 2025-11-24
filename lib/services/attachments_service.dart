import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/attachment.dart';
import '../utils/result.dart';
import 'api/api_exceptions.dart';
import 'api/api_config.dart';
import 'auth/auth_service.dart';
import 'package:path/path.dart' as p;

class AttachmentsService {
  final AuthService _authService;

  AttachmentsService(this._authService);

  /// Upload a file attachment for a ticket or other entity
  Future<Result<Attachment, ApiError>> uploadFile({
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
    required String entityType,
    required String entityId,
    String? mimeType,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.attachments);
      final request = http.MultipartRequest('POST', uri);
      final token = _authService.jwtToken;
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      if (_authService.selectedOrganizationId != null) request.headers['X-Organization-ID'] = _authService.selectedOrganizationId!;
      request.fields['entityType'] = entityType;
      request.fields['entityId'] = entityId;
      http.MultipartFile multipartFile;
      if (fileBytes != null) {
        final filename = fileName ?? 'file';
        multipartFile = http.MultipartFile.fromBytes('file', fileBytes, filename: filename, contentType: mimeType != null ? MediaType.parse(mimeType) : null);
      } else if (filePath != null) {
        final filename = p.basename(filePath);
        multipartFile = await http.MultipartFile.fromPath('file', filePath, contentType: mimeType != null ? MediaType.parse(mimeType) : null, filename: filename);
      } else {
        return Result.error(ApiError.http(400, 'No file provided'));
      }
      request.files.add(multipartFile);
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['url'] != null && (json['url'] as String).startsWith('/')) {
          json['url'] = ApiConfig.baseUrl + json['url'];
        }
        return Result.success(Attachment.fromJson(json));
      }
      return Result.error(ApiError.http(response.statusCode, 'Upload failed'));
    } catch (e) {
      return Result.error(ApiError.unknown('Upload error: $e'));
    }
  }

  /// List attachments for a given entity type/id
  Future<Result<List<Attachment>, ApiError>> listForEntity({
    required String entityType,
    required String entityId,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.attachments).replace(queryParameters: {
        'entityType': entityType,
        'entityId': entityId,
      });
      final token = _authService.jwtToken;
      final headers = <String, String>{};
      if (token != null) headers['Authorization'] = 'Bearer $token';
      if (_authService.selectedOrganizationId != null) headers['X-Organization-ID'] = _authService.selectedOrganizationId!;
      final response = await http.get(uri, headers: headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as List<dynamic>;
        final attachments = json.map((e) {
          final m = Map<String, dynamic>.from(e as Map<String, dynamic>);
          if (m['url'] != null && (m['url'] as String).startsWith('/')) m['url'] = ApiConfig.baseUrl + m['url'];
          return Attachment.fromJson(m);
        }).toList();
        return Result.success(attachments);
      }
      return Result.error(ApiError.http(response.statusCode, 'Failed to list attachments'));
    } catch (e) {
      return Result.error(ApiError.unknown('List attachments error: $e'));
    }
  }

  /// Download attachment content bytes for a given attachment id
  Future<Result<Uint8List, ApiError>> downloadAttachment(String attachmentId) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/attachments/$attachmentId/download');
      final token = _authService.jwtToken;
      final headers = <String, String>{};
      if (token != null) headers['Authorization'] = 'Bearer $token';
      if (_authService.selectedOrganizationId != null) headers['X-Organization-ID'] = _authService.selectedOrganizationId!;
      final response = await http.get(uri, headers: headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Result.success(response.bodyBytes);
      }
      return Result.error(ApiError.http(response.statusCode, 'Failed to download attachment'));
    } catch (e) {
      return Result.error(ApiError.unknown('Download attachments error: $e'));
    }
  }
}
