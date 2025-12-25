// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:main_project/widgets/auth_wrapper.dart';
import 'package:main_project/services/auth/auth_service.dart';

// Mock AuthService
class MockAuthService extends Mock implements AuthService {
  @override
  Future<void> initialize() async {
    // Mock initialization - do nothing
  }

  @override
  bool get isLoggedIn => false;

  @override
  bool get hasSelectedOrganization => false;
}

void main() {
  testWidgets('AuthWrapper shows loading then completes initialization', (
    final WidgetTester tester,
  ) async {
    // Build AuthWrapper with mocked service
    await tester.pumpWidget(
      MaterialApp(
        home: AuthWrapper(),
      ),
    );

    // Verify that loading indicator is shown initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading Main Project...'), findsOneWidget);

    // Wait for initialization to complete
    await tester.pumpAndSettle();

    // After initialization, loading should be gone
    expect(find.text('Loading Main Project...'), findsNothing);
  });
}
