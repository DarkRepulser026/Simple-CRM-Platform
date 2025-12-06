import 'package:flutter/material.dart';
import '../models/ticket.dart';

/// Callback type for status changes
typedef OnStatusChanged = Future<void> Function(TicketStatus newStatus);

/// Callback type for priority changes
typedef OnPriorityChanged = Future<void> Function(TicketPriority newPriority);

/// Callback type for category changes
typedef OnCategoryChanged = Future<void> Function(String newCategory);

/// Callback type for reassignment
typedef OnReassign = Future<void> Function(String newOwnerId);

/// Callback type for resolve action
typedef OnResolve = Future<void> Function(String? resolutionNote);

/// Callback type for close action
typedef OnClose = Future<void> Function();

/// Callback type for reopen action
typedef OnReopen = Future<void> Function();

/// Quick actions panel for ticket operations
class TicketActionsPanel extends StatefulWidget {
  final Ticket ticket;
  final List<String> availableCategories;
  final List<({String id, String name})> availableAgents;
  final OnStatusChanged? onStatusChanged;
  final OnPriorityChanged? onPriorityChanged;
  final OnCategoryChanged? onCategoryChanged;
  final OnReassign? onReassign;
  final OnResolve? onResolve;
  final OnClose? onClose;
  final OnReopen? onReopen;
  final bool isLoading;
  final String? error;
  final VoidCallback? onErrorDismissed;

  const TicketActionsPanel({
    super.key,
    required this.ticket,
    this.availableCategories = const [],
    this.availableAgents = const [],
    this.onStatusChanged,
    this.onPriorityChanged,
    this.onCategoryChanged,
    this.onReassign,
    this.onResolve,
    this.onClose,
    this.onReopen,
    this.isLoading = false,
    this.error,
    this.onErrorDismissed,
  });

  @override
  State<TicketActionsPanel> createState() => _TicketActionsPanelState();
}

class _TicketActionsPanelState extends State<TicketActionsPanel> {
  late TicketStatus _selectedStatus;
  late TicketPriority _selectedPriority;
  String? _selectedCategory;
  String? _selectedAgent;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.ticket.status;
    _selectedPriority = widget.ticket.priority;
    _selectedCategory = widget.ticket.category;
    _selectedAgent = widget.ticket.ownerId;
  }

  @override
  void didUpdateWidget(TicketActionsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ticket.status != widget.ticket.status) {
      _selectedStatus = widget.ticket.status;
    }
    if (oldWidget.ticket.priority != widget.ticket.priority) {
      _selectedPriority = widget.ticket.priority;
    }
    if (oldWidget.ticket.category != widget.ticket.category) {
      _selectedCategory = widget.ticket.category;
    }
    if (oldWidget.ticket.ownerId != widget.ticket.ownerId) {
      _selectedAgent = widget.ticket.ownerId;
    }
  }

  Future<void> _handleStatusChange(TicketStatus? newStatus) async {
    if (newStatus == null) return;
    
    setState(() => _selectedStatus = newStatus);
    await widget.onStatusChanged?.call(newStatus);
  }

  Future<void> _handlePriorityChange(TicketPriority? newPriority) async {
    if (newPriority == null) return;
    
    setState(() => _selectedPriority = newPriority);
    await widget.onPriorityChanged?.call(newPriority);
  }

  Future<void> _handleCategoryChange(String? newCategory) async {
    if (newCategory == null) return;
    
    setState(() => _selectedCategory = newCategory);
    await widget.onCategoryChanged?.call(newCategory);
  }

  Future<void> _handleReassign(String? agentId) async {
    if (agentId == null) return;
    
    setState(() => _selectedAgent = agentId);
    await widget.onReassign?.call(agentId);
  }

  Future<void> _handleResolve() async {
    final resolutionNote = await _showResolutionDialog(context);
    if (resolutionNote != null) {
      await widget.onResolve?.call(resolutionNote);
    }
  }

  Future<void> _handleClose() async {
    await widget.onClose?.call();
  }

  Future<void> _handleReopen() async {
    await widget.onReopen?.call();
  }

  Future<String?> _showResolutionDialog(BuildContext context) {
    return showDialog<String?>(
      context: context,
      builder: (ctx) => _ResolutionDialog(
        ticketSubject: widget.ticket.subject,
      ),
    );
  }

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return Colors.green;
      case TicketStatus.inProgress:
        return Colors.blue;
      case TicketStatus.resolved:
        return Colors.cyan;
      case TicketStatus.closed:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.urgent:
      case TicketPriority.high:
        return Colors.red;
      case TicketPriority.normal:
        return Colors.blue;
      case TicketPriority.low:
        return Colors.grey;
    }
  }

  bool _canTransitionTo(TicketStatus targetStatus) {
    final current = _selectedStatus;
    
    // Define valid transitions
    const transitions = {
      TicketStatus.open: [TicketStatus.inProgress, TicketStatus.resolved],
      TicketStatus.inProgress: [TicketStatus.resolved, TicketStatus.open],
      TicketStatus.resolved: [TicketStatus.closed, TicketStatus.open],
      TicketStatus.closed: [TicketStatus.open],
    };

    return transitions[current]?.contains(targetStatus) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Error message
        if (widget.error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.error!,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
                  ),
                ),
                if (widget.onErrorDismissed != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    iconSize: 18,
                    onPressed: widget.onErrorDismissed,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Action Title
        Text(
          'QUICK ACTIONS',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),

        // Status Dropdown
        _buildActionRow(
          context,
          label: 'Status',
          child: DropdownButton<TicketStatus>(
            value: _selectedStatus,
            isExpanded: true,
            underline: const SizedBox(),
            items: TicketStatus.values
                .where((s) => _canTransitionTo(s) || s == _selectedStatus)
                .map((status) {
              final color = _getStatusColor(status);
              return DropdownMenuItem(
                value: status,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(status.value),
                  ],
                ),
              );
            }).toList(),
            onChanged: widget.isLoading ? null : _handleStatusChange,
          ),
        ),
        const SizedBox(height: 12),

        // Priority Dropdown
        _buildActionRow(
          context,
          label: 'Priority',
          child: DropdownButton<TicketPriority>(
            value: _selectedPriority,
            isExpanded: true,
            underline: const SizedBox(),
            items: TicketPriority.values.map((priority) {
              final color = _getPriorityColor(priority);
              return DropdownMenuItem(
                value: priority,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        priority.value,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: widget.isLoading ? null : _handlePriorityChange,
          ),
        ),
        const SizedBox(height: 12),

        // Category Dropdown
        if (widget.availableCategories.isNotEmpty)
          _buildActionRow(
            context,
            label: 'Category',
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              underline: const SizedBox(),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('No Category'),
                ),
                ...widget.availableCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
              ],
              onChanged: widget.isLoading ? null : _handleCategoryChange,
            ),
          ),
        if (widget.availableCategories.isNotEmpty) const SizedBox(height: 12),

        // Reassign Dropdown
        if (widget.availableAgents.isNotEmpty)
          _buildActionRow(
            context,
            label: 'Assign To',
            child: DropdownButton<String>(
              value: _selectedAgent,
              isExpanded: true,
              underline: const SizedBox(),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Unassigned'),
                ),
                ...widget.availableAgents.map((agent) {
                  return DropdownMenuItem(
                    value: agent.id,
                    child: Text(agent.name),
                  );
                }).toList(),
              ],
              onChanged: widget.isLoading ? null : _handleReassign,
            ),
          ),
        if (widget.availableAgents.isNotEmpty) const SizedBox(height: 12),

        // Action Buttons
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Resolve Button (visible when not resolved/closed)
            if (widget.ticket.status != TicketStatus.resolved &&
                widget.ticket.status != TicketStatus.closed)
              ElevatedButton.icon(
                onPressed: widget.isLoading ? null : _handleResolve,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Resolve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),

            // Close Button (visible when resolved)
            if (widget.ticket.status == TicketStatus.resolved &&
                widget.ticket.status != TicketStatus.closed)
              ElevatedButton.icon(
                onPressed: widget.isLoading ? null : _handleClose,
                icon: const Icon(Icons.lock_outline),
                label: const Text('Close'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                ),
              ),

            // Reopen Button (visible when resolved/closed)
            if ((widget.ticket.status == TicketStatus.resolved ||
                    widget.ticket.status == TicketStatus.closed))
              ElevatedButton.icon(
                onPressed: widget.isLoading ? null : _handleReopen,
                icon: const Icon(Icons.restore),
                label: const Text('Reopen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),

        // Loading indicator
        if (widget.isLoading) ...[
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionRow(
    BuildContext context, {
    required String label,
    required Widget child,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: child),
      ],
    );
  }
}

/// Dialog for entering resolution notes
class _ResolutionDialog extends StatefulWidget {
  final String ticketSubject;

  const _ResolutionDialog({required this.ticketSubject});

  @override
  State<_ResolutionDialog> createState() => _ResolutionDialogState();
}

class _ResolutionDialogState extends State<_ResolutionDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Resolve Ticket'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add resolution notes (optional):',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 4,
            minLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter resolution details...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Resolve'),
        ),
      ],
    );
  }
}
