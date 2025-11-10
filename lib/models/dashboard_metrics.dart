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
    final metrics = json['metrics'] ?? json;
    return DashboardMetrics(
      totalLeads: metrics['totalLeads'] ?? 0,
      totalOpportunities: metrics['totalOpportunities'] ?? 0,
      totalAccounts: metrics['totalAccounts'] ?? 0,
      totalContacts: metrics['totalContacts'] ?? 0,
      pendingTasks: metrics['pendingTasks'] ?? 0,
      opportunityRevenue: (metrics['opportunityRevenue'] ?? 0).toDouble(),
      totalTickets: metrics['totalTickets'] ?? 0,
      openTickets: metrics['openTickets'] ?? 0,
      pendingTickets: metrics['pendingTickets'] ?? 0,
      resolvedTickets: metrics['resolvedTickets'] ?? 0,
      overdueTickets: metrics['overdueTickets'] ?? 0,
      ticketsByStatus: metrics['ticketsByStatus'] != null
          ? Map<String, int>.from(metrics['ticketsByStatus'])
          : {},
      ticketsByAgent: metrics['ticketsByAgent'] != null
          ? Map<String, int>.from(metrics['ticketsByAgent'])
          : {},
      ticketsByPriority: metrics['ticketsByPriority'] != null
          ? Map<String, int>.from(metrics['ticketsByPriority'])
          : {},
      averageCsat: (metrics['averageCsat'] ?? 0).toDouble(),
      averageNps: (metrics['averageNps'] ?? 0).toDouble(),
      totalSatisfactionResponses: metrics['totalSatisfactionResponses'] ?? 0,
      averageFirstResponseTime: (metrics['averageFirstResponseTime'] ?? 0).toDouble(),
      averageResolutionTime: (metrics['averageResolutionTime'] ?? 0).toDouble(),
      averageResponseTime: (metrics['averageResponseTime'] ?? 0).toDouble(),
      slaComplianceRate: (metrics['slaComplianceRate'] ?? 0).toDouble(),
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