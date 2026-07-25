import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/cards/data/card_repository.dart';
import 'package:mobile/features/cards/domain/card.dart';

final cardsProvider = FutureProvider<List<BankCard>>((ref) async {
  final repository = ref.watch(cardRepositoryProvider);
  return repository.list();
});
