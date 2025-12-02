import 'package:flutter/material.dart';
import '../../services/tickets_service.dart';
import '../../services/service_locator.dart';
import '../../models/ticket.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';

class TicketEditArgs {
  const TicketEditArgs({required this.ticketId});
  final String ticketId;
}

class TicketEditScreen extends StatefulWidget {
  final String ticketId;
  const TicketEditScreen({super.key, required this.ticketId});

  @override
  State<TicketEditScreen> createState() => _TicketEditScreenState();
}

class _TicketEditScreenState extends State<TicketEditScreen> {
  late final TicketsService _ticketsService;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _subjectCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  
  // State variables
  TicketPriority? _priority;
  TicketStatus? _status;
  Ticket? _ticket;
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ticketsService = locator<TicketsService>();
    _load();
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await _ticketsService.getTicket(widget.ticketId);
    
    if (res.isSuccess) {
      _ticket = res.value;
      // Fill data vào form
      _subjectCtrl.text = _ticket!.subject;
      _descriptionCtrl.text = _ticket!.description ?? '';
      _priority = _ticket!.priority;
      _status = _ticket!.status;
      
      setState(() => _isLoading = false);
    } else {
      setState(() {
        _error = res.error.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _ticket == null) return;
    
    setState(() => _isSaving = true);

    final data = {
      'subject': _subjectCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim(),
      if (_priority != null) 'priority': _priority!.value,
      if (_status != null) 'status': _status!.value,
    };

    final res = await _ticketsService.updateTicket(_ticket!.id, data);
    
    if (res.isSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket updated successfully')),
        );
        Navigator.of(context).pop(true); 
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: ${res.error.message}')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingView(message: 'Loading ticket details...'));
    if (_error != null) return Scaffold(body: ErrorView(message: _error!, onRetry: _load));

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Decoration chung cho các input
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: cs.surfaceVariant.withOpacity(0.3),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outline.withOpacity(0.1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Nền xám Dashboard
      appBar: AppBar(
        title: const Text('Edit Ticket'),
        backgroundColor: const Color(0xFFF3F4F6),
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
            constraints: const BoxConstraints(maxWidth: 600), // Giới hạn chiều rộng
            child: Card(
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              color: cs.surface,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cs.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.edit_note, color: cs.primary),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ticket #${_ticket?.ticketNumber ?? _ticket?.id.substring(0, 4) ?? ''}',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Update details and status',
                                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Form Fields
                      TextFormField(
                        controller: _subjectCtrl,
                        decoration: inputDecoration.copyWith(
                          labelText: 'Subject',
                          prefixIcon: Icon(Icons.title, color: cs.primary),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter subject' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _descriptionCtrl,
                        decoration: inputDecoration.copyWith(
                          labelText: 'Description',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.description_outlined, color: cs.onSurfaceVariant),
                        ),
                        maxLines: 5,
                      ),
                      const SizedBox(height: 16),

                      // Row: Priority & Status
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<TicketPriority>(
                              value: _priority,
                              decoration: inputDecoration.copyWith(labelText: 'Priority'),
                              items: TicketPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.value))).toList(),
                              onChanged: (v) => setState(() => _priority = v),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<TicketStatus>(
                              value: _status,
                              decoration: inputDecoration.copyWith(labelText: 'Status'),
                              items: TicketStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.value))).toList(),
                              onChanged: (v) => setState(() => _status = v),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 40),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: _isSaving ? null : _save,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: _isSaving 
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.save_outlined),
                            label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
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