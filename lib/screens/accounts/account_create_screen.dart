import 'package:flutter/material.dart';
import '../../models/account.dart';
import '../../services/service_locator.dart';
import '../../services/auth/auth_service.dart';
import '../../services/accounts_service.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _accountsService = locator<AccountsService>();
    _authService = locator<AuthService>();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
      try {
      final account = Account(
        id: '',
        name: _nameCtrl.text.trim(),
        type: _typeCtrl.text.trim(),
        organizationId: _authService.selectedOrganizationId ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final res = await _accountsService.createAccount(account);
      if (res.isSuccess) {
        Navigator.of(context).pop(true);
        return;
      }
      throw Exception(res.error.message);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null) ErrorView(message: _error!, onRetry: null),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Account Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _typeCtrl,
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 20),
              if (_isLoading) const LoadingView(message: 'Creating account...')
              else ElevatedButton(onPressed: _createAccount, child: const Text('Create'))
            ],
          ),
        ),
      ),
    );
  }
}
