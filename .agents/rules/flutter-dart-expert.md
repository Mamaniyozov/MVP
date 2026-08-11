# Flutter & Dart Mobile Development Best Practices

Rule source: Agentpedia Codes (https://agentpedia.codes/rules/mobile-development/flutter-dart-development)

## Core Principles
1. **Offline-First Storage**: Store user domain entities in local Hive boxes (`HiveService`) before sending network requests.
2. **Optimistic UI Updates**: Render UI updates immediately from local state while queueing mutations (`enqueueOfflineMutation`).
3. **State Management**: Use `flutter_riverpod` with immutable state objects and code generation or notifier providers.
4. **Declarative Navigation**: Use `go_router` for route definition, deep linking, and navigation stack management.
5. **Resource Management**: Properly dispose of controllers, streams, and animation listeners to prevent memory leaks.
6. **Responsive Layouts**: Utilize `LayoutBuilder`, `Flexible`, and dynamic constraints for mobile form factors.
