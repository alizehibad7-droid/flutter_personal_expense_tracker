import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../providers/transaction_provider.dart';
import '../utils/app_theme.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction; // null = add mode, non-null = edit mode
  final bool? initialIsExpense; // pre-set type (from quick buttons)

  const AddEditTransactionScreen({
    super.key,
    this.transaction,
    this.initialIsExpense,
  });

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  // Form key — used to validate all fields at once
  final _formKey = GlobalKey<FormState>();

  // Controllers — manage the text inside each TextFormField
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  // State variables
  late bool _isExpense;
  late String _selectedCategory;
  late DateTime _selectedDate;

  bool get isEditMode => widget.transaction != null;

  @override
  void initState() {
    super.initState(); // Always call super first

    // If editing, pre-fill fields with existing data
    // If adding, use defaults
    final t = widget.transaction;
    _isExpense = t?.isExpense ?? widget.initialIsExpense ?? true;
    _titleController = TextEditingController(text: t?.title ?? '');
    _amountController =
        TextEditingController(text: t != null ? t.amount.toString() : '');
    _noteController = TextEditingController(text: t?.note ?? '');
    _selectedDate = t?.date ?? DateTime.now();

    // Set default category based on type
    final cats = getCategoriesForType(_isExpense);
    _selectedCategory = t?.category ?? cats.first.name;
  }

  @override
  void dispose() {
    // Always dispose controllers to free memory
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose(); // Always call super last
  }

  // ─── When type toggle changes ──────────────────────────────────────────────
  void _onTypeChanged(bool isExpense) {
    setState(() {
      _isExpense = isExpense;
      // Reset category to match new type
      _selectedCategory = getCategoriesForType(isExpense).first.name;
    });
  }

  // ─── Theme colors based on type ───────────────────────────────────────────
  Color get _accentColor =>
      _isExpense ? AppTheme.expenseRed : AppTheme.incomeGreen;

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final categoryNames = provider.getCategoryNames(_isExpense);

    // Ensure selected category exists in list, else reset
    if (!categoryNames.contains(_selectedCategory)) {
      _selectedCategory = categoryNames.first;
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Transaction' : 'Add Transaction'),
        backgroundColor: AppTheme.bgDark,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.expenseRed),
              tooltip: 'Delete',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── TYPE TOGGLE ──────────────────────────────────────────────
              _buildTypeToggle(),
              const SizedBox(height: 24),

              // ── AMOUNT ───────────────────────────────────────────────────
              _buildSectionLabel('Amount'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                  color: _accentColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: 'PKR  ',
                  prefixStyle:
                  const TextStyle(color: AppTheme.textSecond, fontSize: 16),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _accentColor, width: 2),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter amount';
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                  return null; // null = valid
                },
              ),
              const SizedBox(height: 20),

              // ── TITLE ────────────────────────────────────────────────────
              _buildSectionLabel('Title'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'e.g. Lunch at restaurant',
                  prefixIcon: Icon(Icons.title, color: AppTheme.textSecond),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter a title';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── CATEGORY ─────────────────────────────────────────────────
              _buildSectionLabel('Category'),
              const SizedBox(height: 8),
              _buildCategoryGrid(categoryNames),
              const SizedBox(height: 8),
              _buildAddCustomCategoryButton(context),
              const SizedBox(height: 20),

              // ── DATE ─────────────────────────────────────────────────────
              _buildSectionLabel('Date'),
              const SizedBox(height: 8),
              _buildDatePicker(context),
              const SizedBox(height: 20),

              // ── NOTE ─────────────────────────────────────────────────────
              _buildSectionLabel('Note (Optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                style: const TextStyle(color: AppTheme.textPrimary),
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Add a note...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: Icon(Icons.note_alt_outlined,
                        color: AppTheme.textSecond),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── SAVE BUTTON ───────────────────────────────────────────────
              ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  isEditMode ? 'Update Transaction' : 'Save Transaction',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              if (isEditMode) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _confirmDelete,
                    icon: const Icon(Icons.delete_outline,
                        color: AppTheme.expenseRed),
                    label: const Text('Delete Transaction',
                        style: TextStyle(color: AppTheme.expenseRed)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(color: AppTheme.expenseRed),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ─── TYPE TOGGLE (Expense / Income) ──────────────────────────────────────
  Widget _buildTypeToggle() {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _typeButton('Expense', true),
          _typeButton('Income', false),
        ],
      ),
    );
  }

  Widget _typeButton(String label, bool isExpense) {
    final isSelected = _isExpense == isExpense;
    final color = isExpense ? AppTheme.expenseRed : AppTheme.incomeGreen;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTypeChanged(isExpense),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                color: isSelected ? Colors.white : AppTheme.textSecond,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecond,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── CATEGORY GRID ────────────────────────────────────────────────────────
  Widget _buildCategoryGrid(List<String> categoryNames) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categoryNames.map((name) {
        final cat = getCategoryByName(name, _isExpense);
        final isSelected = _selectedCategory == name;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? cat.color.withOpacity(0.2)
                  : AppTheme.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? cat.color : AppTheme.divider,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(cat.icon,
                    color: isSelected ? cat.color : AppTheme.textSecond,
                    size: 16),
                const SizedBox(width: 6),
                Text(
                  name,
                  style: TextStyle(
                    color: isSelected ? cat.color : AppTheme.textSecond,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── ADD CUSTOM CATEGORY ──────────────────────────────────────────────────
  Widget _buildAddCustomCategoryButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _showAddCategoryDialog(context),
      icon: const Icon(Icons.add, size: 16),
      label: const Text('Add Custom Category'),
      style: TextButton.styleFrom(foregroundColor: _accentColor),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: Text(
          'New ${_isExpense ? 'Expense' : 'Income'} Category',
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 17),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Category name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                await context.read<TransactionProvider>().addCustomCategory(
                  name: name,
                  isExpense: _isExpense,
                  color: _accentColor,
                  icon: Icons.label_outline,
                );
                setState(() => _selectedCategory = name);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _accentColor),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ─── DATE PICKER ──────────────────────────────────────────────────────────
  Widget _buildDatePicker(BuildContext context) {
    return GestureDetector(
      onTap: () => _pickDate(context),
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                color: _accentColor, size: 20),
            const SizedBox(width: 12),
            Text(
              DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 14),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSecond),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: _accentColor,
            surface: AppTheme.card,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // ─── SECTION LABEL ────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.textSecond,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  // ─── SAVE ─────────────────────────────────────────────────────────────────
  Future<void> _saveTransaction() async {
    // Validate all fields — if any validator returns non-null, stop
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<TransactionProvider>();

    if (isEditMode) {
      await provider.updateTransaction(
        id: widget.transaction!.id,
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        category: _selectedCategory,
        date: _selectedDate,
        isExpense: _isExpense,
        note: _noteController.text.trim(),
      );
    } else {
      await provider.addTransaction(
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        category: _selectedCategory,
        date: _selectedDate,
        isExpense: _isExpense,
        note: _noteController.text.trim(),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  // ─── DELETE ───────────────────────────────────────────────────────────────
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Delete Transaction',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'This will permanently delete this transaction.',
          style: TextStyle(color: AppTheme.textSecond),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
            ElevatedButton.styleFrom(backgroundColor: AppTheme.expenseRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context
          .read<TransactionProvider>()
          .deleteTransaction(widget.transaction!.id);
      if (mounted) Navigator.pop(context);
    }
  }
}