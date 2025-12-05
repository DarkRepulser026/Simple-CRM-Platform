import 'package:flutter/material.dart';

import '../../models/account.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';
import '../../services/service_locator.dart';
import '../../services/accounts_service.dart';
import '../../widgets/role_visibility.dart';
import '../../navigation/app_router.dart';
import 'account_edit_screen.dart';

class AccountDetailArgs {
  const AccountDetailArgs({required this.accountId});
  final String accountId;
}

class AccountDetailScreen extends StatelessWidget {
  final String accountId;
  const AccountDetailScreen({super.key, required this.accountId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const bgColor = Color(0xFFE9EDF5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Account Details', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: AccountDetailCard(accountId: accountId)),
        ),
      ),
    );
  }
}

Future<bool?> showAccountDetailDialog(BuildContext context, {required String accountId}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    useRootNavigator: true,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(child: AccountDetailCard(accountId: accountId)),
        ),
      ),
    ),
  );
}

class AccountDetailCard extends StatefulWidget {
  final String accountId;
  const AccountDetailCard({required this.accountId});

  @override
  State<AccountDetailCard> createState() => _AccountDetailCardState();
}

class _AccountDetailCardState extends State<AccountDetailCard> {
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
      if (!mounted) return;
      if (res.isSuccess) {
        setState(() {
          _account = res.value;
          _isLoading = false;
        });
      } else {
        throw Exception(res.error.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load account: $e';
        _isLoading = false;
      });
    }
  }

  // Keep _load to allow reloading data; no wrapper refresh method is required

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_isLoading) return const Center(child: LoadingView(message: 'Loading account...'));
    if (_error != null) return Center(child: ErrorView(message: _error!, onRetry: _load));
    if (_account == null) return const Center(child: Text('No account data'));

    final account = _account!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _buildMainInfo(context, account, theme, cs)),
        const SizedBox(width: 24),
        Expanded(flex: 1, child: _buildSidebar(context, account, theme, cs)),
      ],
    );
  }

  Widget _buildMainInfo(BuildContext context, Account account, ThemeData theme, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(16)),
              child: Center(
                child: Text(
                  account.name.isNotEmpty ? account.name[0].toUpperCase() : '?',
                  style: theme.textTheme.headlineMedium?.copyWith(color: cs.onSecondaryContainer, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(account.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(border: Border.all(color: cs.outline.withOpacity(0.3)), borderRadius: BorderRadius.circular(4)),
                    child: Text(account.type.isEmpty ? 'Unknown Type' : account.type, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ),
                  const SizedBox(width: 10),
                  ManagerOrAdminOnly(
                      child: FilledButton.icon(
                    onPressed: () async {
                      final res = await AppRouter.navigateTo<bool?>(context, AppRouter.accountEdit, arguments: AccountEditArgs(accountId: account.id));
                      if (res == true) Navigator.of(context).pop(true);
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ))
                ]),
              ]),
            ),
          ]),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),
          Text('About', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildInfoRow(context, Icons.info_outline, 'Description', 'No description available for this account.'),
          const SizedBox(height: 16),
          _buildInfoRow(context, Icons.language, 'Website', account.website ?? ''),
          const SizedBox(height: 16),
          _buildInfoRow(context, Icons.phone, 'Phone', account.phone ?? ''),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, Account account, ThemeData theme, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Properties', style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface)),
        const SizedBox(height: 24),
        _buildMetaRow(context, 'Account ID', account.id),
        const Divider(height: 32),
        _buildMetaRow(context, 'Created', _formatDate(account.createdAt)),
        const Divider(height: 32),
        _buildMetaRow(context, 'Last Updated', _formatDate(account.updatedAt)),
      ]),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 20, color: cs.onSurfaceVariant), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)), Text(value, style: TextStyle(fontSize: 15, color: cs.onSurface))]))]);
  }

  Widget _buildMetaRow(BuildContext context, String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.outline)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 14))]);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
