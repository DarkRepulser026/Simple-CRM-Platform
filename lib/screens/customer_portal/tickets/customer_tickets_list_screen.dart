import 'package:flutter/material.dart';
import '../../../widgets/empty_state.dart';
import '../../../navigation/app_router.dart';

class CustomerTicketsListScreen extends StatefulWidget {
  const CustomerTicketsListScreen({super.key});

  @override
  State<CustomerTicketsListScreen> createState() =>
      _CustomerTicketsListScreenState();
}

class _CustomerTicketsListScreenState extends State<CustomerTicketsListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _tickets = [];
  String? _selectedStatus;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    
    // TODO: Load tickets from API
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() {
        _tickets = []; // Replace with actual data
        _isLoading = false;
      });
    }
  }

  void _navigateToCreateTicket() {
    AppRouter.navigateTo(context, AppRouter.customerTicketCreate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tickets'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search tickets...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (value) {
                    // TODO: Implement search
                  },
                ),
              ),
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedStatus == null,
                      onSelected: (selected) {
                        setState(() => _selectedStatus = null);
                        _loadTickets();
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Open'),
                      selected: _selectedStatus == 'OPEN',
                      onSelected: (selected) {
                        setState(() => _selectedStatus = selected ? 'OPEN' : null);
                        _loadTickets();
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('In Progress'),
                      selected: _selectedStatus == 'IN_PROGRESS',
                      onSelected: (selected) {
                        setState(() => _selectedStatus = selected ? 'IN_PROGRESS' : null);
                        _loadTickets();
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Resolved'),
                      selected: _selectedStatus == 'RESOLVED',
                      onSelected: (selected) {
                        setState(() => _selectedStatus = selected ? 'RESOLVED' : null);
                        _loadTickets();
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Closed'),
                      selected: _selectedStatus == 'CLOSED',
                      onSelected: (selected) {
                        setState(() => _selectedStatus = selected ? 'CLOSED' : null);
                        _loadTickets();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tickets.isEmpty
              ? Center(
                  child: EmptyState(
                    icon: Icons.confirmation_number_outlined,
                    title: 'No Tickets Yet',
                    message: 'Create your first support ticket to get started',
                    actionLabel: 'Create Ticket',
                    onAction: _navigateToCreateTicket,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTickets,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = _tickets[index];
                      return _TicketCard(ticket: ticket);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateTicket,
        icon: const Icon(Icons.add),
        label: const Text('New Ticket'),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;

  const _TicketCard({required this.ticket});

  Color _getStatusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'OPEN':
        return Colors.blue;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'RESOLVED':
        return Colors.green;
      case 'CLOSED':
        return Colors.grey;
      default:
        return colorScheme.primary;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'URGENT':
        return Colors.red;
      case 'HIGH':
        return Colors.orange;
      case 'NORMAL':
        return Colors.blue;
      case 'LOW':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          AppRouter.navigateTo(
            context,
            AppRouter.customerTicketDetail,
            arguments: CustomerTicketDetailArgs(ticketId: ticket['id']),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Priority Indicator
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(ticket['priority'] ?? 'NORMAL'),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Ticket Number
                  Expanded(
                    child: Text(
                      ticket['number'] ?? '#TICKET-001',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        ticket['status'] ?? 'OPEN',
                        colorScheme,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ticket['status'] ?? 'OPEN',
                      style: TextStyle(
                        color: _getStatusColor(
                          ticket['status'] ?? 'OPEN',
                          colorScheme,
                        ),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Subject
              Text(
                ticket['subject'] ?? 'No Subject',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Meta Information
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Updated ${ticket['updatedAt'] ?? 'recently'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (ticket['messageCount'] != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.message_outlined,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${ticket['messageCount']} messages',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
