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

  Future<List<Interaction>> _fetchPage(int page, int limit) async {
    final res = await _interactionService.getInteractions(page: page, limit: limit);
    if (res.isSuccess) return res.value.interactions;
    throw Exception(res.error.message);
  }

  @override
  void initState() {
    super.initState();
    _interactionService = locator<InteractionService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Interactions')),
      body: PaginatedListView<Interaction>(
        pageSize: 20,
        fetchPage: _fetchPage,
        emptyMessage: 'No interactions',
        errorMessage: 'Failed to load interactions',
        loadingMessage: 'Loading interactions...',
        itemBuilder: (context, interaction, index) => ListTile(
          title: Text(interaction.subject ?? interaction.type.value),
          subtitle: Text('${interaction.direction.value} • ${interaction.createdAt.toLocal()}'),
        ),
      ),
    );
  }
}
