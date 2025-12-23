import 'package:flutter/material.dart';
import '../../services/service_locator.dart';
import '../../services/api/api_client.dart';
import '../../services/auth/auth_service.dart';

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
  final ApiClient _apiClient = locator<ApiClient>();
  final AuthService _authService = locator<AuthService>();

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

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = _authService.jwtToken;
    final orgId = _authService.selectedOrganizationId;
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    if (orgId != null) headers['X-Organization-ID'] = orgId;
    return headers;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final headers = await _getAuthHeaders();
      
      // Load unassigned customers
      final unassignedResult = await _apiClient.get<Map<String, dynamic>>(
        '/admin/customers/unassigned',
        headers: headers,
        fromJson: (json) => json,
      );

      // Load assigned customers
      final assignedResult = await _apiClient.get<Map<String, dynamic>>(
        '/admin/customers/assigned',
        headers: headers,
        fromJson: (json) => json,
      );

      // Load statistics
      final statsResult = await _apiClient.get<Map<String, dynamic>>(
        '/admin/customers/stats',
        headers: headers,
        fromJson: (json) => json,
      );

      if (!mounted) return;

      if (unassignedResult.isSuccess &&
          assignedResult.isSuccess &&
          statsResult.isSuccess) {
        final unassigned = (unassignedResult.value['customers'] as List<dynamic>?)
            ?.map((c) => c as Map<String, dynamic>)
            .toList() ?? [];
        final assigned = (assignedResult.value['customers'] as List<dynamic>?)
            ?.map((c) => c as Map<String, dynamic>)
            .toList() ?? [];
        final stats = statsResult.value['stats'] as Map<String, dynamic>?;

        setState(() {
          _unassignedCustomers = unassigned;
          _assignedCustomers = assigned;
          _stats = stats ?? {
            'total': 0,
            'assigned': 0,
            'unassigned': 0,
            'assignmentRate': 0,
          };
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showError('Failed to load data');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load data: $e');
      }
    }
  }

  Future<void> _assignCustomer(String userId, String orgId) async {
    try {
      final headers = await _getAuthHeaders();
      await _apiClient.post(
        '/admin/customers/$userId/assign-organization',
        headers: headers,
        body: {'organizationId': orgId},
      );
      if (mounted) {
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to assign customer: $e');
      }
    }
  }

  Future<void> _unassignCustomer(String userId) async {
    try {
      final headers = await _getAuthHeaders();
      await _apiClient.post(
        '/admin/customers/$userId/unassign-organization',
        headers: headers,
      );
      if (mounted) {
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to unassign customer: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
    final TextEditingController orgIdController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign to Organization'),
        content: TextField(
          controller: orgIdController,
          decoration: const InputDecoration(
            labelText: 'Organization ID',
            hintText: 'Enter organization ID',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (orgIdController.text.isNotEmpty) {
                Navigator.pop(context, orgIdController.text);
              }
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _assignCustomer(customer['userId'], result);
    }
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
