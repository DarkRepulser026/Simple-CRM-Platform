import 'package:flutter/material.dart';
import '../../models/account.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';
import '../../services/service_locator.dart';
import '../../services/accounts_service.dart';
// auth service import no longer used directly in this file
import '../../widgets/role_visibility.dart';
import '../../navigation/app_router.dart';

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
      appBar: AppBar(
        title: Text(_account!.name),
        actions: [
          ManagerOrAdminOnly(child: IconButton(
            onPressed: () => AppRouter.navigateTo(context, AppRouter.accountEdit, arguments: AccountDetailArgs(accountId: _account!.id)),
            icon: const Icon(Icons.edit),
          )),
          IconButton(
            onPressed: () => AppRouter.navigateTo(context, AppRouter.activityLogs, arguments: ActivityLogsArgs(entityType: 'Account', entityId: _account!.id)),
            icon: const Icon(Icons.history),
            tooltip: 'View Activity',
          ),
          AdminOnly(child: IconButton(
              onPressed: () async {
                // confirm
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Account'),
                    content: const Text('Are you sure you want to delete this account? This action cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete'), style: TextButton.styleFrom(foregroundColor: Colors.red)),
                    ],
                  ),
                );
                if (confirm == true) {
                  try {
                    final res = await _accountsService.deleteAccount(_account!.id);
                    if (res.isSuccess) {
                      Navigator.of(context).pop(true);
                      return;
                    }
                    throw Exception(res.error.message);
                  } catch (e) {
                    setState(() => _error = 'Failed to delete account: $e');
                  }
                }
              },
              icon: const Icon(Icons.delete),
            ),
          ),
        ],
      ),
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
