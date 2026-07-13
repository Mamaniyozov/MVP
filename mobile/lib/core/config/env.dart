import 'package:flutter/foundation.dart';

/// Resolves the backend API base URL.
///
/// Override at build/run time with `--dart-define=API_BASE_URL=http://...`.
/// Without an override, falls back to the Android emulator loopback address
/// (10.0.2.2) on Android, and localhost everywhere else (web/desktop).
class Env {
  Env._();

  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_override.isNotEmpty) {
      return _override;
    }
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }
}
