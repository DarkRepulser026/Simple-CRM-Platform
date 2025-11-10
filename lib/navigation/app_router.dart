import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/company_selection_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/contacts/contacts_list_screen.dart';
import '../screens/leads/leads_list_screen.dart';
import '../screens/tasks/tasks_list_screen.dart';
import '../screens/tickets/tickets_list_screen.dart';

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

/// Central route registry with typed navigation
class AppRouter {
  static const String login = '/login';
  static const String companySelection = '/company-selection';
  static const String companyCreate = '/company-create';
  static const String dashboard = '/dashboard';
  static const String about = '/about';
  static const String helpSupport = '/help-support';
  static const String contacts = '/contacts';
  static const String leads = '/leads';
  static const String tickets = '/tickets';
  static const String contactCreate = '/contact-create';
  static const String contactDetail = '/contact-detail';
  static const String leadDetail = '/lead-detail';
  static const String leadCreate = '/lead-create';
  static const String ticketCreate = '/ticket-create';
  static const String ticketDetail = '/ticket-detail';
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
      dashboard: (context) => const DashboardScreen(),
      contacts: (context) => const ContactsListScreen(),
      leads: (context) => const LeadsListScreen(),
      tasks: (context) => const TasksListScreen(),
      tickets: (context) => const TicketsListScreen(),
      // contactCreate: (context) => const ContactCreateScreen(),
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
      case contactDetail:
        final args = settings.arguments as ContactDetailArgs?;
        if (args != null) {
          // TODO: return MaterialPageRoute(
          //   builder: (context) => ContactDetailScreen(contactId: args.contactId),
          // );
        }
        break;
      case leadDetail:
        final args = settings.arguments as LeadDetailArgs?;
        if (args != null) {
          // TODO: return MaterialPageRoute(
          //   builder: (context) => LeadDetailScreen(leadId: args.leadId),
          // );
        }
        break;
      case taskDetail:
        final args = settings.arguments as TaskDetailArgs?;
        if (args != null) {
          // TODO: return MaterialPageRoute(
          //   builder: (context) => TaskDetailScreen(taskId: args.taskId),
          // );
        }
        break;
      case ticketDetail:
        final args = settings.arguments as TicketDetailArgs?;
        if (args != null) {
          // TODO: return MaterialPageRoute(
          //   builder: (context) => TicketDetailScreen(ticketId: args.ticketId),
          // );
        }
        break;
      case taskEdit:
        final args = settings.arguments as TaskDetailArgs?;
        if (args != null) {
          // TODO: return MaterialPageRoute(
          //   builder: (context) => TaskEditScreen(taskId: args.taskId),
          // );
        }
        break;
    }
    return null;
  }
}