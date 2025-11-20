import 'package:flutter/material.dart';

import '../../navigation/app_router.dart';
import '../dashboard/sidebar.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({
    super.key,
    required this.title,
    required this.child,
    required this.selectedMenu, // 'dashboard' | 'contacts' | 'tasks' | 'tickets'
    this.actions,
  });

  final String title;
  final Widget child;
  final String selectedMenu;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        if (isWide) {
          // Desktop / tablet ngang: sidebar cố định
          return Scaffold(
            backgroundColor: const Color(0xFFF5F5FA),
            body: Row(
              children: [
                DashboardSidebar(
                  selectedMenu: selectedMenu,
                  onLogout: () {
                    AppRouter.replaceWith(context, AppRouter.login);
                  },
                ),
                Expanded(
                  child: Column(
                    children: [
                      _buildAppBar(context),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          // Mobile / tablet dọc: dùng drawer
          return Scaffold(
            backgroundColor: const Color(0xFFF5F5FA),
            appBar: AppBar(
              elevation: 0,
              title: Text(title),
              actions: actions,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
            drawer: Drawer(
              child: SafeArea(
                child: DashboardSidebar(
                  selectedMenu: selectedMenu,
                  onLogout: () {
                    AppRouter.replaceWith(context, AppRouter.login);
                  },
                ),
              ),
            ),
            body: child,
          );
        }
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 24, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 20),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey.shade200,
                    child: const Icon(
                      Icons.person,
                      color: Colors.black54,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'User Name',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              ...?actions,
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
