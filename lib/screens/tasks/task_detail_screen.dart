import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/service_locator.dart';
import '../../services/tasks_service.dart';
import '../../services/auth/auth_service.dart';
import '../../navigation/app_router.dart';
import '../../widgets/role_visibility.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/activity_log_widget.dart';
import '../../widgets/owner_dropdown.dart';

/// Màn Task detail dạng popup card ở giữa (khi đi bằng route)
class TaskDetailScreen extends StatelessWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Task Detail'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: SingleChildScrollView(
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: cs.outline.withOpacity(0.1)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _TaskDetailCard(taskId: taskId),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pop-up dialog dùng trong TasksListScreen (nếu muốn dùng dialog thay vì route)
///
/// await showTaskDetailDialog(context, task.id);
Future<void> showTaskDetailDialog(BuildContext context, String taskId) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: _TaskDetailCard(taskId: taskId),
            ),
          ),
        ),
      );
    },
  );
}

/// Card chi tiết task – dùng chung cho cả Screen và Dialog
class _TaskDetailCard extends StatefulWidget {
  final String taskId;
  const _TaskDetailCard({required this.taskId});

  @override
  State<_TaskDetailCard> createState() => _TaskDetailCardState();
}

class _TaskDetailCardState extends State<_TaskDetailCard> {
  late final TasksService _tasksService;
  bool _isLoading = true;
  String? _error;
  Task? _task;

  @override
  void initState() {
    super.initState();
    _tasksService = locator<TasksService>();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _tasksService.getTask(widget.taskId);
      if (res.isSuccess) {
        setState(() {
          _task = res.value;
          _isLoading = false;
        });
        return;
      }
      throw Exception(res.error.message);
    } catch (e) {
      setState(() {
        _error = 'Failed to load task: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_isLoading) {
      return const Center(child: LoadingView(message: 'Loading task...'));
    }
    if (_error != null) {
      return Center(
        child: ErrorView(message: _error!, onRetry: _load),
      );
    }
    if (_task == null) {
      return const Center(child: Text('No task data'));
    }

    final task = _task!;

    return DefaultTabController(
      length: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            tabs: const [
              Tab(text: 'Details'),
              Tab(text: 'Activity Log'),
            ],
            labelColor: cs.primary,
            unselectedLabelColor: cs.onSurfaceVariant,
            indicatorColor: cs.primary,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 500,
            child: TabBarView(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HEADER ROW
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.subject,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Task • ${_formatShortDate(task.createdAt)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          ManagerOrAdminOnly(
                            child: IconButton(
                              tooltip: 'Edit task',
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final res = await AppRouter.navigateTo<bool?>(
                                  context,
                                  AppRouter.taskEdit,
                                  arguments: TaskEditArgs(taskId: task.id),
                                );
                                if (res == true && context.mounted) {
                                  Navigator.of(context).pop(true);
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(),

                      const SizedBox(height: 16),

                      // STATUS + PRIORITY + DUE DATE
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _InfoChip(
                            label: 'Status',
                            child: _StatusChip(task: task),
                          ),
                          _InfoChip(
                            label: 'Priority',
                            child: _PriorityChip(task: task),
                          ),
                          _InfoChip(
                            label: 'Due date',
                            child: Text(
                              task.dueDate != null
                                  ? _formatShortDate(task.dueDate!)
                                  : 'No due date',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: task.isOverdue
                                    ? cs.error
                                    : cs.onSurfaceVariant,
                                fontWeight: task.isOverdue
                                    ? FontWeight.w600
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // DESCRIPTION
                      Text(
                        'Description',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (task.description != null &&
                                  task.description!.trim().isNotEmpty)
                              ? task.description!
                              : 'No description provided.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ASSIGNED TO
                      Row(
                        children: [
                          Text(
                            'Assigned To',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          _buildReassignButton(context, cs),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          task.ownerName ?? 'Unassigned',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: task.ownerName == null
                                ? cs.onSurfaceVariant.withOpacity(0.6)
                                : cs.onSurfaceVariant,
                            fontStyle: task.ownerName == null
                                ? FontStyle.italic
                                : null,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // METADATA
                      Text(
                        'Activity',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _MetaLine(
                              label: 'Created at',
                              value: _formatLongDate(task.createdAt),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _MetaLine(
                              label: 'Last updated',
                              value: _formatLongDate(task.updatedAt),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ActivityLogWidget(entityId: widget.taskId, entityType: 'Task'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatShortDate(DateTime date) =>
      '${date.year}-${_two(date.month)}-${_two(date.day)}';

  String _formatLongDate(DateTime date) =>
      '${_two(date.day)}/${_two(date.month)}/${date.year} '
      '${_two(date.hour)}:${_two(date.minute)}';

  String _two(int n) => n.toString().padLeft(2, '0');

  Future<void> _showReassignDialog() async {
    if (_task == null) return;

    String? newOwnerId = _task!.ownerId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reassign Task'),
              content: SizedBox(
                width: 400,
                child: OwnerDropdown(
                  initialOwnerId: _task!.ownerId,
                  entityType: 'task',
                  onChanged: (value) => newOwnerId = value,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Reassign'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true &&
        newOwnerId != null &&
        newOwnerId!.isNotEmpty &&
        mounted) {
      await _reassignTask(newOwnerId!);
    }
  }

  Future<void> _reassignTask(String newOwnerId) async {
    if (_task == null) return;

    final updatedTask = _task!.copyWith(ownerId: newOwnerId);
    final result = await _tasksService.updateTask(updatedTask);

    if (!mounted) return;

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task reassigned successfully')),
      );
      _load(); // Reload task data
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reassign: ${result.error.message}')),
      );
    }
  }

  Widget _buildReassignButton(BuildContext context, ColorScheme cs) {
    final authService = locator<AuthService>();
    final userRole = authService.currentUser?.role;

    // Any staff member can reassign tasks (it's just updating the owner)
    final canReassign =
        userRole == 'MANAGER' || userRole == 'ADMIN' || userRole == 'AGENT';

    if (!canReassign) return const SizedBox.shrink();

    return OutlinedButton.icon(
      onPressed: _showReassignDialog,
      icon: const Icon(Icons.person_add, size: 16),
      label: const Text('Reassign'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// Chip hiển thị status
class _StatusChip extends StatelessWidget {
  final Task task;
  const _StatusChip({required this.task});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color bg;
    Color fg;

    switch (task.status) {
      case TaskStatus.notStarted:
        bg = cs.surfaceVariant;
        fg = cs.onSurfaceVariant;
        break;
      case TaskStatus.inProgress:
        bg = cs.primaryContainer;
        fg = cs.onPrimaryContainer;
        break;
      case TaskStatus.completed:
        bg = cs.secondaryContainer;
        fg = cs.onSecondaryContainer;
        break;
      case TaskStatus.cancelled:
        bg = cs.errorContainer;
        fg = cs.onErrorContainer;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        task.status.value,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Chip hiển thị priority
class _PriorityChip extends StatelessWidget {
  final Task task;
  const _PriorityChip({required this.task});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color color;
    IconData icon;

    switch (task.priority) {
      case TaskPriority.high:
        color = cs.error;
        icon = Icons.priority_high;
        break;
      case TaskPriority.normal:
        color = cs.primary;
        icon = Icons.flag;
        break;
      case TaskPriority.low:
        color = cs.onSurfaceVariant;
        icon = Icons.flag_outlined;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          task.priority.value,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Ô nhỏ label + nội dung (Status / Priority / Due date)
class _InfoChip extends StatelessWidget {
  final String label;
  final Widget child;
  const _InfoChip({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

/// Dòng metadata
class _MetaLine extends StatelessWidget {
  final String label;
  final String value;
  const _MetaLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

// Helper functions for _TaskDetailCardState
