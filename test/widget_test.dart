// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:main_project/main.dart';
import 'package:main_project/services/service_locator.dart';

void main() {
  testWidgets('App builds and shows loading then navigates to login', (
    final WidgetTester tester,
  ) async {
    // Ensure services are registered for the app
    await setupLocator();
    // Build our app and trigger a frame.
    await tester.pumpWidget(const App());

    // Verify that loading indicator is shown initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading Main Project...'), findsOneWidget);

    // Wait for initialization
    await tester.pump(const Duration(seconds: 3));

    // Wait for navigation to complete
    await tester.pumpAndSettle();

    // Verify that we navigate to login screen after loading
    expect(find.text('Main Project'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text('CRM & Business Management'), findsOneWidget);
  });
}
