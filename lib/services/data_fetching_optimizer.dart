import 'dart:async';

/// Optimizes data fetching with caching, debouncing, and throttling strategies
class DataFetchingOptimizer {
  // Cache storage
  final Map<String, _CacheEntry> _cache = {};
  static const Duration _defaultCacheDuration = Duration(minutes: 5);

  // Debounce timers
  final Map<String, Timer?> _debounceTimers = {};
  static const Duration _defaultDebounceDelay = Duration(milliseconds: 500);

  // Throttle tracking
  final Map<String, DateTime> _lastExecutionTime = {};
  static const Duration _defaultThrottleInterval = Duration(seconds: 1);

  /// Cache a value with automatic expiration
  void cacheValue<T>(
    String key,
    T value, {
    Duration? duration,
  }) {
    _cache[key] = _CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(duration ?? _defaultCacheDuration),
    );
  }

  /// Retrieve cached value if not expired
  T? getCachedValue<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (DateTime.now().isAfter(entry.expiresAt)) {
      _cache.remove(key);
      return null;
    }

    return entry.value as T?;
  }

  /// Check if a cached value exists and is valid
  bool isCacheValid(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    return DateTime.now().isBefore(entry.expiresAt);
  }

  /// Clear specific cache entry
  void clearCache(String key) {
    _cache.remove(key);
  }

  /// Clear all cache
  void clearAllCache() {
    _cache.clear();
  }

  /// Debounce a function call (delays execution until no more calls for delay duration)
  Future<T?> debounce<T>(
    String key,
    Future<T> Function() function, {
    Duration? delay,
  }) async {
    // Cancel previous timer
    _debounceTimers[key]?.cancel();

    // Create new timer
    final completer = Completer<T?>();
    _debounceTimers[key] = Timer(delay ?? _defaultDebounceDelay, () async {
      try {
        final result = await function();
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      } catch (e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      }
      _debounceTimers[key] = null;
    });

    try {
      return await completer.future;
    } catch (e) {
      return null;
    }
  }

  /// Cancel a debounced operation
  void cancelDebounce(String key) {
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = null;
  }

  /// Throttle a function (executes at most once per interval)
  Future<T?> throttle<T>(
    String key,
    Future<T> Function() function, {
    Duration? interval,
  }) async {
    final now = DateTime.now();
    final lastExecution = _lastExecutionTime[key];

    if (lastExecution != null) {
      final elapsed = now.difference(lastExecution);
      if (elapsed < (interval ?? _defaultThrottleInterval)) {
        return null; // Skip execution
      }
    }

    try {
      final result = await function();
      _lastExecutionTime[key] = DateTime.now();
      return result;
    } catch (e) {
      return null;
    }
  }

  /// Clear all debounce timers
  void clearAllDebounce() {
    for (final timer in _debounceTimers.values) {
      timer?.cancel();
    }
    _debounceTimers.clear();
  }

  /// Cleanup (cancel all timers)
  void dispose() {
    clearAllDebounce();
    clearAllCache();
  }
}

class _CacheEntry {
  final dynamic value;
  final DateTime expiresAt;

  _CacheEntry({
    required this.value,
    required this.expiresAt,
  });
}

/// Batch request processor for efficient bulk operations
class BatchRequestProcessor<T> {
  final List<String> _queue = [];
  final Future<T> Function(List<String>) _processor;
  final Duration _batchDelay;
  late Timer _batchTimer;
  bool _timerActive = false;

  BatchRequestProcessor({
    required Future<T> Function(List<String>) processor,
    Duration batchDelay = const Duration(milliseconds: 100),
  })  : _processor = processor,
        _batchDelay = batchDelay;

  /// Add an item to the batch queue
  void addToQueue(String item) {
    _queue.add(item);
    _scheduleBatch();
  }

  /// Add multiple items to the batch queue
  void addMultipleToQueue(List<String> items) {
    _queue.addAll(items);
    _scheduleBatch();
  }

  /// Schedule batch execution
  void _scheduleBatch() {
    if (_timerActive) return;

    _timerActive = true;
    _batchTimer = Timer(_batchDelay, _processBatch);
  }

  /// Process the current batch
  Future<void> _processBatch() async {
    if (_queue.isEmpty) {
      _timerActive = false;
      return;
    }

    final itemsToProcess = List<String>.from(_queue);
    _queue.clear();

    try {
      await _processor(itemsToProcess);
    } finally {
      _timerActive = false;
    }
  }

  /// Flush remaining items immediately
  Future<void> flush() async {
    _batchTimer.cancel();
    await _processBatch();
  }

  /// Clear the queue
  void clear() {
    _batchTimer.cancel();
    _queue.clear();
    _timerActive = false;
  }
}

/// Request deduplication to avoid duplicate concurrent requests
class RequestDeduplicator {
  final Map<String, Future<dynamic>> _pendingRequests = {};

  /// Execute a function, returning cached future if same key already in flight
  Future<T> deduplicate<T>(
    String key,
    Future<T> Function() function,
  ) async {
    // Check if request already in flight
    if (_pendingRequests.containsKey(key)) {
      return _pendingRequests[key] as Future<T>;
    }

    // Execute and cache the future
    final future = function();
    _pendingRequests[key] = future;

    try {
      final result = await future;
      return result;
    } finally {
      _pendingRequests.remove(key);
    }
  }

  /// Clear a specific pending request
  void clearRequest(String key) {
    _pendingRequests.remove(key);
  }

  /// Clear all pending requests
  void clearAll() {
    _pendingRequests.clear();
  }
}

/// Pagination helper for efficient list navigation
class PaginationHelper {
  int _currentPage = 1;
  int _pageSize = 20;
  int _totalItems = 0;
  int _totalPages = 0;

  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalItems => _totalItems;
  int get totalPages => _totalPages;

  bool get hasNextPage => _currentPage < _totalPages;
  bool get hasPreviousPage => _currentPage > 1;

  int get offset => (_currentPage - 1) * _pageSize;

  /// Initialize pagination with totals
  void initialize({required int total, required int pageSize}) {
    _totalItems = total;
    _pageSize = pageSize;
    _totalPages = (total / pageSize).ceil();
    _currentPage = 1;
  }

  /// Move to next page
  bool nextPage() {
    if (hasNextPage) {
      _currentPage++;
      return true;
    }
    return false;
  }

  /// Move to previous page
  bool previousPage() {
    if (hasPreviousPage) {
      _currentPage--;
      return true;
    }
    return false;
  }

  /// Go to specific page
  bool goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      _currentPage = page;
      return true;
    }
    return false;
  }

  /// Reset to first page
  void reset() {
    _currentPage = 1;
  }
}
