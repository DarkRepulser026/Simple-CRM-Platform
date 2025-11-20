import 'package:flutter_test/flutter_test.dart';
import 'package:main_project/models/organization.dart';
import 'package:main_project/models/user.dart';

void main() {
  group('User Model', () {
    test('should create User from JSON', () {
      final json = {
        'id': 'user-123',
        'email': 'test@example.com',
        'name': 'Test User',
        'profileImage': 'http://example.com/img.jpg',
      };

      final user = User.fromJson(json);

      expect(user.id, 'user-123');
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
      expect(user.profileImage, 'http://example.com/img.jpg');
    });

    test('should convert User to JSON', () {
      final user = User(
        id: 'user-123',
        email: 'test@example.com',
        name: 'Test User',
        profileImage: 'http://example.com/img.jpg',
      );

      final json = user.toJson();

      expect(json['id'], 'user-123');
      expect(json['email'], 'test@example.com');
      expect(json['name'], 'Test User');
      expect(json['profileImage'], 'http://example.com/img.jpg');
    });

    test('should handle null profileImage', () {
      final user = User(
        id: 'user-123',
        email: 'test@example.com',
        name: 'Test User',
      );

      final json = user.toJson();

      expect(json.containsKey('profileImage'), false);
    });
  });

  group('Organization Model', () {
    test('should create Organization from JSON', () {
      final json = {
        'id': 'org-123',
        'name': 'Test Organization',
        'role': 'Admin',
      };

      final org = Organization.fromJson(json);

      expect(org.id, 'org-123');
      expect(org.name, 'Test Organization');
      expect(org.role, 'Admin');
    });

    test('should convert Organization to JSON', () {
      final org = Organization(
        id: 'org-123',
        name: 'Test Organization',
        role: 'Admin',
      );

      final json = org.toJson();

      expect(json['id'], 'org-123');
      expect(json['name'], 'Test Organization');
      expect(json['role'], 'Admin');
    });

    test('should handle null role', () {
      final org = Organization(
        id: 'org-123',
        name: 'Test Organization',
      );

      final json = org.toJson();

      expect(json.containsKey('role'), false);
    });
  });
}