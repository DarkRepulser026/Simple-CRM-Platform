import 'package:flutter/material.dart';
import '../../widgets/paginated_list_view.dart';
import '../../models/user_role.dart';
import '../../services/service_locator.dart';
import '../../services/roles_service.dart';
import '../../services/auth/auth_service.dart';
import '../../widgets/role_visibility.dart';
import '../../screens/access_denied_redirect_screen.dart';
// unused import removed

class RolesListScreen extends StatefulWidget {
  const RolesListScreen({super.key});

  @override
  State<RolesListScreen> createState() => _RolesListScreenState();
}

class _RolesListScreenState extends State<RolesListScreen> {
  late final RolesService _rolesService;
  int _reloadVersion = 0;

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
    final myOrgRole = locator<AuthService>().selectedOrganization?.role?.toUpperCase();
    final isAdmin = myOrgRole == 'ADMIN';
    return AdminOnly(fallback: const AccessDeniedRedirectScreen(), child: Scaffold(
      appBar: AppBar(title: const Text('Roles')),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () async {
                await _showRoleDialog(context, null);
                setState(() => _reloadVersion++);
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: PaginatedListView<UserRole>(
        key: ValueKey(_reloadVersion),
        fetchPage: _fetchPage,
        pageSize: 20,
        emptyMessage: 'No roles',
        errorMessage: 'Failed to load roles',
        loadingMessage: 'Loading roles...',
        itemBuilder: (context, role, index) => ListTile(
          title: Text(role.name),
          subtitle: Text("${role.roleType.value}${role.permissions.isNotEmpty ? ' • ${role.permissions.join(', ')}' : ''}"),
          trailing: PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'edit') {
                await _showRoleDialog(context, role);
                setState(() => _reloadVersion++);
              } else if (v == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete role'),
                    content: const Text('Delete this role? Users assigned this role may be affected.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete'), style: TextButton.styleFrom(foregroundColor: Colors.red)),
                    ],
                  ),
                );
                if (confirm == true) {
                  final res = await _rolesService.deleteRole(role.id);
                  if (res.isSuccess) {
                    setState(() => _reloadVersion++);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Role deleted')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete role: ${res.error}')));
                  }
                }
              }
            },
            itemBuilder: (context) => [
              if (isAdmin || myOrgRole == 'MANAGER') const PopupMenuItem(value: 'edit', child: Text('Edit')),
              if (isAdmin) const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ),
      ),
    ));
  }

  Future<void> _showRoleDialog(BuildContext context, UserRole? role) async {
    final isNew = role == null;
    final nameCtrl = TextEditingController(text: role?.name ?? '');
    final descCtrl = TextEditingController(text: role?.description ?? '');
    UserRoleType currentType = role?.roleType ?? UserRoleType.viewer;
    Set<Permission> selected = role != null ? role.permissions.toSet() : {};
    final formKey = GlobalKey<FormState>();
    final myOrgRole = locator<AuthService>().selectedOrganization?.role?.toUpperCase();
    final canEdit = myOrgRole == 'ADMIN';

    await showDialog<void>(context: context, builder: (ctx) {
      return StatefulBuilder(builder: (ctx2, setStateDialog) {
        return AlertDialog(
          title: Text(isNew ? 'Create Role' : 'Edit Role'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a name' : null),
                  const SizedBox(height: 8),
                  TextFormField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<UserRoleType>(
                    decoration: const InputDecoration(labelText: 'Type'),
                    value: currentType,
                    items: UserRoleType.values.map((rt) => DropdownMenuItem(value: rt, child: Text(rt.value))).toList(),
                    onChanged: (v) => currentType = v ?? currentType,
                  ),
                  const SizedBox(height: 8),
                  const Text('Permissions', style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: Permission.values.map((p) {
                      return FilterChip(
                        label: Text(p.value),
                        selected: selected.contains(p),
                        onSelected: (sel) {
                          if (!canEdit) return;
                          setStateDialog(() {
                            if (sel) selected.add(p);
                            else selected.remove(p);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final newRole = UserRole(
                id: role?.id ?? '',
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim(),
                roleType: currentType,
                permissions: selected.toList(),
                organizationId: locator<AuthService>().selectedOrganizationId ?? '',
                isDefault: role?.isDefault ?? false,
                isActive: role?.isActive ?? true,
                createdAt: role?.createdAt ?? DateTime.now(),
                updatedAt: DateTime.now(),
              );
              if (isNew) {
                final res = await _rolesService.createRole(newRole);
                if (res.isSuccess) {
                  Navigator.of(ctx).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create role: ${res.error}')));
                }
              } else {
                final res = await _rolesService.updateRole(newRole);
                if (res.isSuccess) {
                  Navigator.of(ctx).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update role: ${res.error}')));
                }
              }
            }, child: const Text('Save')),
          ],
        );
      });
    });
  }
}