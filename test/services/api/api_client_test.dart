import 'package:flutter_test/flutter_test.dart';
import 'package:main_project/services/api/api_config.dart';
import 'package:main_project/services/api/api_exceptions.dart';
import 'package:main_project/utils/result.dart';

void main() {
  group('ApiError', () {
    test('NetworkError should have correct message', () {
      const error = NetworkError('Connection failed');
      expect(error.message, 'Connection failed');
      expect(error.toString(), 'NetworkError: Connection failed');
    });

    test('HttpError should have correct status code and message', () {
      const error = HttpError(404, 'Not found');
      expect(error.statusCode, 404);
      expect(error.message, 'Not found');
      expect(error.toString(), 'HttpError(404): Not found');
    });

    test('TimeoutError should have correct message', () {
      const error = TimeoutError('Request timed out');
      expect(error.message, 'Request timed out');
      expect(error.toString(), 'TimeoutError: Request timed out');
    });

    test('ParsingError should have correct message', () {
      const error = ParsingError('Invalid JSON');
      expect(error.message, 'Invalid JSON');
      expect(error.toString(), 'ParsingError: Invalid JSON');
    });

    test('UnknownError should have correct message', () {
      const error = UnknownError('Something went wrong');
      expect(error.message, 'Something went wrong');
      expect(error.toString(), 'UnknownError: Something went wrong');
    });
  });

  group('Result', () {
    test('Success should contain value', () {
      final result = Result<int, String>.success(42);
      expect(result.isSuccess, true);
      expect(result.isError, false);
      expect(result.value, 42);
      expect(() => result.error, throwsStateError);
    });

    test('Error should contain error', () {
      final result = Result<int, String>.error('Failed');
      expect(result.isSuccess, false);
      expect(result.isError, true);
      expect(result.error, 'Failed');
      expect(() => result.value, throwsStateError);
    });

    test('Success toString should be readable', () {
      final result = Result.success('test');
      expect(result.toString(), 'Success(test)');
    });

    test('Error toString should be readable', () {
      final result = Result.error('error');
      expect(result.toString(), 'Error(error)');
    });
  });

  group('ApiConfig', () {
    test('should have correct base URL', () {
      // In test environment, the base URL should be set or default to local dev URL; accept http or https
      expect(ApiConfig.baseUrl, isNotEmpty);
      expect(ApiConfig.baseUrl, matches(RegExp(r'^https?://')));
    });

    test('should have correct timeouts', () {
      expect(ApiConfig.connectTimeout, const Duration(seconds: 10));
      expect(ApiConfig.receiveTimeout, const Duration(seconds: 15));
      expect(ApiConfig.sendTimeout, const Duration(seconds: 10));
    });

    test('should have correct retry config', () {
      expect(ApiConfig.maxRetries, 2);
      expect(ApiConfig.retryDelay, const Duration(milliseconds: 500));
    });

    test('should have correct default headers', () {
      expect(ApiConfig.defaultHeaders['content-type'], 'application/json');
      expect(ApiConfig.defaultHeaders['accept'], 'application/json');
    });

    test('should build correct endpoint URLs', () {
      final base = ApiConfig.baseUrl;
      expect(ApiConfig.authGoogle, '$base/auth/google');
      expect(ApiConfig.contacts, '$base/contacts');
      expect(ApiConfig.contactById('123'), '$base/contacts/123');
      expect(ApiConfig.leads, '$base/leads');
      expect(ApiConfig.leadById('456'), '$base/leads/456');
      expect(ApiConfig.tasks, '$base/tasks');
      expect(ApiConfig.taskById('789'), '$base/tasks/789');
    });
  });
}