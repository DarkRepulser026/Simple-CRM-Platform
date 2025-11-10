import 'package:flutter/material.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';
import '../../services/auth/auth_service.dart';
import '../../services/auth/auth_service_mock.dart';
import '../../services/storage/secure_storage.dart';
import '../../navigation/app_router.dart';

/// Company/Organization selection screen
/// Allows users to select or create an organization after authentication
class CompanySelectionScreen extends StatefulWidget {
  const CompanySelectionScreen({super.key});

  @override
  State<CompanySelectionScreen> createState() => _CompanySelectionScreenState();
}

class _CompanySelectionScreenState extends State<CompanySelectionScreen> {
  late final AuthService _authService;
  bool _isLoading = false;
  String? _errorMessage;
  final TextEditingController _companyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final storage = await SecureStorage.create();
    _authService = AuthServiceMock(storage);
  }

  Future<void> _selectCompany(String companyId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.selectOrganization(companyId);
      if (mounted) {
        _navigateToDashboard();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to select company: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createCompany() async {
    final companyName = _companyController.text.trim();
    if (companyName.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a company name';
      });
      return;
    }

    await _selectCompany(companyName);
  }

  void _navigateToDashboard() {
    AppRouter.replaceWith(context, AppRouter.dashboard);
  }

  @override
  void dispose() {
    _companyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Company'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Welcome!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please select or create your company to continue',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Error message
              if (_errorMessage != null) ...[
                ErrorView(
                  message: _errorMessage!,
                  onRetry: null,
                ),
                const SizedBox(height: 24),
              ],

              // Quick company selection buttons
              Text(
                'Quick Select:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Demo companies
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _CompanyChip(
                    name: 'Ep Pe Te',
                    onTap: () => _selectCompany('acme-corp'),
                  ),
                  _CompanyChip(
                    name: '7 chars',
                    onTap: () => _selectCompany('techstart-inc'),
                  ),
                  _CompanyChip(
                    name: 'temp',
                    onTap: () => _selectCompany('global-solutions'),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Create new company section
              Text(
                'Or create a new company:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  hintText: 'Enter your company name',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _createCompany(),
              ),

              const SizedBox(height: 24),

              if (_isLoading) ...[
                const LoadingView(
                  message: 'Setting up your company...',
                  size: 32,
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: _createCompany,
                  child: const Text('Create Company'),
                ),
              ],

              const Spacer(),

              // Logout option
              TextButton.icon(
                onPressed: () async {
                  await _authService.logout();
                  if (mounted) {
                    AppRouter.replaceWith(context, AppRouter.login);
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick selection chip for companies
class _CompanyChip extends StatelessWidget {
  const _CompanyChip({
    required this.name,
    required this.onTap,
  });

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(name),
      onPressed: onTap,
      avatar: const Icon(Icons.business),
    );
  }
}