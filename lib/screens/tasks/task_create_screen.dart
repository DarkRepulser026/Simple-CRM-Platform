import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/service_locator.dart';
import '../../services/auth/auth_service.dart';
import '../../services/tasks_service.dart';
import '../../widgets/owner_dropdown.dart';

/// Màn tạo task dạng "popup card" ở giữa (dùng khi điều hướng bằng route)
class TaskCreateScreen extends StatelessWidget {
  const TaskCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Create New Task'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: _TaskForm(
                  onDone: (created) {
                    Navigator.of(context).pop(created);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pop-up dialog dùng trong TasksListScreen
Future<bool?> showTaskCreateDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: _TaskForm(
            onDone: (created) {
              Navigator.of(ctx).pop(created);
            },
          ),
        ),
      );
    },
  );
}

/// Form chung
class _TaskForm extends StatefulWidget {
  const _TaskForm({required this.onDone});

  final void Function(bool created) onDone;

  @override
  State<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<_TaskForm> {
  late final TasksService _tasksService;
  final _formKey = GlobalKey<FormState>();

  final _subjectCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  TaskPriority _priority = TaskPriority.normal;
  DateTime? _dueDate;
  String? _ownerId;

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tasksService = locator<TasksService>();
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(
        const Duration(days: 365),
      ), // Cho phép chọn quá khứ nếu cần
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final orgId = locator<AuthService>().selectedOrganizationId ?? '';

    final task = Task(
      id: '',
      subject: _subjectCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      status: TaskStatus.notStarted,
      priority: _priority,
      organizationId: orgId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      dueDate: _dueDate,
      ownerId: _ownerId,
    );

    final res = await _tasksService.createTask(task);

    if (!mounted) return;

    if (res.isSuccess) {
      widget.onDone(true);
    } else {
      setState(() {
        _isLoading = false;
        _error = res.error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== HEADER =====
          Text(
            'Create New Task',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add a new task to your workspace',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 24),

          // ===== ERROR MESSAGE =====
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: cs.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: cs.onErrorContainer,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ===== FORM FIELDS =====
          Form(
            key: _formKey,
            child: Column(
              children: [
                // Subject Field
                TextFormField(
                  controller: _subjectCtrl,
                  decoration: InputDecoration(
                    labelText: 'Subject *',
                    hintText: 'e.g. Review Q3 Reports',
                    prefixIcon: Icon(
                      Icons.task_alt_outlined,
                      color: cs.primary,
                    ),
                    filled: true,
                    fillColor: cs.surfaceVariant.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: cs.outline.withOpacity(0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Subject is required'
                      : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Description Field
                TextFormField(
                  controller: _descriptionCtrl,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Add details here...',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Icon(
                        Icons.description_outlined,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    filled: true,
                    fillColor: cs.surfaceVariant.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: cs.outline.withOpacity(0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.primary, width: 2),
                    ),
                    alignLabelWithHint: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  maxLines: 3,
                  minLines: 2,
                ),
                const SizedBox(height: 16),

                // Priority & Due Date Row
                Row(
                  children: [
                    // Priority Dropdown
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<TaskPriority>(
                        value: _priority,
                        decoration: InputDecoration(
                          labelText: 'Priority',
                          prefixIcon: Icon(
                            Icons.flag_outlined,
                            color: cs.primary,
                          ),
                          filled: true,
                          fillColor: cs.surfaceVariant.withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: cs.outline.withOpacity(0.1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: cs.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                        items: TaskPriority.values.map((p) {
                          final pColor = _getPriorityColor(p, cs);
                          return DropdownMenuItem(
                            value: p,
                            child: Text(
                              p.value,
                              style: TextStyle(color: pColor),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _priority = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Due Date Picker
                    Expanded(
                      flex: 1,
                      child: InkWell(
                        onTap: _pickDueDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Due Date',
                            prefixIcon: Icon(
                              Icons.event_outlined,
                              color: cs.primary,
                            ),
                            filled: true,
                            fillColor: cs.surfaceVariant.withOpacity(0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: cs.outline.withOpacity(0.1),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                          child: Text(
                            _dueDate == null
                                ? 'Select date'
                                : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                            style: TextStyle(
                              color: _dueDate == null
                                  ? cs.onSurfaceVariant.withOpacity(0.5)
                                  : cs.onSurface,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Assign To (Owner Dropdown)
                OwnerDropdown(
                  entityType: 'task',
                  onChanged: (ownerId) {
                    setState(() => _ownerId = ownerId);
                  },
                  label: 'Assign To',
                  hintText: 'Select a manager or agent',
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ===== ACTION BUTTONS =====
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isLoading ? null : () => widget.onDone(false),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _isLoading ? null : _createTask,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(_isLoading ? 'Creating...' : 'Create Task'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority, ColorScheme cs) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red[600]!;
      case TaskPriority.normal:
        return cs.primary;
      case TaskPriority.low:
        return Colors.amber[600]!;
    }
  }
}
