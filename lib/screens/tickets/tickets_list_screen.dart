import 'package:flutter/material.dart';
import '../../widgets/paginated_list_view.dart';
import '../../models/ticket.dart';
import '../../models/pagination.dart';
import '../../navigation/app_router.dart';
import 'ticket_detail_screen.dart';
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
  String? _selectedStatus;
  String? _selectedPriority;
  bool _showMyTicketsOnly = false;
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

  void _refreshList() => setState(() => _reloadVersion++);

  Future<void> _navigateToTicketDetail(String ticketId) async {
    final changed = await showTicketDetailDialog(context, ticketId: ticketId);
    if (changed == true) _refreshList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = locator<AuthService>();
    if (auth.isLoggedIn && !auth.hasSelectedOrganization) {
      return Scaffold(
        body: ErrorView(
          message: 'No organization selected.',
          onRetry: () =>
              AppRouter.navigateTo(context, AppRouter.companySelection),
        ),
      );
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Tickets'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.support_agent, size: 14, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  'Support Board',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== SEARCH & FILTERS =====
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 300,
                          child: TextField(
                            controller: _searchCtrl,
                            decoration: InputDecoration(
                              hintText: 'Search tickets...',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: cs.outline.withOpacity(0.2),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: cs.outline.withOpacity(0.2),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: cs.primary),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 12,
                              ),
                            ),
                            onChanged: (_) => _refreshList(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 180,
                          child: DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('All Statuses'),
                              ),
                              DropdownMenuItem(
                                value: 'OPEN',
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Open'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'IN_PROGRESS',
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('In Progress'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'RESOLVED',
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Resolved'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'CLOSED',
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.grey,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Closed'),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (val) => setState(() {
                              _selectedStatus = val;
                              _reloadVersion++;
                            }),
                            decoration: InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 170,
                          child: DropdownButtonFormField<String>(
                            value: _selectedPriority,
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('All Priorities'),
                              ),
                              const DropdownMenuItem(
                                value: 'URGENT',
                                child: Text('Urgent'),
                              ),
                              const DropdownMenuItem(
                                value: 'HIGH',
                                child: Text('High'),
                              ),
                              const DropdownMenuItem(
                                value: 'NORMAL',
                                child: Text('Normal'),
                              ),
                              const DropdownMenuItem(
                                value: 'LOW',
                                child: Text('Low'),
                              ),
                            ],
                            onChanged: (val) => setState(() {
                              _selectedPriority = val;
                              _reloadVersion++;
                            }),
                            decoration: InputDecoration(
                              labelText: 'Priority',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // "My Tickets" Filter Chip
                        FilterChip(
                          label: const Text('My Tickets'),
                          selected: _showMyTicketsOnly,
                          onSelected: (selected) => setState(() {
                            _showMyTicketsOnly = selected;
                            _reloadVersion++;
                          }),
                          avatar: Icon(
                            _showMyTicketsOnly
                                ? Icons.person
                                : Icons.person_outline,
                            size: 18,
                          ),
                          backgroundColor: Colors.white,
                          selectedColor: cs.primary.withOpacity(0.15),
                          side: BorderSide(color: cs.outline.withOpacity(0.2)),
                        ),
                        const SizedBox(width: 16),

                        FilledButton.icon(
                          onPressed: () async {
                            final res = await AppRouter.navigateTo(
                              context,
                              AppRouter.ticketCreate,
                            );
                            if (res == true) _refreshList();
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('New Ticket'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ===== TICKETS LIST =====
                  SizedBox(
                    height: 700,
                    child: PaginatedListView<Ticket>(
                      key: ValueKey(_reloadVersion),
                      fetchPaginated: (page, limit) async {
                        final auth = locator<AuthService>();
                        final currentUserId = _showMyTicketsOnly
                            ? auth.currentUser?.id
                            : null;

                        final res = await _ticketsService.getTickets(
                          page: page,
                          limit: limit,
                          status: _selectedStatus,
                          priority: _selectedPriority,
                          search: _searchCtrl.text.isNotEmpty
                              ? _searchCtrl.text
                              : null,
                          ownerId: currentUserId,
                        );
                        if (res.isSuccess) {
                          final ticketsResp = res.value;
                          final pagination =
                              ticketsResp.pagination ??
                              Pagination(
                                page: page,
                                limit: limit,
                                total: ticketsResp.tickets.length,
                                totalPages: 1,
                                hasNext: false,
                                hasPrev: false,
                              );
                          return PaginatedResponse<Ticket>(
                            items: ticketsResp.tickets,
                            pagination: pagination,
                          );
                        }
                        throw Exception(res.error.message);
                      },
                      pageSize: 4,
                      emptyMessage: 'No tickets found',
                      errorMessage: 'Failed to load tickets',
                      loadingMessage: 'Loading tickets...',
                      itemBuilder: (context, ticket, index) => _TicketCard(
                        ticket: ticket,
                        onTap: () => _navigateToTicketDetail(ticket.id),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTap;
  const _TicketCard({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final createdStr = ticket.createdAt.year == DateTime.now().year
        ? '${ticket.createdAt.month}/${ticket.createdAt.day}'
        : '${ticket.createdAt.year}-${ticket.createdAt.month}-${ticket.createdAt.day}';

    final (statusBg, statusFg, statusIcon) = _getStatusStyle(ticket.status, cs);
    final priorityColor = _getPriorityColor(ticket.priority, cs);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outline.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Subject + Priority Bar
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Priority Indicator Bar
                  Container(
                    width: 4,
                    height: 60,
                    decoration: BoxDecoration(
                      color: priorityColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Subject & Description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.subject,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (ticket.description != null &&
                            ticket.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              ticket.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Status Badge
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
                        Icon(statusIcon, size: 12, color: statusFg),
                        const SizedBox(width: 4),
                        Text(
                          ticket.status.value,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusFg,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Footer: Metadata
              Row(
                children: [
                  // Priority Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      ticket.priority.value,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: priorityColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Owner
                  if (ticket.ownerName != null && ticket.ownerName!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ticket.ownerName!,
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSecondaryContainer,
                        ),
                      ),
                    ),
                  const Spacer(),
                  // Created Date
                  Text(
                    createdStr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
}
