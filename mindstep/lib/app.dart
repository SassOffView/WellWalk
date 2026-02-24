import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/services/storage/local_db_service.dart';
import 'core/services/badge_service.dart';
import 'core/services/gps_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/health_service.dart';
import 'core/services/ai_insight_service.dart';
import 'core/services/tts_service.dart';
import 'core/models/subscription_status.dart';
import 'core/models/notification_preferences.dart';
import 'core/constants/app_strings.dart';

import 'features/onboarding/onboarding_screen.dart';
import 'features/onboarding/setup_profile_screen.dart';
import 'features/onboarding/setup_extras_screen.dart';
import 'features/home/home_screen.dart';
import 'features/history/history_screen.dart';
import 'features/analytics/analytics_screen.dart';
import 'features/achievements/achievements_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/session/session_screen.dart';
import 'subscription/paywall_screen.dart';

/// Provider globale per dependency injection
class AppServices extends ChangeNotifier {
  final LocalDbService db = LocalDbService();
  late final BadgeService badges;
  late final AiInsightService aiInsight;
  final GpsService gps = GpsService();
  final NotificationService notifications = NotificationService();
  final HealthService health = HealthService();
  final TtsService tts = TtsService();

  SubscriptionStatus _subscription = SubscriptionStatus.freePlan;
  ThemeMode _themeMode = ThemeMode.system;
  NotificationPreferences _notifPrefs = NotificationPreferences.defaults;

  SubscriptionStatus get subscription => _subscription;
  ThemeMode get themeMode => _themeMode;
  NotificationPreferences get notifPrefs => _notifPrefs;
  bool get isPro => _subscription.isPro;

  AppServices() {
    badges = BadgeService(db);
    aiInsight = AiInsightService(db);
    badges.onBadgeUnlocked = _onBadgeUnlocked;
    _init();
  }

  Future<void> _init() async {
    _subscription = await db.loadSubscription();
    notifyListeners();
    await Future.wait([
      notifications.initialize(),
      tts.initialize(),
    ]);

    // Carica preferenze notifiche e ripristina scheduling
    final sp = await SharedPreferences.getInstance();
    final notifJson = sp.getString('notification_prefs');
    if (notifJson != null) {
      _notifPrefs = NotificationPreferences.fromJson(
        Map<String, dynamic>.from(jsonDecode(notifJson) as Map),
      );
      notifyListeners();
      await _scheduleNotifications(_notifPrefs);
    }
  }

  /// Salva le preferenze di notifica e programma gli avvisi
  Future<void> applyNotificationPreferences(NotificationPreferences prefs) async {
    _notifPrefs = prefs;
    notifyListeners();

    final sp = await SharedPreferences.getInstance();
    await sp.setString('notification_prefs', jsonEncode(prefs.toJson()));
    await _scheduleNotifications(prefs);
  }

  Future<void> _scheduleNotifications(NotificationPreferences prefs) async {
    if (prefs.dailyReminderEnabled) {
      await notifications.scheduleMorningReminder(
        hour: prefs.dailyReminderHour,
        minute: prefs.dailyReminderMinute,
        message: AppStrings.morningMessages[0],
      );
    }
    if (prefs.routineReminderEnabled) {
      await notifications.scheduleRoutineReminder(
        hour: prefs.routineReminderHour,
        minute: prefs.routineReminderMinute,
      );
    }
    if (prefs.walkReminderEnabled) {
      await notifications.scheduleWalkReminder(
        hour: prefs.walkReminderHour,
        minute: prefs.walkReminderMinute,
      );
    }
    if (prefs.brainReminderEnabled) {
      await notifications.scheduleBrainReminder(
        hour: prefs.brainReminderHour,
        minute: prefs.brainReminderMinute,
      );
    }
    if (prefs.streakWarningEnabled) {
      await notifications.scheduleStreakWarning();
    }
  }

  /// Aggiorna il messaggio della notifica mattutina con l'insight AI
  Future<void> updateMorningMessageWithInsight(String aiMessage) async {
    if (!_notifPrefs.dailyReminderEnabled) return;
    await notifications.scheduleMorningReminder(
      hour: _notifPrefs.dailyReminderHour,
      minute: _notifPrefs.dailyReminderMinute,
      message: aiMessage,
    );
  }

  void _onBadgeUnlocked(dynamic badge) async {
    final statuses = await db.loadAllBadgeStatuses(isPro);
    final index = statuses.indexWhere((s) => s.badge.id == (badge as dynamic).id);
    await notifications.showBadgeUnlocked(
      badgeName: badge.name as String,
      message: badge.unlockMessage as String,
      badgeIndex: index >= 0 ? index : 0,
    );
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  Future<void> refreshSubscription() async {
    _subscription = await db.loadSubscription();
    notifyListeners();
  }
}

class MindStepApp extends StatelessWidget {
  const MindStepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppServices(),
      child: Consumer<AppServices>(
        builder: (context, services, _) {
          return MaterialApp.router(
            title: 'MindStep',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: services.themeMode,
            routerConfig: _buildRouter(services),
          );
        },
      ),
    );
  }

  GoRouter _buildRouter(AppServices services) => GoRouter(
    initialLocation: '/home',
    redirect: (context, state) async {
      final profile = await services.db.loadUserProfile();
      final isOnboarded = profile?.hasCompletedOnboarding ?? false;
      if (!isOnboarded && !state.matchedLocation.startsWith('/onboarding')) {
        return '/onboarding';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (_, __) => const SetupProfileScreen(),
      ),
      GoRoute(
        path: '/setup/extras',
        builder: (_, __) => const SetupExtrasScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/history',
            builder: (_, __) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (_, __) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/achievements',
            builder: (_, __) => const AchievementsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/session',
        builder: (_, __) => const SessionScreen(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (_, __) => const PaywallScreen(),
      ),
    ],
  );
}

/// Shell con bottom navigation bar
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const _tabs = [
    '/home',
    '/history',
    '/analytics',
    '/achievements',
    '/settings',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? const Color(0xFF2B3A7F)
        : const Color(0xFFE5E7EB);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) {
            setState(() => _selectedIndex = i);
            context.go(_tabs[i]);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Storico',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Dati',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              activeIcon: Icon(Icons.emoji_events),
              label: 'Traguardi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.tune_outlined),
              activeIcon: Icon(Icons.tune),
              label: 'Altro',
            ),
          ],
        ),
      ),
    );
  }
}
