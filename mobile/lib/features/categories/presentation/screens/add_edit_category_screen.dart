import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/categories/data/category_exception.dart';
import 'package:mobile/features/categories/data/category_repository.dart';
import 'package:mobile/features/categories/domain/category.dart';
import 'package:mobile/features/categories/presentation/providers/category_providers.dart';

class AddEditCategoryScreen extends ConsumerStatefulWidget {
  const AddEditCategoryScreen({super.key, this.existing});

  /// When non-null, the screen edits this category instead of creating one.
  final Category? existing;

  @override
  ConsumerState<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends ConsumerState<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.existing?.name ?? '');
  late CategoryType _type = widget.existing?.type ?? CategoryType.expense;
  bool _isSubmitting = false;

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final repository = ref.read(categoryRepositoryProvider);
      final name = _nameController.text.trim();
      if (_isEditing) {
        await repository.update(id: widget.existing!.id, name: name, type: _type);
      } else {
        await repository.create(name: name, type: _type);
      }
      ref.invalidate(allCategoriesProvider);
      if (mounted) Navigator.of(context).pop();
    } on CategoryException catch (error) {
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
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Kategoriyani tahrirlash' : 'Yangi kategoriya')),
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
                  onSelectionChanged: (selection) => setState(() => _type = selection.first),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Kategoriya nomi',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  validator: (value) {
                    if ((value?.trim() ?? '').isEmpty) return 'Nomini kiriting';
                    return null;
                  },
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
