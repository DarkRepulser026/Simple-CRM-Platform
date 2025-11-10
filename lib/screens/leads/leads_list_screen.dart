import 'package:flutter/material.dart';
import '../../widgets/paginated_list_view.dart';
import '../../models/lead.dart';
import '../../navigation/app_router.dart';

/// List screen for displaying and managing leads with pagination
class LeadsListScreen extends StatefulWidget {
  const LeadsListScreen({super.key});

  @override
  State<LeadsListScreen> createState() => _LeadsListScreenState();
}

class _LeadsListScreenState extends State<LeadsListScreen> {
  Future<List<Lead>> _fetchLeadsPage(int page, int limit) async {
    // TODO: Implement actual API call using LeadsService
    // For now, return mock data
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay

    return List.generate(
      limit,
      (index) => Lead(
        id: 'lead_${page}_${index}',
        firstName: 'Lead',
        lastName: '${(page - 1) * limit + index + 1}',
        organizationId: 'org123',
        createdAt: DateTime.now().subtract(Duration(days: index)),
        updatedAt: DateTime.now().subtract(Duration(hours: index)),
        email: 'lead${(page - 1) * limit + index + 1}@example.com',
        phone: '+1-555-02${((page - 1) * limit + index + 1).toString().padLeft(4, '0')}',
        company: 'Company ${(page - 1) * limit + index + 1}',
        status: LeadStatus.values[index % LeadStatus.values.length],
        leadSource: LeadSource.values[index % LeadSource.values.length],
        isConverted: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leads'),
        actions: [
          IconButton(
            onPressed: () => AppRouter.navigateTo(context, AppRouter.leadCreate),
            icon: const Icon(Icons.add),
            tooltip: 'Add Lead',
          ),
          IconButton(
            onPressed: () {
              // TODO: Implement search
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search coming soon!')),
              );
            },
            icon: const Icon(Icons.search),
            tooltip: 'Search Leads',
          ),
        ],
      ),
      body: PaginatedListView<Lead>(
        itemBuilder: (context, lead, index) => LeadListItem(
          lead: lead,
          onTap: () => _navigateToLeadDetail(lead.id),
        ),
        fetchPage: _fetchLeadsPage,
        pageSize: 20,
        emptyMessage: 'No leads found',
        errorMessage: 'Failed to load leads',
        loadingMessage: 'Loading leads...',
      ),
    );
  }

  void _navigateToLeadDetail(String leadId) {
    AppRouter.navigateTo(
      context,
      AppRouter.leadDetail,
      arguments: LeadDetailArgs(leadId: leadId),
    );
  }
}

/// Individual lead item in the list
class LeadListItem extends StatelessWidget {
  const LeadListItem({
    super.key,
    required this.lead,
    required this.onTap,
  });

  final Lead lead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(lead.status),
          child: Text(
            lead.firstName[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          lead.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lead.company != null) Text(lead.company!),
            if (lead.email != null) Text(lead.email!),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(lead.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    lead.status.value,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(lead.status),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  lead.leadSource.value,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            Text(
              'Created ${lead.createdAt.toLocal().toString().split(' ')[0]}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Color _getStatusColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead:
        return Colors.blue;
      case LeadStatus.pending:
        return Colors.orange;
      case LeadStatus.contacted:
        return Colors.purple;
      case LeadStatus.qualified:
        return Colors.amber;
      case LeadStatus.unqualified:
        return Colors.grey;
      case LeadStatus.converted:
        return Colors.green;
    }
  }
}