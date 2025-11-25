import 'package:flutter/material.dart';
import '../../services/service_locator.dart';
import '../../services/auth/auth_service.dart';
import '../../services/users_service.dart';
import '../../models/user.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';
import '../../navigation/app_router.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;
  const UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
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
    setState(() => _isLoading = true);
    try {
      final res = await _usersService.getUser(widget.userId);
      if (res.isSuccess) {
        setState(() {
          _user = res.value;
          _isLoading = false;
        });
        return;
      }
      throw Exception(res.error.message);
    } catch (e) {
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
        title: const Text('Delete User'),
        content: const Text('Remove user from organization? This will unassign them from the selected organization.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Remove'), style: TextButton.styleFrom(foregroundColor: Colors.red)),
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
      setState(() => _error = 'Failed to delete user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingView(message: 'Loading user...'));
    if (_error != null) return Scaffold(body: ErrorView(message: _error!, onRetry: _load));
    if (_user == null) return const Scaffold(body: Center(child: Text('No user data')));
    return Scaffold(
      appBar: AppBar(title: Text(_user!.name), actions: [
        Builder(builder: (ctx) {
          final me = locator<AuthService>().currentUser;
          final myRole = locator<AuthService>().selectedOrganization?.role?.toUpperCase();
          final isMe = me?.id == _user!.id;
          final isAdmin = myRole == 'ADMIN';
          final isManager = myRole == 'MANAGER';
          final canEdit = isMe || isAdmin || isManager;
          final canDelete = !isMe && isAdmin;
          return Row(children: [
            if (canEdit) IconButton(onPressed: () async { await AppRouter.navigateTo(context, AppRouter.adminUserEdit, arguments: UserDetailArgs(userId: _user!.id)); _load(); }, icon: const Icon(Icons.edit)),
            if (canDelete) IconButton(onPressed: _delete, icon: const Icon(Icons.delete)),
          ]);
        }),
      ]),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${_user!.name}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Email: ${_user!.email}${_user!.role != null ? ' • ${_user!.role}' : ''}'),
            const SizedBox(height: 8),
            Text('Active: ${_user!.isActive ? 'Yes' : 'No'}'),
          ],
        ),
      ),
    );
  }
}
