import 'package:flutter/material.dart';
import '../../models/account.dart';
import '../../widgets/paginated_list_view.dart';
import '../../services/service_locator.dart';
import '../../services/accounts_service.dart';
import '../../navigation/app_router.dart';
import '../../services/auth/auth_service.dart';
// Error and loading widgets not used directly here

class AccountsListScreen extends StatefulWidget {
  const AccountsListScreen({super.key});

  @override
  State<AccountsListScreen> createState() => _AccountsListScreenState();
}

class _AccountsListScreenState extends State<AccountsListScreen> {
  late final AccountsService _accountsService;

  Future<List<Account>> _fetchAccountsPage(int page, int limit) async {
    try {
      final res = await _accountsService.getAccounts(page: page, limit: limit);
      if (res.isSuccess) return res.value.accounts;
      throw Exception(res.error.message);
    } catch (e) {
      throw Exception('Failed to load accounts: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _accountsService = locator<AccountsService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          if (locator<AuthService>().selectedOrganization?.role == 'Admin' || locator<AuthService>().selectedOrganization?.role == 'Manager')
            IconButton(
              onPressed: () => AppRouter.navigateTo(context, AppRouter.accountCreate),
              icon: const Icon(Icons.add),
              tooltip: 'Create Account',
            ),
        ],
      ),
      body: PaginatedListView<Account>(
        itemBuilder: (context, acc, index) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(acc.name),
            subtitle: Text(acc.type),
            leading: const Icon(Icons.account_balance),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => AppRouter.navigateTo(context, AppRouter.accounts),
          ),
        ),
        fetchPage: _fetchAccountsPage,
        pageSize: 20,
        emptyMessage: 'No accounts found',
        errorMessage: 'Failed to load accounts',
        loadingMessage: 'Loading accounts...',
      ),
    );
  }
}
