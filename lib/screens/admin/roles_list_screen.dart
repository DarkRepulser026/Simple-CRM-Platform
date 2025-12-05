import 'package:flutter/material.dart';
import '../../widgets/paginated_list_view.dart';
import '../../models/user_role.dart'; // Giả sử UserRole có roleType và permissions/ Giả sử có model Permission
import '../../services/service_locator.dart';
import '../../services/roles_service.dart';
import '../../services/auth/auth_service.dart';
import '../../widgets/role_visibility.dart';
import '../../screens/access_denied_redirect_screen.dart';

// ===== MÀN HÌNH CHÍNH =====
class RolesListScreen extends StatefulWidget {
  const RolesListScreen({super.key});

  @override
  State<RolesListScreen> createState() => _RolesListScreenState();
}

class _RolesListScreenState extends State<RolesListScreen> {
  late final RolesService _rolesService;
  int _reloadVersion = 0;

  String _searchTerm = '';
  UserRoleType? _filterType;

  // HÀM TẢI DỮ LIỆU & LỌC CỤC BỘ
  Future<List<UserRole>> _fetchPage(int page, int limit) async {
  // Always fetches the first page of the full dataset, then filters locally.
  // NOTE: This is a LOCAL filtering solution. For large datasets, search/filter logic should be moved to the API level.
    final res = await _rolesService.getRoles(page: page, limit: limit);
    if (!res.isSuccess) throw Exception(res.error.message);

    var roles = res.value.roles;

    if (_searchTerm.isNotEmpty) {
      final lower = _searchTerm.toLowerCase();
      roles = roles.where((r) {
        return r.name.toLowerCase().contains(lower) ||
            (r.description ?? '').toLowerCase().contains(lower);
      }).toList();
    }

    if (_filterType != null) {
      roles = roles.where((r) => r.roleType == _filterType).toList();
    }

    return roles;
  }

  void _refreshList() {
    setState(() => _reloadVersion++);
  }

  @override
  void initState() {
    super.initState();
    _rolesService = locator<RolesService>();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final myOrgRole =
        locator<AuthService>().selectedOrganization?.role?.toUpperCase();
    final isAdmin = myOrgRole == 'ADMIN';

    const bgColor = Color(0xFFE9EDF5);

    return AdminOnly(
      fallback: const AccessDeniedRedirectScreen(),
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          titleSpacing: 0,
          title: const Text(''),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== HEADER ROW =====
                  Row(
                    children: [
                      Text(
                        'Roles',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Admin',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                      const Spacer(),
                      // Nút tạo Role mới chỉ dành cho Admin
                      if (isAdmin)
                        FilledButton.icon(
                          onPressed: () async {
                            await _showRoleDialog(context, null);
                            _refreshList();
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('New role'),
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
                            hintText: 'Search by name or description',
                            filled: true,
                            fillColor: colorScheme.surface.withOpacity(0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(999),
                              borderSide: BorderSide(
                                color:
                                    colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 12,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchTerm = value.trim();
                              _refreshList();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Role Type filter
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<UserRoleType?>(
                          value: _filterType,
                          decoration: InputDecoration(
                            labelText: 'Type',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            filled: true,
                            fillColor: colorScheme.surface,
                          ),
                          items: [
                            const DropdownMenuItem<UserRoleType?>(
                              value: null,
                              child: Text('All'),
                            ),
                            ...UserRoleType.values.map(
                              (rt) => DropdownMenuItem(
                                value: rt,
                                child: Text(rt.value),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _filterType = val;
                              _refreshList();
                            });
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
                                const Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Name',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  flex: 1,
                                  child: Text(
                                    'Type',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Description',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Permissions',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 40), // actions placeholder
                              ],
                            ),
                          ),
                          const Divider(height: 1),

                          // TABLE BODY (PaginatedListView)
                          Expanded(
                            child: PaginatedListView<UserRole>(
                              key: ValueKey(_reloadVersion),
                              fetchPage: _fetchPage,
                              pageSize: 20,
                              emptyMessage: 'No roles found',
                              errorMessage: 'Failed to load roles',
                              loadingMessage: 'Loading roles...',
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemBuilder: (context, role, index) {
                                return _RoleRow(
                                  role: role,
                                  isAdmin: isAdmin,
                                  myOrgRole: myOrgRole,
                                  onEdit: () async {
                                    // Mở dialog chỉnh sửa
                                    await _showRoleDialog(context, role);
                                    _refreshList();
                                  },
                                  onDelete: () async {
                                    await _handleDeleteRole(context, role);
                                  },
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
      ),
    );
  }

  // HÀM XỬ LÝ XÓA VAI TRÒ
  Future<void> _handleDeleteRole(
      BuildContext context, UserRole role) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete role'),
        content: Text(
            'Are you sure you want to delete the role "${role.name}"? Users assigned this role may be affected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await _rolesService.deleteRole(role.id);
      if (res.isSuccess) {
        _refreshList();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Role deleted successfully')),
          );
        }
      } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to delete role: ${res.error.message}'),
              ),
            );
        }
      }
    }
  }

  // HÀM HIỂN THỊ DIALOG TẠO/CHỈNH SỬA VAI TRÒ
  Future<void> _showRoleDialog(BuildContext context, UserRole? role) async {
    final isNew = role == null;
    final nameCtrl = TextEditingController(text: role?.name ?? '');
    final descCtrl = TextEditingController(text: role?.description ?? '');
    UserRoleType currentType = role?.roleType ?? UserRoleType.viewer;
    Set<Permission> selected =
        role != null ? role.permissions.toSet() : <Permission>{};
    final formKey = GlobalKey<FormState>();
    final myOrgRole =
        locator<AuthService>().selectedOrganization?.role?.toUpperCase();
    final canEdit = myOrgRole == 'ADMIN';

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setStateDialog) {
            // final colorScheme = Theme.of(ctx2).colorScheme;
            return Dialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isNew ? 'Create role' : 'Edit role',
                              style: Theme.of(ctx2)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.of(ctx2).pop(),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Name
                        TextFormField(
                          controller: nameCtrl,
                          enabled: canEdit,
                          decoration:
                              const InputDecoration(labelText: 'Name'),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Please enter a name'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        // Description
                        TextFormField(
                          controller: descCtrl,
                          enabled: canEdit,
                          maxLines: 2,
                          decoration:
                              const InputDecoration(labelText: 'Description'),
                        ),
                        const SizedBox(height: 12),
                        // Type
                        DropdownButtonFormField<UserRoleType>(
                          decoration:
                              const InputDecoration(labelText: 'Type'),
                          value: currentType,
                          items: UserRoleType.values
                              .map(
                                (rt) => DropdownMenuItem(
                                  value: rt,
                                  child: Text(rt.value),
                                ),
                              )
                              .toList(),
                          onChanged: canEdit
                              ? (v) =>
                                  currentType = v ?? currentType
                              : null,
                        ),
                        const SizedBox(height: 16),
                        // Permissions
                        Text(
                          'Permissions',
                          style: Theme.of(ctx2)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
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
                                  if (sel) {
                                    selected.add(p);
                                  } else {
                                    selected.remove(p);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        // Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx2).pop(),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            if (canEdit)
                              FilledButton(
                                onPressed: () async {
                                  if (!formKey.currentState!.validate()) return;

                                  final roleToSave = UserRole(
                                    id: role?.id ?? '',
                                    name: nameCtrl.text.trim(),
                                    description: descCtrl.text.trim(),
                                    roleType: currentType,
                                    permissions: selected.toList(),
                                    organizationId: locator<AuthService>()
                                            .selectedOrganizationId ??
                                        '',
                                    isDefault: role?.isDefault ?? false,
                                    isActive: role?.isActive ?? true,
                                    createdAt:
                                        role?.createdAt ?? DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  );

                                  final res = isNew
                                      ? await _rolesService
                                          .createRole(roleToSave)
                                      : await _rolesService
                                          .updateRole(roleToSave);

                                  if (res.isSuccess) {
                                    if (mounted) {
                                       Navigator.of(ctx2).pop();
                                       ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Role ${isNew ? 'created' : 'updated'} successfully'),
                                          ),
                                        );
                                    }
                                  } else {
                                    if (mounted) {
                                       ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to ${isNew ? 'create' : 'update'} role: ${res.error.message}',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Text('Save'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ===== WIDGET HÀNG CỦA VAI TRÒ =====
class _RoleRow extends StatelessWidget {
  const _RoleRow({
    required this.role,
    required this.isAdmin,
    required this.myOrgRole,
    required this.onEdit,
    required this.onDelete,
  });

  final UserRole role;
  final bool isAdmin;
  final String? myOrgRole;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  // Widget hiển thị Type dưới dạng Chip
  Widget _buildRoleTypeChip(BuildContext context, UserRoleType type) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        type.value,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canEdit = isAdmin || myOrgRole == 'MANAGER';
    final canDelete = isAdmin;
    final isDefaultRole = role.isDefault; // Giả định có thuộc tính này
    
    // Nếu là vai trò mặc định (Admin, Manager, Agent) thì không cho xóa/sửa tên
    final allowEdit = canEdit && !isDefaultRole;
    final allowDelete = canDelete && !isDefaultRole;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: allowEdit ? onEdit : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                // 1. Name
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Icon(
                          Icons.security, // Biểu tượng vai trò chung
                          size: 18,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          role.name,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                // 2. Type Chip
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _buildRoleTypeChip(context, role.roleType),
                  ),
                ),
                // 3. Description
                Expanded(
                  flex: 3,
                  child: Text(
                    role.description ?? 'No description provided',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                // 4. Permissions Count
                Expanded(
                  flex: 2,
                  child: Text(
                    role.permissions.isEmpty
                        ? 'No permissions'
                        : '${role.permissions.length} permissions',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                // 5. Actions
                SizedBox(
                  width: 32, // Đặt chiều rộng cố định cho PopupMenuButton
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      if (allowEdit)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                      if (allowDelete)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                    ],
                    child: const Icon(Icons.more_vert, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}