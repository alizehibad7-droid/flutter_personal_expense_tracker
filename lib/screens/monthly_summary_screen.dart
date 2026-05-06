import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/category_model.dart';
import '../utils/app_theme.dart';

class MonthlySummaryScreen extends StatelessWidget {
  const MonthlySummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final fmt = NumberFormat('#,##0.00');
    final monthName =
    DateFormat('MMMM yyyy').format(provider.selectedMonth);
    final spending = provider.categorySpending;
    final totalExpense = provider.totalExpense;
    final savingsRate = provider.totalIncome > 0
        ? (provider.balance / provider.totalIncome * 100).clamp(0, 100)
        : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text('Summary — $monthName'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── BIG STATS ─────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    'Total Income',
                    'PKR ${fmt.format(provider.totalIncome)}',
                    Icons.arrow_downward_rounded,
                    AppTheme.incomeGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    'Total Expense',
                    'PKR ${fmt.format(provider.totalExpense)}',
                    Icons.arrow_upward_rounded,
                    AppTheme.expenseRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _statCard(
              'Remaining Balance',
              'PKR ${fmt.format(provider.balance)}',
              Icons.account_balance_wallet_outlined,
              provider.balance >= 0
                  ? AppTheme.incomeGreen
                  : AppTheme.expenseRed,
              isWide: true,
            ),
            const SizedBox(height: 12),

            // ── SAVINGS RATE ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Savings Rate',
                          style: TextStyle(
                              color: AppTheme.textSecond, fontSize: 13)),
                      Text('${savingsRate.toStringAsFixed(1)}%',
                          style: const TextStyle(
                              color: AppTheme.incomeGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: savingsRate / 100,
                      backgroundColor: AppTheme.divider,
                      color: AppTheme.incomeGreen,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── CATEGORY BREAKDOWN ────────────────────────────────────────
            if (spending.isNotEmpty) ...[
              const Text(
                'SPENDING BY CATEGORY',
                style: TextStyle(
                  color: AppTheme.textSecond,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              ...spending.entries.map((entry) {
                final cat = getCategoryByName(entry.key, true);
                final pct = totalExpense > 0
                    ? entry.value / totalExpense
                    : 0.0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: cat.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child:
                            Icon(cat.icon, color: cat.color, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14),
                            ),
                          ),
                          Text(
                            'PKR ${fmt.format(entry.value)}',
                            style: TextStyle(
                                color: cat.color,
                                fontWeight: FontWeight.w700,
                                fontSize: 14),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(pct * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                                color: AppTheme.textSecond, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: AppTheme.divider,
                          color: cat.color,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ] else ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.pie_chart_outline,
                          size: 60,
                          color: AppTheme.textSecond.withOpacity(0.4)),
                      const SizedBox(height: 12),
                      const Text('No expenses this month',
                          style: TextStyle(color: AppTheme.textSecond)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color,
      {bool isWide = false}) {
    return Container(
      width: isWide ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textSecond, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}