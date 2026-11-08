import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String defaultUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String defaultAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get isConfigured =>
      defaultUrl.isNotEmpty && defaultAnonKey.isNotEmpty;

  static Future<void> initialize() async {
    if (isConfigured) {
      try {
        await Supabase.initialize(
          url: defaultUrl,
          publishableKey: defaultAnonKey,
        );
        debugPrint('Supabase initialized successfully with $defaultUrl');
      } catch (e) {
        debugPrint('Supabase init failed, falling back to mock mode: $e');
      }
    } else {
      debugPrint(
        'No Supabase credentials provided. Running in high-fidelity Mock Mode.',
      );
    }
  }

  static SupabaseClient? get client {
    if (isConfigured) {
      try {
        return Supabase.instance.client;
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
