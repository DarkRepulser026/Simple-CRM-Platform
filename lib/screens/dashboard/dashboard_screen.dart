import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:fl_chart/fl_chart.dart';

import '../../models/dashboard_metrics.dart';
import '../../services/auth/auth_service.dart';
import '../../services/service_locator.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../navigation/app_router.dart';

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF020617)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.98),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 36,
                    offset: const Offset(0, 22),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildSidebar(
                    showLogout: !isSmallScreen,
                    showImpersonation: !isSmallScreen,
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: _buildContent(isSmallScreen)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- CONTENT ----------

  Widget _buildContent(bool isSmallScreen) {
    if (_isLoading) {
      return const LoadingView(message: 'Loading dashboard...');
    }

    if (_errorMessage != null) {
      return ErrorView(
        message: _errorMessage!,
        onRetry: _loadDashboard,
      );
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
              ? 56.0
              : screenWidth > 1000
                  ? 40.0
                  : 24.0;
          final theme = Theme.of(context);

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
                  // HEADER
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildHeaderText(theme)),
                      const SizedBox(width: 16),
                      if (isSmallScreen) _buildSmallHeaderActions(),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // HIGHLIGHT STRIP
                  _buildHighlightStrip(theme),

                  const SizedBox(height: 28),

                  // ROW 1: TOP KPI
                  _buildTopOverviewRow(),

                  const SizedBox(height: 28),

                  // ROW 2: 2 CHART PANELS
                  _buildMiddleChartsRow(),

                  const SizedBox(height: 32),

                  // QUICK ACTIONS
                  _buildQuickActions(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderText(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF).withOpacity(0.9),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color(0xFFCBD5F5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Live overview',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF4F46E5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (_authService.hasSelectedOrganization)
              Text(
                'Org: ${_authService.selectedOrganizationId}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Welcome back 👋',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Here’s what’s happening across your customers, pipeline and support today.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (kDebugMode) ...[
          const SizedBox(height: 8),
          Text(
            'Debug · Auth=${_authService.isLoggedIn ? 'yes' : 'no'} · '
            'Org=${_authService.selectedOrganizationId ?? 'none'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color:
                  theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSmallHeaderActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_authService.isImpersonating)
          IconButton(
            onPressed: () async {
              final ok = await _authService.stopImpersonation();
              if (mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stopped impersonation')),
                );
                await _loadDashboard();
              }
            },
            icon: const Icon(Icons.person_off),
            tooltip: 'Stop impersonation',
          ),
        IconButton(
          onPressed: () async {
            await _authService.logout();
            if (mounted) {
              AppRouter.replaceWith(context, AppRouter.login);
            }
          },
          icon: const Icon(Icons.logout),
        ),
      ],
    );
  }

  Widget _buildHighlightStrip(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bolt,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You have ${_metrics!.pendingTasks} pending tasks and '
              '${_metrics!.openTickets} active tickets to follow up.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- LAYOUT ROWS ----------

  Widget _buildTopOverviewRow() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _CompactMetricCard(
          title: 'Revenue',
          value: '\$${_metrics!.opportunityRevenue.toStringAsFixed(0)}',
          icon: Icons.attach_money,
          color: const Color(0xFFA855F7),
        ),
        _CompactMetricCard(
          title: 'Contacts',
          value: _metrics!.totalContacts.toString(),
          icon: Icons.people,
          color: const Color(0xFF2563EB),
        ),
        _CompactMetricCard(
          title: 'Leads',
          value: _metrics!.totalLeads.toString(),
          icon: Icons.trending_up,
          color: const Color(0xFF22C55E),
        ),
        _CompactMetricCard(
          title: 'Opportunities',
          value: _metrics!.totalOpportunities.toString(),
          icon: Icons.business_center,
          color: const Color(0xFFF97316),
        ),
      ],
    );
  }

  Widget _buildMiddleChartsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;

        if (isNarrow) {
          return Column(
            children: [
              _DashboardPanel(
                title: 'Support health',
                subtitle: 'Tickets status & SLA',
                child: _SupportHealthChart(metrics: _metrics!),
              ),
              const SizedBox(height: 16),
              _DashboardPanel(
                title: 'Customer satisfaction',
                subtitle: 'CSAT · NPS · SLA',
                child: _SatisfactionChart(metrics: _metrics!),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _DashboardPanel(
                title: 'Support health',
                subtitle: 'Tickets status & SLA',
                child: _SupportHealthChart(metrics: _metrics!),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _DashboardPanel(
                title: 'Customer satisfaction',
                subtitle: 'CSAT · NPS · SLA',
                child: _SatisfactionChart(metrics: _metrics!),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------- QUICK ACTIONS ----------

  Widget _buildQuickActions() {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick actions',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Jump straight into the areas you work with the most.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _QuickActionCard(
                title: 'Create Ticket',
                subtitle: 'Open a new customer support ticket',
                icon: Icons.add_circle_outline,
                color: theme.colorScheme.primary,
                onTap: () =>
                    AppRouter.navigateTo(context, AppRouter.ticketCreate),
              ),
              _QuickActionCard(
                title: 'View Tickets',
                subtitle: 'Browse and manage all tickets',
                icon: Icons.list_alt,
                color: theme.colorScheme.secondary,
                onTap: () =>
                    AppRouter.navigateTo(context, AppRouter.tickets),
              ),
              _QuickActionCard(
                title: 'Customer Interactions',
                subtitle: 'Log and track customer interactions',
                icon: Icons.people_outline,
                color: theme.colorScheme.tertiary,
                onTap: () =>
                    AppRouter.navigateTo(context, AppRouter.interactions),
              ),
              _QuickActionCard(
                title: 'View Reports',
                subtitle: 'Generate performance reports',
                icon: Icons.analytics_outlined,
                color: theme.colorScheme.error,
                onTap: () =>
                    AppRouter.navigateTo(context, AppRouter.dashboard),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- SIDEBAR ----------

  Widget _buildSidebar({
    required bool showLogout,
    required bool showImpersonation,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.96),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          bottomLeft: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo + app name
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF22C55E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.dashboard_customize,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CRM Project',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Control center',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          Text(
            'MAIN',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              color:
                  theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),

          _SidebarItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            isSelected: true,
            onTap: () {},
          ),
          _SidebarItem(
            icon: Icons.people_outline,
            label: 'Contacts',
            onTap: () =>
                AppRouter.navigateTo(context, AppRouter.contacts),
          ),
          _SidebarItem(
            icon: Icons.task_outlined,
            label: 'Tasks',
            onTap: () => AppRouter.navigateTo(context, AppRouter.tasks),
          ),
          _SidebarItem(
            icon: Icons.support_agent_outlined,
            label: 'Tickets',
            onTap: () =>
                AppRouter.navigateTo(context, AppRouter.tickets),
          ),

          const SizedBox(height: 24),

          Text(
            'MANAGEMENT',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              color:
                  theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),

          _SidebarItem(
            icon: Icons.business,
            label: 'Organizations',
            onTap: () =>
                AppRouter.navigateTo(context, AppRouter.organizations),
          ),
          _SidebarItem(
            icon: Icons.account_balance,
            label: 'Accounts',
            onTap: () =>
                AppRouter.navigateTo(context, AppRouter.accounts),
          ),
          _SidebarItem(
            icon: Icons.history,
            label: 'Activity Logs',
            onTap: () =>
                AppRouter.navigateTo(context, AppRouter.activityLogs),
          ),

          const Spacer(),

          if (showImpersonation && _authService.isImpersonating)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.secondary,
                  side: BorderSide(
                    color: theme.colorScheme.secondary.withOpacity(0.5),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: () async {
                  final ok = await _authService.stopImpersonation();
                  if (mounted && ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Stopped impersonation')),
                    );
                    await _loadDashboard();
                  }
                },
                icon: const Icon(Icons.person_off, size: 16),
                label: const Text('Stop impersonating'),
              ),
            ),

          if (showLogout)
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () async {
                  await _authService.logout();
                  if (mounted) {
                    AppRouter.replaceWith(context, AppRouter.login);
                  }
                },
                icon: const Icon(Icons.logout, size: 16),
                label: const Text('Logout'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------- SMALL WIDGETS ----------

class _DashboardPanel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _DashboardPanel({
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
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

/// Quick action card widget for web dashboard
class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color; // màu accent
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 260,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.98),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon trong ô bo góc
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 22,
                color: color,
              ),
            ),
            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Mũi tên bên phải
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
          ],
        ),
      ),
    );
  }
}
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
