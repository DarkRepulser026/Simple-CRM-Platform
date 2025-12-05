import 'package:flutter/material.dart';
import '../../services/service_locator.dart';
import '../../services/auth/auth_service.dart';
import '../../services/users_service.dart';
import '../../models/user.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';
import '../../navigation/app_router.dart';

class UserDetailScreen extends StatelessWidget {
  final String userId;
  const UserDetailScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFE9EDF5);
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text('User Details'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: UserDetailCard(userId: userId),
          ),
        ),
      ),
    );
  }
}

/// Dialog helper to show admin user detail as a modal dialog
Future<bool?> showAdminUserDetailDialog(BuildContext context, {required String userId}) {
  return showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(padding: const EdgeInsets.all(16), child: SingleChildScrollView(child: UserDetailCard(userId: userId))),
      ),
    ),
  );
}

class UserDetailCard extends StatefulWidget {
  final String userId;
  const UserDetailCard({required this.userId});

  @override
  State<UserDetailCard> createState() => _UserDetailCardState();
}

class _UserDetailCardState extends State<UserDetailCard> {
  late final UsersService _usersService;
  bool _isLoading = true;
  String? _error;
  User? _user;

  @override
  void initState() {
    super.initState();
    _usersService = locator<UsersService>();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _usersService.getUser(widget.userId);
      if (res.isSuccess) {
        if (!mounted) return;
        setState(() {
          _user = res.value;
          _isLoading = false;
        });
        return;
      }
      throw Exception(res.error.message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load user: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete user'),
        content: const Text(
          'Remove this user from the organization? This will unassign them from the selected organization.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await _usersService.deleteUser(widget.userId);
      if (res.isSuccess) {
        Navigator.of(context).pop(true);
        return;
      }
      throw Exception(res.error.message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to delete user: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    
    if (_isLoading) return const Center(child: LoadingView(message: 'Loading user...'));
    if (_error != null) return Center(child: ErrorView(message: _error!, onRetry: _load));
    if (_user == null) return const Center(child: Text('No user data'));

    final colorScheme = Theme.of(context).colorScheme;
    final user = _user!;

    final me = locator<AuthService>().currentUser;
    final myRole = locator<AuthService>().selectedOrganization?.role?.toUpperCase();
    final isMe = me?.id == user.id;
    final isAdmin = myRole == 'ADMIN';
    final isManager = myRole == 'MANAGER';
    final canEdit = isMe || isAdmin || isManager;
    final canDelete = !isMe && isAdmin;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              user.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            if (user.role != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                child: Text(user.role!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.primary)),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 18, offset: const Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(radius: 32, child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(user.email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 6),
                          Row(children: [
                            Icon(user.isActive ? Icons.check_circle : Icons.cancel, size: 18, color: user.isActive ? Colors.green : Colors.red),
                            const SizedBox(width: 6),
                            Text(user.isActive ? 'Status: Active' : 'Status: Inactive', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: user.isActive ? Colors.green : Colors.red)),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back')),
                    const SizedBox(width: 8),
                    if (canDelete) OutlinedButton.icon(onPressed: _delete, icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), style: OutlinedButton.styleFrom(foregroundColor: Colors.red), label: const Text('Remove')),
                    if (canDelete) const SizedBox(width: 8),
                    if (canEdit) FilledButton.icon(onPressed: () async {
                      final res = await AppRouter.navigateTo<bool?>(context, AppRouter.adminUserEdit, arguments: UserDetailArgs(userId: user.id));
                      if (res == true) Navigator.of(context).pop(true);
                      else _load();
                    }, icon: const Icon(Icons.edit, size: 18), label: const Text('Edit User')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

 
