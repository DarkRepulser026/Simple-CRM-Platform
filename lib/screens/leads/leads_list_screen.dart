import 'package:flutter/material.dart';
import '../../widgets/paginated_list_view.dart';
import '../../models/lead.dart';
import '../../navigation/app_router.dart';
import '../../services/leads_service.dart';
import '../../services/service_locator.dart';
import '../../services/auth/auth_service.dart';
import '../../widgets/error_view.dart';

/// List screen for displaying and managing leads with pagination
class LeadsListScreen extends StatefulWidget {
  const LeadsListScreen({super.key});

  @override
  State<LeadsListScreen> createState() => _LeadsListScreenState();
}

class _LeadsListScreenState extends State<LeadsListScreen> {
  late final LeadsService _leadsService;
  final TextEditingController _searchCtrl = TextEditingController();
  int _reloadVersion = 0;

  @override
  void initState() {
    super.initState();
    _leadsService = locator<LeadsService>();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<Lead>> _fetchLeadsPage(int page, int limit) async {
    try {
      final res = await _leadsService.getLeads(
        page: page,
        limit: limit,
        // search: _searchCtrl.text // Uncomment if API supports search
      );
      if (res.isSuccess) {
        var leads = res.value.leads;
        
        // Filter local demo
        if (_searchCtrl.text.isNotEmpty) {
          final q = _searchCtrl.text.toLowerCase();
          leads = leads.where((l) => 
            l.fullName.toLowerCase().contains(q) || 
            (l.company ?? '').toLowerCase().contains(q) ||
            (l.email ?? '').toLowerCase().contains(q)
          ).toList();
        }
        
        return leads;
      }
      throw Exception(res.error.message);
    } catch (e) {
      throw Exception('Failed to load leads: $e');
    }
  }

  void _refreshList() => setState(() => _reloadVersion++);

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
    const bgColor = Color(0xFFE9EDF5); // Màu nền Dashboard

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
                      'Leads',
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
                        'Sales',
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
                          hintText: 'Search by name, company or email',
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
                        final res = await AppRouter.navigateTo(context, AppRouter.leadCreate);
                        if (res == true) _refreshList();
                      },
                      icon: const Icon(Icons.person_add_alt_1, size: 18),
                      label: const Text('Add Lead'),
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
                              _HeaderCell('Name', flex: 3),
                              _HeaderCell('Company', flex: 2),
                              _HeaderCell('Email', flex: 3),
                              _HeaderCell('Status', flex: 2),
                              _HeaderCell('Source', flex: 2),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        // List
                        Expanded(
                          child: PaginatedListView<Lead>(
                            key: ValueKey(_reloadVersion),
                            fetchPage: _fetchLeadsPage,
                            pageSize: 20,
                            emptyMessage: 'No leads found',
                            errorMessage: 'Failed to load leads',
                            loadingMessage: 'Loading leads...',
                            itemBuilder: (context, lead, index) => _LeadRow(
                              lead: lead,
                              onTap: () => _navigateToLeadDetail(lead.id),
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

  Future<void> _navigateToLeadDetail(String leadId) async {
    final changed = await AppRouter.navigateTo<bool?>(
      context,
      AppRouter.leadDetail,
      arguments: LeadDetailArgs(leadId: leadId),
    );
    if (changed == true) _refreshList();
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

class _LeadRow extends StatelessWidget {
  final Lead lead;
  final VoidCallback onTap;
  const _LeadRow({required this.lead, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    // Initials Avatar
    final initial = lead.firstName.isNotEmpty 
        ? lead.firstName[0].toUpperCase() 
        : (lead.lastName.isNotEmpty ? lead.lastName[0].toUpperCase() : '?');

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
            // Name + Avatar
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      initial, 
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.bold, 
                        color: cs.onPrimaryContainer
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      lead.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            // Company
            Expanded(
              flex: 2,
              child: Text(
                lead.company ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            // Email
            Expanded(
              flex: 3,
              child: Text(
                lead.email ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            // Status
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _StatusChip(status: lead.status),
              ),
            ),
            // Source
            Expanded(
              flex: 2,
              child: Text(
                lead.leadSource.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final LeadStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (status) {
      case LeadStatus.newLead:
        bg = Colors.blue.withOpacity(0.1); fg = Colors.blue; break;
      case LeadStatus.contacted:
        bg = Colors.purple.withOpacity(0.1); fg = Colors.purple; break;
      case LeadStatus.qualified:
        bg = Colors.amber.withOpacity(0.1); fg = Colors.amber.shade800; break;
      case LeadStatus.converted:
        bg = Colors.green.withOpacity(0.1); fg = Colors.green; break;
      case LeadStatus.unqualified:
        bg = Colors.grey.withOpacity(0.1); fg = Colors.grey.shade700; break;
      case LeadStatus.pending: // Fallback
      default:
        bg = Colors.orange.withOpacity(0.1); fg = Colors.orange.shade800;
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