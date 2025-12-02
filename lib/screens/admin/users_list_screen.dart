import 'package:flutter/material.dart';
import '../../widgets/paginated_list_view.dart';
import '../../models/user.dart';
import '../../services/service_locator.dart';
import '../../services/users_service.dart';
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

  String _search = '';
  String _roleFilter = 'All';

  final List<String> _roleOptions = const ['All', 'ADMIN', 'MANAGER', 'AGENT', 'VIEWER'];

  Future<List<User>> _fetchPage(int page, int limit) async {
    final res = await _usersService.getUsers(page: page, limit: limit);
    if (!res.isSuccess) throw Exception(res.error.message);

    var users = res.value.users;


    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      users = users
          .where((u) =>
              u.name.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q))
          .toList();
    }

    if (_roleFilter != 'All') {
      users = users.where((u) => (u.role ?? '').toUpperCase() == _roleFilter).toList();
    }

    return users;
  }

  @override
  void initState() {
    super.initState();
    _usersService = locator<UsersService>();
  }

  void _refreshList() {
    setState(() => _reloadVersion++);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const bgColor = Color(0xFFE9EDF5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        title: const Text(''),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== HEADER ROW =====
                Row(
                  children: [
                    Text(
                      'Users',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Admin',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                    const Spacer(),
                    ManagerOrAdminOnly(
                      child: Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => AppRouter.navigateTo(
                                context, AppRouter.adminInvitations),
                            icon: const Icon(Icons.mail_outline, size: 18),
                            label: const Text('Invitations'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () =>
                                AppRouter.navigateTo(context, AppRouter.adminInvite),
                            icon: const Icon(Icons.person_add_alt_1, size: 18),
                            label: const Text('Invite user'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ===== FILTER BAR =====
                Row(
                  children: [
                    // Search
                    Expanded(
                      flex: 3,
                      child: TextField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search by name or email',
                          filled: true,
                          fillColor:
                              colorScheme.surface.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: BorderSide(
                              color: colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 12,
                          ),
                        ),
                        onChanged: (value) {
                          _search = value.trim();
                          _refreshList();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Role filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _roleFilter,
                        decoration: InputDecoration(
                          labelText: 'Role',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          filled: true,
                          fillColor: colorScheme.surface,
                        ),
                        items: _roleOptions
                            .map(
                              (r) => DropdownMenuItem(
                                value: r,
                                child: Text(r),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          _roleFilter = val ?? 'All';
                          _refreshList();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ===== MAIN TABLE CARD =====
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // TABLE HEADER
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            color: colorScheme.surfaceVariant.withOpacity(0.2),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 40), // avatar placeholder
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Name',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Email',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Role',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Status',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(
                                width: 40,
                                child: Center(
                                  child: Text(
                                    '⋮',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // TABLE BODY (PaginatedListView)
                        Expanded(
                          child: PaginatedListView<User>(
                            key: ValueKey(_reloadVersion),
                            fetchPage: _fetchPage,
                            pageSize: 20,
                            emptyMessage: 'No users',
                            errorMessage: 'Failed to load users',
                            loadingMessage: 'Loading users...',
                            itemBuilder: (context, user, index) {
                              final me = locator<AuthService>().currentUser;
                              final isMe = me?.id == user.id;
                              final myOrgRole = locator<AuthService>()
                                  .selectedOrganization
                                  ?.role
                                  ?.toUpperCase();
                              final isAdmin = myOrgRole == 'ADMIN';
                              final isManager = myOrgRole == 'MANAGER';
                              final canViewAs = isAdmin;
                              final canEditOthers = isAdmin || isManager;
                              final canDelete = isAdmin;

                              return InkWell(
                                onTap: () async {
                                  await AppRouter.navigateTo(
                                    context,
                                    AppRouter.adminUserDetail,
                                    arguments:
                                        UserDetailArgs(userId: user.id),
                                  );
                                  _refreshList();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: colorScheme.outline
                                            .withOpacity(0.06),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Avatar
                                      CircleAvatar(
                                        radius: 16,
                                        child: Text(
                                          user.name.isNotEmpty
                                              ? user.name[0].toUpperCase()
                                              : '?',
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Name
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          user.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      // Email
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          user.email,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ),
                                      // Role chip
                                      Expanded(
                                        flex: 2,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: _buildRoleChip(
                                              context, user.role),
                                        ),
                                      ),
                                      // Status chip
                                      Expanded(
                                        flex: 2,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: _buildStatusChip(
                                              context, user.isActive),
                                        ),
                                      ),
                                      // Actions
                                      SizedBox(
                                        width: 40,
                                        child: PopupMenuButton<String>(
                                          onSelected: (value) async {
                                            if (value == 'view_as') {
                                              final res =
                                                  await locator<UsersService>()
                                                      .viewAs(user.id);
                                              if (res.isSuccess) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Now viewing as user'),
                                                  ),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Failed to impersonate: ${res.error}',
                                                    ),
                                                  ),
                                                );
                                              }
                                            } else if (value == 'edit') {
                                              await AppRouter.navigateTo(
                                                context,
                                                AppRouter.adminUserEdit,
                                                arguments: UserDetailArgs(
                                                    userId: user.id),
                                              );
                                              _refreshList();
                                            } else if (value == 'remove') {
                                              final confirm =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text(
                                                      'Remove user'),
                                                  content: const Text(
                                                      'Remove this user from the organization?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(ctx)
                                                              .pop(false),
                                                      child:
                                                          const Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(ctx)
                                                              .pop(true),
                                                      style: TextButton
                                                          .styleFrom(
                                                        foregroundColor:
                                                            Colors.red,
                                                      ),
                                                      child:
                                                          const Text('Remove'),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (confirm == true) {
                                                final res2 =
                                                    await _usersService
                                                        .deleteUser(user.id);
                                                if (res2.isSuccess) {
                                                  _refreshList();
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'User removed'),
                                                    ),
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Failed to remove user: ${res2.error}',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            }
                                          },
                                          itemBuilder: (context) {
                                            return [
                                              if (canViewAs)
                                                const PopupMenuItem(
                                                  value: 'view_as',
                                                  child: Text('View as'),
                                                ),
                                              if (isMe || canEditOthers)
                                                const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Text('Edit'),
                                                ),
                                              if (!isMe && canDelete)
                                                const PopupMenuItem(
                                                  value: 'remove',
                                                  child: Text('Remove'),
                                                ),
                                            ];
                                          },
                                          child: const Icon(Icons.more_vert),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
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

  Widget _buildRoleChip(BuildContext context, String? role) {
    final colorScheme = Theme.of(context).colorScheme;
    if (role == null || role.isEmpty) {
      return Text(
        '—',
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: colorScheme.onSurfaceVariant),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, bool isActive) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isActive ? Colors.green : Colors.red;
    final bg = isActive ? Colors.green.withOpacity(0.08) : Colors.red.withOpacity(0.08);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.pause_circle_filled,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
