import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../services/contacts_service.dart';
import '../services/service_locator.dart';

/// Reusable dropdown widget for selecting a contact from an account
///
/// Usage:
/// ```dart
/// ContactDropdown(
///   accountId: account.id,
///   initialContactId: ticket.contactId,
///   onChanged: (contactId) => setState(() => _contactId = contactId),
/// )
/// ```
class ContactDropdown extends StatefulWidget {
  final String accountId;
  final String? initialContactId;
  final ValueChanged<String?> onChanged;
  final String? label;
  final String? hintText;
  final bool enabled;

  const ContactDropdown({
    super.key,
    required this.accountId,
    this.initialContactId,
    required this.onChanged,
    this.label,
    this.hintText,
    this.enabled = true,
  });

  @override
  State<ContactDropdown> createState() => _ContactDropdownState();
}

class _ContactDropdownState extends State<ContactDropdown> {
  List<Contact> _contacts = [];
  bool _loading = true;
  String? _selectedContactId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedContactId = widget.initialContactId;
    _loadContacts();
  }

  @override
  void didUpdateWidget(ContactDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.accountId != oldWidget.accountId) {
      _loadContacts();
    }
  }

  Future<void> _loadContacts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final contactsService = locator<ContactsService>();
    final result = await contactsService.getContactsByAccountId(widget.accountId);

    if (result.isSuccess && mounted) {
      setState(() {
        _contacts = result.value;
        _loading = false;
      });
    } else if (mounted) {
      setState(() {
        _error = result.error.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_loading) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label ?? 'Contact',
          filled: true,
          fillColor: cs.surfaceVariant.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        child: const SizedBox(
          height: 20,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label ?? 'Contact',
          filled: true,
          fillColor: cs.errorContainer.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          errorText: _error,
        ),
        child: const SizedBox(height: 20),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedContactId,
      decoration: InputDecoration(
        labelText: widget.label ?? 'Contact',
        hintText: widget.hintText ?? 'Select a contact',
        filled: true,
        fillColor: cs.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(16),
        prefixIcon: Icon(Icons.person_outline, color: cs.primary),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('No contact'),
        ),
        ..._contacts.map((contact) {
          return DropdownMenuItem<String>(
            value: contact.id,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    contact.firstName.isNotEmpty ? contact.firstName[0].toUpperCase() : 'C',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    contact.fullName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
      onChanged: widget.enabled
          ? (value) {
              setState(() => _selectedContactId = value);
              widget.onChanged(value);
            }
          : null,
      isExpanded: true,
    );
  }
}
