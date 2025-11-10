import 'package:flutter/material.dart';
import '../../widgets/paginated_list_view.dart';
import '../../models/task.dart';
import '../../navigation/app_router.dart';

/// List screen for displaying and managing tasks with pagination
class TasksListScreen extends StatefulWidget {
  const TasksListScreen({super.key});

  @override
  State<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen> {
  Future<List<Task>> _fetchTasksPage(int page, int limit) async {
    // TODO: Implement actual API call using TasksService
    // For now, return mock data
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay

    return List.generate(
      limit,
      (index) => Task(
        id: 'task_${page}_${index}',
        subject: 'Task ${(page - 1) * limit + index + 1}',
        description: 'This is a sample task description for task ${(page - 1) * limit + index + 1}',
        status: TaskStatus.values[index % TaskStatus.values.length],
        priority: TaskPriority.values[index % TaskPriority.values.length],
        dueDate: DateTime.now().add(Duration(days: index % 7)),
        organizationId: 'org123',
        createdAt: DateTime.now().subtract(Duration(days: index)),
        updatedAt: DateTime.now().subtract(Duration(hours: index)),
        ownerId: 'user123',
        createdById: 'user123',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            onPressed: () => AppRouter.navigateTo(context, AppRouter.taskCreate),
            icon: const Icon(Icons.add),
            tooltip: 'Add Task',
          ),
          IconButton(
            onPressed: () {
              // TODO: Implement search
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search coming soon!')),
              );
            },
            icon: const Icon(Icons.search),
            tooltip: 'Search Tasks',
          ),
        ],
      ),
      body: PaginatedListView<Task>(
        fetchPage: _fetchTasksPage,
        itemBuilder: (context, task, index) => TaskListItem(
          task: task,
          onTap: () => AppRouter.navigateTo(
            context,
            AppRouter.taskDetail,
            arguments: TaskDetailArgs(taskId: task.id),
          ),
        ),
        emptyMessage: 'No tasks found',
        errorMessage: 'Failed to load tasks',
      ),
    );
  }
}

/// Individual task item widget
class TaskListItem extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const TaskListItem({
    super.key,
    required this.task,
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
                      task.subject,
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
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description!,
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
                  if (task.dueDate != null) ...[
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: task.isOverdue
                          ? colorScheme.error
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDueDate(task.dueDate!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: task.isOverdue
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant,
                        fontWeight: task.isOverdue ? FontWeight.w600 : null,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    _formatDate(task.createdAt),
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

    switch (task.status) {
      case TaskStatus.notStarted:
        backgroundColor = colorScheme.surfaceVariant;
        textColor = colorScheme.onSurfaceVariant;
        break;
      case TaskStatus.inProgress:
        backgroundColor = colorScheme.primaryContainer;
        textColor = colorScheme.onPrimaryContainer;
        break;
      case TaskStatus.completed:
        backgroundColor = colorScheme.secondaryContainer;
        textColor = colorScheme.onSecondaryContainer;
        break;
      case TaskStatus.cancelled:
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
        task.status.value,
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

    switch (task.priority) {
      case TaskPriority.high:
        color = colorScheme.error;
        icon = Icons.priority_high;
        break;
      case TaskPriority.normal:
        color = colorScheme.primary;
        icon = Icons.flag;
        break;
      case TaskPriority.low:
        color = colorScheme.onSurfaceVariant;
        icon = Icons.flag_outlined;
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
          task.priority.value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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

/// Arguments for task detail navigation
class TaskDetailArgs {
  final String taskId;

  const TaskDetailArgs({required this.taskId});

  @override
  String toString() => 'TaskDetailArgs(taskId: $taskId)';
}