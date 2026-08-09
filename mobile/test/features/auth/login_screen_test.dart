import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/api/auth_event_bus.dart';
import 'package:mobile/core/api/token_storage.dart';
import 'package:mobile/core/storage/offline_cache.dart';
import 'package:mobile/features/auth/data/auth_repository.dart';
import 'package:mobile/features/auth/presentation/providers/auth_controller.dart';
import 'package:mobile/features/auth/presentation/providers/auth_state.dart';
import 'package:mobile/features/auth/presentation/screens/login_screen.dart';

class _FakeAuthRepository extends Fake implements AuthRepository {}

class _FakeTokenStorage extends Fake implements TokenStorage {
  @override
  Future<bool> hasValidSession() async => false;

  @override
  Future<void> clear() async {}
}

/// Drives the login screen from a fixed [AuthState] without touching secure
/// storage or the network.
class _FakeAuthController extends AuthController {
  _FakeAuthController([AuthState? initial])
      : super(
          repository: _FakeAuthRepository(),
          tokenStorage: _FakeTokenStorage(),
          eventBus: AuthEventBus(),
          offlineCache: InMemoryOfflineCache(),
        ) {
    if (initial != null) state = initial;
  }
}

Widget _pumpLoginScreen({AuthState? state}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith((ref) => _FakeAuthController(state)),
    ],
    child: const MaterialApp(
      home: LoginScreen(),
    ),
  );
}

void main() {
  testWidgets('renders login screen fields and buttons', (tester) async {
    await tester.pumpWidget(_pumpLoginScreen());
    await tester.pumpAndSettle();

    expect(find.text('Xush kelibsiz'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Parol'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Kirish'), findsOneWidget);
  });

  testWidgets('shows validation errors when fields are empty', (tester) async {
    await tester.pumpWidget(_pumpLoginScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Kirish'));
    await tester.pumpAndSettle();

    expect(find.text('Emailni kiriting'), findsOneWidget);
    expect(find.text('Parolni kiriting'), findsOneWidget);
  });

  testWidgets('shows validation error for invalid email format', (tester) async {
    await tester.pumpWidget(_pumpLoginScreen());
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'invalid-email');
    await tester.enterText(find.widgetWithText(TextFormField, 'Parol'), 'secret123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Kirish'));
    await tester.pumpAndSettle();

    expect(find.text("Email formati noto'g'ri"), findsOneWidget);
  });
}
