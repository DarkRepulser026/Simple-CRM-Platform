import 'package:flutter/material.dart';
import '../../services/service_locator.dart';
import '../../services/api/api_client.dart';
import '../../services/auth/auth_service.dart';

// Models
class DomainMapping {
  final String id;
  final String domain;
  final String organizationId;
  final String organizationName;
  final bool isActive;
  final bool autoAssign;
  final int priority;

  DomainMapping({
    required this.id,
    required this.domain,
    required this.organizationId,
    required this.organizationName,
    required this.isActive,
    required this.autoAssign,
    required this.priority,
  });

  factory DomainMapping.fromJson(Map<String, dynamic> json) {
    return DomainMapping(
      id: json['id'] as String? ?? '',
      domain: json['domain'] as String? ?? '',
      organizationId: json['organizationId'] as String? ?? '',
      organizationName: json['organizationName'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      autoAssign: json['autoAssign'] as bool? ?? false,
      priority: json['priority'] as int? ?? 0,
    );
  }
}

class Organization {
  final String id;
  final String name;

  Organization({required this.id, required this.name});
}

/// Screen for managing organization domain auto-assignment rules
class DomainMappingScreen extends StatefulWidget {
  const DomainMappingScreen({super.key});

  @override
  State<DomainMappingScreen> createState() => _DomainMappingScreenState();
}

class _DomainMappingScreenState extends State<DomainMappingScreen> {
  bool _isLoading = true;
  List<DomainMapping> _mappings = [];
  List<Organization> _organizations = [];
  final ApiClient _apiClient = locator<ApiClient>();
  final AuthService _authService = locator<AuthService>();

  @override
  void initState() {
    super.initState();
    _loadData();
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
      
      // Load domain mappings
      final mappingsResult = await _apiClient.get<Map<String, dynamic>>(
        '/admin/domain-mappings',
        headers: headers,
        fromJson: (json) => json,
      );

      if (!mounted) return;

      if (mappingsResult.isSuccess) {
        final mappingsData = (mappingsResult.value['mappings'] as List<dynamic>?)
            ?.map((m) => DomainMapping.fromJson(m as Map<String, dynamic>))
            .toList() ?? [];
        
        // TODO: Load organizations from API
        // For now, extract unique organizations from mappings
        final orgs = <String, Organization>{};
        for (final mapping in mappingsData) {
          if (!orgs.containsKey(mapping.organizationId)) {
            orgs[mapping.organizationId] = Organization(
              id: mapping.organizationId,
              name: mapping.organizationName,
            );
          }
        }

        setState(() {
          _mappings = mappingsData;
          _organizations = orgs.values.toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showError(mappingsResult.error.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load data: $e');
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

  Future<void> _addDomainMapping() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddDomainDialog(organizations: _organizations),
    );

    if (result != null) {
      // TODO: Call API to create mapping
      await Future.delayed(const Duration(milliseconds: 500));
      _loadData();
    }
  }

  Future<void> _toggleMapping(DomainMapping mapping, String field) async {
    // TODO: Call API to update mapping
    await Future.delayed(const Duration(milliseconds: 500));
    _loadData();
  }

  Future<void> _deleteMapping(DomainMapping mapping) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Domain Mapping'),
        content: Text(
          'Remove domain mapping for ${mapping.domain}?\nCustomers with this email domain will no longer be auto-assigned.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Call API to delete mapping
      await Future.delayed(const Duration(milliseconds: 500));
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Domain Auto-Assignment Rules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _mappings.isEmpty
                  ? _buildEmptyState()
                  : _buildMappingsList(),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDomainMapping,
        icon: const Icon(Icons.add),
        label: const Text('Add Domain'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.domain_disabled, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No domain mappings configured',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Add domains to enable auto-assignment',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addDomainMapping,
            icon: const Icon(Icons.add),
            label: const Text('Add First Domain'),
          ),
        ],
      ),
    );
  }

  Widget _buildMappingsList() {
    // Group by organization
    final groupedMappings = <String, List<DomainMapping>>{};
    for (final mapping in _mappings) {
      groupedMappings.putIfAbsent(mapping.organizationName, () => []).add(mapping);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedMappings.length,
      itemBuilder: (context, index) {
        final orgName = groupedMappings.keys.elementAt(index);
        final orgMappings = groupedMappings[orgName]!;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.business, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        orgName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text('${orgMappings.length} domains'),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...orgMappings.map((mapping) => _DomainMappingTile(
                    mapping: mapping,
                    onToggleActive: () => _toggleMapping(mapping, 'isActive'),
                    onToggleAutoAssign: () => _toggleMapping(mapping, 'autoAssign'),
                    onDelete: () => _deleteMapping(mapping),
                  )),
            ],
          ),
        );
      },
    );
  }
}

class _DomainMappingTile extends StatelessWidget {
  final DomainMapping mapping;
  final VoidCallback onToggleActive;
  final VoidCallback onToggleAutoAssign;
  final VoidCallback onDelete;

  const _DomainMappingTile({
    required this.mapping,
    required this.onToggleActive,
    required this.onToggleAutoAssign,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Icon(
        Icons.alternate_email,
        color: mapping.isActive ? colorScheme.primary : Colors.grey,
      ),
      title: Row(
        children: [
          Text(
            mapping.domain,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: mapping.isActive ? null : Colors.grey,
            ),
          ),
          if (!mapping.isActive) ...[
            const SizedBox(width: 8),
            Chip(
              label: const Text('Inactive', style: TextStyle(fontSize: 11)),
              backgroundColor: Colors.grey.shade300,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                mapping.autoAssign ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: mapping.autoAssign ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                mapping.autoAssign ? 'Auto-assign enabled' : 'Auto-assign disabled',
                style: TextStyle(
                  fontSize: 12,
                  color: mapping.autoAssign ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.priority_high, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 2),
              Text(
                'Priority: ${mapping.priority}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'toggle_active':
              onToggleActive();
              break;
            case 'toggle_auto':
              onToggleAutoAssign();
              break;
            case 'delete':
              onDelete();
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'toggle_active',
            child: Row(
              children: [
                Icon(mapping.isActive ? Icons.visibility_off : Icons.visibility),
                const SizedBox(width: 8),
                Text(mapping.isActive ? 'Deactivate' : 'Activate'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'toggle_auto',
            child: Row(
              children: [
                Icon(mapping.autoAssign ? Icons.toggle_on : Icons.toggle_off),
                const SizedBox(width: 8),
                Text(mapping.autoAssign ? 'Disable Auto-Assign' : 'Enable Auto-Assign'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: Colors.red),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddDomainDialog extends StatefulWidget {
  final List<Organization> organizations;

  const _AddDomainDialog({required this.organizations});

  @override
  State<_AddDomainDialog> createState() => _AddDomainDialogState();
}

class _AddDomainDialogState extends State<_AddDomainDialog> {
  final _formKey = GlobalKey<FormState>();
  final _domainController = TextEditingController();
  String? _selectedOrgId;
  bool _autoAssign = true;
  int _priority = 0;

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Domain Mapping'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Domain input
            TextFormField(
              controller: _domainController,
              decoration: const InputDecoration(
                labelText: 'Domain',
                hintText: 'example.com',
                prefixIcon: Icon(Icons.alternate_email),
                helperText: 'Enter email domain (without @)',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Domain is required';
                }
                final domainRegex = RegExp(r'^[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,}$', caseSensitive: false);
                if (!domainRegex.hasMatch(value)) {
                  return 'Invalid domain format';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Organization selector
            DropdownButtonFormField<String>(
              value: _selectedOrgId,
              decoration: const InputDecoration(
                labelText: 'Organization',
                prefixIcon: Icon(Icons.business),
              ),
              items: widget.organizations
                  .map((org) => DropdownMenuItem(
                        value: org.id,
                        child: Text(org.name),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedOrgId = value);
              },
              validator: (value) => value == null ? 'Select an organization' : null,
            ),
            const SizedBox(height: 16),

            // Auto-assign toggle
            SwitchListTile(
              value: _autoAssign,
              onChanged: (value) {
                setState(() => _autoAssign = value);
              },
              title: const Text('Enable Auto-Assign'),
              subtitle: const Text('Automatically assign new customers'),
              contentPadding: EdgeInsets.zero,
            ),

            // Priority slider
            const SizedBox(height: 8),
            Text('Priority: $_priority', style: Theme.of(context).textTheme.labelLarge),
            Slider(
              value: _priority.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              label: _priority.toString(),
              onChanged: (value) {
                setState(() => _priority = value.toInt());
              },
            ),
            Text(
              'Higher priority domains are matched first',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'domain': _domainController.text.trim().toLowerCase(),
                'organizationId': _selectedOrgId,
                'autoAssign': _autoAssign,
                'priority': _priority,
              });
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

