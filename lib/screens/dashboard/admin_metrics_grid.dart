// import 'package:flutter/material.dart';
// import '../../models/dashboard_metrics.dart';
// import '../../navigation/app_router.dart';
// // service imports removed; use AdminOnly wrapper widget from role_visibility.dart
// import '../../widgets/role_visibility.dart';

// class AdminMetricsGrid extends StatelessWidget {
//   final DashboardMetrics metrics;
//   const AdminMetricsGrid({super.key, required this.metrics});

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: double.infinity,
//       child: Container(
//         padding: const EdgeInsets.all(24),
//         decoration: BoxDecoration(
//           color: Theme.of(context).colorScheme.surface,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Admin Metrics', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
//             const SizedBox(height: 16),
//             Wrap(spacing: 16, runSpacing: 16, children: [
//               _MetricCard(title: 'Total Users', value: metrics.totalUsers.toString(), icon: Icons.people, color: Colors.indigo),
//               _MetricCard(title: 'Total Orgs', value: metrics.totalOrganizations.toString(), icon: Icons.business, color: Colors.teal),
//               _MetricCard(title: 'System Health', value: metrics.systemHealth, icon: Icons.health_and_safety, color: metrics.systemHealth == 'ok' ? Colors.green : Colors.orange),
//               _MetricCard(title: 'Ticket Load', value: metrics.ticketLoad.toStringAsFixed(1), icon: Icons.work_outline, color: Colors.blueGrey),
//               _MetricCard(title: 'Active Users (7d)', value: metrics.activeUsersThisWeek.toString(), icon: Icons.timeline, color: Colors.deepPurple),
//               // Admin action cards
//               AdminOnly(child: Wrap(spacing: 16, runSpacing: 16, children: [
//                 _ActionCard(title: 'Manage Users', subtitle: 'Add/Edit/Remove users', icon: Icons.manage_accounts, color: Colors.indigo, route: AppRouter.adminUsers),
//                 _ActionCard(title: 'Role Settings', subtitle: 'Edit roles & permissions', icon: Icons.security, color: Colors.orange, route: AppRouter.adminRoles),
//               ])),
//             ]),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _ActionCard extends StatelessWidget {
//   const _ActionCard({required this.title, required this.subtitle, required this.icon, required this.color, required this.route});
//   final String title;
//   final String subtitle;
//   final IconData icon;
//   final Color color;
//   final String route;
//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: () => AppRouter.navigateTo(context, route),
//       child: Container(
//         width: 200,
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Theme.of(context).colorScheme.surface,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
//         ),
//         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Row(children: [
//             Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color)),
//             const SizedBox(width: 12),
//             Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)), const SizedBox(height: 6), Text(subtitle, style: Theme.of(context).textTheme.bodySmall)])),
//           ]),
//         ]),
//       ),
//     );
//   }
// }


// class _MetricCard extends StatelessWidget {
//   const _MetricCard({required this.title, required this.value, required this.icon, required this.color});
//   final String title;
//   final String value;
//   final IconData icon;
//   final Color color;
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 200,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.surface,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
//       ),
//       child: Row(children: [
//         Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 24, color: color)),
//         const SizedBox(width: 16),
//         Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text(title, style: Theme.of(context).textTheme.bodyMedium)])),
//       ]),
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../../models/dashboard_metrics.dart';
import '../../navigation/app_router.dart';
import '../../widgets/role_visibility.dart';

class AdminMetricsGrid extends StatelessWidget {
  final DashboardMetrics metrics;
  const AdminMetricsGrid({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Admin Metrics',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Overview',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ===== METRIC CARDS =====
            Wrap(
              alignment: WrapAlignment.start,
              spacing: 20,
              runSpacing: 20,
              children: [
                _MetricCard(
                  title: 'Total Users',
                  value: metrics.totalUsers.toString(),
                  icon: Icons.people,
                  color: Colors.indigo,
                ),
                _MetricCard(
                  title: 'Total Orgs',
                  value: metrics.totalOrganizations.toString(),
                  icon: Icons.business,
                  color: Colors.teal,
                ),
                _MetricCard(
                  title: 'System Health',
                  value: metrics.systemHealth,
                  icon: Icons.health_and_safety_rounded,
                  color: Colors.green,
                ),
                _MetricCard(
                  title: 'Ticket Load',
                  value: metrics.ticketLoad.toStringAsFixed(1),
                  icon: Icons.work_outline,
                  color: Colors.blueGrey,
                ),
                _MetricCard(
                  title: 'Active Users (7d)',
                  value: metrics.activeUsersThisWeek.toString(),
                  icon: Icons.show_chart,
                  color: Colors.deepPurple,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ===== ACTION CARDS =====
            AdminOnly(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    color: colorScheme.outline.withOpacity(0.15),
                    height: 1,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.start,
                    spacing: 20,
                    runSpacing: 16,
                    children: const [
                      _ActionCard(
                        title: 'Manage Users',
                        subtitle: 'Add / Edit / Remove users',
                        icon: Icons.manage_accounts,
                        color: Colors.indigo,
                        route: AppRouter.adminUsers,
                      ),
                      _ActionCard(
                        title: 'Role Settings',
                        subtitle: 'Edit roles & permissions',
                        icon: Icons.admin_panel_settings,
                        color: Colors.orange,
                        route: AppRouter.adminRoles,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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
    final colorScheme = theme.colorScheme;

    return Container(
      width: 210,
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, 
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}


class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => AppRouter.navigateTo(context, route),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.12),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 24,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
