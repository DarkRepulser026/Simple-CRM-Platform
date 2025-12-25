import 'package:flutter/material.dart';
import '../../services/dashboard_service.dart';
import '../../navigation/app_router.dart';

/// Work Queue Table Widget per ARCHITECTURE_PATTERNS.md
/// Shows: ID, Title, Account, Status, Priority, Updated
/// - Default sorted by urgency
/// - Status color-coded
/// - No pagination (limit 10-15)
/// - Read-only, clickable to entity
class WorkQueueWidget extends StatelessWidget {
  final List<WorkQueueItem> items;
  final String title;
  final String emptyMessage;

  const WorkQueueWidget({
    super.key,
    required this.items,
    required this.title,
    this.emptyMessage = 'No items to show',
  });

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
      case 'NEW':
        return Colors.blue;
      case 'IN_PROGRESS':
      case 'PENDING':
        return Colors.orange;
      case 'RESOLVED':
      case 'COMPLETED':
      case 'CLOSED':
        return Colors.green;
      case 'WAITING':
      case 'ON_HOLD':
        return Colors.purple;
      case 'CANCELLED':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  Color _getPriorityColor(String? priority) {
    if (priority == null) return Colors.grey;
    switch (priority.toUpperCase()) {
      case 'CRITICAL':
      case 'URGENT':
        return Colors.red;
      case 'HIGH':
        return Colors.orange;
      case 'MEDIUM':
      case 'NORMAL':
        return Colors.blue;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _navigateToEntity(BuildContext context, WorkQueueItem item) {
    if (item.type == 'ticket') {
      AppRouter.navigateTo(
        context,
        AppRouter.ticketDetail,
        arguments: TicketDetailArgs(ticketId: item.id),
      );
    } else if (item.type == 'task') {
      AppRouter.navigateTo(
        context,
        AppRouter.taskDetail,
        arguments: TaskDetailArgs(taskId: item.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.work_outline,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${items.length} items',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Items list
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: Colors.green[300],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      emptyMessage,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length > 15 ? 15 : items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                final statusColor = _getStatusColor(item.status);
                final priorityColor = _getPriorityColor(item.priority);
                
                return InkWell(
                  onTap: () => _navigateToEntity(context, item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        // Type icon
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            item.type == 'ticket'
                                ? Icons.confirmation_number_outlined
                                : Icons.task_alt,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title with ID
                              Row(
                                children: [
                                  Text(
                                    '#${item.id.substring(0, 8)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // Status, Priority, Updated
                              Row(
                                children: [
                                  // Status badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: statusColor.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      item.status,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: statusColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  
                                  // Priority badge
                                  if (item.priority != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: priorityColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.priority_high,
                                            size: 12,
                                            color: priorityColor,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            item.priority!,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: priorityColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  
                                  const Spacer(),
                                  
                                  // Updated time
                                  Text(
                                    _formatRelativeTime(item.dueDate),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
