// lib/providers/transaction_provider.dart

import 'package:flutter/foundation.dart'; // provides ChangeNotifier
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';

// ChangeNotifier is the core of Provider pattern
// It lets this class "notify" all listening widgets when data changes
// Think of it like a walkie-talkie: this class broadcasts, widgets listen
class TransactionProvider extends ChangeNotifier {
  // Hive Box - like a table in a database, or a named storage bucket
  // Box<TransactionModel> means it stores TransactionModel objects
  late Box<TransactionModel> _transactionBox;

  // Uuid generates unique IDs like: "550e8400-e29b-41d4-a716-446655440000"
  final _uuid = const Uuid();

  // Private list - only accessible within this class
  // The underscore prefix is Dart's convention for private members
  List<TransactionModel> _transactions = [];

  // Getter - read-only access to the private list from outside
  // Returns an UNMODIFIABLE view so external code can't accidentally modify it
  List<TransactionModel> get transactions =>
      List.unmodifiable(_transactions);

  // Computed property - calculated on the fly from _transactions
  // 'get' makes this a getter (accessed like a field, not called like a method)
  double get totalIncome {
    return _transactions
        .where((t) => !t.isExpense) // filter only income
        .fold(0.0, (sum, t) => sum + t.amount); // sum amounts
  }

  double get totalExpense {
    return _transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get balance => totalIncome - totalExpense;

  // Filter transactions for a specific month
  List<TransactionModel> getTransactionsForMonth(DateTime month) {
    return _transactions.where((t) {
      return t.date.year == month.year && t.date.month == month.month;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // sort newest first
  }

  // Group by category for pie chart
  Map<String, double> getExpenseByCategory(DateTime month) {
    final monthTransactions = getTransactionsForMonth(month)
        .where((t) => t.isExpense)
        .toList();

    // Map<String, double> - key is category name, value is total amount
    final Map<String, double> categoryMap = {};

    for (var t in monthTransactions) {
      // If key exists, add to it. If not, initialize to 0 then add.
      categoryMap[t.category] = (categoryMap[t.category] ?? 0) + t.amount;
    }

    return categoryMap;
  }

  // Initialize Hive and load data
  // 'async' because Hive operations are asynchronous (return Future)
  Future<void> init() async {
    // Open the Hive box - creates it if doesn't exist
    _transactionBox = await Hive.openBox<TransactionModel>('transactions');
    _loadTransactions();
  }

  // Load from Hive into our in-memory list
  void _loadTransactions() {
    // .values returns all stored objects
    // .toList() converts the Iterable to a List
    _transactions = _transactionBox.values.toList();
    // Sort by date (newest first) when loading
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    // notifyListeners() tells all Provider consumers to rebuild their UI
    notifyListeners();
  }

  // ADD a new transaction
  Future<void> addTransaction({
    required String title,
    required double amount,
    required String category,
    required DateTime date,
    required bool isExpense,
    String note = '',
  }) async {
    final transaction = TransactionModel(
      id: _uuid.v4(), // Generate unique UUID
      title: title,
      amount: amount,
      category: category,
      date: date,
      isExpense: isExpense,
      note: note,
    );

    // Save to Hive using the ID as the key
    await _transactionBox.put(transaction.id, transaction);
    _loadTransactions(); // Reload and notify
  }

  // EDIT/UPDATE an existing transaction
  Future<void> updateTransaction({
    required String id,
    required String title,
    required double amount,
    required String category,
    required DateTime date,
    required bool isExpense,
    String note = '',
  }) async {
    // Find the existing object in Hive box
    final existing = _transactionBox.get(id);
    if (existing == null) return;

    // Update fields directly on the HiveObject
    existing.title = title;
    existing.amount = amount;
    existing.category = category;
    existing.date = date;
    existing.isExpense = isExpense;
    existing.note = note;

    // .save() persists changes back to Hive
    await existing.save();
    _loadTransactions();
  }

  // DELETE a transaction
  Future<void> deleteTransaction(String id) async {
    await _transactionBox.delete(id);
    _loadTransactions();
  }
}