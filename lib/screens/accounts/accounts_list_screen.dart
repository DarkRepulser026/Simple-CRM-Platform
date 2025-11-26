import 'package:flutter/material.dart';
import '../../models/account.dart';
import '../../widgets/paginated_list_view.dart';
import '../../services/service_locator.dart';
import '../../services/api/api_exceptions.dart';
import '../../services/accounts_service.dart';
import '../../navigation/app_router.dart';
import 'account_detail_screen.dart';
import '../../services/auth/auth_service.dart';
import '../../widgets/role_visibility.dart';
import '../../widgets/error_view.dart';
// Error and loading widgets not used directly here

class AccountsListScreen extends StatefulWidget {
  const AccountsListScreen({super.key});

  @override
  State<AccountsListScreen> createState() => _AccountsListScreenState();
}

class _AccountsListScreenState extends State<AccountsListScreen> {
  late final AccountsService _accountsService;
  bool _apiAvailable = true;

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
    _checkApiAvailability();
  }

  Future<void> _checkApiAvailability() async {
    // Only check availability when user is authenticated and organization selected
    if (!locator<AuthService>().isLoggedIn || !locator<AuthService>().hasSelectedOrganization) return;
    final res = await _accountsService.getAccounts(page: 1, limit: 1);
    if (res.isError) {
      // If backend responds 404, likely API not implemented
      if (res.error is HttpError && (res.error as HttpError).statusCode == 404) {
        _apiAvailable = false;
      }
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (locator<AuthService>().isLoggedIn && !locator<AuthService>().hasSelectedOrganization) {
      return Scaffold(body: ErrorView(message: 'No organization selected. Please select a company to continue.', onRetry: () => AppRouter.navigateTo(context, AppRouter.companySelection)));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          if (_apiAvailable)
            ManagerOrAdminOnly(child: IconButton(
              onPressed: () => AppRouter.navigateTo(context, AppRouter.accountCreate),
              icon: const Icon(Icons.add),
              tooltip: 'Create Account',
            )),
        ],
      ),
        body: _apiAvailable
          ? PaginatedListView<Account>(
        itemBuilder: (context, acc, index) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(acc.name),
            subtitle: Text(acc.type),
            leading: const Icon(Icons.account_balance),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => AppRouter.navigateTo(
              context,
              AppRouter.accountDetail,
              arguments: AccountDetailArgs(accountId: acc.id),
            ),
          ),
        ),
        fetchPage: _apiAvailable ? _fetchAccountsPage : ((int page, int limit) async => throw Exception('Accounts API not available')),
        pageSize: 20,
        emptyMessage: 'No accounts found',
        errorMessage: 'Failed to load accounts',
        loadingMessage: 'Loading accounts...',
          )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Accounts feature is not available on the server'),
              ),
            ),
    );
  }
}
