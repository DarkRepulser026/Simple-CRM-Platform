import 'package:flutter/material.dart';
import '../../widgets/paginated_list_view.dart';
import '../../models/user.dart';
import '../../services/service_locator.dart';
import '../../services/users_service.dart';
import '../../navigation/app_router.dart';
import '../../services/auth/auth_service.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  late final UsersService _usersService;

  Future<List<User>> _fetchPage(int page, int limit) async {
    final res = await _usersService.getUsers(page: page, limit: limit);
    if (res.isSuccess) return res.value.users;
    throw Exception(res.error.message);
  }

  @override
  void initState() {
    super.initState();
    _usersService = locator<UsersService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users'), actions: [
        if (locator<AuthService>().selectedOrganization?.role == 'Admin' || locator<AuthService>().selectedOrganization?.role == 'Manager') ...[
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
        ]
      ]),
      body: PaginatedListView<User>(
        fetchPage: _fetchPage,
        pageSize: 20,
        emptyMessage: 'No users',
        errorMessage: 'Failed to load users',
        loadingMessage: 'Loading users...',
        itemBuilder: (context, user, index) => ListTile(
          leading: CircleAvatar(child: Text(user.name[0].toUpperCase())),
          title: Text(user.name),
          subtitle: Text(user.email),
          trailing: PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'view_as') {
                final res = await locator<UsersService>().viewAs(user.id);
                if (res.isSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Now viewing as user')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to impersonate: ${res.error}')));
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'view_as', child: Text('View as')),
            ],
            child: const Icon(Icons.more_vert),
          ),
          onTap: () {
            // TODO: Implement user detail
          },
        ),
      ),
    );
  }
}
