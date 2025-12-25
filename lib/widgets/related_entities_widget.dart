import 'package:flutter/material.dart';

import '../models/contact.dart';
import '../models/task.dart';
import '../models/ticket.dart';
import '../services/service_locator.dart';
import '../services/contacts_service.dart';
import '../services/tasks_service.dart';
import '../services/tickets_service.dart';
import '../navigation/app_router.dart';
import 'loading_view.dart';
import 'error_view.dart';

/// Widget to display contacts related to an account
class RelatedContactsWidget extends StatefulWidget {
  final String accountId;
  final List<Contact>? initialContacts;
  final VoidCallback? onContactsLoaded;

  const RelatedContactsWidget({
    super.key,
    required this.accountId,
    this.initialContacts,
    this.onContactsLoaded,
  });

  @override
  State<RelatedContactsWidget> createState() => _RelatedContactsWidgetState();
}

class _RelatedContactsWidgetState extends State<RelatedContactsWidget> {
  late final ContactsService _contactsService;
  bool _isLoading = true;
  String? _error;
  List<Contact> _contacts = [];

  @override
  void initState() {
    super.initState();
    _contactsService = locator<ContactsService>();
    if (widget.initialContacts != null) {
      _contacts = widget.initialContacts!;
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onContactsLoaded?.call();
      });
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _contactsService.getContacts();
      if (!mounted) return;
      if (res.isSuccess) {
        setState(() {
          _contacts = res.value.contacts
              .where((c) => c.accountId == widget.accountId)
              .toList();
          _isLoading = false;
          _error = null;
        });
        widget.onContactsLoaded?.call();
      } else {
        throw Exception(res.error.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load contacts: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_isLoading) {
      return const Center(child: LoadingView(message: 'Loading contacts...'));
    }

    if (_error != null) {
      return Center(
        child: ErrorView(
          message: _error!,
          onRetry: _load,
        ),
      );
    }

    if (_contacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outline,
                size: 48,
                color: cs.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No contacts',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _contacts.length,
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        return _buildContactTile(context, contact, theme, cs);
      },
    );
  }

  Widget _buildContactTile(BuildContext context, Contact contact, ThemeData theme, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              contact.firstName.isNotEmpty ? contact.firstName[0].toUpperCase() : '?',
              style: theme.textTheme.labelLarge?.copyWith(
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
        ),
        title: Text(contact.fullName),
        subtitle: Text(contact.email ?? contact.phone ?? 'No contact info'),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: cs.onSurfaceVariant),
        onTap: () async {
          await AppRouter.navigateTo(
            context,
            AppRouter.contactDetail,
            arguments: ContactDetailArgs(contactId: contact.id),
          );
          // Reload the contacts list in case any changes were made
          _load();
        },
      ),
    );
  }
}

/// Widget to display tasks related to an account
class RelatedTasksWidget extends StatefulWidget {
  final String accountId;
  final List<Task>? initialTasks;
  final VoidCallback? onTasksLoaded;

  const RelatedTasksWidget({
    super.key,
    required this.accountId,
    this.initialTasks,
    this.onTasksLoaded,
  });

  @override
  State<RelatedTasksWidget> createState() => _RelatedTasksWidgetState();
}

class _RelatedTasksWidgetState extends State<RelatedTasksWidget> {
  late final TasksService _tasksService;
  bool _isLoading = true;
  String? _error;
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _tasksService = locator<TasksService>();
    if (widget.initialTasks != null) {
      _tasks = widget.initialTasks!;
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onTasksLoaded?.call();
      });
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _tasksService.getTasks();
      if (!mounted) return;
      if (res.isSuccess) {
        setState(() {
          _tasks = res.value.tasks
              .where((t) => t.accountId == widget.accountId)
              .toList();
          _isLoading = false;
          _error = null;
        });
        widget.onTasksLoaded?.call();
      } else {
        throw Exception(res.error.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load tasks: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_isLoading) {
      return const Center(child: LoadingView(message: 'Loading tasks...'));
    }

    if (_error != null) {
      return Center(
        child: ErrorView(
          message: _error!,
          onRetry: _load,
        ),
      );
    }

    if (_tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.checklist,
                size: 48,
                color: cs.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No tasks',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        return _buildTaskTile(context, task, theme, cs);
      },
    );
  }

  Widget _buildTaskTile(BuildContext context, Task task, ThemeData theme, ColorScheme cs) {
    final statusColor = _getTaskStatusColor(task.status.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              Icons.assignment,
              size: 20,
              color: statusColor,
            ),
          ),
        ),
        title: Text(task.title),
        subtitle: Text(
          'Status: ${task.status}',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: cs.onSurfaceVariant),
        onTap: () async {
          await AppRouter.navigateTo(
            context,
            AppRouter.taskDetail,
            arguments: TaskDetailArgs(taskId: task.id),
          );
          // Reload the tasks list in case any changes were made
          _load();
        },
      ),
    );
  }

  Color _getTaskStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'done':
        return Colors.green;
      case 'in_progress':
      case 'inprogress':
        return Colors.blue;
      case 'pending':
      case 'todo':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

/// Widget to display tickets related to an account
class RelatedTicketsWidget extends StatefulWidget {
  final String accountId;
  final List<Ticket>? initialTickets;
  final VoidCallback? onTicketsLoaded;

  const RelatedTicketsWidget({
    super.key,
    required this.accountId,
    this.initialTickets,
    this.onTicketsLoaded,
  });

  @override
  State<RelatedTicketsWidget> createState() => _RelatedTicketsWidgetState();
}

class _RelatedTicketsWidgetState extends State<RelatedTicketsWidget> {
  late final TicketsService _ticketsService;
  bool _isLoading = true;
  String? _error;
  List<Ticket> _tickets = [];

  @override
  void initState() {
    super.initState();
    _ticketsService = locator<TicketsService>();
    if (widget.initialTickets != null) {
      _tickets = widget.initialTickets!;
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onTicketsLoaded?.call();
      });
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _ticketsService.getTickets(accountId: widget.accountId);
      if (!mounted) return;
      if (res.isSuccess) {
        setState(() {
          _tickets = res.value.tickets;
          _isLoading = false;
          _error = null;
        });
        widget.onTicketsLoaded?.call();
      } else {
        throw Exception(res.error.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load tickets: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_isLoading) {
      return const Center(child: LoadingView(message: 'Loading tickets...'));
    }

    if (_error != null) {
      return Center(
        child: ErrorView(
          message: _error!,
          onRetry: _load,
        ),
      );
    }

    if (_tickets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.support_agent,
                size: 48,
                color: cs.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No tickets found for this account',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  final result = await AppRouter.navigateTo(
                    context,
                    AppRouter.ticketCreate,
                    arguments: widget.accountId,
                  );
                  if (result == true) {
                    _load();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Ticket'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          itemCount: _tickets.length,
          itemBuilder: (context, index) {
            final ticket = _tickets[index];
            return _buildTicketTile(context, ticket, theme, cs);
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () async {
              final result = await AppRouter.navigateTo(
                context,
                AppRouter.ticketCreate,
                arguments: TicketCreateArgs(accountId: widget.accountId),
              );
              if (result == true) {
                _load();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Ticket'),
          ),
        ),
      ],
    );
  }

  Widget _buildTicketTile(BuildContext context, Ticket ticket, ThemeData theme, ColorScheme cs) {
    final statusColor = _getTicketStatusColor(ticket.status.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              Icons.confirmation_num,
              size: 20,
              color: statusColor,
            ),
          ),
        ),
        title: Text(ticket.subject),
        subtitle: Text(
          'Status: ${ticket.status}',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: cs.onSurfaceVariant),
        onTap: () async {
          await AppRouter.navigateTo(
            context,
            AppRouter.ticketDetail,
            arguments: TicketDetailArgs(ticketId: ticket.id),
          );
          // Reload the tickets list in case any changes were made
          _load();
        },
      ),
    );
  }

  Color _getTicketStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
      case 'closed':
        return Colors.green;
      case 'open':
      case 'assigned':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'reopen':
      case 'reopened':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
