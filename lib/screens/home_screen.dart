// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../utils/app_theme.dart';
import 'add_edit_transaction_screen.dart';
import 'monthly_summary_screen.dart';

// StatefulWidget because we have local state: _selectedMonth
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedMonth = DateTime.now();

  // Navigate to previous month
  void _previousMonth() {
    setState(() {
      // DateTime constructor automatically handles month overflow
      // month 0 = December of previous year (Dart handles this)
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  // Navigate to next month (can't go beyond current month)
  void _nextMonth() {
    final now = DateTime.now();
    if (_selectedMonth.year == now.year && _selectedMonth.month == now.month) return;
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  // Navigate to Add screen
  Future<void> _goToAdd() async {
    // Navigator.push() pushes a new route (screen) onto the navigation stack
    // It returns a Future that completes when the pushed screen is popped
    await Navigator.push(
      context,
      // MaterialPageRoute defines how to animate to the new screen
      MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()),
    );
  }

  // Navigate to Edit screen with existing transaction data
  Future<void> _goToEdit(TransactionModel transaction) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        // Passing the transaction to the screen for pre-filling
        builder: (_) => AddEditTransactionScreen(transaction: transaction),
      ),
    );
  }

  // Show delete confirmation dialog
  Future<void> _confirmDelete(BuildContext context, TransactionModel t) async {
    // showDialog is async and returns the value passed to Navigator.pop()
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Delete Transaction', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Are you sure you want to delete "${t.title}"?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            // Navigator.pop(ctx, false) closes dialog and returns false
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), // returns true = confirmed
            child: const Text('Delete', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );

    // Only delete if user confirmed (true) and widget is still mounted
    if (confirmed == true && mounted) {
      context.read<TransactionProvider>().deleteTransaction(t.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('💰 Expense Tracker'),
        actions: [
          // Navigate to Monthly Summary screen
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Monthly Summary',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MonthlySummaryScreen(selectedMonth: _selectedMonth),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── SUMMARY CARDS ────────────────────────────────────────────────
          _buildSummaryCards(),

          // ── MONTH NAVIGATOR ──────────────────────────────────────────────
          _buildMonthNavigator(),

          // ── TRANSACTION LIST ─────────────────────────────────────────────
          Expanded(child: _buildTransactionList()),
        ],
      ),

      // FloatingActionButton - the round + button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToAdd,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildSummaryCards() {
    // Consumer<T> is a widget that rebuilds whenever TransactionProvider notifies
    // Alternative to context.watch<T>() - preferred when only part of the tree needs rebuilding
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        // 'child' is an optimization - it's a subtree that never changes
        // and doesn't need to be rebuilt. We're not using it here.
        final income = provider.getTransactionsForMonth(_selectedMonth)
            .where((t) => !t.isExpense)
            .fold(0.0, (sum, t) => sum + t.amount);
        final expense = provider.getTransactionsForMonth(_selectedMonth)
            .where((t) => t.isExpense)
            .fold(0.0, (sum, t) => sum + t.amount);

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              // Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Balance',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(income - expense),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Income and Expense row
              Row(
                children: [
                  // Expanded makes both cards take equal width
                  Expanded(child: _summaryTile('Income', income, AppTheme.accent, Icons.arrow_downward)),
                  const SizedBox(width: 12),
                  Expanded(child: _summaryTile('Expenses', expense, AppTheme.danger, Icons.arrow_upward)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryTile(String label, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              Text(
                _formatCurrency(amount),
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigator() {
    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == now.year &&
        _selectedMonth.month == now.month;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppTheme.textPrimary),
            onPressed: _previousMonth,
          ),
          Text(
            DateFormat('MMMM yyyy').format(_selectedMonth),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: isCurrentMonth ? AppTheme.textSecondary : AppTheme.textPrimary,
            ),
            onPressed: isCurrentMonth ? null : _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    // context.watch<T>() subscribes to changes - widget rebuilds when provider notifies
    // Use inside build() method
    final provider = context.watch<TransactionProvider>();
    final transactions = provider.getTransactionsForMonth(_selectedMonth);

    if (transactions.isEmpty) {
      // Empty state widget
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: AppTheme.textSecondary),
            SizedBox(height: 16),
            Text(
              'No transactions this month',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Tap + to add your first transaction',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // ListView.builder is LAZY - only builds widgets that are visible on screen
    // Much more efficient than ListView() with all children at once
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final t = transactions[index];
        return _buildTransactionItem(t);
      },
    );
  }

  Widget _buildTransactionItem(TransactionModel t) {
    final category = AppCategories.getByName(t.category);

    // Dismissible allows swipe-to-delete gesture
    return Dismissible(
      // key must be unique for each Dismissible widget
      // ValueKey wraps a value to use as a Widget Key
      key: ValueKey(t.id),

      // Only allow swipe from right (to show delete)
      direction: DismissDirection.endToStart,

      // confirmDismiss lets us show a confirmation before actually deleting
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.card,
            title: const Text('Delete?', style: TextStyle(color: AppTheme.textPrimary)),
            content: Text(
              'Delete "${t.title}"?',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete', style: TextStyle(color: AppTheme.danger)),
              ),
            ],
          ),
        );
      },

      // Called when swipe is confirmed
      onDismissed: (_) {
        context.read<TransactionProvider>().deleteTransaction(t.id);
        // Show undo snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t.title} deleted'),
            backgroundColor: AppTheme.surface,
            action: SnackBarAction(
              label: 'OK',
              textColor: AppTheme.primary,
              onPressed: () {},
            ),
          ),
        );
      },

      // Red background shown during swipe
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.danger.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white),
            Text('Delete', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),

      child: GestureDetector(
        onTap: () => _goToEdit(t), // Tap to edit
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Category icon circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(category.icon, color: category.color, size: 22),
              ),
              const SizedBox(width: 14),

              // Title, category, date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${t.category} • ${DateFormat('MMM d').format(t.date)}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    if (t.note.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        t.note,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ]
                  ],
                ),
              ),

              // Amount
              Text(
                '${t.isExpense ? '-' : '+'}${_formatCurrency(t.amount)}',
                style: TextStyle(
                  color: t.isExpense ? AppTheme.danger : AppTheme.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to format numbers as currency
  String _formatCurrency(double amount) {
    // NumberFormat from intl package
    return NumberFormat('#,##0', 'en_US').format(amount);
  }
}