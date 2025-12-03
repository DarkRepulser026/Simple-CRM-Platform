import 'package:flutter/material.dart';
import '../../widgets/paginated_list_view.dart';
import '../../models/ticket.dart';
import '../../navigation/app_router.dart';
import '../../services/auth/auth_service.dart';
import '../../widgets/error_view.dart';
import '../../services/tickets_service.dart';
import '../../services/service_locator.dart';

class TicketsListScreen extends StatefulWidget {
  const TicketsListScreen({super.key});

  @override
  State<TicketsListScreen> createState() => _TicketsListScreenState();
}

class _TicketsListScreenState extends State<TicketsListScreen> {
  late final TicketsService _ticketsService;
  final TextEditingController _searchCtrl = TextEditingController();
  int _reloadVersion = 0;

  @override
  void initState() {
    super.initState();
    _ticketsService = locator<TicketsService>();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<Ticket>> _fetchTicketsPage(int page, int limit) async {
    try {
      final res = await _ticketsService.getTickets(
        page: page,
        limit: limit,
        // search: _searchCtrl.text, // Uncomment nếu API đã hỗ trợ search
      );
      if (res.isSuccess) {
        var tickets = res.value.tickets;
        
        // Filter local (dùng tạm khi chưa có API search)
        if (_searchCtrl.text.isNotEmpty) {
          final q = _searchCtrl.text.toLowerCase();
          tickets = tickets.where((t) {
            final subjectMatch = t.subject.toLowerCase().contains(q);
            // Xử lý null cho ticketNumber trước khi search
            final numberMatch = (t.ticketNumber ?? '').toLowerCase().contains(q);
            return subjectMatch || numberMatch;
          }).toList();
        }
        return tickets;
      }
      throw Exception(res.error.message);
    } catch (e) {
      throw Exception('Failed to load tickets: $e');
    }
  }

  void _refreshList() => setState(() => _reloadVersion++);

  Future<void> _navigateToTicketDetail(String ticketId) async {
    final changed = await AppRouter.navigateTo<bool?>(
      context,
      AppRouter.ticketDetail,
      arguments: TicketDetailArgs(ticketId: ticketId),
    );
    if (changed == true) _refreshList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = locator<AuthService>();
    if (auth.isLoggedIn && !auth.hasSelectedOrganization) {
      return Scaffold(
        body: ErrorView(
          message: 'No organization selected.',
          onRetry: () => AppRouter.navigateTo(context, AppRouter.companySelection),
        ),
      );
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    const bgColor = Color(0xFFE9EDF5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bgColor,
        title: const Text(''),
        iconTheme: IconThemeData(color: cs.onSurface),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshList,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // ===== HEADER =====
                Row(
                  children: [
                    Text(
                      'Tickets',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Support',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 16),

                // ===== ACTIONS =====
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search by subject or ticket ID',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: cs.surface.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: BorderSide(color: cs.outline.withOpacity(0.2)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        ),
                        onSubmitted: (_) => _refreshList(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () async {
                        final res = await AppRouter.navigateTo(context, AppRouter.ticketCreate);
                        if (res == true) _refreshList();
                      },
                      icon: const Icon(Icons.add_comment_outlined, size: 18),
                      label: const Text('New ticket'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ===== TABLE CARD =====
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.outline.withOpacity(0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            color: cs.surfaceVariant.withOpacity(0.2),
                          ),
                          child: Row(
                            children: [
                              _HeaderCell('Subject', flex: 4),
                              _HeaderCell('Status', flex: 2),
                              _HeaderCell('Priority', flex: 2),
                              _HeaderCell('Assignee', flex: 2),
                              _HeaderCell('Created', flex: 2, align: TextAlign.right),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        // List
                        Expanded(
                          child: PaginatedListView<Ticket>(
                            key: ValueKey(_reloadVersion),
                            fetchPage: _fetchTicketsPage,
                            pageSize: 20,
                            emptyMessage: 'No tickets found',
                            errorMessage: 'Failed to load tickets',
                            loadingMessage: 'Loading tickets...',
                            itemBuilder: (context, ticket, index) => _TicketRow(
                              ticket: ticket,
                              onTap: () => _navigateToTicketDetail(ticket.id),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final int flex;
  final TextAlign align;
  const _HeaderCell(this.label, {this.flex = 1, this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: align,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTap;
  const _TicketRow({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final createdStr = "${ticket.createdAt.year}-${ticket.createdAt.month.toString().padLeft(2,'0')}-${ticket.createdAt.day.toString().padLeft(2,'0')}";

    final assigneeName = ticket.assigneeName ?? '';
    final displayAssignee = assigneeName.isEmpty ? 'Unassigned' : assigneeName;
    final initialAssignee = assigneeName.isNotEmpty ? assigneeName[0].toUpperCase() : '?';
    final ticketNum = ticket.ticketNumber ?? '---';

    return InkWell(
      onTap: onTap,
      hoverColor: cs.surfaceVariant.withOpacity(0.1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: cs.outline.withOpacity(0.06))),
        ),
        child: Row(
          children: [
            // Subject
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ticket.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '#$ticketNum', 
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant, 
                      fontSize: 11
                    ),
                  ),
                ],
              ),
            ),
            // Status
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _StatusChip(status: ticket.status),
              ),
            ),
            // Priority
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  _PriorityIcon(priority: ticket.priority),
                  const SizedBox(width: 6),
                  Text(
                    ticket.priority.value,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            // Assignee
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: cs.secondaryContainer,
                    child: Text(
                      initialAssignee,
                      style: TextStyle(fontSize: 10, color: cs.onSecondaryContainer),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      displayAssignee,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            // Created Date
            Expanded(
              flex: 2,
              child: Text(
                createdStr,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final TicketStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (status) {
      case TicketStatus.open:
        bg = Colors.green.withOpacity(0.1); fg = Colors.green[700]!; break;
      case TicketStatus.pending:
        bg = Colors.orange.withOpacity(0.1); fg = Colors.orange[800]!; break;
      case TicketStatus.closed:
        bg = Colors.grey.withOpacity(0.15); fg = Colors.grey[700]!; break;
      default:
        bg = Colors.blue.withOpacity(0.1); fg = Colors.blue[700]!;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        status.value,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}

class _PriorityIcon extends StatelessWidget {
  final TicketPriority priority;
  const _PriorityIcon({required this.priority});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Xử lý đầy đủ tất cả các case trong Enum
    switch (priority) {
      case TicketPriority.critical:
      case TicketPriority.urgent:
      case TicketPriority.high:
        return const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red);
      
      case TicketPriority.medium:
        return const Icon(Icons.density_medium_rounded, size: 16, color: Colors.orange);
      
      case TicketPriority.normal:
        return Icon(Icons.horizontal_rule_rounded, size: 16, color: cs.primary);
      
      case TicketPriority.low:
        return Icon(Icons.arrow_downward_rounded, size: 16, color: cs.outline);
    }
  }
}