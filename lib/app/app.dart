import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/app/router.dart';

/// ═══════════════════════════════════════════════════════════════
/// SpeakWise Root Application Widget
/// ═══════════════════════════════════════════════════════════════
class SpeakWiseApp extends ConsumerWidget {
  const SpeakWiseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
