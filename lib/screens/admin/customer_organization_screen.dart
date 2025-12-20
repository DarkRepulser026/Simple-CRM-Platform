import 'package:flutter/material.dart';

/// Screen for managing customer-organization assignments
class CustomerOrganizationScreen extends StatefulWidget {
  const CustomerOrganizationScreen({super.key});

  @override
  State<CustomerOrganizationScreen> createState() =>
      _CustomerOrganizationScreenState();
}

class _CustomerOrganizationScreenState
    extends State<CustomerOrganizationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _unassignedCustomers = [];
  List<Map<String, dynamic>> _assignedCustomers = [];
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // TODO: Load data from API
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _unassignedCustomers = []; // Replace with API data
        _assignedCustomers = []; // Replace with API data
        _stats = {
          'total': 0,
          'assigned': 0,
          'unassigned': 0,
          'assignmentRate': '0',
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _assignCustomer(String userId, String orgId) async {
    // TODO: Call API to assign customer
    await Future.delayed(const Duration(milliseconds: 500));
    _loadData();
  }

  Future<void> _unassignCustomer(String userId) async {
    // TODO: Call API to unassign customer
    await Future.delayed(const Duration(milliseconds: 500));
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Organization Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Unassigned', icon: Icon(Icons.person_off)),
            Tab(text: 'Assigned', icon: Icon(Icons.business)),
            Tab(text: 'Statistics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUnassignedTab(),
                _buildAssignedTab(),
                _buildStatsTab(),
              ],
            ),
    );
  }

  Widget _buildUnassignedTab() {
    if (_unassignedCustomers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green.shade300),
            const SizedBox(height: 16),
            const Text(
              'All customers are assigned!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _unassignedCustomers.length,
        itemBuilder: (context, index) {
          final customer = _unassignedCustomers[index];
          return _CustomerCard(
            customer: customer,
            isAssigned: false,
            onAssign: () => _showAssignDialog(customer),
          );
        },
      ),
    );
  }

  Widget _buildAssignedTab() {
    if (_assignedCustomers.isEmpty) {
      return const Center(
        child: Text('No assigned customers yet'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _assignedCustomers.length,
        itemBuilder: (context, index) {
          final customer = _assignedCustomers[index];
          return _CustomerCard(
            customer: customer,
            isAssigned: true,
            onUnassign: () => _showUnassignDialog(customer),
          );
        },
      ),
    );
  }

  Widget _buildStatsTab() {
    if (_stats == null) {
      return const Center(child: Text('No statistics available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatsCard(
            title: 'Total Customers',
            value: _stats!['total'].toString(),
            icon: Icons.people,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _StatsCard(
            title: 'Assigned',
            value: _stats!['assigned'].toString(),
            icon: Icons.business,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _StatsCard(
            title: 'Unassigned',
            value: _stats!['unassigned'].toString(),
            icon: Icons.person_off,
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _StatsCard(
            title: 'Assignment Rate',
            value: '${_stats!['assignmentRate']}%',
            icon: Icons.percent,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Future<void> _showAssignDialog(Map<String, dynamic> customer) async {
    // TODO: Show dialog to select organization
    // For now, just a placeholder
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign to Organization'),
        content: Text('Assign ${customer['name']} to an organization'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // _assignCustomer(customer['userId'], selectedOrgId);
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  Future<void> _showUnassignDialog(Map<String, dynamic> customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unassign Customer'),
        content: Text(
          'Remove ${customer['name']} from ${customer['organizationName']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Unassign'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _unassignCustomer(customer['userId']);
    }
  }
}

class _CustomerCard extends StatelessWidget {
  final Map<String, dynamic> customer;
  final bool isAssigned;
  final VoidCallback? onAssign;
  final VoidCallback? onUnassign;

  const _CustomerCard({
    required this.customer,
    required this.isAssigned,
    this.onAssign,
    this.onUnassign,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAssigned
              ? colorScheme.primaryContainer
              : colorScheme.errorContainer,
          child: Icon(
            isAssigned ? Icons.business : Icons.person_off,
            color: isAssigned
                ? colorScheme.onPrimaryContainer
                : colorScheme.onErrorContainer,
          ),
        ),
        title: Text(
          customer['name'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(customer['email'] ?? ''),
            if (customer['companyName'] != null)
              Text(
                customer['companyName'],
                style: TextStyle(color: colorScheme.primary),
              ),
            if (isAssigned && customer['organizationName'] != null)
              Chip(
                label: Text(
                  customer['organizationName'],
                  style: const TextStyle(fontSize: 12),
                ),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        trailing: isAssigned
            ? IconButton(
                icon: const Icon(Icons.remove_circle),
                color: Colors.red,
                onPressed: onUnassign,
                tooltip: 'Unassign',
              )
            : IconButton(
                icon: const Icon(Icons.add_circle),
                color: Colors.green,
                onPressed: onAssign,
                tooltip: 'Assign',
              ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
