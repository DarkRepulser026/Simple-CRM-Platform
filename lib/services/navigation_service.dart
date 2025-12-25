import 'package:flutter/material.dart';
import '../navigation/app_router.dart';

/// Navigation context to track current screen and navigation history
class NavigationContext {
  final String routeName;
  final Object? arguments;
  final DateTime timestamp;
  final String? title;

  const NavigationContext({
    required this.routeName,
    this.arguments,
    required this.timestamp,
    this.title,
  });
}

/// Enhanced navigation service with standardized patterns and breadcrumb support
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();

  factory NavigationService() {
    return _instance;
  }

  NavigationService._internal();

  // Navigation history for breadcrumbs
  final List<NavigationContext> _navigationHistory = [];

  // Current route tracking
  NavigationContext? _currentContext;

  /// Get current navigation context
  NavigationContext? get currentContext => _currentContext;

  /// Get navigation history
  List<NavigationContext> get navigationHistory => List.unmodifiable(_navigationHistory);

  /// Get breadcrumb titles
  List<String> get breadcrumbs {
    return _navigationHistory
        .where((ctx) => ctx.title != null)
        .map((ctx) => ctx.title!)
        .toList();
  }

  /// Navigate to a simple route without arguments
  static Future<T?> navigateTo<T>(
    BuildContext context,
    String route, {
    String? title,
  }) async {
    final result = await AppRouter.navigateTo<T>(context, route);
    _instance._recordNavigation(route, title: title);
    return result;
  }

  /// Navigate to a detail screen with typed arguments
  static Future<T?> navigateToDetail<T>(
    BuildContext context,
    String route, {
    required Object arguments,
    String? title,
  }) async {
    final result = await AppRouter.navigateTo<T>(context, route, arguments: arguments);
    _instance._recordNavigation(route, arguments: arguments, title: title);
    return result;
  }

  /// Navigate to a create screen
  static Future<T?> navigateToCreate<T>(
    BuildContext context,
    String route, {
    String? title,
  }) async {
    final entityType = _extractEntityType(route);
    final finalTitle = title ?? 'Create $entityType';
    final result = await AppRouter.navigateTo<T>(context, route);
    _instance._recordNavigation(route, title: finalTitle);
    return result;
  }

  /// Navigate to an edit screen with ID
  static Future<T?> navigateToEdit<T>(
    BuildContext context,
    String route, {
    required Object arguments,
    String? title,
  }) async {
    final entityType = _extractEntityType(route);
    final finalTitle = title ?? 'Edit $entityType';
    final result = await AppRouter.navigateTo<T>(context, route, arguments: arguments);
    _instance._recordNavigation(route, arguments: arguments, title: finalTitle);
    return result;
  }

  /// Show a dialog/modal
  static Future<T?> showModal<T>(
    BuildContext context, {
    required Widget Function(BuildContext) builder,
    String? title,
    bool barrierDismissible = true,
  }) async {
    final dialog = Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: builder(context),
    );

    final result = await showDialog<T>(
      context: context,
      builder: (_) => dialog,
      barrierDismissible: barrierDismissible,
    );

    if (result != null) {
      _instance._recordNavigation('modal', title: title ?? 'Dialog');
    }

    return result;
  }

  /// Show a confirmation dialog
  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    bool isDangerous = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: isDangerous ? Colors.red : null,
            ),
            child: Text(confirmLabel ?? 'Confirm'),
          ),
        ],
      ),
    );
  }

  /// Show a snackbar message
  static void showMessage(
    BuildContext context, {
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : colorScheme.primary,
        duration: duration,
      ),
    );
  }

  /// Go back to previous screen
  static void goBack<T>(BuildContext context, [T? result]) {
    AppRouter.pop(context, result);
    _instance._navigationHistory.removeLast();
  }

  /// Go back to home/dashboard
  static void goHome(BuildContext context) {
    AppRouter.popToRoot(context);
    _instance._navigationHistory.clear();
    _instance._currentContext = NavigationContext(
      routeName: AppRouter.dashboard,
      timestamp: DateTime.now(),
      title: 'Dashboard',
    );
  }

  /// Replace current route
  static Future<T?> replaceWith<T>(
    BuildContext context,
    String route, {
    Object? arguments,
    String? title,
  }) async {
    final result = await AppRouter.replaceWith<T>(
      context,
      route,
      arguments: arguments,
    );
    _instance._recordNavigation(route, arguments: arguments, title: title);
    return result;
  }

  /// Clear navigation history (useful on logout)
  static void clearHistory() {
    _instance._navigationHistory.clear();
    _instance._currentContext = null;
  }

  /// Record navigation in history
  void _recordNavigation(
    String routeName, {
    Object? arguments,
    String? title,
  }) {
    final context = NavigationContext(
      routeName: routeName,
      arguments: arguments,
      timestamp: DateTime.now(),
      title: title,
    );
    _navigationHistory.add(context);
    _currentContext = context;

    // Keep only last 20 items to prevent memory leak
    if (_navigationHistory.length > 20) {
      _navigationHistory.removeAt(0);
    }
  }

  /// Extract entity type from route name
  static String _extractEntityType(String route) {
    if (route.contains('contact')) return 'Contact';
    if (route.contains('lead')) return 'Lead';
    if (route.contains('account')) return 'Account';
    if (route.contains('task')) return 'Task';
    if (route.contains('ticket')) return 'Ticket';
    if (route.contains('user')) return 'User';
    return 'Item';
  }

  /// Get breadcrumb widgets for UI
  List<Widget> getBreadcrumbWidgets(BuildContext context) {
    if (_navigationHistory.isEmpty) return [];

    final cs = Theme.of(context).colorScheme;
    final widgets = <Widget>[];

    for (int i = 0; i < breadcrumbs.length; i++) {
      if (i > 0) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 16),
          ),
        );
      }

      widgets.add(
        InkWell(
          onTap: () {
            // Navigate to this breadcrumb
            if (i < _navigationHistory.length) {
              final targetContext = _navigationHistory[i];
              AppRouter.navigateTo(context, targetContext.routeName);
            }
          },
          child: Text(
            breadcrumbs[i],
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      );
    }

    return widgets;
  }
}

/// Mixin for screens that want to track breadcrumbs
mixin NavigationTracker {
  String? getScreenTitle();
  String getScreenRoute();
}

/// Helper class for common navigation patterns
class CommonNavigations {
  /// Navigate to contacts list
  static Future<void> toContactsList(BuildContext context) =>
      NavigationService.navigateTo(context, AppRouter.contacts, title: 'Contacts');

  /// Navigate to contact detail
  static Future<void> toContactDetail(BuildContext context, String contactId) =>
      NavigationService.navigateToDetail(context, AppRouter.contactDetail,
          arguments: ContactDetailArgs(contactId: contactId), title: 'Contact Details');

  /// Navigate to create contact
  static Future<void> toCreateContact(BuildContext context) =>
      NavigationService.navigateToCreate(context, AppRouter.contactCreate, title: 'New Contact');

  /// Navigate to edit contact
  static Future<void> toEditContact(BuildContext context, String contactId) =>
      NavigationService.navigateToEdit(context, AppRouter.contactEdit,
          arguments: ContactEditArgs(contactId: contactId));

  /// Navigate to leads list
  static Future<void> toLeadsList(BuildContext context) =>
      NavigationService.navigateTo(context, AppRouter.leads, title: 'Leads');

  /// Navigate to lead detail
  static Future<void> toLeadDetail(BuildContext context, String leadId) =>
      NavigationService.navigateToDetail(context, AppRouter.leadDetail,
          arguments: LeadDetailArgs(leadId: leadId), title: 'Lead Details');

  /// Navigate to create lead
  static Future<void> toCreateLead(BuildContext context) =>
      NavigationService.navigateToCreate(context, AppRouter.leadCreate, title: 'New Lead');

  /// Navigate to edit lead
  static Future<void> toEditLead(BuildContext context, String leadId) =>
      NavigationService.navigateToEdit(context, AppRouter.leadEdit,
          arguments: LeadEditArgs(leadId: leadId));

  /// Navigate to accounts list
  static Future<void> toAccountsList(BuildContext context) =>
      NavigationService.navigateTo(context, AppRouter.accounts, title: 'Accounts');

  /// Navigate to account detail
  static Future<void> toAccountDetail(BuildContext context, String accountId) =>
      NavigationService.navigateToDetail(context, AppRouter.accountDetail,
          arguments: AccountDetailArgs(accountId: accountId), title: 'Account Details');

  /// Navigate to create account
  static Future<void> toCreateAccount(BuildContext context) =>
      NavigationService.navigateToCreate(context, AppRouter.accountCreate, title: 'New Account');

  /// Navigate to edit account
  static Future<void> toEditAccount(BuildContext context, String accountId) =>
      NavigationService.navigateToEdit(context, AppRouter.accountEdit,
          arguments: AccountDetailArgs(accountId: accountId));

  /// Navigate to tasks list
  static Future<void> toTasksList(BuildContext context) =>
      NavigationService.navigateTo(context, AppRouter.tasks, title: 'Tasks');

  /// Navigate to task detail
  static Future<void> toTaskDetail(BuildContext context, String taskId) =>
      NavigationService.navigateToDetail(context, AppRouter.taskDetail,
          arguments: TaskDetailArgs(taskId: taskId), title: 'Task Details');

  /// Navigate to create task
  static Future<void> toCreateTask(BuildContext context) =>
      NavigationService.navigateToCreate(context, AppRouter.taskCreate, title: 'New Task');

  /// Navigate to edit task
  static Future<void> toEditTask(BuildContext context, String taskId) =>
      NavigationService.navigateToEdit(context, AppRouter.taskEdit,
          arguments: TaskEditArgs(taskId: taskId));

  /// Navigate to tickets list
  static Future<void> toTicketsList(BuildContext context) =>
      NavigationService.navigateTo(context, AppRouter.tickets, title: 'Tickets');

  /// Navigate to ticket detail
  static Future<void> toTicketDetail(BuildContext context, String ticketId) =>
      NavigationService.navigateToDetail(context, AppRouter.ticketDetail,
          arguments: TicketDetailArgs(ticketId: ticketId), title: 'Ticket Details');

  /// Navigate to create ticket
  static Future<void> toCreateTicket(BuildContext context) =>
      NavigationService.navigateToCreate(context, AppRouter.ticketCreate, title: 'New Ticket');

  /// Navigate to edit ticket
  static Future<void> toEditTicket(BuildContext context, String ticketId) =>
      NavigationService.navigateToEdit(context, AppRouter.ticketEdit,
          arguments: TicketEditArgs(ticketId: ticketId));

  /// Navigate to dashboard
  static Future<void> toDashboard(BuildContext context) =>
      NavigationService.navigateTo(context, AppRouter.dashboard, title: 'Dashboard');
}

// Note: Imports for ContactDetailArgs, LeadDetailArgs, etc. 
// are handled via app_router.dart which is already imported above
