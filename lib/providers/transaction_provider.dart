import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../models/custom_category_model.dart';
import '../models/category_model.dart';

class TransactionProvider extends ChangeNotifier {
  // ─── Private fields ────────────────────────────────────────────────────────
  late Box<TransactionModel> _transactionBox;
  late Box<CustomCategoryModel> _customCategoryBox;

  List<TransactionModel> _transactions = [];
  List<CustomCategoryModel> _customCategories = [];

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  final Uuid _uuid = const Uuid();

  // ─── Getters ───────────────────────────────────────────────────────────────
  DateTime get selectedMonth => _selectedMonth;

  List<TransactionModel> get transactions =>
      List.unmodifiable(_transactions);

  List<CustomCategoryModel> get customCategories =>
      List.unmodifiable(_customCategories);

  // All transactions for selected month only
  List<TransactionModel> get monthlyTransactions {
    return _transactions.where((t) {
      return t.date.year == _selectedMonth.year &&
          t.date.month == _selectedMonth.month;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // newest first
  }

  // ─── Computed values ───────────────────────────────────────────────────────
  double get totalIncome {
    return monthlyTransactions
        .where((t) => !t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return monthlyTransactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get balance => totalIncome - totalExpense;

  // Category spending map (expense only) — for pie chart
  Map<String, double> get categorySpending {
    final map = <String, double>{};
    for (final t in monthlyTransactions.where((t) => t.isExpense)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  // Monthly trend — last 6 months income & expense
  List<Map<String, dynamic>> get monthlyTrend {
    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final monthTxns = _transactions.where((t) =>
      t.date.year == month.year && t.date.month == month.month);

      result.add({
        'month': month,
        'income': monthTxns
            .where((t) => !t.isExpense)
            .fold(0.0, (s, t) => s + t.amount),
        'expense': monthTxns
            .where((t) => t.isExpense)
            .fold(0.0, (s, t) => s + t.amount),
      });
    }
    return result;
  }

  // Combined predefined + custom categories for a type
  List<String> getCategoryNames(bool isExpense) {
    final predefined = getCategoriesForType(isExpense).map((c) => c.name);
    final custom = _customCategories
        .where((c) => c.isExpense == isExpense)
        .map((c) => c.name);
    return [...predefined, ...custom];
  }

  // ─── Init ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    _transactionBox = await Hive.openBox<TransactionModel>('transactions');
    _customCategoryBox =
    await Hive.openBox<CustomCategoryModel>('custom_categories');
    _loadData();
  }

  void _loadData() {
    _transactions = _transactionBox.values.toList();
    _customCategories = _customCategoryBox.values.toList();
    notifyListeners();
  }

  // ─── Month navigation ──────────────────────────────────────────────────────
  void previousMonth() {
    _selectedMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    notifyListeners();
  }

  void nextMonth() {
    final now = DateTime.now();
    final next =
    DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (!next.isAfter(DateTime(now.year, now.month))) {
      _selectedMonth = next;
      notifyListeners();
    }
  }

  // ─── CRUD: Transactions ────────────────────────────────────────────────────

  Future<void> addTransaction({
    required String title,
    required double amount,
    required String category,
    required DateTime date,
    required bool isExpense,
    String note = '',
  }) async {
    final t = TransactionModel(
      id: _uuid.v4(),
      title: title,
      amount: amount,
      category: category,
      date: date,
      isExpense: isExpense,
      note: note,
    );
    await _transactionBox.put(t.id, t);
    _transactions.add(t);
    notifyListeners();
  }

  Future<void> updateTransaction({
    required String id,
    required String title,
    required double amount,
    required String category,
    required DateTime date,
    required bool isExpense,
    String note = '',
  }) async {
    final existing = _transactionBox.get(id);
    if (existing == null) return;

    existing.title = title;
    existing.amount = amount;
    existing.category = category;
    existing.date = date;
    existing.isExpense = isExpense;
    existing.note = note;

    await existing.save(); // HiveObject's built-in save
    _loadData();
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionBox.delete(id);
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // ─── CRUD: Custom Categories ───────────────────────────────────────────────

  Future<void> addCustomCategory({
    required String name,
    required bool isExpense,
    required Color color,
    required IconData icon,
  }) async {
    // Check duplicate
    final exists = _customCategories.any(
          (c) => c.name.toLowerCase() == name.toLowerCase() &&
          c.isExpense == isExpense,
    );
    if (exists) return;

    final cat = CustomCategoryModel(
      id: _uuid.v4(),
      name: name,
      isExpense: isExpense,
      colorValue: color.value,
      iconCodePoint: icon.codePoint,
    );
    await _customCategoryBox.put(cat.id, cat);
    _customCategories.add(cat);
    notifyListeners();
  }

  Future<void> deleteCustomCategory(String id) async {
    await _customCategoryBox.delete(id);
    _customCategories.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}