import 'package:flutter/material.dart';
import '../services/service_locator.dart';
import '../services/auth/auth_service.dart';
// unused: import '../screens/access_denied_screen.dart';
import '../screens/access_denied_redirect_screen.dart';

/// Utility functions to wrap route builders with authorization checks.
WidgetBuilder adminGuarded(WidgetBuilder builder) {
  return (context) {
    final auth = locator<AuthService>();
    if (auth.isAdmin) return builder(context);
    // If not admin, redirect to dashboard with toast
    return const AccessDeniedRedirectScreen();
  };
}

WidgetBuilder managerOrAdminGuarded(WidgetBuilder builder) {
  return (context) {
    final auth = locator<AuthService>();
    if (auth.isManagerOrAdmin) return builder(context);
    return const AccessDeniedRedirectScreen();
  };
}
