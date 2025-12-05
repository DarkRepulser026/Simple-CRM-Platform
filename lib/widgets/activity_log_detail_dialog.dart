import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/activity_log.dart';
import 'package:flutter/services.dart';
import '../screens/accounts/account_detail_screen.dart';
import '../screens/contacts/contact_detail_screen.dart';
import '../screens/leads/lead_detail_screen.dart' as lead_detail;
import '../screens/tasks/task_detail_screen.dart';
import '../screens/tickets/ticket_detail_screen.dart';

class ActivityLogDetailDialog extends StatelessWidget {
  final ActivityLog activityLog;
  const ActivityLogDetailDialog({super.key, required this.activityLog});

  String _prettyJson(Map<String, dynamic>? map) {
    if (map == null) return '{}';
    try {
      return const JsonEncoder.withIndent('  ').convert(map);
    } catch (_) {
      return map.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final oldVals = activityLog.oldValues;
    final newVals = activityLog.newValues;
    final metadata = activityLog.metadata;
    final displayMap = metadata ?? (oldVals ?? newVals);

    return AlertDialog(
      title: Text(activityLog.activityType.value),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (activityLog.userName != null) Text('User: ${activityLog.userName}'),
              Text('When: ${activityLog.createdAt.toLocal()}'),
              const SizedBox(height: 8),
              if (activityLog.entityType != null)
                Text('Entity: ${activityLog.entityType} ${activityLog.entityName ?? ''} (${activityLog.entityId ?? ''})'),
              if (activityLog.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Description:', style: Theme.of(context).textTheme.titleMedium),
                Text(activityLog.description),
              ],
              const SizedBox(height: 8),
              if ((oldVals != null && newVals != null) || (displayMap != null))
                ExpansionTile(
                  title: const Text('Details / Changes'),
                  children: [
                    if (oldVals != null && newVals != null)
                      _buildDiffView(oldVals, newVals),
                    if (displayMap != null && (oldVals == null || newVals == null))
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SelectableText(_prettyJson(displayMap as Map<String, dynamic>?)),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () async {
                            final str = _prettyJson(displayMap);
                            await Clipboard.setData(ClipboardData(text: str));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                          },
                          tooltip: 'Copy JSON',
                        )
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        if (activityLog.entityType != null && activityLog.entityId != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // navigate to entity detail based on type
              final entityType = activityLog.entityType;
              final entityId = activityLog.entityId!;
              switch (entityType) {
                case 'Account':
                  showAccountDetailDialog(context, accountId: entityId);
                  break;
                case 'Contact':
                  // Use the dialog helper which will show the contact dialog reliably
                  showContactDetailDialog(context, contactId: entityId);
                  break;
                case 'Lead':
                  // Use the lead dialog helper to show the lead details reliably
                  lead_detail.showLeadDetailDialog(context, leadId: entityId);
                  break;
                case 'Task':
                  // Use the existing helper to show task detail as dialog
                  showTaskDetailDialog(context, entityId);
                  break;
                case 'Ticket':
                  showTicketDetailDialog(context, ticketId: entityId);
                  break;
                default:
                  break;
              }
            },
            child: const Text('Open Entity'),
          ),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
      ],
    );
  }

  Widget _buildDiffView(Map<String, dynamic> oldVals, Map<String, dynamic> newVals) {
    final keys = <String>{};
    keys.addAll(oldVals.keys);
    keys.addAll(newVals.keys);
    final sortedKeys = keys.toList()..sort();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sortedKeys.map((k) {
          final oldVal = oldVals[k];
          final newVal = newVals[k];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
                const SizedBox(width: 8),
                Expanded(flex: 4, child: Text(oldVal?.toString() ?? '-', overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward, size: 14),
                const SizedBox(width: 6),
                Expanded(flex: 4, child: Text(newVal?.toString() ?? '-', overflow: TextOverflow.ellipsis)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
