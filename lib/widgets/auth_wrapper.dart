import 'package:flutter/material.dart';
import '../navigation/app_router.dart';

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
    // TODO: Initialize auth service and check authentication state
    await Future.delayed(const Duration(seconds: 2)); // Simulate initialization
    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
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

    // TODO: Check authentication status and organization selection
    // For now, navigate to login screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppRouter.replaceWith(context, AppRouter.login);
    });

    return const SizedBox.shrink(); // Placeholder while navigating
  }
}