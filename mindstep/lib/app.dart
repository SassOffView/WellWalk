import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
import 'core/services/quote_service.dart';
import 'core/services/coaching_service.dart';
import 'core/services/weather_service.dart';
import 'core/models/subscription_status.dart';
import 'core/models/notification_preferences.dart';
import 'core/models/badge_model.dart';
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
import 'features/coach/coach_screen.dart';
import 'subscription/paywall_screen.dart';

/// Provider globale per dependency injection
class AppServices extends ChangeNotifier {
  final LocalDbService db = LocalDbService();
  late final BadgeService badges;
  late final AiInsightService aiInsight;
  late final CoachingService coaching;
  final GpsService gps = GpsService();
  final NotificationService notifications = NotificationService();
  final HealthService health = HealthService();
  final TtsService tts = TtsService();
  final QuoteService quotes = QuoteService();
  final WeatherService weather = WeatherService();

  // TESTING MODE: PRO unlocked — change back to freePlan before production release
  SubscriptionStatus _subscription = const SubscriptionStatus(
    plan: SubscriptionPlan.proMonthly,
    purchasedAt: null,
  );
  ThemeMode _themeMode = ThemeMode.system;
  NotificationPreferences _notifPrefs = NotificationPreferences.defaults;

  SubscriptionStatus get subscription => _subscription;
  ThemeMode get themeMode => _themeMode;
  NotificationPreferences get notifPrefs => _notifPrefs;
  bool get isPro => _subscription.isPro;

  AppServices() {
    badges = BadgeService(db);
    aiInsight = AiInsightService(db);
    coaching = CoachingService(aiInsight);
    badges.onBadgeUnlocked = _onBadgeUnlocked;
    _init();
  }

  Future<void> _init() async {
    final loaded = await db.loadSubscription();
    // TESTING MODE: forza PRO — rimuovere prima del rilascio in produzione
    _subscription = loaded.isPro
        ? loaded
        : const SubscriptionStatus(plan: SubscriptionPlan.proMonthly);
    notifyListeners();
    await Future.wait([
      notifications.initialize(),
      tts.initialize(),
    ]);

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

  Future<void> updateMorningMessageWithInsight(String aiMessage) async {
    if (!_notifPrefs.dailyReminderEnabled) return;
    await notifications.scheduleMorningReminder(
      hour: _notifPrefs.dailyReminderHour,
      minute: _notifPrefs.dailyReminderMinute,
      message: aiMessage,
    );
  }

  void _onBadgeUnlocked(BadgeModel badge) async {
    final statuses = await db.loadAllBadgeStatuses(isPro);
    final index = statuses.indexWhere((s) => s.badge.id == badge.id);
    await notifications.showBadgeUnlocked(
      badgeName: badge.name,
      message: badge.unlockMessage,
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
      final loc = state.matchedLocation;
      final inOnboardingFlow =
          loc.startsWith('/onboarding') || loc.startsWith('/setup');
      if (!isOnboarded && !inOnboardingFlow) {
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
        path: '/coach',
        builder: (_, __) => const CoachScreen(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (_, __) => const PaywallScreen(),
      ),
    ],
  );
}

/// Shell con bottom navigation bar — icone Phosphor
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
          items: [
            BottomNavigationBarItem(
              icon: PhosphorIcon(PhosphorIcons.house(), size: 22),
              activeIcon: PhosphorIcon(
                  PhosphorIcons.house(PhosphorIconsStyle.fill), size: 22),
              label: AppStrings.navHome,
            ),
            BottomNavigationBarItem(
              icon: PhosphorIcon(PhosphorIcons.calendarDots(), size: 22),
              activeIcon: PhosphorIcon(
                  PhosphorIcons.calendarDots(PhosphorIconsStyle.fill), size: 22),
              label: AppStrings.navHistory,
            ),
            BottomNavigationBarItem(
              icon: PhosphorIcon(PhosphorIcons.chartBar(), size: 22),
              activeIcon: PhosphorIcon(
                  PhosphorIcons.chartBar(PhosphorIconsStyle.fill), size: 22),
              label: AppStrings.navAnalytics,
            ),
            BottomNavigationBarItem(
              icon: PhosphorIcon(PhosphorIcons.trophy(), size: 22),
              activeIcon: PhosphorIcon(
                  PhosphorIcons.trophy(PhosphorIconsStyle.fill), size: 22),
              label: AppStrings.navAchievements,
            ),
            BottomNavigationBarItem(
              icon: PhosphorIcon(PhosphorIcons.gear(), size: 22),
              activeIcon: PhosphorIcon(
                  PhosphorIcons.gear(PhosphorIconsStyle.fill), size: 22),
              label: AppStrings.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}
