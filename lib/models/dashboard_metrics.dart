/// Dashboard metrics model representing key business metrics
class DashboardMetrics {
  final int totalLeads;
  final int totalOpportunities;
  final int totalAccounts;
  final int totalContacts;
  final int pendingTasks;
  final double opportunityRevenue;

  // Ticket metrics
  final int totalTickets;
  final int openTickets;
  final int pendingTickets;
  final int resolvedTickets;
  final int overdueTickets;
  final Map<String, int> ticketsByStatus; // Status -> count
  final Map<String, int> ticketsByAgent; // Agent ID -> count
  final Map<String, int> ticketsByPriority; // Priority -> count

  // Customer satisfaction metrics
  final double averageCsat; // Customer Satisfaction Score (1-5 scale)
  final double averageNps; // Net Promoter Score (-100 to 100)
  final int totalSatisfactionResponses;

  // Response time metrics (in hours)
  final double averageFirstResponseTime;
  final double averageResolutionTime;
  final double averageResponseTime;

  // SLA compliance
  final double slaComplianceRate; // Percentage of tickets resolved within SLA

  const DashboardMetrics({
    required this.totalLeads,
    required this.totalOpportunities,
    required this.totalAccounts,
    required this.totalContacts,
    required this.pendingTasks,
    required this.opportunityRevenue,
    required this.totalTickets,
    required this.openTickets,
    required this.pendingTickets,
    required this.resolvedTickets,
    required this.overdueTickets,
    required this.ticketsByStatus,
    required this.ticketsByAgent,
    required this.ticketsByPriority,
    required this.averageCsat,
    required this.averageNps,
    required this.totalSatisfactionResponses,
    required this.averageFirstResponseTime,
    required this.averageResolutionTime,
    required this.averageResponseTime,
    required this.slaComplianceRate,
  });

  /// Factory constructor to create DashboardMetrics from JSON
  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    final counts = json['counts'] ?? {};
    final ticketStats = json['ticketStats'] as List<dynamic>? ?? [];
    final Map<String, int> ticketsByStatus = {};
    for (final s in ticketStats) {
      try {
        final status = s['status'] as String? ?? 'Unknown';
        final count = (s['_count'] != null && s['_count']['status'] != null) ? (s['_count']['status'] as int) : (s['count'] as int? ?? 0);
        ticketsByStatus[status] = count;
      } catch (_) {
        // ignore parsing errors for stats
      }
    }

    final totalTickets = (counts['tickets'] is int)
      ? counts['tickets'] as int
      : ticketsByStatus.values.fold<int>(0, (a, b) => a + b);
    final openTickets = ticketsByStatus['Open'] ?? ticketsByStatus['open'] ?? 0;
    final pendingTickets = ticketsByStatus['Pending'] ?? ticketsByStatus['pending'] ?? 0;
    final resolvedTickets = ticketsByStatus['Resolved'] ?? ticketsByStatus['resolved'] ?? 0;
    final overdueTickets = ticketsByStatus['Overdue'] ?? ticketsByStatus['overdue'] ?? 0;

    return DashboardMetrics(
      totalLeads: (counts['leads'] as int?) ?? 0,
      totalOpportunities: 0,
      totalAccounts: (counts['accounts'] as int?) ?? 0,
      totalContacts: (counts['contacts'] as int?) ?? 0,
      pendingTasks: (counts['tasks'] as int?) ?? 0,
      opportunityRevenue: 0.0,
      totalTickets: totalTickets,
      openTickets: openTickets,
      pendingTickets: pendingTickets,
      resolvedTickets: resolvedTickets,
      overdueTickets: overdueTickets,
      ticketsByStatus: ticketsByStatus,
      ticketsByAgent: {},
      ticketsByPriority: {},
      averageCsat: 0.0,
      averageNps: 0.0,
      totalSatisfactionResponses: 0,
      averageFirstResponseTime: 0.0,
      averageResolutionTime: 0.0,
      averageResponseTime: 0.0,
      slaComplianceRate: 0.0,
    );
  }

  /// Convert DashboardMetrics to JSON
  Map<String, dynamic> toJson() {
    return {
      'totalLeads': totalLeads,
      'totalOpportunities': totalOpportunities,
      'totalAccounts': totalAccounts,
      'totalContacts': totalContacts,
      'pendingTasks': pendingTasks,
      'opportunityRevenue': opportunityRevenue,
      'totalTickets': totalTickets,
      'openTickets': openTickets,
      'pendingTickets': pendingTickets,
      'resolvedTickets': resolvedTickets,
      'overdueTickets': overdueTickets,
      'ticketsByStatus': ticketsByStatus,
      'ticketsByAgent': ticketsByAgent,
      'ticketsByPriority': ticketsByPriority,
      'averageCsat': averageCsat,
      'averageNps': averageNps,
      'totalSatisfactionResponses': totalSatisfactionResponses,
      'averageFirstResponseTime': averageFirstResponseTime,
      'averageResolutionTime': averageResolutionTime,
      'averageResponseTime': averageResponseTime,
      'slaComplianceRate': slaComplianceRate,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DashboardMetrics &&
        other.totalLeads == totalLeads &&
        other.totalOpportunities == totalOpportunities &&
        other.totalAccounts == totalAccounts &&
        other.totalContacts == totalContacts &&
        other.pendingTasks == pendingTasks &&
        other.opportunityRevenue == opportunityRevenue &&
        other.totalTickets == totalTickets &&
        other.openTickets == openTickets &&
        other.pendingTickets == pendingTickets &&
        other.resolvedTickets == resolvedTickets &&
        other.overdueTickets == overdueTickets &&
        _mapEquals(other.ticketsByStatus, ticketsByStatus) &&
        _mapEquals(other.ticketsByAgent, ticketsByAgent) &&
        _mapEquals(other.ticketsByPriority, ticketsByPriority) &&
        other.averageCsat == averageCsat &&
        other.averageNps == averageNps &&
        other.totalSatisfactionResponses == totalSatisfactionResponses &&
        other.averageFirstResponseTime == averageFirstResponseTime &&
        other.averageResolutionTime == averageResolutionTime &&
        other.averageResponseTime == averageResponseTime &&
        other.slaComplianceRate == slaComplianceRate;
  }

  @override
  int get hashCode {
    return totalLeads.hashCode ^
        totalOpportunities.hashCode ^
        totalAccounts.hashCode ^
        totalContacts.hashCode ^
        pendingTasks.hashCode ^
        opportunityRevenue.hashCode ^
        totalTickets.hashCode ^
        openTickets.hashCode ^
        pendingTickets.hashCode ^
        resolvedTickets.hashCode ^
        overdueTickets.hashCode ^
        ticketsByStatus.hashCode ^
        ticketsByAgent.hashCode ^
        ticketsByPriority.hashCode ^
        averageCsat.hashCode ^
        averageNps.hashCode ^
        totalSatisfactionResponses.hashCode ^
        averageFirstResponseTime.hashCode ^
        averageResolutionTime.hashCode ^
        averageResponseTime.hashCode ^
        slaComplianceRate.hashCode;
  }

  /// Helper method to compare maps
  static bool _mapEquals(Map<String, int>? a, Map<String, int>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}