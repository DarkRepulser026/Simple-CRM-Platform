/// Pagination information for paginated API responses
class Pagination {
  final int page;
  final int limit;
  final int total;
  final int? totalPages;
  final bool hasNext;
  final bool hasPrev;

  const Pagination({
    required this.page,
    required this.limit,
    required this.total,
    this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  /// Convenience getter for hasPrevious
  bool get hasPrevious => hasPrev;

  /// Convenience getter for total pages
  int get pages => totalPages ?? 1;

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 10,
      total: json['total'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? json['pages'] as int?,
      hasNext: json['hasNext'] as bool? ?? false,
      hasPrev: json['hasPrev'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total': total,
      if (totalPages != null) 'totalPages': totalPages,
      'hasNext': hasNext,
      'hasPrev': hasPrev,
    };
  }

  @override
  String toString() {
    return 'Pagination(page: $page, limit: $limit, total: $total, totalPages: $totalPages, hasNext: $hasNext, hasPrev: $hasPrev)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pagination &&
        other.page == page &&
        other.limit == limit &&
        other.total == total &&
        other.totalPages == totalPages &&
        other.hasNext == hasNext &&
        other.hasPrev == hasPrev;
  }

  @override
  int get hashCode {
    return page.hashCode ^
        limit.hashCode ^
        total.hashCode ^
        totalPages.hashCode ^
        hasNext.hashCode ^
        hasPrev.hashCode;
  }
}

/// Generic paginated response wrapper
class PaginatedResponse<T> {
  final List<T> items;
  final Pagination pagination;

  const PaginatedResponse({
    required this.items,
    required this.pagination,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .map((item) => fromJsonT(item as Map<String, dynamic>))
        .toList();

    final pagination = Pagination.fromJson(json['pagination'] as Map<String, dynamic>? ?? {});

    return PaginatedResponse<T>(
      items: items,
      pagination: pagination,
    );
  }

  Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
    return {
      'items': items.map(toJsonT).toList(),
      'pagination': pagination.toJson(),
    };
  }

  @override
  String toString() {
    return 'PaginatedResponse(items: ${items.length} items, pagination: $pagination)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaginatedResponse<T> &&
        other.items.length == items.length &&
        other.pagination == pagination;
  }

  @override
  int get hashCode {
    return items.hashCode ^ pagination.hashCode;
  }
}