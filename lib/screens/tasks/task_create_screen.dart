import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/service_locator.dart';
import '../../services/auth/auth_service.dart';
import '../../services/tasks_service.dart';

/// Màn tạo task dạng "popup card" ở giữa (dùng khi điều hướng bằng route)
class TaskCreateScreen extends StatelessWidget {
  const TaskCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Nền xám nhạt dashboard
      appBar: AppBar(
        title: const Text('Create Task'),
        backgroundColor: const Color(0xFFF3F4F6),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              color: cs.surface,
              child: _TaskForm(
                onDone: (created) {
                  Navigator.of(context).pop(created);
                },
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
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
      firstDate: now.subtract(const Duration(days: 365)), // Cho phép chọn quá khứ nếu cần
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

    // Helper decoration cho các input field
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: cs.surfaceVariant.withOpacity(0.3), // Màu nền nhẹ cho input
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outline.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== HEADER =====
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Task',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add a new item to your workspace',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => widget.onDone(false),
                icon: Icon(Icons.close, color: cs.onSurfaceVariant),
                tooltip: 'Close',
              ),
            ],
          ),
          
          const SizedBox(height: 24),

          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.errorContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: cs.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!, style: TextStyle(color: cs.onSurface)),
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
                  decoration: inputDecoration.copyWith(
                    labelText: 'Subject',
                    hintText: 'e.g. Review Q3 Reports',
                    prefixIcon: Icon(Icons.check_circle_outline, color: cs.primary),
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
                  decoration: inputDecoration.copyWith(
                    labelText: 'Description',
                    hintText: 'Add details here...',
                    prefixIcon: Icon(Icons.notes, color: cs.onSurfaceVariant),
                    alignLabelWithHint: true, // Căn label lên trên cho text area
                  ),
                  maxLines: 4,
                  minLines: 2,
                ),
                const SizedBox(height: 16),

                // Priority & Due Date Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Priority Dropdown
                    Expanded(
                      flex: 4,
                      child: DropdownButtonFormField<TaskPriority>(
                        value: _priority,
                        decoration: inputDecoration.copyWith(
                          labelText: 'Priority',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        items: TaskPriority.values.map((p) {
                          Color pColor;
                          IconData pIcon;
                          switch(p) {
                            case TaskPriority.high:
                              pColor = cs.error;
                              pIcon = Icons.priority_high;
                              break;
                            case TaskPriority.low:
                              pColor = Colors.green;
                              pIcon = Icons.low_priority;
                              break;
                            default: 
                              pColor = Colors.orange;
                              pIcon = Icons.flag;
                          }
                          return DropdownMenuItem(
                            value: p,
                            child: Row(
                              children: [
                                Icon(pIcon, size: 16, color: pColor),
                                const SizedBox(width: 8),
                                Text(p.value),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _priority = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Due Date Picker
                    Expanded(
                      flex: 5,
                      child: InkWell(
                        onTap: _pickDueDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: inputDecoration.copyWith(
                            labelText: 'Due Date',
                            suffixIcon: _dueDate != null 
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () => setState(() => _dueDate = null),
                                ) 
                              : const Icon(Icons.calendar_today, size: 18),
                          ),
                          child: Text(
                            _dueDate == null
                                ? 'Set date'
                                : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                            style: TextStyle(
                              color: _dueDate == null 
                                ? cs.onSurfaceVariant.withOpacity(0.7) 
                                : cs.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ===== ACTIONS =====
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isLoading ? null : () => widget.onDone(false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _isLoading ? null : _createTask,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isLoading 
                  ? const SizedBox(
                      width: 18, height: 18, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
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
}