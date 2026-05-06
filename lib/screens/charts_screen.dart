import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/category_model.dart';
import '../utils/app_theme.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Charts'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecond,
          tabs: const [
            Tab(text: 'Category Pie'),
            Tab(text: 'Monthly Trend'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _PieChartTab(),
          _TrendChartTab(),
        ],
      ),
    );
  }
}

// ─── PIE CHART TAB ────────────────────────────────────────────────────────────
class _PieChartTab extends StatefulWidget {
  const _PieChartTab();

  @override
  State<_PieChartTab> createState() => _PieChartTabState();
}

class _PieChartTabState extends State<_PieChartTab> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final spending = provider.categorySpending;
    final total = provider.totalExpense;

    if (spending.isEmpty) {
      return _emptyChart('No expenses this month');
    }

    // Convert spending map to pie sections
    final sections = spending.entries.map((entry) {
      final index = spending.keys.toList().indexOf(entry.key);
      final cat = getCategoryByName(entry.key, true);
      final pct = total > 0 ? entry.value / total : 0.0;
      final isTouched = index == _touchedIndex;

      return PieChartSectionData(
        value: entry.value,
        color: cat.color,
        radius: isTouched ? 90 : 75,
        title: '${(pct * 100).toStringAsFixed(1)}%',
        titleStyle: TextStyle(
          fontSize: isTouched ? 14 : 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        badgeWidget: isTouched
            ? Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: cat.color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            entry.key,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
        )
            : null,
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Pie Chart
          SizedBox(
            height: 280,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 50,
                sectionsSpace: 3,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex =
                          response.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Tap a slice to highlight',
              style: TextStyle(color: AppTheme.textSecond, fontSize: 12)),
          const SizedBox(height: 24),

          // Legend
          ...spending.entries.map((entry) {
            final cat = getCategoryByName(entry.key, true);
            final pct = total > 0 ? entry.value / total * 100 : 0.0;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: cat.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(cat.icon, color: cat.color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(entry.key,
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 13)),
                  ),
                  Text(
                    'PKR ${NumberFormat('#,##0').format(entry.value)}',
                    style: TextStyle(
                        color: cat.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  Text('${pct.toStringAsFixed(1)}%',
                      style: const TextStyle(
                          color: AppTheme.textSecond, fontSize: 12)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── TREND CHART TAB ──────────────────────────────────────────────────────────
class _TrendChartTab extends StatelessWidget {
  const _TrendChartTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final trend = provider.monthlyTrend;

    // Find max value for Y axis scaling
    double maxVal = 100;
    for (final m in trend) {
      final income = m['income'] as double;
      final expense = m['expense'] as double;
      if (income > maxVal) maxVal = income;
      if (expense > maxVal) maxVal = expense;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Last 6 Months',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Income vs Expense trend',
            style: TextStyle(color: AppTheme.textSecond, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Legend
          Row(
            children: [
              _legendDot(AppTheme.incomeGreen, 'Income'),
              const SizedBox(width: 20),
              _legendDot(AppTheme.expenseRed, 'Expense'),
            ],
          ),
          const SizedBox(height: 16),

          // Bar Chart
          SizedBox(
            height: 280,
            child: BarChart(
              BarChartData(
                maxY: maxVal * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.card,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final month = trend[group.x]['month'] as DateTime;
                      final isIncome = rodIndex == 0;
                      return BarTooltipItem(
                        '${DateFormat('MMM').format(month)}\n',
                        const TextStyle(
                            color: AppTheme.textSecond, fontSize: 11),
                        children: [
                          TextSpan(
                            text:
                            'PKR ${NumberFormat('#,##0').format(rod.toY)}',
                            style: TextStyle(
                              color: isIncome
                                  ? AppTheme.incomeGreen
                                  : AppTheme.expenseRed,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (val, _) => Text(
                        'PKR ${NumberFormat.compact().format(val)}',
                        style: const TextStyle(
                            color: AppTheme.textSecond, fontSize: 9),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= trend.length) {
                          return const SizedBox();
                        }
                        final month = trend[idx]['month'] as DateTime;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('MMM').format(month),
                            style: const TextStyle(
                                color: AppTheme.textSecond, fontSize: 11),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppTheme.divider,
                    strokeWidth: 1,
                  ),
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: false),
                barGroups: trend.asMap().entries.map((entry) {
                  final i = entry.key;
                  final m = entry.value;
                  return BarChartGroupData(
                    x: i,
                    groupVertically: false,
                    barRods: [
                      BarChartRodData(
                        toY: m['income'] as double,
                        color: AppTheme.incomeGreen,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                      BarChartRodData(
                        toY: m['expense'] as double,
                        color: AppTheme.expenseRed,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Monthly data table
          ...trend.map((m) {
            final month = m['month'] as DateTime;
            final income = m['income'] as double;
            final expense = m['expense'] as double;
            final net = income - expense;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      DateFormat('MMM yy').format(month),
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '+${NumberFormat('#,##0').format(income)}',
                      style: const TextStyle(
                          color: AppTheme.incomeGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '-${NumberFormat('#,##0').format(expense)}',
                      style: const TextStyle(
                          color: AppTheme.expenseRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      NumberFormat('#,##0').format(net),
                      style: TextStyle(
                          color: net >= 0
                              ? AppTheme.incomeGreen
                              : AppTheme.expenseRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration:
            BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style:
            const TextStyle(color: AppTheme.textSecond, fontSize: 12)),
      ],
    );
  }
}

Widget _emptyChart(String msg) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.bar_chart_outlined,
            size: 72,
            color: AppTheme.textSecond.withOpacity(0.4)),
        const SizedBox(height: 16),
        Text(msg,
            style: const TextStyle(color: AppTheme.textSecond, fontSize: 15)),
      ],
    ),
  );
}