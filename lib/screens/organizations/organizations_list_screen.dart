import 'package:flutter/material.dart';
import '../../widgets/paginated_list_view.dart';
import '../../models/organization.dart';
import '../../services/service_locator.dart';
import '../../services/organizations_service.dart';
import '../../navigation/app_router.dart';
import '../../services/auth/auth_service.dart';
import '../../widgets/error_view.dart';

class OrganizationsListScreen extends StatefulWidget {
  const OrganizationsListScreen({super.key});

  @override
  State<OrganizationsListScreen> createState() => _OrganizationsListScreenState();
}

class _OrganizationsListScreenState extends State<OrganizationsListScreen> {
  late final OrganizationsService _organizationsService;
  late final AuthService _authService;
  bool _isNavigating = false; // Để chặn double-tap khi đang chuyển trang

  @override
  void initState() {
    super.initState();
    _organizationsService = locator<OrganizationsService>();
    _authService = locator<AuthService>();
  }

  Future<List<Organization>> _fetchOrgs(int page, int limit) async {
    try {
      final res = await _organizationsService.getOrganizations(page: page, limit: limit);
      if (res.isSuccess) return res.value.organizations;
      throw Exception(res.error.message);
    } catch (e) {
      throw Exception('Failed to load organizations: $e');
    }
  }

  Future<void> _selectOrganization(Organization org) async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    try {
      await _authService.selectOrganization(org.id);
      if (mounted) {
        // Sử dụng replaceWith để không quay lại màn hình chọn Org khi back
        AppRouter.replaceWith(context, AppRouter.dashboard);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isNavigating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed selecting organization: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    const bgColor = Color(0xFFE9EDF5); // Màu nền Dashboard

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bgColor,
        title: const Text(''), // Ẩn title mặc định để dùng Custom Header
        iconTheme: IconThemeData(color: cs.onSurface),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800), // Giới hạn chiều rộng hẹp hơn các list khác để tập trung
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== HEADER SECTION =====
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Organizations',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select an organization to manage',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    FilledButton.icon(
                      onPressed: () => AppRouter.navigateTo(context, AppRouter.companyCreate),
                      icon: const Icon(Icons.add_business_outlined, size: 20),
                      label: const Text('Create New'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),

                // ===== LIST CARD =====
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    // ClipRRect để bo góc cho ListView bên trong
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: PaginatedListView<Organization>(
                        fetchPage: _fetchOrgs,
                        pageSize: 20,
                        emptyMessage: 'You are not part of any organization yet.',
                        errorMessage: 'Failed to load organizations',
                        loadingMessage: 'Loading your workspaces...',
                        itemBuilder: (context, org, index) => _OrganizationItem(
                          org: org,
                          onTap: () => _selectOrganization(org),
                          isEnabled: !_isNavigating,
                        ),
                        separatorBuilder: (context, index) => Divider(
                          height: 1, 
                          color: cs.outline.withOpacity(0.1),
                          indent: 80, // Thụt vào để thẳng hàng với text
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Footer text nhỏ
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Logged in as ${_authService.currentUser?.email ?? 'User'}',
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
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

/// Widget hiển thị từng dòng Organization
class _OrganizationItem extends StatelessWidget {
  final Organization org;
  final VoidCallback onTap;
  final bool isEnabled;

  const _OrganizationItem({
    required this.org,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    // Lấy chữ cái đầu làm logo
    final initial = org.name.isNotEmpty ? org.name[0].toUpperCase() : '?';
    
    // Màu ngẫu nhiên giả lập dựa trên hash code của tên (để mỗi cty có màu riêng)
    final colorIndex = org.name.codeUnitAt(0) % Colors.primaries.length;
    final avatarColor = Colors.primaries[colorIndex];

    return InkWell(
      onTap: isEnabled ? onTap : null,
      hoverColor: cs.surfaceVariant.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Logo / Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: avatarColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: avatarColor,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 20),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    org.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          (org.role ?? 'MEMBER').toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // ID (optional, for debug or detail)
                      // Text('#${org.id.substring(0, 4)}', style: TextStyle(fontSize: 11, color: cs.outline)),
                    ],
                  ),
                ],
              ),
            ),
            
            // Arrow icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: cs.outline.withOpacity(0.1)),
              ),
              child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}