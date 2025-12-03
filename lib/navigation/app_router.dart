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

class TicketDetailArgs {
  const TicketDetailArgs({required this.ticketId});

  final String ticketId;
}

class ActivityLogsArgs {
  const ActivityLogsArgs({this.entityType, this.entityId, this.userId, this.search});
  final String? entityType;
  final String? entityId;
  final String? userId;
  final String? search;
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
    return Navigator.of(context).pushNamed<T>(route, arguments: arguments);
  }

  /// Replace current route
  static Future<T?> replaceWith<T>(
    BuildContext context,
    String route, {
    Object? arguments,
  }) {
    return Navigator.of(context).pushReplacementNamed<T, dynamic>(
      route,
      arguments: arguments,
    );
  }

  /// Pop current route
  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop(result);
  }

  /// Pop until root
  static void popToRoot(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Get route settings for MaterialApp
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginScreen(),
      companySelection: (context) => const CompanySelectionScreen(),
      '/invite/accept': (context) => const InviteAcceptScreen(),
      dashboard: (context) => const DashboardScreen(),
      contacts: (context) => const ContactsListScreen(),
      organizations: (context) => const OrganizationsListScreen(),
      accounts: (context) => const AccountsListScreen(),
      accountCreate: (context) => const AccountCreateScreen(),
      leads: (context) => const LeadsListScreen(),
      taskCreate: (context) => const TaskCreateScreen(),
      leadCreate: (context) => const LeadCreateScreen(),
      tasks: (context) => const TasksListScreen(),
      tickets: (context) => const TicketsListScreen(),
      ticketCreate: (context) => const TicketCreateScreen(),
      // wrap admin routes with the route guard - these return a WidgetBuilder
      adminUsers: (context) => managerOrAdminGuarded((c) => const UsersListScreen())(context),
      adminInvite: (context) => managerOrAdminGuarded((c) => const InviteUserScreen())(context),
      adminRoles: (context) => adminGuarded((c) => const RolesListScreen())(context),
      adminInvitations: (context) => managerOrAdminGuarded((c) => const InvitationsScreen())(context),
      activityLogs: (context) => adminGuarded((c) => const ActivityLogsScreen())(context),
      interactions: (context) => const InteractionsListScreen(),
      contactCreate: (context) => const ContactCreateScreen(),
      // contactDetail: (context) => const ContactDetailScreen(),
      // leadCreate: (context) => const LeadCreateScreen(),
      // leadDetail: (context) => const LeadDetailScreen(),
      // taskCreate: (context) => const TaskCreateScreen(),
      // taskDetail: (context) => const TaskDetailScreen(),
      // taskEdit: (context) => const TaskEditScreen(),
    };
  }

  /// Handle onGenerateRoute for dynamic routes with arguments
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case adminUserDetail:
        final args = settings.arguments as UserDetailArgs?;
        if (args != null) {
          if (!locator<AuthService>().isManagerOrAdmin) return MaterialPageRoute(builder: (context) => const AccessDeniedRedirectScreen());
          return MaterialPageRoute(builder: (context) => UserDetailScreen(userId: args.userId));
        }
        break;
      case adminUserEdit:
        final editArgs = settings.arguments as UserDetailArgs?;
        if (editArgs != null) {
          if (!locator<AuthService>().isManagerOrAdmin) return MaterialPageRoute(builder: (context) => const AccessDeniedRedirectScreen());
          return MaterialPageRoute(builder: (context) => UserEditScreen(userId: editArgs.userId));
        }
        break;
      case activityLogs:
        final args = settings.arguments as ActivityLogsArgs?;
        if (args != null) {
          if (!locator<AuthService>().isAdmin) return MaterialPageRoute(builder: (context) => const AccessDeniedRedirectScreen());
          return MaterialPageRoute(builder: (context) => ActivityLogsScreen());
        }
        break;
            case accountDetail:
              final args = settings.arguments as AccountDetailArgs?;
              if (args != null) {
                return MaterialPageRoute(
                  builder: (context) => AccountDetailScreen(accountId: args.accountId),
                );
              }
            case accountEdit:
              final argsEdit = settings.arguments as AccountDetailArgs?;
              if (argsEdit != null) {
                return MaterialPageRoute(builder: (context) => AccountEditScreen(accountId: argsEdit.accountId));
              }
              break;
      case contactDetail:
        final args = settings.arguments as ContactDetailArgs?;
        if (args != null) {
          return MaterialPageRoute(
            builder: (context) => ContactDetailScreen(contactId: args.contactId),
          );
        }
        break;
        case contactEdit:
          final ca = settings.arguments as ContactEditArgs?;
          if (ca != null) {
            return MaterialPageRoute(builder: (context) => ContactEditScreen(contactId: ca.contactId));
          }
          // If args are missing show a helpful error page instead of returning null
          return MaterialPageRoute(builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Edit contact')), 
            body: Center(child: Text('Missing contact ID for edit route')), 
          ));
      case leadDetail:
        final args = settings.arguments as LeadDetailArgs?;
        if (args != null) {
          return MaterialPageRoute(
            builder: (context) => LeadDetailScreen(leadId: args.leadId),
          );
        }
        break;
      case leadEdit:
        final args = settings.arguments as LeadEditArgs?;
        if (args != null) {
          return MaterialPageRoute(builder: (context) => LeadEditScreen(leadId: args.leadId));
        }
        break;
      case taskDetail:
        final args = settings.arguments as TaskDetailArgs?;
        if (args != null) {
          return MaterialPageRoute(
            builder: (context) => TaskDetailScreen(taskId: args.taskId),
          );
        }
        break;
      case taskEdit:
        final args = settings.arguments as TaskEditArgs?;
        if (args != null) {
          return MaterialPageRoute(builder: (context) => TaskEditScreen(taskId: args.taskId));
        }
        break;
      case ticketDetail:
        final args = settings.arguments as TicketDetailArgs?;
        if (args != null) {
          return MaterialPageRoute(
            builder: (context) => TicketDetailScreen(ticketId: args.ticketId),
          );
        }
        break;
      case ticketEdit:
        final args = settings.arguments as TicketEditArgs?;
        if (args != null) {
          return MaterialPageRoute(builder: (context) => TicketEditScreen(ticketId: args.ticketId));
        }
        break;
        case adminInvite:
          return MaterialPageRoute(builder: (context) => const InviteUserScreen());
      
    }
    return null;
  }
}

class UserDetailArgs {
  const UserDetailArgs({required this.userId});
  final String userId;
}