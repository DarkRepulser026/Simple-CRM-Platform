import 'package:flutter/material.dart';
import '../../models/activity_log.dart';
import '../../navigation/app_router.dart';

/// Recent Activity Widget per ARCHITECTURE_PATTERNS.md
/// Shows: Entity updates (Ticket updated, Lead converted, Task completed)
/// Format: "Bob resolved Ticket #231 (ACME) — 10m ago"
/// - Read-only
/// - Clickable to entity
class RecentActivityWidget extends StatelessWidget {
  final List<ActivityLog> activities;
  final String title;
  final int maxItems;

  const RecentActivityWidget({
    super.key,
    required this.activities,
    this.title = 'Recent Activity',
    this.maxItems = 10,
  });

  IconData _getActionIcon(String? action) {
    if (action == null) return Icons.circle_outlined;
    
    final upperAction = action.toUpperCase();
    if (upperAction.contains('CREATE')) return Icons.add_circle_outline;
    if (upperAction.contains('UPDATE') || upperAction.contains('EDIT')) {
      return Icons.edit_outlined;
    }
    if (upperAction.contains('DELETE')) return Icons.delete_outline;
    if (upperAction.contains('RESOLVE')) return Icons.check_circle_outline;
    if (upperAction.contains('CLOSE')) return Icons.cancel_outlined;
    if (upperAction.contains('ASSIGN')) return Icons.person_add_outlined;
    if (upperAction.contains('CONVERT')) return Icons.transform_outlined;
    if (upperAction.contains('COMPLETE')) return Icons.done_all_outlined;
    if (upperAction.contains('INVITE')) return Icons.mail_outline;
    
    return Icons.fiber_manual_record;
  }

  Color _getActionColor(String? action) {
    if (action == null) return Colors.blueGrey;
    
    final upperAction = action.toUpperCase();
    if (upperAction.contains('CREATE')) return Colors.green;
    if (upperAction.contains('UPDATE') || upperAction.contains('EDIT')) {
      return Colors.blue;
    }
    if (upperAction.contains('DELETE')) return Colors.red;
    if (upperAction.contains('RESOLVE') || upperAction.contains('COMPLETE')) {
      return Colors.teal;
    }
    if (upperAction.contains('CLOSE')) return Colors.grey;
    if (upperAction.contains('ASSIGN')) return Colors.purple;
    if (upperAction.contains('CONVERT')) return Colors.orange;
    
    return Colors.blueGrey;
  }

  String _formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inDays > 7) {
      return '${diff.inDays} days ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatActionMessage(ActivityLog activity) {
    final actor = activity.userName ?? 'Someone';
    final action = activity.action?.replaceAll('_', ' ').toLowerCase() ?? 'updated';
    final entity = activity.entityType ?? 'item';
    final entityId = activity.entityId ?? '';
    
    return '$actor $action $entity${entityId.isNotEmpty ? " #${entityId.substring(0, 8)}" : ""}';
  }

  void _navigateToEntity(BuildContext context, ActivityLog activity) {
    if (activity.entityType == null || activity.entityId == null) return;
    
    final entityType = activity.entityType!.toLowerCase();
    final entityId = activity.entityId!;
    
    switch (entityType) {
      case 'ticket':
        AppRouter.navigateTo(
          context,
          '${AppRouter.tickets}/$entityId',
          arguments: {'ticketId': entityId},
        );
        break;
      case 'task':
        AppRouter.navigateTo(
          context,
          '${AppRouter.tasks}/$entityId',
          arguments: {'taskId': entityId},
        );
        break;
      case 'lead':
        AppRouter.navigateTo(
          context,
          '${AppRouter.leads}/$entityId',
          arguments: {'leadId': entityId},
        );
        break;
      case 'account':
        AppRouter.navigateTo(
          context,
          '${AppRouter.accounts}/$entityId',
          arguments: {'accountId': entityId},
        );
        break;
      case 'contact':
        AppRouter.navigateTo(
          context,
          '${AppRouter.contacts}/$entityId',
          arguments: {'contactId': entityId},
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayItems = activities.take(maxItems).toList();
    
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
                  Icons.history,
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
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Activities list
          if (displayItems.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurface.withOpacity(0.2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No recent activity',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: displayItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final activity = displayItems[index];
                final actionColor = _getActionColor(activity.action);
                final actionIcon = _getActionIcon(activity.action);
                final isClickable = activity.entityId != null;
                
                return InkWell(
                  onTap: isClickable
                      ? () => _navigateToEntity(context, activity)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Action icon
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: actionColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            actionIcon,
                            size: 18,
                            color: actionColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatActionMessage(activity),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatRelativeTime(activity.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Clickable indicator
                        if (isClickable)
                          Icon(
                            Icons.chevron_right,
                            size: 18,
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
