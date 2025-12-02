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
      
      // FIX: Kiểm tra mounted để tránh lỗi setState called after dispose
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

  void _refresh() {
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingView(message: 'Loading account...'));
    if (_error != null) return Scaffold(body: ErrorView(message: _error!, onRetry: _load));
    if (_account == null) return const Scaffold(body: Center(child: Text('No account data')));

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
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
        actions: [
          ManagerOrAdminOnly(
            child: IconButton(
              onPressed: () async {
                final res = await AppRouter.navigateTo(
                  context,
                  AppRouter.accountEdit,
                  arguments: AccountDetailArgs(accountId: _account!.id),
                );
                if (res == true) _refresh();
              },
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
            ),
          ),
          IconButton(
            onPressed: () => AppRouter.navigateTo(
              context,
              AppRouter.activityLogs,
              arguments: ActivityLogsArgs(entityType: 'Account', entityId: _account!.id),
            ),
            icon: const Icon(Icons.history),
            tooltip: 'View History',
          ),
          AdminOnly(
            child: IconButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Account'),
                    content: Text('Are you sure you want to delete "${_account!.name}"? This action cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  try {
                    final res = await _accountsService.deleteAccount(_account!.id);
                    if (res.isSuccess) {
                      if (mounted) Navigator.of(context).pop(true);
                    } else {
                      throw Exception(res.error.message);
                    }
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                  }
                }
              },
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete',
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === LEFT COLUMN (Main Info) ===
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: cs.secondaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  _account!.name.isNotEmpty ? _account!.name[0].toUpperCase() : '?',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    color: cs.onSecondaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _account!.name,
                                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: cs.outline.withOpacity(0.3)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _account!.type.isEmpty ? 'Unknown Type' : _account!.type,
                                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 32),
                        
                        Text('About', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        // Mock data fields (vì model Account đơn giản)
                        _buildInfoRow(context, Icons.info_outline, 'Description', 'No description available for this account.'),
                        const SizedBox(height: 16),
                        _buildInfoRow(context, Icons.language, 'Website', 'www.example.com'), // Mock
                        const SizedBox(height: 16),
                        _buildInfoRow(context, Icons.phone, 'Phone', '+1 234 567 890'), // Mock
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 24),
                
                // === RIGHT COLUMN (Sidebar) ===
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('System Info', style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface)),
                        const SizedBox(height: 24),
                        _buildMetaRow(context, 'Account ID', _account!.id),
                        const Divider(height: 32),
                        _buildMetaRow(context, 'Created', _formatDate(_account!.createdAt)),
                        const Divider(height: 32),
                        _buildMetaRow(context, 'Last Updated', _formatDate(_account!.updatedAt)),
                      ],
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

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: cs.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              Text(value, style: TextStyle(fontSize: 15, color: cs.onSurface)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetaRow(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.outline)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}