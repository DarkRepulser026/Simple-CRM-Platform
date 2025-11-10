import 'package:flutter_test/flutter_test.dart';
import 'package:main_project/models/account.dart';

void main() {
  group('Account Model', () {
    test('should create Account from JSON', () {
      final json = {
        'id': '123',
        'name': 'ABC Corporation',
        'type': 'Customer',
        'website': 'https://abc.com',
        'phone': '+1234567890',
      };

      final account = Account.fromJson(json);

      expect(account.id, '123');
      expect(account.name, 'ABC Corporation');
      expect(account.type, 'Customer');
      expect(account.website, 'https://abc.com');
      expect(account.phone, '+1234567890');
    });

    test('should handle null values in JSON', () {
      final json = {
        'id': '123',
        'name': 'ABC Corporation',
        'type': 'Customer',
      };

      final account = Account.fromJson(json);

      expect(account.website, isNull);
      expect(account.phone, isNull);
    });

    test('should convert Account to JSON', () {
      const account = Account(
        id: '123',
        name: 'ABC Corporation',
        type: 'Customer',
        website: 'https://abc.com',
        phone: '+1234567890',
      );

      final json = account.toJson();

      expect(json['id'], '123');
      expect(json['name'], 'ABC Corporation');
      expect(json['type'], 'Customer');
      expect(json['website'], 'https://abc.com');
      expect(json['phone'], '+1234567890');
    });

    test('should create copy with modified fields', () {
      const account = Account(
        id: '123',
        name: 'ABC Corporation',
        type: 'Customer',
        website: 'https://abc.com',
        phone: '+1234567890',
      );

      final updatedAccount = account.copyWith(
        name: 'XYZ Corporation',
        type: 'Partner',
        website: 'https://xyz.com',
      );

      expect(updatedAccount.name, 'XYZ Corporation');
      expect(updatedAccount.type, 'Partner');
      expect(updatedAccount.website, 'https://xyz.com');
      expect(updatedAccount.phone, '+1234567890'); // unchanged
      expect(updatedAccount.id, '123'); // unchanged
    });

    test('should implement equality correctly', () {
      const account1 = Account(
        id: '123',
        name: 'ABC Corporation',
        type: 'Customer',
        website: 'https://abc.com',
        phone: '+1234567890',
      );

      const account2 = Account(
        id: '123',
        name: 'ABC Corporation',
        type: 'Customer',
        website: 'https://abc.com',
        phone: '+1234567890',
      );

      const account3 = Account(
        id: '456',
        name: 'ABC Corporation',
        type: 'Customer',
        website: 'https://abc.com',
        phone: '+1234567890',
      );

      expect(account1 == account2, true);
      expect(account1 == account3, false);
      expect(account1.hashCode == account2.hashCode, true);
      expect(account1.hashCode == account3.hashCode, false);
    });

    test('should handle partial copyWith correctly', () {
      const account = Account(
        id: '123',
        name: 'ABC Corporation',
        type: 'Customer',
        website: 'https://abc.com',
        phone: '+1234567890',
      );

      final updatedAccount = account.copyWith(
        website: null, // Set to null
      );

      expect(updatedAccount.website, isNull);
      expect(updatedAccount.name, 'ABC Corporation'); // unchanged
    });
  });
}