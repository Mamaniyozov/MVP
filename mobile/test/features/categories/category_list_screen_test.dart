import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/categories/data/category_repository.dart';
import 'package:mobile/features/categories/domain/category.dart';
import 'package:mobile/features/categories/presentation/screens/category_list_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

Widget _pumpCategoryListScreen(CategoryRepository repository) {
  return ProviderScope(
    overrides: [
      categoryRepositoryProvider.overrideWithValue(repository),
    ],
    child: const MaterialApp(
      home: CategoryListScreen(),
    ),
  );
}

void main() {
  late MockCategoryRepository repository;

  setUp(() {
    repository = MockCategoryRepository();
  });

  testWidgets('renders categories list split by expense and income', (tester) async {
    final categories = [
      const Category(id: 1, name: 'Oziq-ovqat', type: CategoryType.expense, icon: '', isDefault: true),
      const Category(id: 2, name: 'Maosh', type: CategoryType.income, icon: '', isDefault: false),
    ];
    when(() => repository.list()).thenAnswer((_) async => categories);

    await tester.pumpWidget(_pumpCategoryListScreen(repository));
    await tester.pumpAndSettle();

    expect(find.text('Kategoriyalar'), findsOneWidget);
    expect(find.text('Xarajat kategoriyalari'), findsOneWidget);
    expect(find.text('Daromad kategoriyalari'), findsOneWidget);
    expect(find.text('Oziq-ovqat'), findsOneWidget);
    expect(find.text('Maosh'), findsOneWidget);
    expect(find.text('Standart kategoriya'), findsOneWidget);
  });
}
