import 'package:flutter/material.dart';
import 'package:main_project/screens/accounts/account_detail_screen.dart';
import 'package:main_project/screens/accounts/account_edit_screen.dart';
import '../../models/account.dart';
import '../../widgets/paginated_list_view.dart';
import '../../services/service_locator.dart';
import '../../services/api/api_exceptions.dart';
import '../../services/accounts_service.dart';
import '../../navigation/app_router.dart';
import '../../services/auth/auth_service.dart';
import '../../widgets/role_visibility.dart';
import '../../widgets/error_view.dart';

class AccountsListScreen extends StatefulWidget {
  const AccountsListScreen({super.key});

  @override
  State<AccountsListScreen> createState() => _AccountsListScreenState();
}

class _AccountsListScreenState extends State<AccountsListScreen> {
  late final AccountsService _accountsService;
  bool _apiAvailable = true;
  final TextEditingController _searchCtrl = TextEditingController();
  int _reloadVersion = 0;

  @override
  void initState() {
    super.initState();
    _accountsService = locator<AccountsService>();
    _checkApiAvailability();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkApiAvailability() async {
    if (!locator<AuthService>().isLoggedIn || !locator<AuthService>().hasSelectedOrganization) return;
    final res = await _accountsService.getAccounts(page: 1, limit: 1);
    if (res.isError) {
      if (res.error is HttpError && (res.error as HttpError).statusCode == 404) {
        if (mounted) setState(() => _apiAvailable = false);
      }
    }
  }

  Future<List<Account>> _fetchAccountsPage(int page, int limit) async {
    try {
      final res = await _accountsService.getAccounts(page: page, limit: limit);
      if (res.isSuccess) {
        var accounts = res.value.accounts;
        // Client-side search demo
        if (_searchCtrl.text.isNotEmpty) {
          final q = _searchCtrl.text.toLowerCase();
          accounts = accounts.where((a) => a.name.toLowerCase().contains(q) || a.type.toLowerCase().contains(q)).toList();
        }
        return accounts;
      }
      throw Exception(res.error.message);
    } catch (e) {
      throw Exception('Failed to load accounts: $e');
    }
  }

  void _refreshList() => setState(() => _reloadVersion++);

  Future<void> _navigateToAccountDetail(String accountId) async {
    debugPrint('AccountsListScreen: open account dialog $accountId');
    final changed = await showAccountDetailDialog(context, accountId: accountId);
    if (changed == true) _refreshList();
  }

  @override
  Widget build(BuildContext context) {
    if (locator<AuthService>().isLoggedIn && !locator<AuthService>().hasSelectedOrganization) {
      return Scaffold(body: ErrorView(message: 'No organization selected.', onRetry: () => AppRouter.navigateTo(context, AppRouter.companySelection)));
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    const bgColor = Color(0xFFE9EDF5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bgColor,
        title: const Text(''),
        iconTheme: IconThemeData(color: cs.onSurface),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshList,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== HEADER =====
                Row(
                  children: [
                    Text(
                      'Accounts',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'CRM',
                        style: theme.textTheme.bodySmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 16),

                // ===== ACTIONS =====
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search by account name or type',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: cs.surface.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: BorderSide(color: cs.outline.withOpacity(0.2)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        ),
                        onSubmitted: (_) => _refreshList(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_apiAvailable)
                      ManagerOrAdminOnly(
                        child: FilledButton.icon(
                          onPressed: () async {
                            final res = await AppRouter.navigateTo(context, AppRouter.accountCreate);
                            if (res == true) _refreshList();
                          },
                          icon: const Icon(Icons.domain_add, size: 18),
                          label: const Text('New Account'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // ===== TABLE CARD =====
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.outline.withOpacity(0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _apiAvailable 
                      ? Column(
                          children: [
                            // Header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                color: cs.surfaceVariant.withOpacity(0.2),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 48), // Avatar space
                                  _HeaderCell('Account Name', flex: 4),
                                  _HeaderCell('Type', flex: 3),
                                  _HeaderCell('Status', flex: 2),
                                  _HeaderCell('Created', flex: 2, align: TextAlign.right),
                                  const SizedBox(width: 48), // Actions space
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            // Body
                            Expanded(
                              child: PaginatedListView<Account>(
                                key: ValueKey(_reloadVersion),
                                fetchPage: _fetchAccountsPage,
                                pageSize: 20,
                                emptyMessage: 'No accounts found',
                                errorMessage: 'Failed to load accounts',
                                loadingMessage: 'Loading accounts...',
                                itemBuilder: (context, acc, index) => _AccountRow(
                                  account: acc,
                                  onTap: () => _navigateToAccountDetail(acc.id),
                                  onRefresh: _refreshList,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cloud_off, size: 48, color: cs.outline),
                              const SizedBox(height: 16),
                              Text('Accounts API is not available on this server', style: TextStyle(color: cs.onSurfaceVariant)),
                            ],
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final int flex;
  final TextAlign align;
  const _HeaderCell(this.label, {this.flex = 1, this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: align,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final Account account;
  final VoidCallback onTap;
  final VoidCallback onRefresh;
  const _AccountRow({required this.account, required this.onTap, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial = account.name.isNotEmpty ? account.name[0].toUpperCase() : '?';

    return InkWell(
      onTap: onTap,
      hoverColor: cs.surfaceVariant.withOpacity(0.1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: cs.outline.withOpacity(0.06))),
        ),
        child: Row(
          children: [
            const SizedBox(width: 48), // Avatar space to align with header
            // Name + Avatar
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(8), // Square avatar for businesses
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSecondaryContainer),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        // ID nhỏ bên dưới
                        Text(
                          '#${account.id.substring(0, 4)}...',
                          style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Type
            Expanded(
              flex: 3,
              child: Text(account.type, style: TextStyle(color: cs.onSurface)),
            ),
            // Status (New Widget)
            const Expanded(
              flex: 2,
              child: StatusBadge(status: 'Active'), // Sử dụng StatusBadge mới
            ),
            // Created (Mock)
            const Expanded(
              flex: 2,
              child: Text('—', textAlign: TextAlign.right, style: TextStyle(color: Colors.grey)),
            ),
            // Actions
            SizedBox(
              width: 48,
              child: IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'Edit',
                onPressed: () async {
                  final res = await AppRouter.navigateTo(
                    context,
                    AppRouter.accountEdit,
                    arguments: AccountEditArgs(accountId: account.id),
                  );
                  if (res == true) {
                    onRefresh();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget: StatusBadge (Loại 2)
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'active':
        bgColor = const Color(0xFFE6F4EA); // Xanh lá nhạt
        textColor = const Color(0xFF1E8E3E); // Xanh lá đậm
        break;
      case 'inactive':
        bgColor = const Color(0xFFF1F3F4); // Xám nhạt
        textColor = const Color(0xFF5F6368); // Xám đậm
        break;
      case 'pending':
        bgColor = const Color(0xFFFEF7E0); // Vàng nhạt
        textColor = const Color(0xFFB06000); // Cam đậm
        break;
      default:
        bgColor = const Color(0xFFE8F0FE);
        textColor = const Color(0xFF1967D2);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}