import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/app/router.dart';
import 'package:speakwise_mobile/core/services/storage_service.dart';
import 'package:speakwise_mobile/features/auth/auth.dart';

/// ═══════════════════════════════════════════════════════════════
/// SpeakWise Root Application Widget
/// ═══════════════════════════════════════════════════════════════
class SpeakWiseApp extends ConsumerStatefulWidget {
  const SpeakWiseApp({super.key});

  @override
  ConsumerState<SpeakWiseApp> createState() => _SpeakWiseAppState();
}

class _SpeakWiseAppState extends ConsumerState<SpeakWiseApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final storage = ref.read(storageServiceProvider);
      if (storage.isAuthenticated && !storage.isGuest) {
        final isValid = await ref.read(authRemoteDataSourceProvider).validateSession();
        if (!isValid && mounted) {
          ref.invalidate(routerProvider);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SpeakWise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
