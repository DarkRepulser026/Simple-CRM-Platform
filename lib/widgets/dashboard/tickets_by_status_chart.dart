import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TicketsByStatusChart extends StatelessWidget {
  const TicketsByStatusChart({
    super.key,
    required this.data,
  });

  final Map<String, int> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (data.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Text(
          'No ticket data available',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tickets by Status',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Distribution of tickets across different statuses',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // 🔧 Quan trọng: luôn cho chart một height cố định
              if (isWide)
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 260,
                        child: _TicketsStatusBarChart(data: data),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 260,
                        child: _TicketsStatusPieChart(data: data),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    SizedBox(
                      height: 220,
                      child: _TicketsStatusBarChart(data: data),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 220,
                      child: _TicketsStatusPieChart(data: data),
                    ),
                  ],
                ),

              const SizedBox(height: 16),
              _StatusLegend(data: data),
            ],
          );
        },
      ),
    );
  }
}

/// BAR CHART
class _TicketsStatusBarChart extends StatelessWidget {
  const _TicketsStatusBarChart({
    required this.data,
  });

  final Map<String, int> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = data.entries.toList();

    // max value để scale trục Y
    final maxValue = entries
        .map((e) => e.value)
        .fold<int>(0, (prev, curr) => curr > prev ? curr : prev)
        .toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue == 0 ? 1 : maxValue * 1.2,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          horizontalInterval:
              maxValue <= 5 ? 1 : (maxValue / 4).ceilToDouble(),
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.dividerColor.withOpacity(0.3),
            strokeWidth: 0.6,
          ),
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= entries.length) {
                  return const SizedBox.shrink();
                }
                final label = entries[index].key;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(entries.length, (index) {
          final e = entries[index];
          final color = _statusColor(e.key, context);
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: e.value.toDouble(),
                borderRadius: BorderRadius.circular(6),
                width: 18,
                color: color,
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// PIE CHART
class _TicketsStatusPieChart extends StatelessWidget {
  const _TicketsStatusPieChart({
    required this.data,
  });

  final Map<String, int> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = data.entries.toList();
    final total = entries.fold<int>(0, (p, e) => p + e.value);

    if (total == 0) {
      return Center(
        child: Text(
          'No data',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        startDegreeOffset: -90,
        sections: List.generate(entries.length, (index) {
          final e = entries[index];
          final value = e.value.toDouble();
          final percent = value / total * 100;
          final color = _statusColor(e.key, context);

          return PieChartSectionData(
            value: value,
            color: color,
            radius: 52,
            title: percent >= 8 ? '${percent.toStringAsFixed(0)}%' : '',
            titleStyle: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          );
        }),
      ),
    );
  }
}

/// LEGEND
class _StatusLegend extends StatelessWidget {
  const _StatusLegend({
    required this.data,
  });

  final Map<String, int> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = data.entries.toList();
    final total = entries.fold<int>(0, (p, e) => p + e.value);

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: entries.map((e) {
        final color = _statusColor(e.key, context);
        final percent =
            total == 0 ? 0 : (e.value / total * 100);

        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                e.key,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${e.value} (${percent.toStringAsFixed(0)}%)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// màu cho từng status
Color _statusColor(String status, BuildContext context) {
  switch (status.toLowerCase()) {
    case 'open':
      return Colors.blue;
    case 'pending':
      return Colors.orange;
    case 'in progress':
      return Colors.indigo;
    case 'resolved':
      return Colors.green;
    case 'closed':
      return Colors.grey;
    default:
      return Theme.of(context).colorScheme.primary;
  }
}
