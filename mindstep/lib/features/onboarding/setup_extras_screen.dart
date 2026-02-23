import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/models/notification_preferences.dart';
import 'setup_notifications_screen.dart';
import 'setup_ai_provider_screen.dart';

/// Coordinator screen per gli step extra di onboarding:
/// Step 3 → Notifiche  |  Step 4 → AI provider
class SetupExtrasScreen extends StatefulWidget {
  const SetupExtrasScreen({super.key});

  @override
  State<SetupExtrasScreen> createState() => _SetupExtrasScreenState();
}

class _SetupExtrasScreenState extends State<SetupExtrasScreen> {
  final _pageController = PageController();
  NotificationPreferences _notifPrefs = NotificationPreferences.defaults;

  @override
  Widget build(BuildContext context) {
    final services = context.read<AppServices>();

    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // ── Step 3: Notifiche ─────────────────────────────────────────
            SetupNotificationsScreen(
              onBack: () => context.pop(),
              onNext: (prefs) {
                setState(() => _notifPrefs = prefs);
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),

            // ── Step 4: AI Provider ───────────────────────────────────────
            SetupAiProviderScreen(
              aiService: services.aiInsight,
              onBack: () => _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              onNext: (config) async {
                // Salva preferenze notifiche e programma avvisi
                await services.applyNotificationPreferences(_notifPrefs);
                if (mounted) context.go('/home');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
