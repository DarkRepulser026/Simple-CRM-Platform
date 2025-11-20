import 'package:flutter/material.dart';
import '../../widgets/paginated_list_view.dart';
import '../../models/user_role.dart';
import '../../services/service_locator.dart';
import '../../services/roles_service.dart';

class RolesListScreen extends StatefulWidget {
  const RolesListScreen({super.key});

  @override
  State<RolesListScreen> createState() => _RolesListScreenState();
}

class _RolesListScreenState extends State<RolesListScreen> {
  late final RolesService _rolesService;

  Future<List<UserRole>> _fetchPage(int page, int limit) async {
    final res = await _rolesService.getRoles(page: page, limit: limit);
    if (res.isSuccess) return res.value.roles;
    throw Exception(res.error.message);
  }

  @override
  void initState() {
    super.initState();
    _rolesService = locator<RolesService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Roles')),
      body: PaginatedListView<UserRole>(
        fetchPage: _fetchPage,
        pageSize: 20,
        emptyMessage: 'No roles',
        errorMessage: 'Failed to load roles',
        loadingMessage: 'Loading roles...',
        itemBuilder: (context, role, index) => ListTile(
          title: Text(role.name),
          subtitle: Text(role.roleType.value),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
