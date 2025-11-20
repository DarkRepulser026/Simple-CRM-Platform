import 'package:flutter/material.dart';
import '../../navigation/app_router.dart';

class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({
    super.key,
    required this.onLogout,
    this.selectedMenu = 'dashboard', // 'dashboard' | 'contacts' | 'tasks' | 'tickets'
  });

  final VoidCallback onLogout;
  final String selectedMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 230,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(2, 0),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo + app name
          Row(
            children: [
              Icon(Icons.dashboard, color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Dashboard',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          _menuItem(
            context,
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            selected: selectedMenu == 'dashboard',
            onTap: () => AppRouter.navigateTo(context, AppRouter.dashboard),
          ),
          _menuItem(
            context,
            icon: Icons.people_outline,
            label: 'Contacts',
            selected: selectedMenu == 'contacts',
            onTap: () => AppRouter.navigateTo(context, AppRouter.contacts),
          ),
          _menuItem(
            context,
            icon: Icons.task_outlined,
            label: 'Tasks',
            selected: selectedMenu == 'tasks',
            onTap: () => AppRouter.navigateTo(context, AppRouter.tasks),
          ),
          _menuItem(
            context,
            icon: Icons.support_agent_outlined,
            label: 'Tickets',
            selected: selectedMenu == 'tickets',
            onTap: () => AppRouter.navigateTo(context, AppRouter.tickets),
          ),

          const Spacer(),
          const Divider(height: 32),

          // Logout đẹp hơn
          Text(
            'Account',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                side: BorderSide(
                  color: theme.colorScheme.error.withOpacity(0.4),
                ),
                foregroundColor: theme.colorScheme.error,
                backgroundColor: theme.colorScheme.error.withOpacity(0.05),
                textStyle: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
