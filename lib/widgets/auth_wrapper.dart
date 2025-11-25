import 'package:flutter/material.dart';
import '../navigation/app_router.dart';
import '../services/service_locator.dart';
import '../services/auth/auth_service.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Service locator has been initialized in `main.dart`.
      // Initialize auth service
      final authService = locator<AuthService>();
      await authService.initialize();

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing app: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading Main Project...',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
      );
    }

    // Check authentication status and organization selection
    final authService = locator<AuthService>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Allow direct deep links (e.g., /invite/accept) or hash route fragments to render.
      var currentPath = Uri.base.path;
      if (Uri.base.fragment.isNotEmpty) {
        final frag = Uri.base.fragment.split('?').first;
        if (frag.isNotEmpty) currentPath = frag;
      }

      try {
        if (currentPath != '/' && currentPath.isNotEmpty) {
          // Navigate to the requested route from the URL (deep link)
          AppRouter.replaceWith(context, currentPath);
          return;
        }
      } catch (e) {
        debugPrint('Deep link navigation error: $e');
        // Continue to default redirect behaviour below
      }

      if (authService.isLoggedIn) {
        if (authService.hasSelectedOrganization) {
          AppRouter.replaceWith(context, AppRouter.dashboard);
        } else {
          AppRouter.replaceWith(context, AppRouter.companySelection);
        }
      } else {
        AppRouter.replaceWith(context, AppRouter.login);
      }
    });

    return const SizedBox.shrink(); // Placeholder while navigating
  }
}