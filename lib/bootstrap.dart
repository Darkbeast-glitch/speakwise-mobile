import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakwise_mobile/app/app.dart';
import 'package:speakwise_mobile/core/services/remote_config_service.dart';
import 'package:speakwise_mobile/core/services/storage_service.dart';
import 'package:speakwise_mobile/firebase_options.dart';

/// ═══════════════════════════════════════════════════════════════
/// Bootstrapping Pipeline (Pre-flight async setup)
/// ═══════════════════════════════════════════════════════════════
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load local environment variables (.env) safely
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('dotenv init notice: $e');
  }

  // 2. Initialize Firebase Core
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('🔥 Firebase Core initialized successfully');
  } catch (e) {
    debugPrint('Firebase init notice: $e');
  }

  // 3. Initialize Firebase Remote Config
  final remoteConfigService = RemoteConfigService();
  try {
    await remoteConfigService.init();
  } catch (e) {
    debugPrint('RemoteConfig init notice: $e');
  }

  // 4. Initialize Local Storage (SharedPreferences)
  final sharedPreferences = await SharedPreferences.getInstance();

  // 5. Launch App with Riverpod ProviderScope Overrides
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        remoteConfigServiceProvider.overrideWithValue(remoteConfigService),
      ],
      child: const SpeakWiseApp(),
    ),
  );
}
