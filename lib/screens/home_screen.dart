import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../utils/app_theme.dart';
import 'add_edit_transaction_screen.dart';
import 'monthly_summary_screen.dart';
import 'charts_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // context.watch rebuilds this widget whenever TransactionProvider changes
    final provider = context.watch<TransactionProvider>();
    final transactions = provider.monthlyTransactions;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, provider),
            _buildBalanceCard(provider),
            _buildMonthNavigator(context, provider),
            _buildQuickActions(context),
            Expanded(
              child: transactions.isEmpty
                  ? _buildEmptyState()
                  : _buildTransactionList(context, transactions, provider),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddScreen(context),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ─── APP BAR HEADER ────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, TransactionProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Expense Tracker',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                DateFormat('MMMM yyyy').format(provider.selectedMonth),
                style: const TextStyle(
                  color: AppTheme.textSecond,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Charts button
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChartsScreen()),
            ),
            icon: const Icon(Icons.bar_chart_rounded, color: AppTheme.textPrimary),
            tooltip: 'Charts',
          ),
          // Summary button
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MonthlySummaryScreen()),
            ),
            icon: const Icon(Icons.summarize_rounded, color: AppTheme.textPrimary),
            tooltip: 'Summary',
          ),
        ],
      ),
    );
  }

  // ─── BALANCE CARD ─────────────────────────────────────────────────────────
  Widget _buildBalanceCard(TransactionProvider provider) {
    final fmt = NumberFormat('#,##0.00');
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'PKR ${fmt.format(provider.balance)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Net Balance',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _balanceStat(
                  'Income',
                  provider.totalIncome,
                  Icons.arrow_downward_rounded,
                  AppTheme.incomeGreen,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(
                child: _balanceStat(
                  'Expense',
                  provider.totalExpense,
                  Icons.arrow_upward_rounded,
                  AppTheme.expenseRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceStat(String label, double amount, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'PKR ${NumberFormat('#,##0').format(amount)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ─── MONTH NAVIGATOR ──────────────────────────────────────────────────────
  Widget _buildMonthNavigator(
      BuildContext context, TransactionProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () => context.read<TransactionProvider>().previousMonth(),
            icon: const Icon(Icons.chevron_left_rounded,
                color: AppTheme.textSecond),
          ),
          Text(
            DateFormat('MMMM yyyy').format(provider.selectedMonth),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            onPressed: () => context.read<TransactionProvider>().nextMonth(),
            icon: const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSecond),
          ),
        ],
      ),
    );
  }

  // ─── QUICK ACTIONS ────────────────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: [
          _quickBtn(
            context,
            'Add Expense',
            Icons.remove_circle_outline,
            AppTheme.expenseRed,
                () => _openAddScreen(context, isExpense: true),
          ),
          const SizedBox(width: 12),
          _quickBtn(
            context,
            'Add Income',
            Icons.add_circle_outline,
            AppTheme.incomeGreen,
                () => _openAddScreen(context, isExpense: false),
          ),
        ],
      ),
    );
  }

  Widget _quickBtn(BuildContext context, String label, IconData icon,
      Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── TRANSACTION LIST ─────────────────────────────────────────────────────
  Widget _buildTransactionList(BuildContext context,
      List<TransactionModel> transactions, TransactionProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final t = transactions[index];
        return _buildTransactionCard(context, t, provider);
      },
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionModel t,
      TransactionProvider provider) {
    final cat = getCategoryByName(t.category, t.isExpense);
    final fmt = NumberFormat('#,##0.00');
    final dateStr = DateFormat('dd MMM').format(t.date);

    return Dismissible(
      key: ValueKey(t.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await _confirmDeleteDialog(context);
      },
      onDismissed: (_) {
        context.read<TransactionProvider>().deleteTransaction(t.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t.title} deleted'),
            backgroundColor: AppTheme.expenseRed,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.expenseRed,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        onTap: () => _openEditScreen(context, t),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Category icon circle
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: cat.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(cat.icon, color: cat.color, size: 22),
              ),
              const SizedBox(width: 12),
              // Title + category + note
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: cat.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            t.category,
                            style: TextStyle(
                                color: cat.color,
                                fontSize: 11,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(dateStr,
                            style: const TextStyle(
                                color: AppTheme.textSecond, fontSize: 11)),
                      ],
                    ),
                    if (t.note.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        t.note,
                        style: const TextStyle(
                            color: AppTheme.textSecond, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${t.isExpense ? '-' : '+'}PKR ${fmt.format(t.amount)}',
                    style: TextStyle(
                      color: t.isExpense
                          ? AppTheme.expenseRed
                          : AppTheme.incomeGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppTheme.textSecond, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── EMPTY STATE ──────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 72, color: AppTheme.textSecond.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text(
            'No transactions this month',
            style: TextStyle(color: AppTheme.textSecond, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap + Add to get started',
            style: TextStyle(color: AppTheme.textSecond, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────
  Future<bool?> _confirmDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Delete Transaction',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Are you sure you want to delete this transaction?',
            style: TextStyle(color: AppTheme.textSecond)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.expenseRed)),
          ),
        ],
      ),
    );
  }

  void _openAddScreen(BuildContext context, {bool? isExpense}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditTransactionScreen(initialIsExpense: isExpense),
      ),
    );
  }

  void _openEditScreen(BuildContext context, TransactionModel t) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditTransactionScreen(transaction: t),
      ),
    );
  }
}