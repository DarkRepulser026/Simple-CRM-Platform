import 'package:flutter/material.dart';
import '../../widgets/paginated_list_view.dart';
import '../../models/interaction.dart';
import '../../services/service_locator.dart';
import '../../services/interaction_service.dart';

class InteractionsListScreen extends StatefulWidget {
  const InteractionsListScreen({super.key});

  @override
  State<InteractionsListScreen> createState() => _InteractionsListScreenState();
}

class _InteractionsListScreenState extends State<InteractionsListScreen> {
  late final InteractionService _interactionService;
  int _reloadVersion = 0;

  final int _flexType = 2;
  final int _flexSubject = 4;
  final int _flexDirection = 2;
  final int _flexDate = 3;

  Future<List<Interaction>> _fetchPage(int page, int limit) async {
    final res =
        await _interactionService.getInteractions(page: page, limit: limit);
    if (res.isSuccess) return res.value.interactions;
    throw Exception(res.error.message);
  }

  @override
  void initState() {
    super.initState();
    _interactionService = locator<InteractionService>();
  }

  // _refreshList is unused; keep reloadVersion state and expose refresh capability via other UI actions

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const bgColor = Color(0xFFE9EDF5);

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== HEADER =====
                _buildHeader(context, colorScheme),
                const SizedBox(height: 24),

                // ===== FILTER BAR =====
                _buildFilterBar(context, colorScheme),
                const SizedBox(height: 16),

                // ===== TABLE CARD =====
                Expanded(
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: colorScheme.outlineVariant.withOpacity(0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        // --- TABLE HEADER ---
                        Container(
                          height: 48,
                          color: colorScheme.surfaceVariant.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(flex: _flexType, child: _buildHeaderLabel(context, 'TYPE')),
                              Expanded(flex: _flexSubject, child: _buildHeaderLabel(context, 'SUBJECT / NOTE')),
                              Expanded(flex: _flexDirection, child: _buildHeaderLabel(context, 'DIRECTION')),
                              Expanded(flex: _flexDate, child: _buildHeaderLabel(context, 'DATE & TIME')),
                              const SizedBox(width: 40), // Cột action
                            ],
                          ),
                        ),
                        const Divider(height: 1, thickness: 1),

                        // --- TABLE BODY ---
                        Expanded(
                          child: PaginatedListView<Interaction>(
                            key: ValueKey(_reloadVersion),
                            pageSize: 20,
                            fetchPage: _fetchPage,
                            emptyMessage: 'No interactions found',
                            errorMessage: 'Failed to load interactions',
                            loadingMessage: 'Loading interactions...',
                            separatorBuilder: (context, index) => Divider(
                                height: 1,
                                color: colorScheme.outlineVariant.withOpacity(0.2)),
                            itemBuilder: (context, interaction, index) =>
                                _buildInteractionRow(context, interaction, colorScheme),
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

  // Header Title
  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interactions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
            ),
            Text(
              'History of customer touchpoints',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        FilledButton.icon(
          onPressed: () {
            // TODO: Navigate to Create Interaction
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Log Interaction'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  // Filter UI
  Widget _buildFilterBar(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, size: 20),
              hintText: 'Search subject...',
              isDense: true,
              filled: true,
              fillColor: colorScheme.surface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colorScheme.primary),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            ),
            onChanged: (val) {
              // TODO: Implement search logic
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
    );
  }

  // Row Item
  Widget _buildInteractionRow(
      BuildContext context, Interaction item, ColorScheme colorScheme) {
    return InkWell(
      onTap: () {
        // TODO: View detail
      },
      hoverColor: colorScheme.primary.withOpacity(0.04),
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Column 1: Type
            Expanded(
              flex: _flexType,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildTypeChip(context, item.type.value),
              ),
            ),

            // Column 2: Subject
            Expanded(
              flex: _flexSubject,
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(
                  item.subject ?? 'No subject',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Column 3: Direction
            Expanded(
              flex: _flexDirection,
              child: _buildDirectionInfo(context, item.direction.value),
            ),

            // Cột 4: Date
            Expanded(
              flex: _flexDate,
              child: Text(
                _formatDateTime(item.createdAt),
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            
            // Cột 5: Action
            SizedBox(
              width: 40,
              child: IconButton(
                icon: Icon(Icons.chevron_right, color: colorScheme.outline),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(BuildContext context, String type) {
    IconData icon;
    Color color;
    String label = type;


    final t = type.toLowerCase();
    if (t.contains('call') || t.contains('phone')) {
      icon = Icons.phone;
      color = Colors.green;
    } else if (t.contains('email') || t.contains('mail')) {
      icon = Icons.email;
      color = Colors.blue;
    } else if (t.contains('meeting')) {
      icon = Icons.calendar_month;
      color = Colors.purple;
    } else {
      icon = Icons.notes;
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionInfo(BuildContext context, String direction) {
    final isInbound = direction.toLowerCase().contains('inbound');
    final color = isInbound ? const Color(0xFF1B8C57) : const Color(0xFFD97706); // Green vs Orange
    final icon = isInbound ? Icons.call_received : Icons.call_made;

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          direction,
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    final local = date.toLocal();
    return "${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} "
           "${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}";
  }
}