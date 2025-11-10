import 'package:flutter/material.dart';
import '../../widgets/paginated_list_view.dart';
import '../../models/ticket.dart';
import '../../navigation/app_router.dart';

/// List screen for displaying and managing tickets with pagination
class TicketsListScreen extends StatefulWidget {
  const TicketsListScreen({super.key});

  @override
  State<TicketsListScreen> createState() => _TicketsListScreenState();
}

class _TicketsListScreenState extends State<TicketsListScreen> {
  Future<List<Ticket>> _fetchTicketsPage(int page, int limit) async {
    // TODO: Implement actual API call using TicketsService
    // For now, return mock data
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay

    return List.generate(
      limit,
      (index) => Ticket(
        id: 'ticket_${page}_${index}',
        subject: 'Support Ticket ${(page - 1) * limit + index + 1}',
        description: 'Customer is experiencing issues with the product. Need immediate assistance.',
        status: TicketStatus.values[index % TicketStatus.values.length],
        priority: TicketPriority.values[index % TicketPriority.values.length],
        type: TicketType.values[index % TicketType.values.length],
        dueDate: DateTime.now().add(Duration(days: index % 7)),
        organizationId: 'org123',
        createdAt: DateTime.now().subtract(Duration(days: index)),
        updatedAt: DateTime.now().subtract(Duration(hours: index)),
        customerId: 'customer${(page - 1) * limit + index + 1}',
        assignedToId: index % 3 == 0 ? 'agent1' : null,
        createdById: 'agent1',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickets'),
        actions: [
          IconButton(
            onPressed: () => AppRouter.navigateTo(context, AppRouter.ticketCreate),
            icon: const Icon(Icons.add),
            tooltip: 'Create Ticket',
          ),
          IconButton(
            onPressed: () {
              // TODO: Implement search
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search coming soon!')),
              );
            },
            icon: const Icon(Icons.search),
            tooltip: 'Search Tickets',
          ),
        ],
      ),
      body: PaginatedListView<Ticket>(
        fetchPage: _fetchTicketsPage,
        itemBuilder: (context, ticket, index) => TicketListItem(
          ticket: ticket,
          onTap: () => AppRouter.navigateTo(
            context,
            AppRouter.ticketDetail,
            arguments: TicketDetailArgs(ticketId: ticket.id),
          ),
        ),
        emptyMessage: 'No tickets found',
        errorMessage: 'Failed to load tickets',
      ),
    );
  }
}

/// Individual ticket item widget
class TicketListItem extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTap;

  const TicketListItem({
    super.key,
    required this.ticket,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.subject,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(context),
                ],
              ),
              if (ticket.description != null && ticket.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  ticket.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildPriorityIndicator(context),
                  const SizedBox(width: 16),
                  _buildTypeIndicator(context),
                  const Spacer(),
                  if (ticket.dueDate != null) ...[
                    Icon(
                      ticket.isOverdue ? Icons.warning : Icons.calendar_today,
                      size: 16,
                      color: ticket.isOverdue
                          ? colorScheme.error
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDueDate(ticket.dueDate!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: ticket.isOverdue
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant,
                        fontWeight: ticket.isOverdue ? FontWeight.w600 : null,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '#${ticket.id}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(ticket.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color backgroundColor;
    Color textColor;

    switch (ticket.status) {
      case TicketStatus.open:
        backgroundColor = colorScheme.primaryContainer;
        textColor = colorScheme.onPrimaryContainer;
        break;
      case TicketStatus.pending:
        backgroundColor = colorScheme.secondaryContainer;
        textColor = colorScheme.onSecondaryContainer;
        break;
      case TicketStatus.inProgress:
        backgroundColor = colorScheme.tertiaryContainer;
        textColor = colorScheme.onTertiaryContainer;
        break;
      case TicketStatus.resolved:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        break;
      case TicketStatus.closed:
        backgroundColor = colorScheme.surfaceVariant;
        textColor = colorScheme.onSurfaceVariant;
        break;
      case TicketStatus.cancelled:
        backgroundColor = colorScheme.errorContainer;
        textColor = colorScheme.onErrorContainer;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        ticket.status.value,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color color;
    IconData icon;

    switch (ticket.priority) {
      case TicketPriority.low:
        color = Colors.grey;
        icon = Icons.arrow_downward;
        break;
      case TicketPriority.normal:
        color = colorScheme.primary;
        icon = Icons.remove;
        break;
      case TicketPriority.high:
        color = Colors.orange;
        icon = Icons.arrow_upward;
        break;
      case TicketPriority.urgent:
        color = Colors.deepOrange;
        icon = Icons.priority_high;
        break;
      case TicketPriority.critical:
        color = colorScheme.error;
        icon = Icons.warning;
        break;
    }

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          ticket.priority.value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeIndicator(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        ticket.type.value,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Due today';
    } else if (difference == 1) {
      return 'Due tomorrow';
    } else if (difference == -1) {
      return 'Due yesterday';
    } else if (difference > 0) {
      return 'Due in $difference days';
    } else {
      return 'Overdue by ${-difference} days';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}