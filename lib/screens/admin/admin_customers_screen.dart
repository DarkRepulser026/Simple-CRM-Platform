import 'package:flutter/material.dart';
import '../../services/service_locator.dart';
import '../../services/api/api_client.dart';
import '../../services/auth/auth_service.dart';

// Customer model for admin view
class AdminCustomer {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String? companyName;
  final String? phone;
  final String? organizationId;
  final String? organizationName;
  final bool isActive;
  final DateTime? createdAt;

  AdminCustomer({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.companyName,
    this.phone,
    this.organizationId,
    this.organizationName,
    required this.isActive,
    this.createdAt,
  });

  factory AdminCustomer.fromJson(Map<String, dynamic> json) {
    return AdminCustomer(
      id: json['id'] as String? ?? json['userId'] as String? ?? '',
      userId: json['userId'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      companyName: json['companyName'] as String?,
      phone: json['phone'] as String?,
      organizationId: json['organizationId']?.toString(),
      organizationName: json['organizationName'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString()) 
          : null,
    );
  }
}

class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  final ApiClient _apiClient = locator<ApiClient>();
  final AuthService _authService = locator<AuthService>();
  
  List<AdminCustomer> _customers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);

    try {
      final headers = await _getAuthHeaders();
      final result = await _apiClient.get<Map<String, dynamic>>(
        '/admin/customers',
        headers: headers,
        fromJson: (json) => json,
      );
      
      if (result.isSuccess && mounted) {
        final customers = (result.value['customers'] as List<dynamic>?)
            ?.map((c) => AdminCustomer.fromJson(c as Map<String, dynamic>))
            .toList() ?? [];
        
        setState(() {
          _customers = customers;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
        _showError(result.error.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load customers: $e');
      }
    }
  }

  List<AdminCustomer> get _filteredCustomers {
    if (_searchQuery.isEmpty) return _customers;
    
    final query = _searchQuery.toLowerCase();
    return _customers.where((c) {
      return c.name.toLowerCase().contains(query) ||
             c.email.toLowerCase().contains(query) ||
             (c.companyName?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Future<void> _toggleActiveStatus(AdminCustomer customer) async {
    final newStatus = !customer.isActive;
    final action = newStatus ? 'activate' : 'suspend';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${newStatus ? 'Activate' : 'Suspend'} Customer'),
        content: Text('Are you sure you want to $action ${customer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: newStatus ? Colors.green : Colors.orange,
            ),
            child: Text(newStatus ? 'Activate' : 'Suspend'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // TODO: Implement actual activate/suspend API
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Customer ${newStatus ? 'activated' : 'suspended'} successfully'),
        backgroundColor: Colors.green,
      ),
    );
    _loadCustomers();
  }

  Future<void> _showAssignOrganizationDialog(AdminCustomer customer) async {
    final TextEditingController orgIdController = TextEditingController(
      text: customer.organizationId ?? '',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Organization'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${customer.name}'),
            const SizedBox(height: 16),
            TextField(
              controller: orgIdController,
              decoration: const InputDecoration(
                labelText: 'Organization ID',
                hintText: 'Enter organization ID or leave empty',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Assign'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final orgIdText = orgIdController.text.trim();
    
    try {
      final headers = await _getAuthHeaders();
      
      if (orgIdText.isEmpty) {
        // Unassign organization
        await _apiClient.post(
            '/admin/customers/${customer.userId}/unassign-organization',
        );
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Organization cleared for ${customer.name}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Assign organization
        await _apiClient.post(
          '/admin/customers/${customer.userId}/assign-organization',
          headers: headers,
          body: {'organizationId': orgIdText},
        );
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Organization assigned to ${customer.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      _loadCustomers();
    } catch (e) {
      if (mounted) {
        _showError('Failed to update organization: $e');
      }
    }
  }

  Future<void> _showResetPasswordDialog(AdminCustomer customer) async {
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${customer.name}'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (passwordController.text == confirmController.text &&
                  passwordController.text.isNotEmpty) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // TODO: Implement actual password reset API
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Password reset for ${customer.name}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _showConvertToAgentDialog(AdminCustomer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convert to Agent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Convert ${customer.name} to an agent?'),
            const SizedBox(height: 8),
            const Text(
              'This will change their account type from Customer to Agent.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Convert'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // TODO: Implement actual convert to agent API
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${customer.name} converted to agent successfully'),
        backgroundColor: Colors.green,
      ),
    );
    _loadCustomers();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showCustomerActions(AdminCustomer customer) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                customer.isActive ? Icons.block : Icons.check_circle,
                color: customer.isActive ? Colors.orange : Colors.green,
              ),
              title: Text(customer.isActive ? 'Suspend Account' : 'Activate Account'),
              onTap: () {
                Navigator.pop(context);
                _toggleActiveStatus(customer);
              },
            ),
            ListTile(
              leading: const Icon(Icons.business, color: Colors.blue),
              title: const Text('Assign Organization'),
              onTap: () {
                Navigator.pop(context);
                _showAssignOrganizationDialog(customer);
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_reset, color: Colors.purple),
              title: const Text('Reset Password'),
              onTap: () {
                Navigator.pop(context);
                _showResetPasswordDialog(customer);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add, color: Colors.indigo),
              title: const Text('Convert to Agent'),
              onTap: () {
                Navigator.pop(context);
                _showConvertToAgentDialog(customer);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Customer list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCustomers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No customers found'
                                  : 'No customers match your search',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = _filteredCustomers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: customer.isActive
                                    ? Colors.green.shade100
                                    : Colors.grey.shade300,
                                child: Icon(
                                  Icons.person,
                                  color: customer.isActive
                                      ? Colors.green.shade700
                                      : Colors.grey.shade600,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(child: Text(customer.name)),
                                  if (!customer.isActive)
                                    Chip(
                                      label: const Text('Suspended'),
                                      backgroundColor: Colors.orange.shade100,
                                      labelStyle: TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange.shade900,
                                      ),
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(customer.email),
                                  if (customer.companyName != null)
                                    Text(
                                      customer.companyName!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  if (customer.organizationId != null)
                                    Text(
                                      'Org: ${customer.organizationName ?? customer.organizationId}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () => _showCustomerActions(customer),
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
