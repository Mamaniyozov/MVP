import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/cards/data/card_exception.dart';
import 'package:mobile/features/cards/data/card_repository.dart';
import 'package:mobile/features/cards/domain/card.dart';
import 'package:mobile/features/cards/presentation/providers/card_providers.dart';

class AddEditCardScreen extends ConsumerStatefulWidget {
  const AddEditCardScreen({super.key, this.existing});

  /// When non-null, the screen edits this card instead of creating one.
  final BankCard? existing;

  @override
  ConsumerState<AddEditCardScreen> createState() => _AddEditCardScreenState();
}

class _AddEditCardScreenState extends ConsumerState<AddEditCardScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.existing?.name ?? '');
  late final _last4Controller = TextEditingController(text: widget.existing?.last4 ?? '');
  bool _isSubmitting = false;

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _nameController.dispose();
    _last4Controller.dispose();
    super.dispose();
  }

  /// Validates the optional "last 4 digits" field.
  ///
  /// The backend stores this as `CharField(max_length=4, blank=True)`, so an
  /// empty value is always valid. A partially-entered value is not: it looks
  /// like card data but identifies nothing, so it must be all four digits.
  String? _validateLast4(String? value) {
    final last4 = value?.trim() ?? '';
    if (last4.isEmpty) return null;
    if (last4.length != 4) {
      return "To'liq 4 raqam kiriting";
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final repository = ref.read(cardRepositoryProvider);
      final name = _nameController.text.trim();
      final last4 = _last4Controller.text.trim();
      if (_isEditing) {
        await repository.update(id: widget.existing!.id, name: name, last4: last4);
      } else {
        await repository.create(name: name, last4: last4);
      }
      ref.invalidate(cardsProvider);
      if (mounted) Navigator.of(context).pop();
    } on CardException catch (error) {
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
      appBar: AppBar(title: Text(_isEditing ? 'Kartani tahrirlash' : 'Yangi karta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Karta nomi',
                    hintText: 'Masalan: Humo ish kartasi',
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                  validator: (value) {
                    if ((value?.trim() ?? '').isEmpty) return 'Nomini kiriting';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _last4Controller,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Oxirgi 4 raqam (ixtiyoriy)',
                    hintText: '1234',
                    prefixIcon: Icon(Icons.tag),
                  ),
                  validator: _validateLast4,
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
