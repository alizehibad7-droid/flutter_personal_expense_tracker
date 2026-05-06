// lib/screens/add_edit_transaction_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../providers/transaction_provider.dart';
import '../utils/app_theme.dart';

// StatefulWidget because this screen has LOCAL state (form fields, selected date, etc.)
// The data changes within this screen before being saved
class AddEditTransactionScreen extends StatefulWidget {
  // Optional parameter - null means "Add mode", non-null means "Edit mode"
  // This is the "nullable type" pattern in Dart: TransactionModel?
  final TransactionModel? transaction;

  const AddEditTransactionScreen({super.key, this.transaction});

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

// The State class holds the mutable state for AddEditTransactionScreen
// It starts with _ to indicate it's private (only used by its widget)
class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  // GlobalKey<FormState> is used to validate and save the form
  // Think of it as a "handle" to control the Form widget from outside
  final _formKey = GlobalKey<FormState>();

  // TextEditingController connects a TextField to code
  // It lets you read the typed text, clear it, or set it programmatically
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  // Local state variables
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  bool _isExpense = true; // defaults to expense
  bool _isLoading = false;

  // initState() is called ONCE when the widget is first inserted into the tree
  // Perfect for one-time setup like pre-filling edit form data
  @override
  void initState() {
    super.initState(); // Always call super first

    // If a transaction was passed in, we're in EDIT mode
    // widget.transaction accesses the parent StatefulWidget's properties
    if (widget.transaction != null) {
      final t = widget.transaction!; // ! asserts non-null (safe here since we checked)
      _titleController.text = t.title;
      _amountController.text = t.amount.toString();
      _noteController.text = t.note;
      _selectedCategory = t.category;
      _selectedDate = t.date;
      _isExpense = t.isExpense;
    }
  }

  // dispose() is called when this widget is permanently removed from the tree
  // ALWAYS dispose controllers to prevent memory leaks!
  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose(); // Always call super last in dispose
  }

  // Show date picker and update state
  Future<void> _pickDate() async {
    // showDatePicker is a built-in Flutter dialog
    // It returns a Future<DateTime?> - might be null if user cancels
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        // Wrap with Theme to customize the picker appearance
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: AppTheme.primary),
          ),
          child: child!,
        );
      },
    );

    // Only update if user didn't cancel (null check)
    if (picked != null) {
      // setState() tells Flutter this widget's state changed -> rebuild UI
      setState(() => _selectedDate = picked);
    }
  }

  // Confirm and delete this transaction (Edit mode only)
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text(
          'Delete Transaction',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${_titleController.text}"? This cannot be undone.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), // Cancel
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), // Confirm
            child: const Text('Delete', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<TransactionProvider>().deleteTransaction(widget.transaction!.id);
      // Pop back to home screen after deletion
      if (mounted) Navigator.pop(context);
    }
  }

  // Save transaction (handles both Add and Edit)
  Future<void> _save() async {
    // _formKey.currentState!.validate() triggers validators on all form fields
    // Returns true only if ALL validators pass
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // context.read<T>() gets the Provider without listening to changes
    // (vs context.watch<T>() which rebuilds when data changes)
    // Use read() in callbacks/actions, watch() in build()
    final provider = context.read<TransactionProvider>();

    try {
      if (widget.transaction == null) {
        // ADD mode
        await provider.addTransaction(
          title: _titleController.text.trim(),
          amount: double.parse(_amountController.text),
          category: _selectedCategory,
          date: _selectedDate,
          isExpense: _isExpense,
          note: _noteController.text.trim(),
        );
      } else {
        // EDIT mode
        await provider.updateTransaction(
          id: widget.transaction!.id,
          title: _titleController.text.trim(),
          amount: double.parse(_amountController.text),
          category: _selectedCategory,
          date: _selectedDate,
          isExpense: _isExpense,
          note: _noteController.text.trim(),
        );
      }

      // Navigator.pop() closes the current screen and goes back
      // mounted check prevents using context after widget is disposed
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're in edit mode for UI customization
    final isEditMode = widget.transaction != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Transaction' : 'Add Transaction'),
      ),
      body: SingleChildScrollView(
        // SingleChildScrollView allows the content to scroll if it overflows
        padding: const EdgeInsets.all(20),
        child: Form(
          // Form widget groups multiple TextFormFields
          // Assigning _formKey links this Form to our GlobalKey
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── TYPE TOGGLE (Income / Expense) ──────────────────────────
              _buildTypeToggle(),
              const SizedBox(height: 20),

              // ── TITLE FIELD ──────────────────────────────────────────────
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Grocery Shopping',
                  prefixIcon: Icon(Icons.title),
                ),
                // validator is called when form.validate() is triggered
                // Return null = valid, return String = error message
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null; // null means valid
                },
              ),
              const SizedBox(height: 16),

              // ── AMOUNT FIELD ─────────────────────────────────────────────
              TextFormField(
                controller: _amountController,
                style: const TextStyle(color: AppTheme.textPrimary),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (PKR)',
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  // double.tryParse returns null if parsing fails
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── CATEGORY SELECTOR ────────────────────────────────────────
              _buildCategorySelector(),
              const SizedBox(height: 16),

              // ── DATE PICKER ──────────────────────────────────────────────
              _buildDatePicker(),
              const SizedBox(height: 16),

              // ── NOTE FIELD ───────────────────────────────────────────────
              TextFormField(
                controller: _noteController,
                style: const TextStyle(color: AppTheme.textPrimary),
                maxLines: 3, // Multi-line input
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  hintText: 'Add a note...',
                  prefixIcon: Icon(Icons.note),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 28),

              // ── SAVE BUTTON ──────────────────────────────────────────────
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                // Ternary operator: condition ? valueIfTrue : valueIfFalse
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Text(isEditMode ? 'Update Transaction' : 'Add Transaction'),
              ),

              // ── DELETE BUTTON (only shown in Edit mode) ───────────────────
              // if (condition) widget  — renders widget only when condition is true
              if (isEditMode) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _confirmDelete,
                  icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                  label: const Text(
                    'Delete Transaction',
                    style: TextStyle(color: AppTheme.danger),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppTheme.danger),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── HELPER WIDGETS (extracted for cleaner build method) ────────────────────

  Widget _buildTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          // Expense toggle button
          Expanded(child: _typeButton('Expense', true, Icons.arrow_upward, AppTheme.danger)),
          // Income toggle button
          Expanded(child: _typeButton('Income', false, Icons.arrow_downward, AppTheme.accent)),
        ],
      ),
    );
  }

  Widget _typeButton(String label, bool isExpenseType, IconData icon, Color color) {
    final isSelected = _isExpense == isExpenseType;
    return GestureDetector(
      onTap: () => setState(() => _isExpense = isExpenseType),
      child: AnimatedContainer(
        // AnimatedContainer smoothly animates between property changes
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: color, width: 1.5) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : AppTheme.textSecondary, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 10),
        // Wrap lays out children and wraps to next line when out of space
        Wrap(
          spacing: 8, // horizontal gap between chips
          runSpacing: 8, // vertical gap between rows
          children: AppCategories.predefined.map((category) {
            // .map() transforms each item in a list
            // Here we transform CategoryModel -> Widget
            final isSelected = _selectedCategory == category.name;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = category.name),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? category.color.withOpacity(0.25)
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? category.color : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min, // Don't take full width
                  children: [
                    Icon(category.icon,
                        size: 16,
                        color: isSelected ? category.color : AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      category.name,
                      style: TextStyle(
                        color: isSelected ? category.color : AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(), // Convert Iterable<Widget> to List<Widget>
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppTheme.textSecondary, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Date', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  // DateFormat from intl package formats DateTime to readable string
                  DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                  style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const Spacer(), // Takes all remaining space - pushes next widget to end
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}