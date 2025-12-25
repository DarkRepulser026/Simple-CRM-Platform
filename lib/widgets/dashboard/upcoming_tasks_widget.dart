import 'package:flutter/material.dart';
import '../../navigation/app_router.dart';
import '../../services/dashboard_service.dart' show TaskItem;

/// Upcoming Tasks Widget per ARCHITECTURE_PATTERNS.md
/// Shows tasks due today/tomorrow assigned to me
/// Format: "[ ] Follow up with ACME — Today 4pm"
class UpcomingTasksWidget extends StatelessWidget {
  final List<TaskItem> tasks;
  final String title;

  const UpcomingTasksWidget({
    super.key,
    required this.tasks,
    this.title = 'Upcoming Tasks',
  });

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
                  Icons.event_outlined,
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
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tasks.length} task${tasks.length != 1 ? 's' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Tasks list
          if (tasks.isEmpty)
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
                      'No upcoming tasks 🎉',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Great job staying on top of your work.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...tasks.map((task) => _TaskListItem(
                    task: task,
                    isToday: false,
                  )),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TaskListItem extends StatelessWidget {
  final TaskItem task;
  final bool isToday;

  const _TaskListItem({
    required this.task,
    required this.isToday,
  });

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr = _formatTime(task.dueDate);
    
    return InkWell(
      onTap: () {
        AppRouter.navigateTo(
          context,
          AppRouter.taskDetail,
          arguments: TaskDetailArgs(taskId: task.id),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 12,
        ),
        child: Row(
          children: [
            // Checkbox (read-only)
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isToday ? Colors.red : Colors.orange,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: task.isCompleted
                  ? Icon(
                      Icons.check,
                      size: 14,
                      color: isToday ? Colors.red : Colors.orange,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            
            // Task title and time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (task.description != null && task.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            
            // Time badge
            if (timeStr.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (isToday ? Colors.red : Colors.orange).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  timeStr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isToday ? Colors.red[700] : Colors.orange[700],
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
            
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}
