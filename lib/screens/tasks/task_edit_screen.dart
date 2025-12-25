import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/service_locator.dart';
import '../../services/tasks_service.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';

class TaskEditArgs {
  const TaskEditArgs({required this.taskId});
  final String taskId;
}

class TaskEditScreen extends StatefulWidget {
  final String taskId;
  const TaskEditScreen({super.key, required this.taskId});

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  late final TasksService _tasksService;
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
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
    setState(() => _isLoading = true);
    final res = await _tasksService.getTask(widget.taskId);
    if (res.isSuccess) {
      _task = res.value;
      _subjectCtrl.text = _task!.subject;
      _descriptionCtrl.text = _task!.description ?? '';
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _error = res.error.message);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _task == null) return;
    setState(() => _isLoading = true);
    final updated = _task!.copyWith(
      subject: _subjectCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      updatedAt: DateTime.now(),
    );
    final res = await _tasksService.updateTask(updated);
    if (res.isSuccess) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() { _error = res.error.message; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_isLoading && _task == null) {
      return const Scaffold(body: LoadingView(message: 'Loading task...'));
    }
    if (_error != null && _task == null) {
      return Scaffold(body: ErrorView(message: _error!, onRetry: _load));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Edit Task'),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===== HEADER =====
                      Text(
                        'Edit Task',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Update task details and save changes',
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
                              Icon(Icons.error_outline, color: cs.onErrorContainer, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(color: cs.onErrorContainer, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ===== FORM FIELDS =====
                      // Subject Field
                      TextFormField(
                        controller: _subjectCtrl,
                        decoration: InputDecoration(
                          labelText: 'Subject *',
                          hintText: 'e.g. Review Q3 Reports',
                          prefixIcon: Icon(Icons.task_alt_outlined, color: cs.primary),
                          filled: true,
                          fillColor: cs.surfaceVariant.withOpacity(0.3),
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
                            borderSide: BorderSide(color: cs.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                            child: Icon(Icons.description_outlined, color: cs.onSurfaceVariant),
                          ),
                          filled: true,
                          fillColor: cs.surfaceVariant.withOpacity(0.3),
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
                            borderSide: BorderSide(color: cs.primary, width: 2),
                          ),
                          alignLabelWithHint: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        maxLines: 3,
                        minLines: 2,
                      ),

                      const SizedBox(height: 28),

                      // ===== ACTION BUTTONS =====
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: _isLoading ? null : _save,
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
                            label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
