import 'package:flutter/material.dart';
import '../../models/account.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';
import '../../services/service_locator.dart';
import '../../services/accounts_service.dart';

class AccountDetailArgs {
  const AccountDetailArgs({required this.accountId});
  final String accountId;
}

class AccountDetailScreen extends StatefulWidget {
  final String accountId;
  const AccountDetailScreen({super.key, required this.accountId});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  late final AccountsService _accountsService;
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
    setState(() => _isLoading = true);
    try {
      final res = await _accountsService.getAccount(widget.accountId);
      if (res.isSuccess) {
        setState(() {
          _account = res.value;
          _isLoading = false;
        });
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingView(message: 'Loading account...'));
    if (_error != null) return Scaffold(body: ErrorView(message: _error!, onRetry: _load));
    if (_account == null) return const Scaffold(body: Center(child: Text('No account data')));
    return Scaffold(
      appBar: AppBar(title: Text(_account!.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${_account!.name}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('Type: ${_account!.type}')
          ],
        ),
      ),
    );
  }
}
