// lib/screens/monthly_summary_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/category_model.dart';
import '../utils/app_theme.dart';

class MonthlySummaryScreen extends StatelessWidget {
  final DateTime selectedMonth;

  // StatelessWidget is appropriate here because this screen only READS data
  // All data comes from the Provider (TransactionProvider)
  const MonthlySummaryScreen({super.key, required this.selectedMonth});

  @override
  Widget build(BuildContext context) {
    // context.watch rebuilds the whole screen when provider changes
    final provider = context.watch<TransactionProvider>();
    final transactions = provider.getTransactionsForMonth(selectedMonth);

    final income = transactions
        .where((t) => !t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final expense = transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final balance = income - expense;

    final categoryBreakdown = provider.getExpenseByCategory(selectedMonth);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(DateFormat('MMMM yyyy').format(selectedMonth)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── SUMMARY SECTION ────────────────────────────────────────────
            _buildSummarySection(income, expense, balance),
            const SizedBox(height: 24),

            // ── CATEGORY BREAKDOWN ──────────────────────────────────────────
            if (categoryBreakdown.isNotEmpty) ...[
              const Text(
                'Spending by Category',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _buildCategoryBreakdown(categoryBreakdown, expense),
            ],

            const SizedBox(height: 24),

            // ── TRANSACTION COUNT ───────────────────────────────────────────
            _buildStatsCards(transactions.length, income, expense),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(double income, double expense, double balance) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: balance >= 0
              ? [AppTheme.accent.withOpacity(0.3), AppTheme.surface]
              : [AppTheme.danger.withOpacity(0.3), AppTheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: balance >= 0
              ? AppTheme.accent.withOpacity(0.3)
              : AppTheme.danger.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          // Month balance display
          Text(
            'Net Balance',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(balance),
            style: TextStyle(
              color: balance >= 0 ? AppTheme.accent : AppTheme.danger,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white12),
          const SizedBox(height: 16),

          // Income / Expense row
          Row(
            children: [
              Expanded(
                child: _summaryRow('Total Income', income, AppTheme.accent, Icons.trending_up),
              ),
              Container(width: 1, height: 50, color: Colors.white12),
              Expanded(
                child: _summaryRow('Total Expenses', expense, AppTheme.danger, Icons.trending_down),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double amount, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          _formatCurrency(amount),
          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(Map<String, double> breakdown, double totalExpense) {
    // Sort by amount descending
    // entries returns an Iterable of MapEntry objects
    final sortedEntries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedEntries.map((entry) {
        final category = AppCategories.getByName(entry.key);
        // Calculate percentage of total expense
        final percentage = totalExpense > 0 ? (entry.value / totalExpense) : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Category icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(category.icon, color: category.color, size: 18),
                  ),
                  const SizedBox(width: 12),

                  // Category name
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Amount and percentage
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatCurrency(entry.value),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${(percentage * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Progress bar showing relative spending
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage, // 0.0 to 1.0
                  backgroundColor: category.color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(category.color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsCards(int transactionCount, double income, double expense) {
    final savings = income > 0 ? ((income - expense) / income * 100) : 0.0;

    return Row(
      children: [
        Expanded(
          child: _statCard(
            'Transactions',
            '$transactionCount',
            Icons.receipt,
            AppTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            'Savings Rate',
            '${savings.clamp(0, 100).toStringAsFixed(1)}%',
            Icons.savings,
            savings >= 0 ? AppTheme.accent : AppTheme.danger,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800),
          ),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,##0', 'en_US').format(amount.abs());
  }
}