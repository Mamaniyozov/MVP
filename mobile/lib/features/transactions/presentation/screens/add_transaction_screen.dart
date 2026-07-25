import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/cards/presentation/providers/card_providers.dart';
import 'package:mobile/features/categories/domain/category.dart';
import 'package:mobile/features/categories/presentation/providers/category_providers.dart';
import 'package:mobile/features/transactions/data/transaction_exception.dart';
import 'package:mobile/features/transactions/data/transaction_repository.dart';
import 'package:mobile/features/transactions/presentation/providers/transaction_list_controller.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  CategoryType _type = CategoryType.expense;
  DateTime _date = DateTime.now();
  int? _categoryId;
  int? _cardId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onTypeChanged(CategoryType type) {
    if (type == _type) return;
    setState(() {
      _type = type;
      // The previously selected category may not belong to the new type.
      _categoryId = null;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Kategoriyani tanlang')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));
      await ref.read(transactionRepositoryProvider).create(
            categoryId: _categoryId!,
            cardId: _cardId,
            amount: amount,
            type: _type,
            date: _date,
            note: _noteController.text.trim(),
          );
      await ref.read(transactionListControllerProvider.notifier).refresh();
      if (mounted) Navigator.of(context).pop();
    } on TransactionException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesByTypeProvider(_type));
    final cardsAsync = ref.watch(cardsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Yangi tranzaksiya')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<CategoryType>(
                  segments: const [
                    ButtonSegment(
                      value: CategoryType.expense,
                      label: Text('Xarajat'),
                      icon: Icon(Icons.arrow_upward),
                    ),
                    ButtonSegment(
                      value: CategoryType.income,
                      label: Text('Daromad'),
                      icon: Icon(Icons.arrow_downward),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (selection) => _onTypeChanged(selection.first),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Summa',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Summani kiriting';
                    final amount = double.tryParse(text.replaceAll(',', '.'));
                    if (amount == null || amount <= 0) {
                      return "Summa musbat son bo'lishi kerak";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                categoriesAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => Text(
                    "Kategoriyalarni yuklab bo'lmadi",
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                  data: (categories) {
                    if (_categoryId != null &&
                        categories.every((category) => category.id != _categoryId)) {
                      WidgetsBinding.instance
                          .addPostFrameCallback((_) => setState(() => _categoryId = null));
                    }
                    return DropdownButtonFormField<int>(
                      initialValue: _categoryId,
                      decoration: const InputDecoration(
                        labelText: 'Kategoriya',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: categories
                          .map((category) => DropdownMenuItem(
                                value: category.id,
                                child: Text(category.name),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _categoryId = value),
                    );
                  },
                ),
                const SizedBox(height: 16),
                cardsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (error, _) => const SizedBox.shrink(),
                  data: (cards) {
                    if (cards.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DropdownButtonFormField<int?>(
                        initialValue: _cardId,
                        decoration: const InputDecoration(
                          labelText: 'Karta (ixtiyoriy)',
                          prefixIcon: Icon(Icons.credit_card_outlined),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Kartasiz')),
                          ...cards.map((card) => DropdownMenuItem(
                                value: card.id,
                                child: Text(card.displayName),
                              )),
                        ],
                        onChanged: (value) => setState(() => _cardId = value),
                      ),
                    );
                  },
                ),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Sana',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(DateFormat('dd.MM.yyyy').format(_date)),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Izoh (ixtiyoriy)',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('Saqlash'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
