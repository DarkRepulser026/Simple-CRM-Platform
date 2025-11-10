import 'package:flutter/material.dart';
import 'loading_view.dart';
import 'error_view.dart';

/// Generic paginated list view that handles loading, error states, and pagination
class PaginatedListView<T> extends StatefulWidget {
  const PaginatedListView({
    super.key,
    required this.itemBuilder,
    required this.fetchPage,
    this.initialItems = const [],
    this.pageSize = 20,
    this.emptyMessage = 'No items found',
    this.errorMessage = 'Failed to load items',
    this.loadingMessage = 'Loading items...',
    this.scrollController,
    this.padding = const EdgeInsets.all(16),
    this.separatorBuilder,
    this.onRefresh,
  });

  final List<T> initialItems;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Future<List<T>> Function(int page, int limit) fetchPage;
  final int pageSize;
  final String emptyMessage;
  final String errorMessage;
  final String loadingMessage;
  final ScrollController? scrollController;
  final EdgeInsets padding;
  final Widget Function(BuildContext context, int index)? separatorBuilder;
  final Future<void> Function()? onRefresh;

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final List<T> _items = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  bool _hasNextPage = true;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _items.addAll(widget.initialItems);
    if (_items.isEmpty) {
      _loadInitialPage();
    }
  }

  @override
  void didUpdateWidget(PaginatedListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialItems != oldWidget.initialItems) {
      _items.clear();
      _items.addAll(widget.initialItems);
      _currentPage = 0;
      _hasNextPage = true;
      _error = null;
    }
  }

  Future<void> _loadInitialPage() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await widget.fetchPage(1, widget.pageSize);
      setState(() {
        _items.clear();
        _items.addAll(items);
        _currentPage = 1;
        _hasNextPage = items.length >= widget.pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasNextPage) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final items = await widget.fetchPage(nextPage, widget.pageSize);
      setState(() {
        _items.addAll(items);
        _currentPage = nextPage;
        _hasNextPage = items.length >= widget.pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refresh() async {
    if (widget.onRefresh != null) {
      await widget.onRefresh!();
    } else {
      await _loadInitialPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _items.isEmpty) {
      return LoadingView(message: widget.loadingMessage);
    }

    if (_error != null && _items.isEmpty) {
      return ErrorView(
        message: widget.errorMessage,
        onRetry: _loadInitialPage,
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: widget.padding,
          child: Text(
            widget.emptyMessage,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: widget.scrollController,
        padding: widget.padding,
        itemCount: _items.length + (_hasNextPage ? 1 : 0) + (_error != null && _items.isNotEmpty ? 1 : 0),
        separatorBuilder: widget.separatorBuilder ?? (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          // Error banner at the top if there's an error and we have items
          if (_error != null && _items.isNotEmpty && index == 0) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: ErrorView(
                message: _error!,
                onRetry: _loadInitialPage,
              ),
            );
          }

          // Adjust index if error banner is shown
          final adjustedIndex = (_error != null && _items.isNotEmpty) ? index - 1 : index;

          // Loading indicator at the bottom
          if (adjustedIndex == _items.length) {
            if (_isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            // Load more trigger (invisible item that triggers loading when visible)
            return SizedBox(
              height: 50,
              child: Center(
                child: ElevatedButton(
                  onPressed: _loadNextPage,
                  child: const Text('Load More'),
                ),
              ),
            );
          }

          // Regular item
          return widget.itemBuilder(context, _items[adjustedIndex], adjustedIndex);
        },
      ),
    );
  }
}