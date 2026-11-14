import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakwise_mobile/app/app.dart';
import 'package:speakwise_mobile/core/services/storage_service.dart';

/// ═══════════════════════════════════════════════════════════════
/// Bootstrapping Pipeline (Pre-flight async setup)
/// ═══════════════════════════════════════════════════════════════
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load environment variables (.env) safely
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('dotenv init notice: $e');
  }

  // 2. Initialize Local Storage (SharedPreferences)
  final sharedPreferences = await SharedPreferences.getInstance();

  // 3. Launch App with Riverpod ProviderScope Overrides
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const SpeakWiseApp(),
    ),
  );
}
