import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/cards/data/card_repository.dart';
import 'package:mobile/features/cards/domain/card.dart';
import 'package:mobile/features/cards/presentation/screens/card_list_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockCardRepository extends Mock implements CardRepository {}

Widget _pumpCardListScreen(CardRepository repository) {
  return ProviderScope(
    overrides: [
      cardRepositoryProvider.overrideWithValue(repository),
    ],
    child: const MaterialApp(
      home: CardListScreen(),
    ),
  );
}

void main() {
  late MockCardRepository repository;

  setUp(() {
    repository = MockCardRepository();
  });

  testWidgets('renders empty view when cards list is empty', (tester) async {
    when(() => repository.list()).thenAnswer((_) async => []);

    await tester.pumpWidget(_pumpCardListScreen(repository));
    await tester.pumpAndSettle();

    expect(find.text('Kartalar'), findsOneWidget);
    expect(find.text("Hali karta qo'shilmagan"), findsOneWidget);
  });

  testWidgets('renders card items when repository returns cards', (tester) async {
    final cards = [
      const BankCard(id: 1, name: 'Uzcard', last4: '8888'),
      const BankCard(id: 2, name: 'Humo', last4: '9999'),
    ];
    when(() => repository.list()).thenAnswer((_) async => cards);

    await tester.pumpWidget(_pumpCardListScreen(repository));
    await tester.pumpAndSettle();

    expect(find.text('Uzcard'), findsOneWidget);
    expect(find.text('•••• 8888'), findsOneWidget);
    expect(find.text('Humo'), findsOneWidget);
    expect(find.text('•••• 9999'), findsOneWidget);
  });
}
