import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:fl_chart/fl_chart.dart';

import '../../models/dashboard_metrics.dart';
import '../../models/activity_log.dart';
import '../../services/auth/auth_service.dart';
import '../../services/service_locator.dart';
import '../../services/dashboard_service.dart';
import '../../services/users_service.dart';
import '../../services/roles_service.dart';
import '../../models/user.dart';
import '../../models/user_role.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../navigation/app_router.dart';
import 'admin_metrics_grid.dart';
import '../../widgets/role_visibility.dart';

/// Dashboard screen showing business metrics and navigation to main features
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final AuthService _authService;
  late final DashboardService _dashboardService;
  late final UsersService _usersService;
  late final RolesService _rolesService;

  bool _isLoading = true;
  String? _errorMessage;
  DashboardMetrics? _metrics;
  bool _showedInviteToast = false;
  bool _adminExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _authService = locator<AuthService>();
    _dashboardService = locator<DashboardService>();
    _usersService = locator<UsersService>();
    _rolesService = locator<RolesService>();
    await _loadDashboard();
  }

  Future<List<User>> _fetchPreviewUsers() async {
    try {
      final res = await _usersService.getUsers(limit: 5);
      if (res.isSuccess) return res.value.users;
    } catch (_) {}
    return [];
  }

  Future<List<UserRole>> _fetchPreviewRoles() async {
    try {
      final res = await _rolesService.getRoles(limit: 5);
      if (res.isSuccess) return res.value.roles;
    } catch (_) {}
    return [];
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _dashboardService.getDashboardMetrics();
      if (res.isSuccess) {
        setState(() {
          _metrics = res.value;
          _isLoading = false;
        });
        // Show 'Invite accepted' toast if recent activities include this action and we haven't shown it yet
        if (!_showedInviteToast && _metrics != null && _metrics!.recentActivities.isNotEmpty) {
          final acceptedFound = _metrics!.recentActivities.any((a) => (a.action ?? '').toUpperCase() == 'INVITE_ACCEPTED');
          if (acceptedFound) {
            _showedInviteToast = true;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite accepted')));
            }
          }
        }
        return;
      }

      if (!_authService.isLoggedIn) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to continue')),
          );
          AppRouter.replaceWith(context, AppRouter.login);
        }
        return;
      }

      if (!_authService.hasSelectedOrganization) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Please select an organization to view dashboard'),
            ),
          );
          AppRouter.navigateTo(context, AppRouter.companySelection);
        }
        return;
      }

      throw Exception(res.error.message);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load dashboard: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 900;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      floatingActionButton: kDebugMode
          ? FloatingActionButton(
              mini: true,
              tooltip: 'Debug info',
              child: const Icon(Icons.info_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Debug Info'),
                    content: Text(
                      'Logged in: ${_authService.isLoggedIn}\n'
                      'Impersonating: ${_authService.isImpersonating}\n'
                      'Selected organization: ${_authService.selectedOrganizationId ?? 'none'}\n'
                      'JWT present: ${_authService.jwtToken != null}',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            )
          : null,
      body: Row(
        children: [
          _buildSidebar(showLogout: !isSmallScreen, showImpersonation: !isSmallScreen),
          Expanded(child: _buildContent(isSmallScreen)),
        ],
      ),
    );
  }

  // ---------- CONTENT ----------

  Widget _buildContent(bool isSmallScreen) {
    if (_isLoading) {
      return const LoadingView(message: 'Loading dashboard...');
    }

    if (_errorMessage != null) {
      return ErrorView(message: _errorMessage!, onRetry: _loadDashboard);
    }

    if (_metrics == null) {
      return const Center(child: Text('No data available'));
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final horizontalPadding = screenWidth > 1200 ? 64.0 : (screenWidth > 800 ? 48.0 : 24.0);
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Welcome back!', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Here\'s your business overview', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ])),
                ]),
                const SizedBox(height: 40),
                AdminMetricsGrid(metrics: _metrics!),
                const SizedBox(height: 48),
                _buildManageTableRow(),
                const SizedBox(height: 24),
                _buildMetricRow('Weekly Performance', [
                  _CompactMetricCard(title: 'Leads This Week', value: _metrics!.leadsThisWeek.toString(), icon: Icons.new_releases, color: Colors.blue),
                  _CompactMetricCard(title: 'Tickets Resolved', value: _metrics!.ticketsResolvedThisWeek.toString(), icon: Icons.done, color: Colors.green),
                  _CompactMetricCard(title: 'Tasks Completed', value: _metrics!.tasksCompletedThisWeek.toString(), icon: Icons.check_circle, color: Colors.purple),
                ]),
                const SizedBox(height: 24),
                _buildRecentActivities(),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricRow(String sectionTitle, List<Widget> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sectionTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards,
        ),
      ],
    );
  }

  // Quick actions removed for admin dashboard.

  Widget _buildRecentActivities() {
    if (_metrics == null || _metrics!.recentActivities.isEmpty) {
      return const SizedBox.shrink();
    }
    final activities = _metrics!.recentActivities.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.08)),
          ),
          child: Column(
            children: activities.map((act) => Column(children: [_buildActivityTile(act), const Divider(height: 1)])).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildManageTableRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildUsersPreview()),
        const SizedBox(width: 16),
        Expanded(child: _buildRolesPreview()),
      ],
    );
  }

  Widget _buildUsersPreview() {
    return FutureBuilder<List<User>>(
      future: _fetchPreviewUsers(),
      builder: (context, AsyncSnapshot<List<User>> snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final users = snapshot.data ?? [];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.08))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('User Management', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)), AdminOnly(child: Row(children: [TextButton(onPressed: () => AppRouter.navigateTo(context, AppRouter.adminUsers), child: const Text('Manage')), const SizedBox(width: 8), ElevatedButton(onPressed: () => _showUserDialog(context), child: const Text('Create'))]))]),
            const Divider(),
            Column(
              children: users.map<Widget>((u) {
                return ListTile(
                  leading: CircleAvatar(child: Text(u.name[0].toUpperCase())),
                  title: Text(u.name),
                  subtitle: Text(u.email),
                  onTap: () => AppRouter.navigateTo(context, AppRouter.adminUserDetail, arguments: UserDetailArgs(userId: u.id)),
                  trailing: SizedBox(
                    width: 88,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      AdminOnly(child: IconButton(icon: const Icon(Icons.edit), onPressed: () => _showUserDialog(context, user: u))),
                      AdminOnly(child: IconButton(icon: const Icon(Icons.delete), onPressed: () async {
                        final ok = await showDialog<bool>(context: context, builder: (dCtx) => AlertDialog(title: const Text('Confirm delete'), content: const Text('Delete user?'), actions: [TextButton(onPressed: () => Navigator.of(dCtx).pop(false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.of(dCtx).pop(true), child: const Text('Delete'))]));
                        if (ok == true) {
                          final resp = await _usersService.deleteUser(u.id);
                          if (resp.isSuccess) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User removed')));
                            await _loadDashboard();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: ${resp.error}')));
                          }
                        }
                      })),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildRolesPreview() {
    return FutureBuilder<List<UserRole>>(
      future: _fetchPreviewRoles(),
      builder: (context, AsyncSnapshot<List<UserRole>> snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final roles = snapshot.data ?? [];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.08))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Role Settings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)), AdminOnly(child: Row(children: [TextButton(onPressed: () => AppRouter.navigateTo(context, AppRouter.adminRoles), child: const Text('Manage')), const SizedBox(width: 8), ElevatedButton(onPressed: () => _showRoleDialog(context), child: const Text('Create'))]))]),
            const Divider(),
            Column(
              children: roles.map<Widget>((r) {
                return ListTile(
                  title: Text(r.name),
                  subtitle: Text(r.roleType.value),
                  onTap: () => AppRouter.navigateTo(context, AppRouter.adminRoles),
                  trailing: SizedBox(
                    width: 88,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      AdminOnly(child: IconButton(icon: const Icon(Icons.edit), onPressed: () => _showRoleDialog(context, role: r))),
                      AdminOnly(child: IconButton(icon: const Icon(Icons.delete), onPressed: () async {
                        final ok = await showDialog<bool>(context: context, builder: (dCtx) => AlertDialog(title: const Text('Confirm delete'), content: const Text('Delete role?'), actions: [TextButton(onPressed: () => Navigator.of(dCtx).pop(false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.of(dCtx).pop(true), child: const Text('Delete'))]));
                        if (ok == true) {
                          final resp = await _rolesService.deleteRole(r.id);
                          if (resp.isSuccess) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Role removed')));
                            await _loadDashboard();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete role: ${resp.error}')));
                          }
                        }
                      })),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ]),
        );
      },
    );
  }

  Future<void> _showUserDialog(BuildContext ctx, {User? user}) async {
    final isNew = user == null;
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    String role = user?.role ?? 'VIEWER';
    bool isActive = user?.isActive ?? true;
    bool sendInvite = true; // default to invite when creating a new user
    final formKey = GlobalKey<FormState>();
    await showDialog<void>(context: ctx, builder: (dialogCtx) {
      return StatefulBuilder(builder: (ctx2, setStateDialog) {
        return AlertDialog(
          title: Text(isNew ? 'Create User' : 'Edit User'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => (v == null || v.isEmpty) ? 'Email required' : null),
                const SizedBox(height: 8),
                TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => (v == null || v.isEmpty) ? 'Name required' : null),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(value: role, decoration: const InputDecoration(labelText: 'Role'), items: ['ADMIN','MANAGER','AGENT','VIEWER'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(), onChanged: (v) => role = v ?? role),
                const SizedBox(height: 8),
                SwitchListTile(title: const Text('Active'), value: isActive, onChanged: (v) => setStateDialog(() => isActive = v)),
                const SizedBox(height: 8),
                if (isNew)
                  SwitchListTile(title: const Text('Send invitation instead of immediate creation'), value: sendInvite, onChanged: (v) => setStateDialog(() => sendInvite = v)),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('Cancel')),
            ElevatedButton(onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final newUser = User(id: user?.id ?? '', email: emailCtrl.text.trim(), name: nameCtrl.text.trim(), role: role, isActive: isActive);
              if (isNew) {
                // When creating a new user, prefer sending an invite unless explicitly disabled
                if (sendInvite) {
                  final orgId = locator<AuthService>().selectedOrganizationId;
                  if (orgId == null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('No organization selected')));
                    return;
                  }
                  final res = await _usersService.inviteUser(orgId: orgId, email: newUser.email, role: newUser.role ?? 'VIEWER');
                  if (res.isSuccess) {
                    Navigator.of(dialogCtx).pop();
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Invitation sent')));
                    await _loadDashboard();
                  } else {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Failed to send invite: ${res.error}')));
                  }
                } else {
                  final res = await _usersService.createUser(newUser);
                  if (res.isSuccess) {
                    Navigator.of(dialogCtx).pop();
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('User created')));
                    await _loadDashboard();
                  } else {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Failed to create user: ${res.error}')));
                  }
                }
              } else {
                final res = await _usersService.updateUser(newUser);
                if (res.isSuccess) {
                  Navigator.of(dialogCtx).pop();
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('User updated')));
                  await _loadDashboard();
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Failed to update user: ${res.error}')));
                }
              }
            }, child: Text(isNew ? (sendInvite ? 'Invite' : 'Create') : 'Save')),
          ],
        );
      });
    });
  }

  Future<void> _showRoleDialog(BuildContext ctx, {UserRole? role}) async {
    final isNew = role == null;
    final nameCtrl = TextEditingController(text: role?.name ?? '');
    final descCtrl = TextEditingController(text: role?.description ?? '');
    UserRoleType currentType = role?.roleType ?? UserRoleType.viewer;
    Set<Permission> selected = role != null ? role.permissions.toSet() : {};
    final formKey = GlobalKey<FormState>();
    final myOrgRole = locator<AuthService>().selectedOrganization?.role;
    final canEdit = myOrgRole == 'ADMIN';

    await showDialog<void>(context: ctx, builder: (dialogCtx) {
      return StatefulBuilder(builder: (ctx2, setStateDialog) {
        return AlertDialog(
          title: Text(isNew ? 'Create Role' : 'Edit Role'),
          content: SingleChildScrollView(
            child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a name' : null),
              const SizedBox(height: 8),
              TextFormField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 8),
              DropdownButtonFormField<UserRoleType>(decoration: const InputDecoration(labelText: 'Type'), value: currentType, items: UserRoleType.values.map((rt) => DropdownMenuItem(value: rt, child: Text(rt.value))).toList(), onChanged: (v) => currentType = v ?? currentType),
              const SizedBox(height: 8),
              const Text('Permissions', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(spacing: 6, runSpacing: 4, children: Permission.values.map((p) { return FilterChip(label: Text(p.value), selected: selected.contains(p), onSelected: (sel) { if (!canEdit) return; setStateDialog(() { if (sel) selected.add(p); else selected.remove(p); }); }, ); }).toList()),
            ])),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('Cancel')), ElevatedButton(onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            final newRole = UserRole(id: role?.id ?? '', name: nameCtrl.text.trim(), description: descCtrl.text.trim(), roleType: currentType, permissions: selected.toList(), organizationId: locator<AuthService>().selectedOrganizationId ?? '', isDefault: role?.isDefault ?? false, isActive: role?.isActive ?? true, createdAt: role?.createdAt ?? DateTime.now(), updatedAt: DateTime.now());
            if (isNew) {
              final res = await _rolesService.createRole(newRole);
              if (res.isSuccess) { Navigator.of(dialogCtx).pop(); ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Role created'))); await _loadDashboard(); } else { ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Failed to create role: ${res.error}'))); }
            } else { final res = await _rolesService.updateRole(newRole); if (res.isSuccess) { Navigator.of(dialogCtx).pop(); ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Role updated'))); await _loadDashboard(); } else { ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Failed to update role: ${res.error}'))); } }
          }, child: const Text('Save'))],
        );
      });
    });
  }

  Widget _buildActivityTile(ActivityLog a) {
    final isInviteAccepted = (a.action ?? '').toUpperCase() == 'INVITE_ACCEPTED' || (a.description.toLowerCase().contains('accepted invite'));
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () {
        AppRouter.navigateTo(context, AppRouter.activityLogs, arguments: ActivityLogsArgs(entityType: a.entityType, entityId: a.entityId, userId: a.userId));
      },
      leading: CircleAvatar(
        backgroundColor: isInviteAccepted ? Colors.green : Theme.of(context).colorScheme.primary.withOpacity(0.1),
        child: Icon(isInviteAccepted ? Icons.person_add_alt : Icons.info_outline, color: isInviteAccepted ? Colors.white : Theme.of(context).colorScheme.primary),
      ),
      title: Text(a.description.isNotEmpty ? a.description : a.activityType.value, style: Theme.of(context).textTheme.bodyMedium),
      subtitle: Text(a.userName ?? a.entityName ?? '', style: Theme.of(context).textTheme.bodySmall),
      trailing: Text(a.createdAt.toLocal().toString().split('.').first, style: Theme.of(context).textTheme.bodySmall),
    );
  }

  Widget _buildSidebar({required bool showLogout, required bool showImpersonation}) {
    final items = <Widget>[
      // Logo & title
      Row(
        children: [
          Icon(Icons.dashboard, color: Theme.of(context).colorScheme.primary, size: 28),
          const SizedBox(width: 8),
          Text('Dashboard', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        ],
      ),
      const SizedBox(height: 32),
      // Navigation
      _SidebarItem(icon: Icons.dashboard_outlined, label: 'Dashboard', isSelected: true, onTap: () {}),
      AdminOnly(child: ExpansionTile(
        initiallyExpanded: _adminExpanded,
        onExpansionChanged: (v) => setState(() => _adminExpanded = v),
        leading: Icon(Icons.admin_panel_settings, color: Theme.of(context).colorScheme.primary),
        title: const Text('Admin'),
        children: [
          ListTile(leading: Icon(Icons.people, color: Theme.of(context).colorScheme.primary), title: const Text('Users'), onTap: () => AppRouter.navigateTo(context, AppRouter.adminUsers)),
          ListTile(leading: Icon(Icons.admin_panel_settings, color: Theme.of(context).colorScheme.primary), title: const Text('Roles'), onTap: () => AppRouter.navigateTo(context, AppRouter.adminRoles)),
          ListTile(leading: Icon(Icons.mail, color: Theme.of(context).colorScheme.primary), title: const Text('Invitations'), onTap: () => AppRouter.navigateTo(context, AppRouter.adminInvitations)),
          ListTile(leading: Icon(Icons.history, color: Theme.of(context).colorScheme.primary), title: const Text('Activity Logs'), onTap: () => AppRouter.navigateTo(context, AppRouter.activityLogs)),
        ],
      )),
      _SidebarItem(icon: Icons.people_outline, label: 'Contacts', onTap: () => AppRouter.navigateTo(context, AppRouter.contacts)),
      _SidebarItem(icon: Icons.task_outlined, label: 'Tasks', onTap: () => AppRouter.navigateTo(context, AppRouter.tasks)),
      _SidebarItem(icon: Icons.support_agent_outlined, label: 'Tickets', onTap: () => AppRouter.navigateTo(context, AppRouter.tickets)),
      const Spacer(),
      if (showImpersonation)
        IconButton(onPressed: () async { final ok = await _authService.stopImpersonation(); if (mounted && ok) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stopped impersonation'))); await _loadDashboard(); } }, icon: const Icon(Icons.person_off), tooltip: 'Stop impersonation'),
      if (showLogout)
        TextButton.icon(onPressed: () async { await _authService.logout(); if (mounted) { AppRouter.replaceWith(context, AppRouter.login); } }, icon: const Icon(Icons.logout, size: 16), label: const Text('Logout'), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))),
      const SizedBox(height: 16),
      ListTile(leading: Icon(Icons.business, color: Theme.of(context).colorScheme.primary), title: const Text('Organizations'), onTap: () => AppRouter.navigateTo(context, AppRouter.organizations)),
      ListTile(leading: Icon(Icons.account_balance, color: Theme.of(context).colorScheme.primary), title: const Text('Accounts'), onTap: () => AppRouter.navigateTo(context, AppRouter.accounts)),
      const Divider(),
    ];

    return Container(width: 250, color: Theme.of(context).colorScheme.surface, padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: items));
  }
}

/// Compact metric card widget for web dashboard
class _CompactMetricCard extends StatelessWidget {
  const _CompactMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: color,
                ),
              ),
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// QuickActionCard class removed because Quick Actions have been removed from the Dashboard

/// Sidebar item widget for web dashboard
class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bgColor = isSelected
        ? theme.colorScheme.primary.withOpacity(0.08)
        : Colors.transparent;

    final iconColor = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    final textColor = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- CHART WIDGETS ----------

class _SupportHealthChart extends StatelessWidget {
  final DashboardMetrics metrics;

  const _SupportHealthChart({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final total = metrics.totalTickets;
    final open = metrics.openTickets;
    final closed = (total - open).clamp(0, total);
    final hasTickets = total > 0;

    return Row(
      children: [
        SizedBox(
          height: 160,
          width: 160,
          child: hasTickets
              ? PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    borderData: FlBorderData(show: false),
                    sections: [
                      PieChartSectionData(
                        value: open.toDouble(),
                        color: const Color(0xFFEF4444),
                        radius: 26,
                        title: '',
                      ),
                      PieChartSectionData(
                        value: closed.toDouble(),
                        color: const Color(0xFF22C55E),
                        radius: 26,
                        title: '',
                      ),
                    ],
                  ),
                )
              : Center(
                  child: Text(
                    'No tickets',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _legendDot(
                'Open tickets',
                '${open}/${total}',
                const Color(0xFFEF4444),
                theme,
              ),
              const SizedBox(height: 4),
              _legendDot(
                'Closed tickets',
                '$closed/$total',
                const Color(0xFF22C55E),
                theme,
              ),
              const SizedBox(height: 12),
              Text(
                'SLA compliance: ${metrics.slaComplianceRate.toStringAsFixed(1)}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Avg response time: ${metrics.averageResponseTime.toStringAsFixed(1)}h',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                'Avg resolution time: ${metrics.averageResolutionTime.toStringAsFixed(1)}h',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendDot(
    String label,
    String value,
    Color color,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SatisfactionChart extends StatelessWidget {
  final DashboardMetrics metrics;

  const _SatisfactionChart({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final scores = [
      metrics.averageCsat,
      metrics.averageNps,
      metrics.slaComplianceRate,
    ];

    final maxScore = (scores.reduce((a, b) => a > b ? a : b) * 1.1)
        .clamp(10, 100)
        .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxScore / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color:
                      theme.colorScheme.outline.withOpacity(0.15),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: maxScore / 4,
                    getTitlesWidget: (value, _) {
                      return Text(
                        value.toStringAsFixed(0),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              theme.colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, _) {
                      switch (value.toInt()) {
                        case 0:
                          return const Text('CSAT', style: TextStyle(fontSize: 11));
                        case 1:
                          return const Text('NPS', style: TextStyle(fontSize: 11));
                        case 2:
                          return const Text('SLA', style: TextStyle(fontSize: 11));
                        default:
                          return const SizedBox.shrink();
                      }
                    },
                  ),
                ),
              ),
              barGroups: [
                _barGroup(0, metrics.averageCsat, const Color(0xFF4F46E5)),
                _barGroup(1, metrics.averageNps, const Color(0xFF22C55E)),
                _barGroup(
                    2, metrics.slaComplianceRate, const Color(0xFFF97316)),
              ],
              maxY: maxScore,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ScorePill('CSAT', metrics.averageCsat.toStringAsFixed(1)),
            _ScorePill('NPS', metrics.averageNps.toStringAsFixed(1)),
            _ScorePill(
                'SLA', '${metrics.slaComplianceRate.toStringAsFixed(0)}%'),
          ],
        ),
      ],
    );
  }

  BarChartGroupData _barGroup(int x, double value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          color: color,
          borderRadius: BorderRadius.circular(4),
          width: 20,
        ),
      ],
    );
  }
}

class _ScorePill extends StatelessWidget {
  final String label;
  final String value;

  const _ScorePill(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFF3F4F6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}
