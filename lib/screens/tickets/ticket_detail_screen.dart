import 'package:flutter/material.dart';
import '../../models/ticket.dart';
import '../../services/service_locator.dart';
import '../../services/tickets_service.dart';
import '../../services/auth/auth_service.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/activity_log_widget.dart';
import '../../widgets/owner_dropdown.dart';

// Argument class để truyền ID khi navigate
class TicketDetailArgs {
  final String ticketId;
  const TicketDetailArgs({required this.ticketId});
}

class TicketDetailScreen extends StatelessWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Ticket Detail'),
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
                  child: _TicketDetailCard(
                    ticketId: ticketId,
                    onChanged: () {
                      // Reload on edit
                    },
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

/// Pop-up dialog dùng trong TicketsListScreen
Future<bool?> showTicketDetailDialog(
  BuildContext context, {
  required String ticketId,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    useRootNavigator: true,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: _TicketDetailCard(ticketId: ticketId),
          ),
        ),
      ),
    ),
  );
}

class _TicketDetailCard extends StatefulWidget {
  final String ticketId;
  final VoidCallback? onChanged;
  const _TicketDetailCard({required this.ticketId, this.onChanged});

  @override
  State<_TicketDetailCard> createState() => _TicketDetailCardState();
}

class _TicketDetailCardState extends State<_TicketDetailCard> {
  late final TicketsService _ticketsService;
  bool _isLoading = true;
  String? _error;
  Ticket? _ticket;

  @override
  void initState() {
    super.initState();
    _ticketsService = locator<TicketsService>();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _ticketsService.getTicket(widget.ticketId);
      if (res.isSuccess) {
        setState(() {
          _ticket = res.value;
          _isLoading = false;
        });
        return;
      }
      throw Exception(res.error.message);
    } catch (e) {
      setState(() {
        _error = 'Failed to load ticket: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showReassignDialog() async {
    if (_ticket == null) return;

    String? newOwnerId = _ticket!.ownerId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reassign Ticket'),
              content: SizedBox(
                width: 400,
                child: OwnerDropdown(
                  initialOwnerId: _ticket!.ownerId,
                  entityType: 'ticket',
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
      await _reassignTicket(newOwnerId!);
    }
  }

  Future<void> _reassignTicket(String newOwnerId) async {
    final result = await _ticketsService.assignTicket(_ticket!.id, newOwnerId);

    if (!mounted) return;

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket reassigned successfully')),
      );
      widget.onChanged?.call();
      _load(); // Reload ticket data
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reassign: ${result.error.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_isLoading) {
      return const Center(child: LoadingView(message: 'Loading ticket...'));
    }
    if (_error != null) {
      return Center(
        child: ErrorView(message: _error!, onRetry: _load),
      );
    }
    if (_ticket == null) {
      return const Center(child: Text('No ticket data'));
    }

    final ticket = _ticket!;
    final (statusBg, statusFg, statusIcon) = _getStatusStyle(ticket.status, cs);
    final priorityColor = _getPriorityColor(ticket.priority, cs);

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
                      // Header
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ticket.subject,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '#${ticket.id.substring(0, 8).toUpperCase()}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 14, color: statusFg),
                                const SizedBox(width: 4),
                                Text(
                                  ticket.status.value,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: statusFg,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(height: 1),
                      const SizedBox(height: 24),

                      // Details Section
                      Text(
                        'DETAILS',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Priority
                      _buildDetailRow(
                        context,
                        label: 'Priority',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            ticket.priority.value,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: priorityColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Category
                      if (ticket.category != null &&
                          ticket.category!.isNotEmpty)
                        _buildDetailRow(
                          context,
                          label: 'Category',
                          child: Text(ticket.category!),
                        ),
                      if (ticket.category != null &&
                          ticket.category!.isNotEmpty)
                        const SizedBox(height: 12),

                      // Owner with Reassign Button
                      _buildDetailRow(
                        context,
                        label: 'Assigned To',
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                ticket.ownerName ?? 'Unassigned',
                                style: TextStyle(
                                  color: ticket.ownerName == null
                                      ? cs.onSurfaceVariant.withOpacity(0.6)
                                      : null,
                                  fontStyle: ticket.ownerName == null
                                      ? FontStyle.italic
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildReassignButton(context, cs),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Created Date
                      _buildDetailRow(
                        context,
                        label: 'Created',
                        child: Text(ticket.createdAt.toString().split('.')[0]),
                      ),
                      const SizedBox(height: 12),

                      // Updated Date
                      _buildDetailRow(
                        context,
                        label: 'Last Updated',
                        child: Text(ticket.updatedAt.toString().split('.')[0]),
                      ),

                      if (ticket.description != null &&
                          ticket.description!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Divider(height: 1),
                        const SizedBox(height: 24),
                        Text(
                          'DESCRIPTION',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ticket.description!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                      const Divider(height: 1),
                      const SizedBox(height: 24),

                      // Edit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Ticket'),
                          onPressed: () => _showEditDialog(context),
                        ),
                      ),
                    ],
                  ),
                ),
                ActivityLogWidget(
                  entityId: widget.ticketId,
                  entityType: 'Ticket',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required Widget child,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: child),
      ],
    );
  }

  (Color, Color, IconData) _getStatusStyle(
    TicketStatus status,
    ColorScheme cs,
  ) {
    switch (status) {
      case TicketStatus.open:
        return (
          Colors.green.withOpacity(0.1),
          Colors.green[700]!,
          Icons.circle,
        );
      case TicketStatus.inProgress:
        return (
          Colors.blue.withOpacity(0.1),
          Colors.blue[700]!,
          Icons.autorenew,
        );
      case TicketStatus.resolved:
        return (
          Colors.cyan.withOpacity(0.1),
          Colors.cyan[700]!,
          Icons.check_circle,
        );
      case TicketStatus.closed:
        return (Colors.grey.withOpacity(0.15), Colors.grey[700]!, Icons.lock);
    }
  }

  Color _getPriorityColor(TicketPriority priority, ColorScheme cs) {
    switch (priority) {
      case TicketPriority.urgent:
      case TicketPriority.high:
        return Colors.red;
      case TicketPriority.normal:
        return cs.primary;
      case TicketPriority.low:
        return Colors.grey;
    }
  }

  Widget _buildReassignButton(BuildContext context, ColorScheme cs) {
    final authService = locator<AuthService>();
    final userRole = authService.currentUser?.role;

    // Only MANAGER and ADMIN can reassign
    final canReassign = userRole == 'MANAGER' || userRole == 'ADMIN';

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

  void _showEditDialog(BuildContext context) {
    if (_ticket == null) return;

    final subjectCtrl = TextEditingController(text: _ticket!.subject);
    final descriptionCtrl = TextEditingController(
      text: _ticket!.description ?? '',
    );
    final categoryCtrl = TextEditingController(text: _ticket!.category ?? '');
    String? selectedStatus = _ticket!.status.name;
    String? selectedPriority = _ticket!.priority.name;

    showDialog<bool>(
      context: context,
      builder: (dialogCtx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (ctx, setState) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Ticket',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Subject
                    TextField(
                      controller: subjectCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextField(
                      controller: descriptionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),

                    // Category
                    TextField(
                      controller: categoryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: TicketStatus.values
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.name,
                              child: Text(e.value),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => selectedStatus = val),
                    ),
                    const SizedBox(height: 16),

                    // Priority Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      items: TicketPriority.values
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.name,
                              child: Text(e.value),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => selectedPriority = val),
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => _saveTicket(
                            subjectCtrl.text,
                            descriptionCtrl.text,
                            categoryCtrl.text,
                            selectedStatus,
                            selectedPriority,
                            dialogCtx,
                          ),
                          child: const Text('Save'),
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
    );
  }

  Future<void> _saveTicket(
    String subject,
    String description,
    String category,
    String? status,
    String? priority,
    BuildContext dialogCtx,
  ) async {
    try {
      final updateData = {
        'subject': subject,
        if (description.isNotEmpty) 'description': description,
        if (category.isNotEmpty) 'category': category,
        if (status != null) 'status': status.toUpperCase(),
        if (priority != null) 'priority': priority.toUpperCase(),
      };

      final res = await _ticketsService.updateTicket(
        widget.ticketId,
        updateData,
      );

      if (res.isSuccess) {
        if (mounted) {
          Navigator.pop(dialogCtx);
          setState(() {
            _ticket = res.value;
          });
          widget.onChanged?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ticket updated successfully')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(dialogCtx).showSnackBar(
            SnackBar(content: Text('Error: ${res.error.message}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          dialogCtx,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
