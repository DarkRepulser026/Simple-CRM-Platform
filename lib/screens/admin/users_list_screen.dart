import 'package:flutter/material.dart';
import '../../widgets/paginated_list_view.dart';
import '../../models/user.dart';
import '../../services/service_locator.dart';
import '../../services/users_service.dart';
// import '../../services/roles_service.dart';
import '../../navigation/app_router.dart';
import '../../widgets/role_visibility.dart';
import '../../services/auth/auth_service.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  late final UsersService _usersService;
  int _reloadVersion = 0;
  // Simple role checks are used (ADMIN/MANAGER)

  Future<List<User>> _fetchPage(int page, int limit) async {
    final res = await _usersService.getUsers(page: page, limit: limit);
    if (res.isSuccess) return res.value.users;
    throw Exception(res.error.message);
  }

  @override
  void initState() {
    super.initState();
    _usersService = locator<UsersService>();
    //_rolesService = locator<RolesService>();
    //_loadRoles();
  }

  // placeholder for future roles fetching

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users'), actions: [
        ManagerOrAdminOnly(child: Row(children: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Invite user',
            onPressed: () => AppRouter.navigateTo(context, AppRouter.adminInvite),
          ),
          IconButton(
            icon: const Icon(Icons.mail_outline),
            tooltip: 'Manage invites',
            onPressed: () => AppRouter.navigateTo(context, AppRouter.adminInvitations),
          )
        ]))
      ]),
      body: PaginatedListView<User>(
        key: ValueKey(_reloadVersion),
        fetchPage: _fetchPage,
        pageSize: 20,
        emptyMessage: 'No users',
        errorMessage: 'Failed to load users',
        loadingMessage: 'Loading users...',
        itemBuilder: (context, user, index) => ListTile(
          leading: CircleAvatar(child: Text(user.name[0].toUpperCase())),
          title: Text(user.name),
          subtitle: Text('${user.email}${user.role != null ? ' • ${user.role}' : ''}'),
          trailing: PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'view_as') {
                final res = await locator<UsersService>().viewAs(user.id);
                if (res.isSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Now viewing as user')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to impersonate: ${res.error}')));
                }
              } else if (value == 'edit') {
                await AppRouter.navigateTo(context, AppRouter.adminUserEdit, arguments: UserDetailArgs(userId: user.id));
                setState(() => _reloadVersion++);
              } else if (value == 'remove') {
                final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                          title: const Text('Remove user'),
                          content: const Text('Remove this user from the organization?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Remove'), style: TextButton.styleFrom(foregroundColor: Colors.red)),
                          ],
                        ));
                if (confirm == true) {
                  final res2 = await _usersService.deleteUser(user.id);
                  if (res2.isSuccess) {
                    setState(() => _reloadVersion++);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User removed')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove user: ${res2.error}')));
                  }
                }
              }
            },
            itemBuilder: (context) {
              final me = locator<AuthService>().currentUser;
              final isMe = me?.id == user.id;
              final myOrgRole = locator<AuthService>().selectedOrganization?.role?.toUpperCase();
              final isAdmin = myOrgRole == 'ADMIN';
              final isManager = myOrgRole == 'MANAGER';
              final canViewAs = isAdmin; // only ADMIN allowed
              final canEditOthers = isAdmin || isManager;
              final canDelete = isAdmin;
              return [
                if (canViewAs) const PopupMenuItem(value: 'view_as', child: Text('View as')),
                if (isMe || canEditOthers) const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (!isMe && canDelete) const PopupMenuItem(value: 'remove', child: Text('Remove')),
              ];
            },
            child: const Icon(Icons.more_vert),
          ),
          onTap: () async {
            await AppRouter.navigateTo(context, AppRouter.adminUserDetail, arguments: UserDetailArgs(userId: user.id));
            setState(() => _reloadVersion++);
          },
        ),
      ),
    );
  }
}
