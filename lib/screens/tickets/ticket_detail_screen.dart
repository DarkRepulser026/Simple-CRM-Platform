import 'package:flutter/material.dart';
import '../../models/ticket.dart';
import '../../services/service_locator.dart';
import '../../navigation/app_router.dart';
import 'ticket_edit_screen.dart';
import '../../services/tickets_service.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

// Argument class để truyền ID khi navigate
class TicketDetailArgs {
  final String ticketId;
  const TicketDetailArgs({required this.ticketId});
}

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  late final TicketsService _ticketsService;
  late Future<Ticket> _futureTicket;

  @override
  void initState() {
    super.initState();
    _ticketsService = locator<TicketsService>();
    _futureTicket = _fetchTicket();
  }

  Future<Ticket> _fetchTicket() async {
    final res = await _ticketsService.getTicket(widget.ticketId);
    if (res.isSuccess) return res.value;
    throw Exception(res.error.message);
  }

  void _refresh() {
    setState(() {
      _futureTicket = _fetchTicket();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const bgColor = Color(0xFFE9EDF5); // Màu nền Dashboard

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Ticket Details',
          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: cs.onSurface),
            tooltip: 'Edit Ticket',
            onPressed: () async {
              final res = await AppRouter.navigateTo<bool?>(
                context,
                AppRouter.ticketEdit,
                arguments: TicketEditArgs(ticketId: widget.ticketId),
              );
              if (res == true) Navigator.of(context).pop(true);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<Ticket>(
        future: _futureTicket,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(message: 'Loading ticket details...');
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Ticket not found'));
          }

          final ticket = snapshot.data!;
          
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: isWide 
                        ? _buildWideLayout(context, ticket) 
                        : _buildNarrowLayout(context, ticket),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- LAYOUTS ---

  // Layout cho Desktop/Web (2 cột)
  Widget _buildWideLayout(BuildContext context, Ticket ticket) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: Column(
            children: [
              _buildMainInfoCard(context, ticket),
              const SizedBox(height: 24),
              _buildActivitySection(context),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 3,
          child: _buildSidebarCard(context, ticket),
        ),
      ],
    );
  }

  // Layout cho Mobile
  Widget _buildNarrowLayout(BuildContext context, Ticket ticket) {
    return Column(
      children: [
        _buildMainInfoCard(context, ticket),
        const SizedBox(height: 24),
        _buildSidebarCard(context, ticket),
        const SizedBox(height: 24),
        _buildActivitySection(context),
      ],
    );
  }

  // --- WIDGET COMPONENTS ---

  /// Card with Title & Description
  Widget _buildMainInfoCard(BuildContext context, Ticket ticket) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ticketNum = ticket.ticketNumber ?? ticket.id.substring(0, 8);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb / ID
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#$ticketNum',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _formatDate(ticket.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Subject
          Text(
            ticket.subject,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          
          // Description Label
          Text(
            'Description',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          
          // Description Content
          Text(
            ticket.description != null && ticket.description!.isNotEmpty 
                ? ticket.description! 
                : 'No description provided.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// The card on the right displays metadata (Status, Priority, Assignee...)
  Widget _buildSidebarCard(BuildContext context, Ticket ticket) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Properties',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cs.onSurface),
          ),
          const SizedBox(height: 24),
          
          _buildPropertyRow(context, 'Status', _buildStatusChip(context, ticket.status)),
          const Divider(height: 32),
          
          _buildPropertyRow(context, 'Priority', _buildPriorityRow(context, ticket.priority)),
          const Divider(height: 32),
          
          _buildPropertyRow(context, 'Type', Text(ticket.type.value)),
          const Divider(height: 32),
          
          _buildPropertyRow(context, 'Assignee', _buildAssigneeRow(context, ticket.assigneeName)),
          const Divider(height: 32),
          
          _buildPropertyRow(context, 'Requester', 
            Text(ticket.createdById ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w500))
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyRow(BuildContext context, String label, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  /// Phần Activity / Comments (Giả lập giao diện)
  Widget _buildActivitySection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'Activity',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: cs.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Input giả
          TextField(
            decoration: InputDecoration(
              hintText: 'Add an internal note or reply...',
              filled: true,
              fillColor: cs.surfaceVariant.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {},
                color: cs.primary,
              ),
            ),
            maxLines: 2,
          ),
          
          const SizedBox(height: 32),
          
          // List Activity (Demo static)
          _buildActivityItem(context, 'System', 'Ticket created', '2 days ago', isSystem: true),
          _buildActivityItem(context, 'Admin', 'Changed priority to High', '1 day ago', isSystem: true),
          _buildActivityItem(context, 'Support Agent', 'Hello, we are looking into this issue. Please provide more logs.', '5 hours ago', isSystem: false),
        ],
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, String user, String content, String time, {bool isSystem = false}) {
    final cs = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isSystem ? cs.surfaceVariant : cs.primaryContainer,
            child: Text(
              user[0], 
              style: TextStyle(
                fontSize: 12, 
                color: isSystem ? cs.onSurfaceVariant : cs.onPrimaryContainer, 
                fontWeight: FontWeight.bold
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(user, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(width: 8),
                    Text(time, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  content, 
                  style: TextStyle(
                    color: isSystem ? cs.onSurfaceVariant : cs.onSurface,
                    fontStyle: isSystem ? FontStyle.italic : FontStyle.normal
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPERS HIỂN THỊ ---

  Widget _buildStatusChip(BuildContext context, TicketStatus status) {
    Color bg, fg;
    switch (status) {
      case TicketStatus.open: bg = Colors.green.shade50; fg = Colors.green.shade700; break;
      case TicketStatus.pending: bg = Colors.orange.shade50; fg = Colors.orange.shade800; break;
      case TicketStatus.closed: bg = Colors.grey.shade100; fg = Colors.grey.shade700; break;
      default: bg = Colors.blue.shade50; fg = Colors.blue.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(status.value, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildPriorityRow(BuildContext context, TicketPriority priority) {
    IconData icon;
    Color color;
    switch (priority) {
      case TicketPriority.critical:
      case TicketPriority.urgent:
      case TicketPriority.high:
        icon = Icons.warning_amber_rounded; color = Colors.red; break;
      case TicketPriority.medium:
        icon = Icons.density_medium_rounded; color = Colors.orange; break;
      case TicketPriority.normal:
        icon = Icons.horizontal_rule_rounded; color = Theme.of(context).colorScheme.primary; break;
      default:
        icon = Icons.arrow_downward_rounded; color = Colors.grey;
    }
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(priority.value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildAssigneeRow(BuildContext context, String? assigneeName) {
    if (assigneeName == null || assigneeName.isEmpty) {
      return const Text('Unassigned', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey));
    }
    return Row(
      children: [
        CircleAvatar(radius: 12, backgroundColor: Colors.blue.shade100, child: Text(assigneeName[0], style: const TextStyle(fontSize: 10))),
        const SizedBox(width: 8),
        Text(assigneeName, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour}:${date.minute}";
  }
}

/// Dialog helper to show ticket detail as modal. Keeps consistent look with TicketDetailScreen content.
Future<bool?> showTicketDetailDialog(BuildContext context, {required String ticketId}) {
  return showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(child: TicketDetailScreen(ticketId: ticketId)),
        ),
      ),
    ),
  );
}