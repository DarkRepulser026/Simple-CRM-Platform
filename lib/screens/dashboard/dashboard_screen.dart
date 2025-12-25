import 'package:flutter/material.dart';
import '../../models/dashboard_metrics.dart';
import '../../services/auth/auth_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../../services/service_locator.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../navigation/app_router.dart';
import '../../widgets/role_visibility.dart';
import '../../widgets/dashboard/kpi_card.dart';
import '../../widgets/dashboard/work_queue_widget.dart';
import '../../widgets/dashboard/recent_activity_widget.dart';
import '../../widgets/dashboard/upcoming_tasks_widget.dart';
import '../../services/dashboard_service.dart' show WorkQueueItem, TaskItem;

/// Dashboard screen showing business metrics and navigation to main features
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final AuthService _authService;
  late final DashboardService _dashboardService;

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
    await _loadDashboard();
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

        if (!_showedInviteToast &&
            _metrics != null &&
            _metrics!.recentActivities.isNotEmpty) {
          final acceptedFound = _metrics!.recentActivities.any(
            (a) => (a.action ?? '').toUpperCase() == 'INVITE_ACCEPTED',
          );
          if (acceptedFound) {
            _showedInviteToast = true;
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Invite accepted')));
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
              content: Text('Please select an organization to view dashboard'),
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

    // NỀN MÀU XÁM XANH NHẠT
    const dashboardBg = Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: dashboardBg,
      floatingActionButton: kDebugMode
          ? FloatingActionButton(
              mini: true,
              tooltip: 'Debug info',
              child: const Icon(Icons.info_outline),
              onPressed: () {
                // ... (Keep debug logic)
              },
            )
          : null,
      body: SafeArea(
        child: Row(
          children: [
            _buildSidebar(
              showLogout: !isSmallScreen,
              showImpersonation: !isSmallScreen,
            ),
            Expanded(child: _buildContent(isSmallScreen)),
          ],
        ),
      ),
    );
  }

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
          final horizontalPadding = screenWidth > 1400
              ? 72.0
              : (screenWidth > 1000 ? 48.0 : 24.0);

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DashboardHeader(
                    userName: _authService.currentUser?.name ?? 'Welcome back',
                    organizationName:
                        _authService.selectedOrganization?.name ?? '',
                    metrics: _metrics!,
                  ),
                  const SizedBox(height: 32),

                  // Role-based dashboard per ARCHITECTURE_PATTERNS.md
                  _buildRoleBasedDashboard(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Build role-based dashboard per ARCHITECTURE_PATTERNS.md
  Widget _buildRoleBasedDashboard() {
    final userRole = (_authService.currentUser?.role ?? 'AGENT').toUpperCase();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Admin Dashboard (only visible to admins)
        AdminOnly(
          child: Column(
            children: [
              _buildAdminDashboard(),
              const SizedBox(height: 48),
            ],
          ),
        ),
        
        // Manager Dashboard (visible to managers and below)
        if (userRole == 'MANAGER')
          _buildManagerDashboard()
        else if (userRole == 'AGENT' || userRole != 'ADMIN')
          _buildAgentDashboard(),
      ],
    );
  }

  Widget _buildAgentDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPI Cards (max 5 per ARCHITECTURE_PATTERNS.md)
        Wrap(
          alignment: WrapAlignment.start,
          runAlignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: 20,
          runSpacing: 20,
          children: [
            SizedBox(
              width: 240,
              child: KpiCard(
                title: 'My Open Tickets',
                value: _metrics!.openTickets.toString(),
                icon: Icons.confirmation_number_outlined,
                color: Colors.blue[600]!,
                onTap: () => AppRouter.navigateTo(
                  context,
                  '${AppRouter.tickets}?status=OPEN',
                ),
              ),
            ),
            SizedBox(
              width: 240,
              child: KpiCard(
                title: 'Overdue Tasks',
                value: _metrics!.overdueTasks.toString(),
                icon: Icons.warning_amber_rounded,
                color: Colors.red[600]!,
                onTap: () => AppRouter.navigateTo(
                  context,
                  '${AppRouter.tasks}?overdue=true',
                ),
              ),
            ),
            SizedBox(
              width: 240,
              child: KpiCard(
                title: 'Pending Tasks',
                value: _metrics!.pendingTasks.toString(),
                icon: Icons.schedule,
                color: Colors.orange[600]!,
                onTap: () => AppRouter.navigateTo(
                  context,
                  AppRouter.tasks,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        
        // My Tickets Queue (read-only, clickable)
        FutureBuilder<List<WorkQueueItem>>(
          future: _dashboardService.getMyWork().then((r) {
            if (kDebugMode && !r.isSuccess) {
              print('❌ My Work Error: ${r.error.message}');
            }
            return r.isSuccess ? r.value : <WorkQueueItem>[];
          }),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ErrorView(
                message: 'Failed to load work items: ${snapshot.error}',
                onRetry: () => setState(() {}),
              );
            }
            return WorkQueueWidget(
              items: snapshot.data ?? [],
              title: 'My Tickets',
              emptyMessage: 'No tickets assigned to you 🎉',
            );
          },
        ),
        const SizedBox(height: 24),
        
        // Upcoming Tasks + Recent Activity
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 900) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: _dashboardService.getUpcomingTasks().then((r) {
                        if (kDebugMode && !r.isSuccess) {
                          print('❌ Upcoming Tasks Error: ${r.error.message}');
                        }
                        return r.isSuccess ? Map<String, dynamic>.from(r.value) : {};
                      }),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        final data = snapshot.data!;
                        final tasks = (data['tasks'] as List<dynamic>?)
                            ?.map((t) => TaskItem.fromJson(t))
                            .toList() ?? [];
                        return UpcomingTasksWidget(tasks: tasks);
                      },
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: RecentActivityWidget(
                      activities: _metrics!.recentActivities,
                      maxItems: 8,
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                FutureBuilder<Map<String, dynamic>>(
                  future: _dashboardService.getUpcomingTasks().then((r) {
                    if (kDebugMode && !r.isSuccess) {
                      print('❌ Upcoming Tasks Error: ${r.error.message}');
                    }
                    return r.isSuccess ? Map<String, dynamic>.from(r.value) : {};
                  }),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final data = snapshot.data!;
                    final tasks = (data['tasks'] as List<dynamic>?)
                        ?.map((t) => TaskItem.fromJson(t))
                        .toList() ?? [];
                    return UpcomingTasksWidget(tasks: tasks);
                  },
                ),
                const SizedBox(height: 16),
                RecentActivityWidget(
                  activities: _metrics!.recentActivities,
                  maxItems: 8,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildManagerDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Manager KPI Cards
        Wrap(
          alignment: WrapAlignment.start,
          runAlignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: 20,
          runSpacing: 20,
          children: [
            SizedBox(
              width: 240,
              child: KpiCard(
                title: 'Open Tickets (Org)',
                value: _metrics!.openTickets.toString(),
                icon: Icons.confirmation_number_outlined,
                color: Colors.blue[600]!,
                onTap: () => AppRouter.navigateTo(context, AppRouter.tickets),
              ),
            ),
            SizedBox(
              width: 240,
              child: KpiCard(
                title: 'Overdue Tickets',
                value: _metrics!.overdueTickets.toString(),
                icon: Icons.warning_amber_rounded,
                color: Colors.red[600]!,
                trend: '+${_metrics!.overdueTickets}',
                trendIsPositive: false,
                onTap: () => AppRouter.navigateTo(
                  context,
                  AppRouter.tickets,
                ),
              ),
            ),
            SizedBox(
              width: 240,
              child: KpiCard(
                title: 'Active Leads',
                value: _metrics!.totalLeads.toString(),
                icon: Icons.bolt_rounded,
                color: Colors.amber[700]!,
                onTap: () => AppRouter.navigateTo(context, AppRouter.leads),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        
        // Team Work Queue (Manager+)
        FutureBuilder<Map<String, dynamic>>(
          future: _dashboardService.getTeamWork().then((r) {
            if (kDebugMode && !r.isSuccess) {
              print('❌ Team Work Error: ${r.error.message}');
            }
            return r.isSuccess ? Map<String, dynamic>.from(r.value) : {};
          }),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ErrorView(
                message: 'Failed to load team work: ${snapshot.error}',
                onRetry: () => setState(() {}),
              );
            }
            final data = snapshot.data ?? {};
            final unassigned = (data['unassigned'] as List<dynamic>?)
                ?.map((item) => WorkQueueItem.fromJson(item))
                .toList() ?? [];
            return WorkQueueWidget(
              items: unassigned,
              title: 'Unassigned / At Risk',
              emptyMessage: 'All items are assigned ✓',
            );
          },
        ),
        const SizedBox(height: 24),
        
        // Recent Activity
        RecentActivityWidget(
          activities: _metrics!.recentActivities,
          maxItems: 10,
        ),
      ],
    );
  }

  Widget _buildAdminDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Admin KPI Cards - System Health
        Wrap(
          alignment: WrapAlignment.start,
          runAlignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: 20,
          runSpacing: 20,
          children: [
            SizedBox(
              width: 240,
              child: KpiCard(
                title: 'Active Users',
                value: _metrics!.activeUsersThisWeek.toString(),
                icon: Icons.people_alt_rounded,
                color: Colors.indigo[600]!,
                onTap: () => AppRouter.navigateTo(context, AppRouter.adminUsers),
              ),
            ),
            SizedBox(
              width: 240,
              child: KpiCard(
                title: 'Accounts',
                value: _metrics!.totalAccounts.toString(),
                icon: Icons.business_outlined,
                color: Colors.teal[600]!,
                onTap: () => AppRouter.navigateTo(context, AppRouter.accounts),
              ),
            ),
            SizedBox(
              width: 240,
              child: KpiCard(
                title: 'Total Tickets',
                value: _metrics!.totalTickets.toString(),
                icon: Icons.confirmation_number_outlined,
                color: Colors.blue[600]!,
                onTap: () => AppRouter.navigateTo(context, AppRouter.tickets),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSidebar({
    required bool showLogout,
    required bool showImpersonation,
  }) {
    final items = <Widget>[
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[800]!, Colors.blue[600]!],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.dashboard_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'CRM Dashboard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
      const SizedBox(height: 40),
      
      // 🔹 WORKSPACE SECTION
      Padding(
        padding: const EdgeInsets.only(left: 12, bottom: 8, top: 8),
        child: Text(
          'WORKSPACE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
      ),
      _SidebarItem(
        icon: Icons.grid_view_rounded,
        label: 'Overview',
        isSelected: true,
        onTap: () {},
      ),
      _SidebarItem(
        icon: Icons.trending_up_rounded,
        label: 'Leads',
        onTap: () => AppRouter.navigateTo(context, AppRouter.leads),
      ),
      _SidebarItem(
        icon: Icons.business_outlined,
        label: 'Accounts',
        onTap: () => AppRouter.navigateTo(context, AppRouter.accounts),
      ),
      _SidebarItem(
        icon: Icons.confirmation_number_outlined,
        label: 'Tickets',
        onTap: () => AppRouter.navigateTo(context, AppRouter.tickets),
      ),
      _SidebarItem(
        icon: Icons.task_outlined,
        label: 'Tasks',
        onTap: () => AppRouter.navigateTo(context, AppRouter.tasks),
      ),
      
      const SizedBox(height: 16),
      
      // 🔹 ADMIN SECTION (Admin only)
      AdminOnly(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 8),
              child: Text(
                'ADMIN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              childrenPadding: EdgeInsets.zero,
              initiallyExpanded: _adminExpanded,
              onExpansionChanged: (v) => setState(() => _adminExpanded = v),
              shape: const Border(),
              leading: const Icon(Icons.shield_outlined, size: 20),
              title: const Text('System', style: TextStyle(fontSize: 14)),
              children: [
                _SidebarSubItem(
                  label: 'Users',
                  onTap: () => AppRouter.navigateTo(context, AppRouter.adminUsers),
                ),
                _SidebarSubItem(
                  label: 'Roles',
                  onTap: () => AppRouter.navigateTo(context, AppRouter.adminRoles),
                ),
                _SidebarSubItem(
                  label: 'Domain Mappings',
                  onTap: () =>
                      AppRouter.navigateTo(context, AppRouter.adminDomainMappings),
                ),
                _SidebarSubItem(
                  label: 'Activity Logs',
                  onTap: () =>
                      AppRouter.navigateTo(context, AppRouter.activityLogs),
                ),
              ],
            ),
          ],
        ),
      ),
      const Spacer(),
      if (showLogout)
        ListTile(
          leading: const Icon(Icons.logout, size: 20, color: Colors.grey),
          title: const Text(
            'Logout',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          onTap: () async {
            await _authService.logout();
            if (mounted) AppRouter.replaceWith(context, AppRouter.login);
          },
        ),
    ];

    return Container(
      width: 250,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items,
      ),
    );
  }
}

/// 1. Header Dashboard
class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.userName,
    required this.organizationName,
    required this.metrics,
  });

  final String userName;
  final String organizationName;
  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E293B),
            Color(0xFF334155),
          ], // Slate 800 -> Slate 700
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $userName',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Chữ trắng trên nền tối
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  organizationName.isNotEmpty
                      ? 'Here’s what’s happening in $organizationName today.'
                      : 'Overview of your business performance.',
                  style: TextStyle(color: Colors.blueGrey[100], fontSize: 15),
                ),
                const SizedBox(height: 24),
                // Chips thông số nhanh
                Row(
                  children: [
                    _HeaderMetricChip(
                      label: 'Total Users',
                      value: metrics.totalUsers.toString(),
                      icon: Icons.people,
                    ),
                    const SizedBox(width: 12),
                    _HeaderMetricChip(
                      label: 'Accounts',
                      value: metrics.totalAccounts.toString(),
                      icon: Icons.business_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Hình minh họa (Placeholder icon)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              size: 64,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderMetricChip extends StatelessWidget {
  const _HeaderMetricChip({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: Colors.blueGrey[100], fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Helper sidebar sub-item
class _SidebarSubItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SidebarSubItem({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 54),
      dense: true,
      title: Text(
        label,
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
      onTap: onTap,
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tileColor: isSelected ? const Color(0xFFEFF6FF) : null, // Xanh rất nhạt
        leading: Icon(
          icon,
          color: isSelected ? Colors.blue[700] : Colors.blueGrey[400],
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blue[700] : Colors.blueGrey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
