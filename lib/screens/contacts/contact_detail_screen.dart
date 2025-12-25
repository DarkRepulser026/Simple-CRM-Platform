import 'package:flutter/material.dart';
import '../../models/contact.dart';
import '../../services/service_locator.dart';
import '../../navigation/app_router.dart';
import '../../widgets/role_visibility.dart';
import 'contact_edit_screen.dart' show showContactEditDialog;
import '../../services/contacts_service.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/activity_log_widget.dart';

class ContactDetailArgs {
  const ContactDetailArgs({required this.contactId});
  final String contactId;
}

Future<bool?> showContactDetailDialog(
  BuildContext context, {
  required String contactId,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    useRootNavigator: true,
    builder: (_) => _ContactDetailDialog(contactId: contactId),
  );
}

class ContactDetailScreen extends StatefulWidget {
  final String contactId;
  const ContactDetailScreen({super.key, required this.contactId});

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final result = await showContactDetailDialog(
        context,
        contactId: widget.contactId,
      );
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(result ?? false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// ===================== DIALOG CHI TIẾT CONTACT =======================

class _ContactDetailDialog extends StatefulWidget {
  const _ContactDetailDialog({required this.contactId});

  final String contactId;

  @override
  State<_ContactDetailDialog> createState() => _ContactDetailDialogState();
}

class _ContactDetailDialogState extends State<_ContactDetailDialog> {
  late final ContactsService _contactsService;
  bool _isLoading = true;
  String? _error;
  Contact? _contact;

  @override
  void initState() {
    super.initState();
    _contactsService = locator<ContactsService>();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    debugPrint('ContactDetailDialog: loading contact ${widget.contactId}');
    try {
      final res = await _contactsService.getContact(widget.contactId);
      if (res.isSuccess) {
        setState(() {
          _contact = res.value;
          _isLoading = false;
        });
        return;
      }
      throw Exception(res.error.message);
    } catch (e) {
      setState(() {
        _error = 'Failed to load contact: $e';
        _isLoading = false;
      });
    }
  }

  void _goToEdit() async {
    if (_contact == null) return;
    try {
      final edited = await showContactEditDialog(context, contactId: _contact!.id);
      if (edited == true) {
        // Close the detail dialog and indicate to caller that the contact changed
        Navigator.of(context).pop(true);
      }
    } catch (e, st) {
      debugPrint('Navigation to contact edit failed: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: _isLoading
            ? const SizedBox(
                height: 200,
                child: Center(
                  child: LoadingView(message: 'Loading contact...'),
                ),
              )
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ErrorView(message: _error!, onRetry: _load),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Close'),
                          ),
                        ),
                      ],
                    ),
                  )
                : DefaultTabController(
                    length: 2,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const TabBar(
                          tabs: [
                            Tab(text: 'Details'),
                            Tab(text: 'Activity Log'),
                          ],
                        ),
                        SizedBox(
                          height: 500,
                          child: TabBarView(
                            children: [
                              SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: _buildContent(context, colorScheme),
                              ),
                              SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: ActivityLogWidget(
                                  entityId: widget.contactId,
                                  entityType: 'Contact',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Close'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme colorScheme) {
    final c = _contact!;
    final created = c.createdAt.toLocal().toString().split(' ').first;
    final updated = c.updatedAt.toLocal().toString().split(' ').first;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== HEADER =====
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: colorScheme.primary.withOpacity(0.12),
              child: Text(
                (c.fullName.isNotEmpty ? c.fullName[0] : '?').toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.fullName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Contact',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (c.email != null && c.email!.isNotEmpty)
                        Icon(
                          Icons.mail_outline,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      if (c.email != null && c.email!.isNotEmpty)
                        const SizedBox(width: 4),
                      if (c.email != null && c.email!.isNotEmpty)
                        Text(
                          c.email!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                AppRouter.navigateTo(
                  context,
                  AppRouter.activityLogs,
                  arguments: ActivityLogsArgs(entityType: 'Contact', entityId: c.id),
                );
              },
              tooltip: 'View activity',
              icon: const Icon(Icons.history, size: 18),
            ),
            // Action buttons
            ManagerOrAdminOnly(
              child: FilledButton.icon(
                onPressed: _goToEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => Navigator.of(context).pop(false),
              icon: const Icon(Icons.close),
              tooltip: 'Close',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ===== MAIN INFO CARD =====
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.08),
            ),
          ),
          child: Column(
            children: [
              // Title
              Row(children: [
                _infoLabel(context, 'Title'),
                const SizedBox(width: 12),
                Expanded(child: Text(c.title ?? '-', style: Theme.of(context).textTheme.bodyMedium)),
              ]),
              const SizedBox(height: 10),

              // Department
              Row(children: [
                _infoLabel(context, 'Department'),
                const SizedBox(width: 12),
                Expanded(child: Text(c.department ?? '-', style: Theme.of(context).textTheme.bodyMedium)),
              ]),
              const SizedBox(height: 10),

              // Email
              Row(children: [
                _infoLabel(context, 'Email'),
                const SizedBox(width: 12),
                Expanded(child: Text(c.email ?? '-', style: Theme.of(context).textTheme.bodyMedium)),
              ]),
              const SizedBox(height: 10),

              // Phone
              Row(children: [
                _infoLabel(context, 'Phone'),
                const SizedBox(width: 12),
                Expanded(child: Text(c.phone ?? '-', style: Theme.of(context).textTheme.bodyMedium)),
              ]),
              const SizedBox(height: 10),

              // Address
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _infoLabel(context, 'Address'),
                const SizedBox(width: 12),
                Expanded(child: Text(c.fullAddress, style: Theme.of(context).textTheme.bodyMedium)),
              ]),
              const SizedBox(height: 10),

              // Owner
              Row(children: [
                _infoLabel(context, 'Owner'),
                const SizedBox(width: 12),
                Expanded(child: Text(c.owner?.name ?? '-', style: Theme.of(context).textTheme.bodyMedium)),
              ]),
              const SizedBox(height: 10),

              // Geo
              Row(children: [
                _infoLabel(context, 'Geo'),
                const SizedBox(width: 12),
                Expanded(child: Text(c.latitude != null && c.longitude != null ? '${c.latitude}, ${c.longitude}' : '-', style: Theme.of(context).textTheme.bodyMedium)),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ===== META INFO (CREATED / UPDATED) =====
        Row(
          children: [
            _metaChip(
              context,
              icon: Icons.schedule,
              label: 'Created $created',
            ),
            const SizedBox(width: 8),
            _metaChip(
              context,
              icon: Icons.update,
              label: 'Updated $updated',
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoLabel(BuildContext context, String text) {
    return SizedBox(
      width: 70,
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }

  Widget _metaChip(BuildContext context,
      {required IconData icon, required String label}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
