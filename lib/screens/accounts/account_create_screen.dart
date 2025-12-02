import 'package:flutter/material.dart';
import '../../models/account.dart';
import '../../services/service_locator.dart';
import '../../services/auth/auth_service.dart';
import '../../services/accounts_service.dart';
import '../../services/api/api_exceptions.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';

class AccountCreateScreen extends StatefulWidget {
  const AccountCreateScreen({super.key});

  @override
  State<AccountCreateScreen> createState() => _AccountCreateScreenState();
}

class _AccountCreateScreenState extends State<AccountCreateScreen> {
  late final AccountsService _accountsService;
  late final AuthService _authService;
  bool _apiAvailable = true;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _accountsService = locator<AccountsService>();
    _authService = locator<AuthService>();
    _checkApiAvailability();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _typeCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkApiAvailability() async {
    if (!_authService.isLoggedIn || !_authService.hasSelectedOrganization) return;
    // Check if API endpoint exists by fetching 1 item
    final res = await _accountsService.getAccounts(page: 1, limit: 1);
    if (res.isError && res.error is HttpError && (res.error as HttpError).statusCode == 404) {
      if (mounted) setState(() => _apiAvailable = false);
    }
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    try {
      final account = Account(
        id: '', // Server generated
        name: _nameCtrl.text.trim(),
        type: _typeCtrl.text.trim(),
        organizationId: _authService.selectedOrganizationId ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final res = await _accountsService.createAccount(account);
      
      if (res.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created successfully')),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception(res.error.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    // Style input chung
    final inputDecor = InputDecoration(
      filled: true,
      fillColor: cs.surfaceVariant.withOpacity(0.3),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outline.withOpacity(0.1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: const Color(0xFFF3F4F6),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              color: cs.surface,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section inside Card
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cs.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.domain_add, size: 28, color: cs.primary),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'New Organization', 
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Add a new business entity to CRM',
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // API Error Banner
                      if (!_apiAvailable)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: cs.errorContainer.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: cs.error.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: cs.error),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Accounts API is not available on the server. Creation is disabled.',
                                  style: TextStyle(color: cs.onSurface),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (_error != null) ...[
                        ErrorView(message: _error!, onRetry: null),
                        const SizedBox(height: 16),
                      ],

                      // Form Fields
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: inputDecor.copyWith(
                          labelText: 'Account Name',
                          hintText: 'e.g. Acme Corp',
                          prefixIcon: Icon(Icons.business, color: cs.primary),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
                        enabled: _apiAvailable,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _typeCtrl,
                        decoration: inputDecor.copyWith(
                          labelText: 'Account Type',
                          hintText: 'e.g. Vendor, Partner, Client',
                          prefixIcon: Icon(Icons.category_outlined, color: cs.onSurfaceVariant),
                        ),
                        enabled: _apiAvailable,
                      ),
                      
                      const SizedBox(height: 40),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 16),
                          FilledButton.icon(
                            onPressed: (_apiAvailable && !_isLoading) ? _createAccount : null,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: _isLoading 
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check),
                            label: Text(_isLoading ? 'Creating...' : 'Create Account'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}