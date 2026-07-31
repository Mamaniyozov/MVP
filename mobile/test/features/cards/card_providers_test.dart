import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/cards/data/card_repository.dart';
import 'package:mobile/features/cards/domain/card.dart';
import 'package:mobile/features/cards/presentation/providers/card_providers.dart';
import 'package:mocktail/mocktail.dart';

class MockCardRepository extends Mock implements CardRepository {}

void main() {
  test('cardsProvider exposes the repository list result', () async {
    final repository = MockCardRepository();
    final card = const BankCard(id: 1, name: 'Humo', last4: '1234');
    when(() => repository.list()).thenAnswer((_) async => [card]);

    final container = ProviderContainer(
      overrides: [cardRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final result = await container.read(cardsProvider.future);

    expect(result, [card]);
  });

  test('invalidating cardsProvider triggers a fresh repository call', () async {
    final repository = MockCardRepository();
    var callCount = 0;
    when(() => repository.list()).thenAnswer((_) async {
      callCount++;
      return <BankCard>[];
    });

    final container = ProviderContainer(
      overrides: [cardRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(cardsProvider.future);
    container.invalidate(cardsProvider);
    await container.read(cardsProvider.future);

    expect(callCount, 2);
  });
}
