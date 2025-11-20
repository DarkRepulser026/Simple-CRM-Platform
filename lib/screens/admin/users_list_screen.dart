import 'package:flutter/material.dart';
import '../../widgets/paginated_list_view.dart';
import '../../models/user.dart';
import '../../services/service_locator.dart';
import '../../services/users_service.dart';

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
      appBar: AppBar(title: const Text('Users')),
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
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Implement user detail
          },
        ),
      ),
    );
  }
}
