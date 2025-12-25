import 'package:flutter/material.dart';
import '../../models/account.dart';
import '../../services/service_locator.dart';
import '../../services/accounts_service.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';

class AccountEditArgs {
  const AccountEditArgs({required this.accountId});
  final String accountId;
}

class AccountEditScreen extends StatefulWidget {
  final String accountId;
  const AccountEditScreen({super.key, required this.accountId});

  @override
  State<AccountEditScreen> createState() => _AccountEditScreenState();
}

class _AccountEditScreenState extends State<AccountEditScreen> {
  late final AccountsService _accountsService;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  Account? _account;

  @override
  void initState() {
    super.initState();
    _accountsService = locator<AccountsService>();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _typeCtrl.dispose();
    _websiteCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _accountsService.getAccount(widget.accountId);
      if (res.isSuccess) {
        _account = res.value;
        _nameCtrl.text = _account?.name ?? '';
        _typeCtrl.text = _account?.type ?? '';
        _websiteCtrl.text = _account?.website ?? '';
        _phoneCtrl.text = _account?.phone ?? '';
        setState(() => _isLoading = false);
      } else {
        throw Exception(res.error.message);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load account: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _update() async {
    if (!_formKey.currentState!.validate() || _account == null) return;
    setState(() => _isSaving = true);
    
    try {
      final updated = _account!.copyWith(
        name: _nameCtrl.text.trim(),
        type: _typeCtrl.text.trim(),
        website: _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        updatedAt: DateTime.now(),
      );
      final res = await _accountsService.updateAccount(updated);
      
      if (res.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account updated successfully')));
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception(res.error.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingView(message: 'Loading account details...'));
    if (_error != null) return Scaffold(body: ErrorView(message: _error!, onRetry: _load));

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    final inputDecor = InputDecoration(
      filled: true,
      fillColor: cs.surfaceVariant.withOpacity(0.3),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outline.withOpacity(0.1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.primary, width: 1.5)),
      contentPadding: const EdgeInsets.all(16),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Edit Account'),
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
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: cs.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.business_outlined, size: 28, color: cs.primary),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Account Details', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                              Text('Update company information', style: TextStyle(color: cs.onSurfaceVariant)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Fields
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: inputDecor.copyWith(
                          labelText: 'Account Name',
                          prefixIcon: Icon(Icons.domain, color: cs.primary),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _typeCtrl,
                        decoration: inputDecor.copyWith(
                          labelText: 'Account Type',
                          prefixIcon: Icon(Icons.category_outlined, color: cs.onSurfaceVariant),
                          hintText: 'e.g. Customer, Partner, Reseller',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _websiteCtrl,
                        decoration: inputDecor.copyWith(
                          labelText: 'Website',
                          prefixIcon: Icon(Icons.language, color: cs.onSurfaceVariant),
                          hintText: 'e.g. https://example.com',
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneCtrl,
                        decoration: inputDecor.copyWith(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone, color: cs.onSurfaceVariant),
                          hintText: 'e.g. +1-234-567-8900',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      
                      const SizedBox(height: 40),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 16),
                          FilledButton.icon(
                            onPressed: _isSaving ? null : _update,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: _isSaving 
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.save_outlined),
                            label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
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