import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/company_selection_screen.dart';
import '../screens/auth/invite_accept_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/organizations/organizations_list_screen.dart';
import '../screens/contacts/contacts_list_screen.dart';
import '../screens/contacts/contact_create_screen.dart';
import '../screens/contacts/contact_detail_screen.dart';
import '../screens/contacts/contact_edit_screen.dart';
import '../screens/accounts/accounts_list_screen.dart';
import '../screens/accounts/account_create_screen.dart';
import '../screens/accounts/account_edit_screen.dart';
import '../screens/accounts/account_detail_screen.dart';
import '../screens/leads/leads_list_screen.dart';
import '../screens/leads/lead_create_screen.dart';
import '../screens/leads/lead_detail_screen.dart';
import '../screens/leads/lead_edit_screen.dart';
import '../screens/admin/users_list_screen.dart';
import '../screens/admin/user_detail_screen.dart';
import '../screens/admin/user_edit_screen.dart';
import '../screens/admin/invite_user_screen.dart';
import '../screens/admin/invitations_screen.dart';
import '../screens/admin/roles_list_screen.dart';
import '../screens/admin/activity_logs_screen.dart';
import '../screens/admin/domain_mapping_screen.dart';
// unused: '../screens/access_denied_screen.dart';
import '../screens/access_denied_redirect_screen.dart';
import 'route_guards.dart';
import '../services/service_locator.dart';
import '../services/auth/auth_service.dart';
import '../screens/interactions/interactions_list_screen.dart';
import '../screens/tasks/tasks_list_screen.dart';
import '../screens/tasks/task_create_screen.dart';
import '../screens/tasks/task_detail_screen.dart';
import '../screens/tasks/task_edit_screen.dart';
import '../screens/tickets/tickets_list_screen.dart';
import '../screens/tickets/ticket_create_screen.dart';
import '../screens/tickets/ticket_detail_screen.dart';
import '../screens/tickets/ticket_edit_screen.dart';
import '../widgets/app_shell.dart';

/// ===== CUSTOM PAGE TRANSITIONS =====
/// Smooth fade transition for better UX
class FadeRoute<T> extends PageRoute<T> {
  FadeRoute({required this.builder, RouteSettings? settings})
    : super(settings: settings);

  final WidgetBuilder builder;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }
}

/// Slide transition for detail screens
class SlideRoute<T> extends PageRoute<T> {
  SlideRoute({required this.builder, RouteSettings? settings})
    : super(settings: settings);

  final WidgetBuilder builder;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 250);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;
    const curve = Curves.easeOutCubic;
    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    return SlideTransition(position: animation.drive(tween), child: child);
  }
}

/// Typed route arguments for type-safe navigation
class ContactDetailArgs {
  const ContactDetailArgs({required this.contactId});

  final String contactId;
}

class LeadDetailArgs {
  const LeadDetailArgs({required this.leadId});

  final String leadId;
}

class TaskDetailArgs {
  const TaskDetailArgs({required this.taskId});

  final String taskId;
}

class TaskEditArgs {
  const TaskEditArgs({required this.taskId});

  final String taskId;
}

class TicketCreateArgs {
  const TicketCreateArgs({this.accountId});

  final String? accountId;
}

class TicketDetailArgs {
  const TicketDetailArgs({required this.ticketId});

  final String ticketId;
}

class ActivityLogsArgs {
  const ActivityLogsArgs({
    this.entityType,
    this.entityId,
    this.userId,
    this.search,
  });
  final String? entityType;
  final String? entityId;
  final String? userId;
  final String? search;
}

class TicketEditArgs {
  const TicketEditArgs({required this.ticketId});
  final String ticketId;
}

class AccountDetailArgs {
  const AccountDetailArgs({required this.accountId});
  final String accountId;
}

class LeadEditArgs {
  const LeadEditArgs({required this.leadId});
  final String leadId;
}

class ContactEditArgs {
  const ContactEditArgs({required this.contactId});
  final String contactId;
}

/// Central route registry with typed navigation
class AppRouter {
  static const String login = '/login';
  static const String companySelection = '/company-selection';
  static const String companyCreate = '/company-create';
  static const String dashboard = '/dashboard';
  static const String about = '/about';
  static const String helpSupport = '/help-support';
  static const String contacts = '/contacts';
  static const String organizations = '/organizations';
  static const String accounts = '/accounts';
  static const String accountDetail = '/accounts/detail';
  static const String accountCreate = '/accounts/create';
  static const String accountEdit = '/accounts/edit';
  static const String leads = '/leads';
  static const String tickets = '/tickets';
  static const String contactCreate = '/contact-create';
  static const String contactDetail = '/contact-detail';
  static const String contactEdit = '/contact-edit';
  static const String leadDetail = '/lead-detail';
  static const String leadCreate = '/lead-create';
  static const String leadEdit = '/lead-edit';
  static const String ticketCreate = '/ticket-create';
  static const String ticketDetail = '/ticket-detail';
  static const String ticketEdit = '/ticket-edit';
  static const String adminUsers = '/admin/users';
  static const String adminUserDetail = '/admin/users/detail';
  static const String adminUserEdit = '/admin/users/edit';
  static const String adminInvite = '/admin/invite';
  static const String adminInvitations = '/admin/invitations';
  static const String adminRoles = '/admin/roles';
  static const String activityLogs = '/admin/activity-logs';
  static const String adminDomainMappings = '/admin/domain-mappings';
  static const String interactions = '/interactions';
  static const String tasks = '/tasks';
  static const String taskCreate = '/task-create';
  static const String taskDetail = '/task-detail';
  static const String taskEdit = '/task-edit';

  /// Navigate to a route with optional arguments
  static Future<T?> navigateTo<T>(
    BuildContext context,
    String route, {
    Object? arguments,
  }) {
    return Navigator.of(
      context,
    ).pushNamed(route, arguments: arguments).then((value) => value as T?);
  }

  /// Replace current route with smooth fade transition
  static Future<T?> replaceWith<T>(
    BuildContext context,
    String route, {
    Object? arguments,
  }) {
    return Navigator.of(context)
        .pushReplacementNamed(route, arguments: arguments)
        .then((result) => result as T?);
  }

  /// Pop current route
  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop(result);
  }

  /// Pop until root
  static void popToRoot(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Wrap a screen with AppShell for breadcrumb support
  static Widget _withAppShell(Widget screen) {
    return AppShell(child: screen);
  }

  /// Wrap a SlideRoute builder with AppShell
  static SlideRoute<T> _slideWithAppShell<T>(WidgetBuilder builder) {
    return SlideRoute<T>(builder: (context) => _withAppShell(builder(context)));
  }

  /// Get route settings for MaterialApp
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginScreen(),
      companySelection: (context) => const CompanySelectionScreen(),
      '/invite/accept': (context) => const InviteAcceptScreen(),
      dashboard: (context) => _withAppShell(const DashboardScreen()),
      contacts: (context) => _withAppShell(const ContactsListScreen()),
      organizations: (context) =>
          _withAppShell(const OrganizationsListScreen()),
      accounts: (context) => _withAppShell(const AccountsListScreen()),
      accountCreate: (context) => _withAppShell(const AccountCreateScreen()),
      leads: (context) => _withAppShell(const LeadsListScreen()),
      taskCreate: (context) => _withAppShell(const TaskCreateScreen()),
      leadCreate: (context) => _withAppShell(const LeadCreateScreen()),
      tasks: (context) => _withAppShell(const TasksListScreen()),
      tickets: (context) => _withAppShell(const TicketsListScreen()),
      // ticketCreate handled in onGenerateRoute to support optional accountId
      // wrap admin routes with the route guard - these return a WidgetBuilder
      adminUsers: (context) => _withAppShell(
        managerOrAdminGuarded((c) => const UsersListScreen())(context),
      ),
      adminInvite: (context) => _withAppShell(
        managerOrAdminGuarded((c) => const InviteUserScreen())(context),
      ),
      adminRoles: (context) =>
          _withAppShell(adminGuarded((c) => const RolesListScreen())(context)),
      adminInvitations: (context) => _withAppShell(
        managerOrAdminGuarded((c) => const InvitationsScreen())(context),
      ),
      activityLogs: (context) => _withAppShell(
        adminGuarded((c) => const ActivityLogsScreen())(context),
      ),
      adminDomainMappings: (context) => _withAppShell(
        managerOrAdminGuarded((c) => const DomainMappingScreen())(context),
      ),
      interactions: (context) => _withAppShell(const InteractionsListScreen()),
      contactCreate: (context) => _withAppShell(const ContactCreateScreen()),
      // contactDetail: (context) => const ContactDetailScreen(),
      // leadCreate: (context) => const LeadCreateScreen(),
      // leadDetail: (context) => const LeadDetailScreen(),
      // taskCreate: (context) => const TaskCreateScreen(),
      // taskDetail: (context) => const TaskDetailScreen(),
      // taskEdit: (context) => const TaskEditScreen(),
    };
  }

  /// Handle onGenerateRoute for dynamic routes with arguments
  static Route<Object?>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case adminUserDetail:
        final args = settings.arguments as UserDetailArgs?;
        if (args != null) {
          if (!locator<AuthService>().isManagerOrAdmin)
            return FadeRoute<Object?>(
              builder: (context) => const AccessDeniedRedirectScreen(),
            );
          return FadeRoute<Object?>(
            builder: (context) => UserDetailScreen(userId: args.userId),
          );
        }
        break;
      case adminUserEdit:
        final editArgs = settings.arguments as UserDetailArgs?;
        if (editArgs != null) {
          if (!locator<AuthService>().isManagerOrAdmin)
            return FadeRoute<Object?>(
              builder: (context) => const AccessDeniedRedirectScreen(),
            );
          return FadeRoute<Object?>(
            builder: (context) => UserEditScreen(userId: editArgs.userId),
          );
        }
        break;
      case activityLogs:
        final args = settings.arguments as ActivityLogsArgs?;
        if (args != null) {
          if (!locator<AuthService>().isAdmin)
            return FadeRoute<Object?>(
              builder: (context) => const AccessDeniedRedirectScreen(),
            );
          return FadeRoute<Object?>(builder: (context) => ActivityLogsScreen());
        }
        break;
      case accountDetail:
        final args = settings.arguments as AccountDetailArgs?;
        if (args != null) {
          return _slideWithAppShell<Object?>(
            (context) => AccountDetailScreen(accountId: args.accountId),
          );
        }
      case accountEdit:
        final argsEdit = settings.arguments as AccountEditArgs?;
        if (argsEdit != null) {
          return _slideWithAppShell<Object?>(
            (context) => AccountEditScreen(accountId: argsEdit.accountId),
          );
        }
        break;
      case contactDetail:
        final args = settings.arguments as ContactDetailArgs?;
        if (args != null) {
          return _slideWithAppShell<Object?>(
            (context) => ContactDetailScreen(contactId: args.contactId),
          );
        }
        break;
      case contactEdit:
        final ca = settings.arguments as ContactEditArgs?;
        if (ca != null) {
          return _slideWithAppShell<Object?>(
            (context) => ContactEditScreen(contactId: ca.contactId),
          );
        }
        // If args are missing show a helpful error page instead of returning null
        return _slideWithAppShell<Object?>(
          (context) => Scaffold(
            appBar: AppBar(title: const Text('Edit contact')),
            body: Center(child: Text('Missing contact ID for edit route')),
          ),
        );
      case leadDetail:
        final args = settings.arguments as LeadDetailArgs?;
        if (args != null) {
          return _slideWithAppShell<Object?>(
            (context) => LeadDetailScreen(leadId: args.leadId),
          );
        }
        break;
      case leadEdit:
        final args = settings.arguments as LeadEditArgs?;
        if (args != null) {
          return _slideWithAppShell<Object?>(
            (context) => LeadEditScreen(leadId: args.leadId),
          );
        }
        break;
      case taskDetail:
        final args = settings.arguments as TaskDetailArgs?;
        if (args != null) {
          return _slideWithAppShell<Object?>(
            (context) => TaskDetailScreen(taskId: args.taskId),
          );
        }
        break;
      case taskEdit:
        final args = settings.arguments as TaskEditArgs?;
        if (args != null) {
          return _slideWithAppShell<Object?>(
            (context) => TaskEditScreen(taskId: args.taskId),
          );
        }
        break;
      case ticketDetail:
        final args = settings.arguments as TicketDetailArgs?;
        if (args != null) {
          return _slideWithAppShell<Object?>(
            (context) => TicketDetailScreen(ticketId: args.ticketId),
          );
        }
        break;
      case ticketCreate:
        final args = settings.arguments;
        // Support both String (accountId) and TicketCreateArgs
        final accountId = args is String ? args : (args as TicketCreateArgs?)?.accountId;
        return _slideWithAppShell<Object?>(
          (context) => TicketCreateScreen(accountId: accountId),
        );
      case ticketEdit:
        final args = settings.arguments as TicketEditArgs?;
        if (args != null) {
          return _slideWithAppShell<Object?>(
            (context) => TicketEditScreen(ticketId: args.ticketId),
          );
        }
        break;
      case adminInvite:
        return FadeRoute<Object?>(
          builder: (context) => const InviteUserScreen(),
        );
    }
    return null;
  }
}

class UserDetailArgs {
  const UserDetailArgs({required this.userId});
  final String userId;
}
