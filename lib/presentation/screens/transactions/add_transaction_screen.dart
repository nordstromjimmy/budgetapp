import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/category.dart';
import '../../../data/models/transaction.dart';
import '../../providers/transaction_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({
    super.key,
    required this.isExpense,
    this.transactionId,
  });

  /// Pre-selects the transaction type. Ignored when editing (type comes from the transaction).
  final bool isExpense;

  /// When provided, the screen enters edit mode and loads this transaction.
  final String? transactionId;

  bool get isEditing => transactionId != null;

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountFocusNode = FocusNode();

  late bool _isExpense;
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  bool _isLoading = false;

  Transaction? _existingTransaction;

  static final _dateFormat = DateFormat('d MMMM yyyy', 'sv_SE');

  // ── Lifecycle ─────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _isExpense = widget.isExpense;

    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadTransaction());
    } else {
      // Auto-focus the amount field on add
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _amountFocusNode.requestFocus(),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _loadTransaction() {
    final transactions = ref.read(transactionNotifierProvider);
    final transaction = transactions.firstWhere(
      (t) => t.id == widget.transactionId,
      orElse: () => throw StateError('Transaction not found'),
    );
    final categories = ref.read(categoryNotifierProvider);
    final category = categories.firstWhere(
      (c) => c.id == transaction.categoryId,
      orElse: () => categories.first,
    );

    setState(() {
      _existingTransaction = transaction;
      _isExpense = transaction.isExpense;
      _selectedDate = transaction.date;
      _selectedCategory = category;
      _amountController.text =
          transaction.amount.toStringAsFixed(2).replaceAll('.', ',');
      _descriptionController.text = transaction.description;
    });
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? AppStrings.editTransactionTitle
              : AppStrings.addTransactionTitle,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppColors.expense,
              tooltip: AppStrings.buttonDelete,
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // ── Type toggle ──────────────────────────────────
            _TypeToggle(
              isExpense: _isExpense,
              onChanged: (value) => setState(() {
                _isExpense = value;
                _selectedCategory =
                    null; // reset — categories are type-specific
              }),
            ),
            const Gap(24),

            // ── Amount ───────────────────────────────────────
            _buildAmountField(theme),
            const Gap(16),

            // ── Description ──────────────────────────────────
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: AppStrings.fieldDescription,
                hintText: AppStrings.fieldDescriptionHint,
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLength: 80,
              buildCounter: (_,
                      {required currentLength,
                      required isFocused,
                      maxLength}) =>
                  null, // hide the counter
            ),
            const Gap(16),

            // ── Category ─────────────────────────────────────
            _buildCategorySelector(theme),
            const Gap(16),

            // ── Date ─────────────────────────────────────────
            _buildDateSelector(theme),
            const Gap(32),

            // ── Save button ───────────────────────────────────
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(AppStrings.buttonSave),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Amount field ──────────────────────────────────────────────

  Widget _buildAmountField(ThemeData theme) {
    return TextFormField(
      controller: _amountController,
      focusNode: _amountFocusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
      ],
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      decoration: InputDecoration(
        labelText: AppStrings.fieldAmount,
        hintText: AppStrings.fieldAmountHint,
        prefixIcon: const Icon(Icons.payments_outlined),
        suffixText: 'kr',
        suffixStyle: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.5),
          fontWeight: FontWeight.w600,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return AppStrings.validationRequired;
        }
        if (CurrencyFormatter.tryParse(value) == null) {
          return AppStrings.validationInvalidAmount;
        }
        if ((CurrencyFormatter.tryParse(value) ?? 0) <= 0) {
          return AppStrings.validationInvalidAmount;
        }
        return null;
      },
    );
  }

  // ── Category selector ─────────────────────────────────────────

  Widget _buildCategorySelector(ThemeData theme) {
    return FormField<Category>(
      initialValue: _selectedCategory,
      validator: (_) => _selectedCategory == null
          ? AppStrings.validationSelectCategory
          : null,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _openCategorySheet,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: theme.inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(12),
                  border: field.hasError
                      ? Border.all(color: AppColors.error, width: 1.5)
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.grid_view_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const Gap(12),
                    if (_selectedCategory != null) ...[
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _selectedCategory!.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          _selectedCategory!.icon,
                          size: 16,
                          color: _selectedCategory!.color,
                        ),
                      ),
                      const Gap(10),
                      Text(
                        _selectedCategory!.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else
                      Text(
                        AppStrings.fieldCategory,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: theme.colorScheme.onSurface.withOpacity(0.35),
                    ),
                  ],
                ),
              ),
            ),
            if (field.hasError) ...[
              const Gap(6),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  field.errorText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // ── Date selector ─────────────────────────────────────────────

  Widget _buildDateSelector(ThemeData theme) {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            const Gap(12),
            Text(
              AppStrings.fieldDate,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const Spacer(),
            Text(
              _dateFormat.format(_selectedDate),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(4),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.onSurface.withOpacity(0.35),
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────

  Future<void> _openCategorySheet() async {
    final categories = ref.read(categoryNotifierProvider);
    final filtered = _isExpense
        ? categories.where((c) => c.isExpense).toList()
        : categories.where((c) => !c.isExpense).toList();

    final selected = await showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CategoryPickerSheet(
        categories: filtered,
        selected: _selectedCategory,
      ),
    );

    if (selected != null) {
      setState(() => _selectedCategory = selected);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('sv', 'SE'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    // Validate form — shows inline error messages
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) return;

    final amount = CurrencyFormatter.tryParse(_amountController.text)!;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(transactionNotifierProvider.notifier);

      if (widget.isEditing && _existingTransaction != null) {
        await notifier.updateTransaction(
          _existingTransaction!.copyWith(
            amount: amount,
            description: _descriptionController.text.trim(),
            categoryId: _selectedCategory!.id,
            date: _selectedDate,
            isExpense: _isExpense,
          ),
        );
        if (mounted) {
          _showSnack(AppStrings.snackTransactionUpdated);
          Navigator.of(context).pop();
        }
      } else {
        await notifier.addTransaction(
          amount: amount,
          description: _descriptionController.text.trim(),
          categoryId: _selectedCategory!.id,
          date: _selectedDate,
          isExpense: _isExpense,
        );
        if (mounted) {
          _showSnack(AppStrings.snackTransactionAdded);
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) _showSnack(AppStrings.snackError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.transactionDeleteConfirm),
        content: const Text(AppStrings.transactionDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.buttonCancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.buttonDelete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(transactionNotifierProvider.notifier)
          .deleteTransaction(widget.transactionId!);
      if (mounted) {
        _showSnack(AppStrings.snackTransactionDeleted);
        Navigator.of(context).pop();
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TYPE TOGGLE
// ─────────────────────────────────────────────────────────────────────────────

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.isExpense, required this.onChanged});

  final bool isExpense;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _ToggleOption(
            label: AppStrings.transactionExpense,
            icon: Icons.arrow_upward_rounded,
            color: AppColors.expense,
            selected: isExpense,
            onTap: () => onChanged(true),
          ),
          _ToggleOption(
            label: AppStrings.transactionIncome,
            icon: Icons.arrow_downward_rounded,
            color: AppColors.income,
            selected: !isExpense,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? color
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              const Gap(6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? color
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY PICKER SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryPickerSheet extends StatelessWidget {
  const _CategoryPickerSheet({
    required this.categories,
    required this.selected,
  });

  final List<Category> categories;
  final Category? selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          // ── Handle ──────────────────────────────────────────
          const Gap(8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              AppStrings.fieldCategory,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const Gap(12),

          // ── Grid ────────────────────────────────────────────
          Expanded(
            child: GridView.builder(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.05,
              ),
              itemCount: categories.length,
              itemBuilder: (_, i) {
                final cat = categories[i];
                final isSelected = selected?.id == cat.id;

                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cat.color.withOpacity(0.15)
                          : theme.colorScheme.onSurface.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: isSelected
                          ? Border.all(color: cat.color, width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cat.color.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(cat.icon, color: cat.color, size: 22),
                        ),
                        const Gap(6),
                        Text(
                          cat.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? cat.color
                                : theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
