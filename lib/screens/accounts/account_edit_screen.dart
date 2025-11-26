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
  bool _isLoading = true;
  String? _error;
  Account? _account;

  @override
  void initState() {
    super.initState();
    _accountsService = locator<AccountsService>();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _accountsService.getAccount(widget.accountId);
      if (res.isSuccess) {
        _account = res.value;
        _nameCtrl.text = _account?.name ?? '';
        _typeCtrl.text = _account?.type ?? '';
        setState(() => _isLoading = false);
        return;
      }
      throw Exception(res.error.message);
    } catch (e) {
      setState(() {
        _error = 'Failed to load account: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _update() async {
    if (!_formKey.currentState!.validate() || _account == null) return;
    setState(() => _isLoading = true);
    try {
      final updated = _account!.copyWith(
        name: _nameCtrl.text.trim(),
        type: _typeCtrl.text.trim(),
        updatedAt: DateTime.now(),
      );
      final res = await _accountsService.updateAccount(updated);
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
    if (_isLoading) return const Scaffold(body: LoadingView(message: 'Loading...'));
    if (_error != null) return Scaffold(body: ErrorView(message: _error!, onRetry: _load));
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Account Name'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,),
              const SizedBox(height: 12),
              TextFormField(controller: _typeCtrl, decoration: const InputDecoration(labelText: 'Type')),
              const SizedBox(height: 20),
              if (_isLoading) const LoadingView(message: 'Updating account...')
              else ElevatedButton(onPressed: _update, child: const Text('Save'))
            ],
          ),
        ),
      ),
    );
  }
}
