import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/models/notification_preferences.dart';
import '../../core/models/user_profile.dart';
import 'setup_notifications_screen.dart';
import 'setup_ai_provider_screen.dart';
import 'setup_goals_screen.dart';

/// Coordinator screen per gli step extra di onboarding:
/// Step 3 → Notifiche  |  Step 4 → AI provider  |  Step 5 → Obiettivi
class SetupExtrasScreen extends StatefulWidget {
  const SetupExtrasScreen({super.key});

  @override
  State<SetupExtrasScreen> createState() => _SetupExtrasScreenState();
}

class _SetupExtrasScreenState extends State<SetupExtrasScreen> {
  final _pageController = PageController();
  NotificationPreferences _notifPrefs = NotificationPreferences.defaults;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final services = context.read<AppServices>();
    final profile = await services.db.loadUserProfile();
    if (mounted) setState(() => _profile = profile);
  }

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
                // Salva preferenze notifiche
                await services.applyNotificationPreferences(_notifPrefs);
                // Vai allo step obiettivi
                if (mounted) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
            ),

            // ── Step 5: Obiettivi giornalieri ─────────────────────────────
            Builder(
              builder: (ctx) {
                final profile = _profile;
                if (profile == null) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                return SetupGoalsScreen(
                  profile: profile,
                  onBack: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  onDone: (updated) async {
                    await services.db.saveUserProfile(updated);
                    if (mounted) context.go('/home');
                  },
                );
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
