import 'package:flutter/material.dart';
import '../../models/dashboard_metrics.dart';
import '../../services/auth/auth_service.dart';
import '../../services/auth/auth_service_mock.dart';
import '../../services/storage/secure_storage.dart';
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

  bool _isLoading = true;
  String? _errorMessage;
  DashboardMetrics? _metrics;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final storage = await SecureStorage.create();
    _authService = AuthServiceMock(storage);
    await _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Implement dashboard service call
      // For now, create mock data
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      setState(() {
        _metrics = const DashboardMetrics(
          totalContacts: 1250,
          totalLeads: 89,
          totalOpportunities: 45,
          totalAccounts: 12,
          pendingTasks: 34,
          opportunityRevenue: 456780.50,
          totalTickets: 156,
          openTickets: 42,
          pendingTickets: 18,
          resolvedTickets: 89,
          overdueTickets: 7,
          ticketsByStatus: {
            'Open': 42,
            'Pending': 18,
            'In Progress': 15,
            'Resolved': 89,
            'Closed': 10,
          },
          ticketsByAgent: {
            'agent1': 25,
            'agent2': 32,
            'agent3': 28,
            'agent4': 19,
          },
          ticketsByPriority: {
            'Low': 45,
            'Normal': 67,
            'High': 32,
            'Urgent': 8,
            'Critical': 4,
          },
          averageCsat: 4.2,
          averageNps: 35.5,
          totalSatisfactionResponses: 89,
          averageFirstResponseTime: 2.3,
          averageResolutionTime: 18.5,
          averageResponseTime: 1.8,
          slaComplianceRate: 87.3,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load dashboard: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
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
      ),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
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
      return const Center(
        child: Text('No data available'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate responsive padding based on screen width
          final screenWidth = constraints.maxWidth;
          final horizontalPadding = screenWidth > 1200
              ? 64.0 // Large screens
              : screenWidth > 800
                  ? 48.0 // Medium screens
                  : 24.0; // Small screens

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome header
                  Text(
                    'Welcome back!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Here\'s your business overview',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Metrics cards
                  _buildMetricsGrid(),

                  const SizedBox(height: 48),

                  // Quick actions
                  _buildQuickActions(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Metrics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            // Business Overview Row
            _buildMetricRow(
              'Business Overview',
              [
                _CompactMetricCard(
                  title: 'Contacts',
                  value: _metrics!.totalContacts.toString(),
                  icon: Icons.people,
                  color: Colors.blue,
                ),
                _CompactMetricCard(
                  title: 'Leads',
                  value: _metrics!.totalLeads.toString(),
                  icon: Icons.trending_up,
                  color: Colors.green,
                ),
                _CompactMetricCard(
                  title: 'Opportunities',
                  value: _metrics!.totalOpportunities.toString(),
                  icon: Icons.business_center,
                  color: Colors.orange,
                ),
                _CompactMetricCard(
                  title: 'Revenue',
                  value: '\$${_metrics!.opportunityRevenue.toStringAsFixed(0)}',
                  icon: Icons.attach_money,
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Task Management Row
            _buildMetricRow(
              'Task Management',
              [
                _CompactMetricCard(
                  title: 'Pending Tasks',
                  value: _metrics!.pendingTasks.toString(),
                  icon: Icons.pending_actions,
                  color: Colors.red,
                ),
                _CompactMetricCard(
                  title: 'Accounts',
                  value: _metrics!.totalAccounts.toString(),
                  icon: Icons.account_balance,
                  color: Colors.teal,
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Customer Service Row
            _buildMetricRow(
              'Customer Service',
              [
                _CompactMetricCard(
                  title: 'CSAT Score',
                  value: _metrics!.averageCsat.toStringAsFixed(1),
                  icon: Icons.star_rate,
                  color: Colors.blueGrey,
                ),
                _CompactMetricCard(
                  title: 'NPS Score',
                  value: _metrics!.averageNps.toStringAsFixed(1),
                  icon: Icons.thumb_up,
                  color: Colors.lightGreen,
                ),
                _CompactMetricCard(
                  title: 'SLA Compliance',
                  value: '${_metrics!.slaComplianceRate.toStringAsFixed(1)}%',
                  icon: Icons.access_time,
                  color: Colors.redAccent,
                ),
                _CompactMetricCard(
                  title: 'Avg Response',
                  value: '${_metrics!.averageResponseTime.toStringAsFixed(1)}h',
                  icon: Icons.timer,
                  color: Colors.cyan,
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Performance Row
            _buildMetricRow(
              'Performance',
              [
                _CompactMetricCard(
                  title: 'First Response',
                  value: '${_metrics!.averageFirstResponseTime.toStringAsFixed(1)}h',
                  icon: Icons.schedule,
                  color: Colors.indigo,
                ),
                _CompactMetricCard(
                  title: 'Resolution Time',
                  value: '${_metrics!.averageResolutionTime.toStringAsFixed(1)}h',
                  icon: Icons.done_all,
                  color: Colors.deepOrange,
                ),
                _CompactMetricCard(
                  title: 'Total Tickets',
                  value: _metrics!.totalTickets.toString(),
                  icon: Icons.confirmation_number,
                  color: Colors.brown,
                ),
                _CompactMetricCard(
                  title: 'Active Tickets',
                  value: _metrics!.openTickets.toString(),
                  icon: Icons.pending,
                  color: Colors.pink,
                ),
              ],
            ),
          ],
        ),
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

  Widget _buildQuickActions() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _QuickActionCard(
                title: 'Create Ticket',
                subtitle: 'Open a new customer support ticket',
                icon: Icons.add_circle_outline,
                color: Theme.of(context).colorScheme.primary,
                onTap: () => AppRouter.navigateTo(context, AppRouter.ticketCreate),
              ),
              _QuickActionCard(
                title: 'View Tickets',
                subtitle: 'Browse and manage all tickets',
                icon: Icons.list_alt,
                color: Theme.of(context).colorScheme.secondary,
                onTap: () => AppRouter.navigateTo(context, AppRouter.tickets),
              ),
              _QuickActionCard(
                title: 'Customer Interactions',
                subtitle: 'Log and track customer interactions',
                icon: Icons.people_outline,
                color: Theme.of(context).colorScheme.tertiary,
                onTap: () => AppRouter.navigateTo(context, AppRouter.contacts), // TODO: Create interactions screen
              ),
              _QuickActionCard(
                title: 'View Reports',
                subtitle: 'Generate performance reports',
                icon: Icons.analytics_outlined,
                color: Theme.of(context).colorScheme.error,
                onTap: () => AppRouter.navigateTo(context, AppRouter.dashboard), // TODO: Create reports screen
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo and app name
          Row(
            children: [
              Icon(
                Icons.dashboard,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Dashboard',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Navigation items
          _SidebarItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            isSelected: true,
            onTap: () {
              // Already on Dashboard
            },
          ),
          _SidebarItem(
            icon: Icons.people_outline,
            label: 'Contacts',
            onTap: () => AppRouter.navigateTo(context, AppRouter.contacts),
          ),
          _SidebarItem(
            icon: Icons.task_outlined,
            label: 'Tasks',
            onTap: () => AppRouter.navigateTo(context, AppRouter.tasks),
          ),
          _SidebarItem(
            icon: Icons.support_agent_outlined,
            label: 'Tickets',
            onTap: () => AppRouter.navigateTo(context, AppRouter.tickets),
          ),
          const Spacer(),
          // Logout button
          TextButton.icon(
            onPressed: () async {
              await _authService.logout();
              if (mounted) {
                AppRouter.replaceWith(context, AppRouter.login);
              }
            },
            icon: const Icon(Icons.logout, size: 16),
            label: const Text('Logout'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
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
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 24,
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
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
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 24,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}