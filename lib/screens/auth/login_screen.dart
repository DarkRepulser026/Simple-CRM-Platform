import 'package:flutter/material.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';
import '../../services/auth/auth_service.dart';
import '../../services/auth/auth_service_mock.dart';
import '../../services/storage/secure_storage.dart';
import '../../navigation/app_router.dart';

/// Login screen that handles Google Sign-In authentication
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthService _authService; // TODO: provider when :( 
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Initialize storage and auth service
    final storage = await SecureStorage.create();
    _authService = AuthServiceMock(storage);
    await _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      await _authService.initialize();
      if (mounted && _authService.isLoggedIn) {
        // User is already logged in, navigate to company selection
        _navigateToCompanySelection();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize authentication: $e';
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _authService.signInWithGoogle();
      if (mounted) {
        if (success) {
          _navigateToCompanySelection();
        } else {
          setState(() {
            _errorMessage = 'Sign-in failed. Please try again.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Sign-in error: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToCompanySelection() {
    AppRouter.replaceWith(context, AppRouter.companySelection);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Logo/Title
              Column(
                children: [
                  Icon(
                    Icons.business_center,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'CRM Project',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Customer Services & Business Management',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              const SizedBox(height: 64),

              // Error message
              if (_errorMessage != null) ...[
                ErrorView(
                  message: _errorMessage!,
                  onRetry: _handleGoogleSignIn,
                  retryText: 'Try Sign In Again',
                ),
                const SizedBox(height: 24),
              ],

              // Sign In Button
              if (!_isLoading) ...[
                ElevatedButton.icon(
                  onPressed: _handleGoogleSignIn,
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in with Google'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ] else ...[
                const LoadingView(
                  message: 'Signing you in...',
                  size: 32,
                ),
              ],

              const SizedBox(height: 32),

              // Footer text
              Text(
                'Secure authentication powered by Google',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}