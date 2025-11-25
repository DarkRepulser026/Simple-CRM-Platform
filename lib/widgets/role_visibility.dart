import 'package:flutter/material.dart';
import '../services/service_locator.dart';
import '../services/auth/auth_service.dart';
// fallback screen import intentionally unused by default; fallback can provide it.

/// Widget wrapper that shows [child] only when the current user is an Admin.
class AdminOnly extends StatelessWidget {
  const AdminOnly({super.key, required this.child, this.fallback});

  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final auth = locator<AuthService>();
    if (auth.isAdmin) return child;
    return fallback ?? const SizedBox.shrink();
  }
}

/// Widget wrapper that shows [child] only when the current user is a Manager or Admin.
class ManagerOrAdminOnly extends StatelessWidget {
  const ManagerOrAdminOnly({super.key, required this.child, this.fallback});

  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final auth = locator<AuthService>();
    if (auth.isManagerOrAdmin) return child;
    return fallback ?? const SizedBox.shrink();
  }
}
