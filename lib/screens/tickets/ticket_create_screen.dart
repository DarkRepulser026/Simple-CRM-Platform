import 'package:flutter/material.dart';
import '../../models/ticket.dart';
import '../../services/service_locator.dart';
import '../../services/auth/auth_service.dart';
import '../../services/tickets_service.dart';
import '../../widgets/owner_dropdown.dart';
import '../../widgets/contact_dropdown.dart';
import '../../widgets/account_dropdown.dart';
import 'ticket_detail_screen.dart';

class TicketCreateScreen extends StatefulWidget {
  final String? accountId;
  
  const TicketCreateScreen({super.key, this.accountId});

  @override
  State<TicketCreateScreen> createState() => _TicketCreateScreenState();
}

class _TicketCreateScreenState extends State<TicketCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  
  // Default values
  TicketPriority _priority = TicketPriority.normal;
  TicketStatus _status = TicketStatus.open;
  TicketType _type = TicketType.question;
  String? _ownerId;
  String? _contactId;
  String? _selectedAccountId; // For global creation when account is selected
  
  bool _isSubmitting = false;
  late final TicketsService _ticketsService;

  @override
  void initState() {
    super.initState();
    _ticketsService = locator<TicketsService>();
    _selectedAccountId = widget.accountId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final orgId = locator<AuthService>().selectedOrganizationId ?? '';

      final ticketMap = {
        'subject': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'priority': _priority.value,
        'status': _status.value,
        'ownerId': _ownerId,
        'organizationId': orgId,
        if (_selectedAccountId != null) 'accountId': _selectedAccountId,
        if (_contactId != null) 'contactId': _contactId,
      };
      
      final res = await _ticketsService.createTicket(ticketMap);
      // ---------------------

      if (res.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket created successfully')),
        );
        // Navigate to ticket detail screen
        final ticket = res.value;
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => TicketDetailScreen(ticketId: ticket.id),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create: ${res.error.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Style chung cho Input
    final inputDecor = InputDecoration(
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
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.all(16),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Nền xám Dashboard
      appBar: AppBar(
        title: const Text('New Ticket'),
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
                      // Header Form
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cs.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.support_agent, color: cs.primary, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.accountId != null ? 'New Ticket for Account' : 'New Ticket',
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Describe the issue clearly',
                                style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Title Field
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: inputDecor.copyWith(
                          labelText: 'Title',
                          hintText: 'e.g. Cannot login to dashboard',
                          prefixIcon: Icon(Icons.title, color: cs.primary),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Description Field
                      TextFormField(
                        controller: _descCtrl,
                        decoration: inputDecor.copyWith(
                          labelText: 'Description',
                          hintText: 'Provide details about the issue...',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.description_outlined, color: cs.onSurfaceVariant),
                        ),
                        maxLines: 5,
                        minLines: 3,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Row: Type & Priority
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Type
                          Expanded(
                            child: DropdownButtonFormField<TicketType>(
                              value: _type,
                              decoration: inputDecor.copyWith(labelText: 'Type'),
                              items: TicketType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.value))).toList(),
                              onChanged: (v) => setState(() => _type = v!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Priority
                          Expanded(
                            child: DropdownButtonFormField<TicketPriority>(
                              value: _priority,
                              decoration: inputDecor.copyWith(labelText: 'Priority'),
                              items: TicketPriority.values.map((p) => DropdownMenuItem(
                                value: p,
                                child: Row(
                                  children: [
                                    _buildPriorityIcon(p),
                                    const SizedBox(width: 8),
                                    Text(p.value),
                                  ],
                                ),
                              )).toList(),
                              onChanged: (v) => setState(() => _priority = v!),
                            ),
                          ),
                        ],
                      ),                      const SizedBox(height: 16),

                      // A. Account-based creation: Show account info + contact dropdown
                      if (widget.accountId != null)
                        Column(
                          children: [
                            // Display account context
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: cs.primary.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.business, color: cs.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Creating ticket for selected account',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: cs.onSurface,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Contact dropdown (optional)
                            ContactDropdown(
                              accountId: widget.accountId!,
                              onChanged: (contactId) {
                                setState(() => _contactId = contactId);
                              },
                              label: 'Contact (Optional)',
                              hintText: 'Select a contact from this account',
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),

                      // B. Global creation: Show account dropdown + conditional contact dropdown
                      if (widget.accountId == null)
                        Column(
                          children: [
                            AccountDropdown(
                              initialAccountId: _selectedAccountId,
                              onChanged: (accountId) {
                                setState(() {
                                  _selectedAccountId = accountId;
                                  // Clear contact if account changes
                                  if (_contactId != null) _contactId = null;
                                });
                              },
                              label: 'Account (Optional)',
                              hintText: 'Link ticket to an account',
                            ),
                            const SizedBox(height: 16),
                            // Show contact dropdown only if account is selected
                            if (_selectedAccountId != null)
                              Column(
                                children: [
                                  ContactDropdown(
                                    accountId: _selectedAccountId!,
                                    onChanged: (contactId) {
                                      setState(() => _contactId = contactId);
                                    },
                                    label: 'Contact (Optional)',
                                    hintText: 'Select a contact from this account',
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                          ],
                        ),

                      // Assign To Agent
                      OwnerDropdown(
                        entityType: 'ticket',
                        onChanged: (ownerId) {
                          setState(() => _ownerId = ownerId);
                        },
                        label: 'Assign To Agent',
                        hintText: 'Select an agent to handle this ticket',
                      ),                      
                      const SizedBox(height: 40),

                      // Actions Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: _isSubmitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: _isSubmitting 
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                              : const Icon(Icons.send_rounded),
                            label: Text(_isSubmitting ? 'Submitting...' : 'Submit Ticket'),
                          ),
                        ],
                      )
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

  // Helper to build priority icon
  Widget _buildPriorityIcon(TicketPriority p) {
    Color color;
    switch (p) {
      case TicketPriority.high:
      case TicketPriority.urgent:
        color = Colors.red;
        break;
      case TicketPriority.normal:
        color = Colors.blue;
        break;
      case TicketPriority.low:
        color = Colors.grey;
        break;
    }
    return Icon(Icons.circle, size: 10, color: color);
  }
}