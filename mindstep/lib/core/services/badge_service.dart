import '../constants/app_badges.dart';
import '../models/badge_model.dart';
import '../models/day_data.dart';
import 'storage/local_db_service.dart';

/// Servizio badge — risolve TUTTI i bug della PWA v5.0:
/// 1. checkAll al primo avvio
/// 2. walks badge mai chiamato → ora triggera su ogni walk completata
/// 3. firstBrainstorm per-giorno → ora flag globale nel profilo
/// 4. race condition → await sequenziale
/// 5. countTotalWalks mai usato → ora integrato
class BadgeService {
  BadgeService(this._db);

  final LocalDbService _db;

  // Callback per notificare l'UI quando si sblocca un badge
  Function(BadgeModel badge)? onBadgeUnlocked;

  /// Controlla tutti i badge ad ogni apertura dell'app (FIX BUG #1)
  Future<List<BadgeModel>> checkAllBadgesOnStartup({required bool isPro}) async {
    final newBadges = <BadgeModel>[];
    final unlockedIds = await _db.loadUnlockedBadgeIds();
    final totalWalks = await _db.countTotalWalks();
    final totalKm = await _db.getTotalDistanceKm();
    final streak = await _db.calculateStreak();

    final badges = isPro ? AppBadges.all : AppBadges.freeOnly;

    for (final badge in badges) {
      if (unlockedIds.contains(badge.id)) continue;

      bool shouldUnlock = false;

      switch (badge.type) {
        case BadgeType.totalWalks: // FIX BUG #2 e #5
          shouldUnlock = totalWalks >= badge.requiredValue;
          break;
        case BadgeType.totalDistance:
          shouldUnlock = totalKm >= badge.requiredValue;
          break;
        case BadgeType.streak:
          shouldUnlock = streak >= badge.requiredValue;
          break;
        case BadgeType.firstRoutine:
        case BadgeType.routinePercentage:
        case BadgeType.singleWalkMinutes:
        case BadgeType.firstBrainstorm:
        case BadgeType.totalBrainstorms:
        case BadgeType.dailyCombo:
          // Questi vengono controllati in tempo reale tramite checkForEvent
          break;
      }

      if (shouldUnlock) {
        await _db.unlockBadge(badge.id); // await garantisce no race condition
        newBadges.add(badge);
        onBadgeUnlocked?.call(badge);
      }
    }

    return newBadges;
  }

  /// Chiamato quando viene completata una camminata
  Future<List<BadgeModel>> onWalkCompleted({
    required int walkMinutes,
    required bool isPro,
    required DayData dayData,
  }) async {
    final newBadges = <BadgeModel>[];

    // 1. Total walks check (FIX BUG #2 — prima mai chiamato)
    newBadges.addAll(await _checkAndUnlock(
      type: BadgeType.totalWalks,
      currentValue: await _db.countTotalWalks(),
      isPro: isPro,
    ));

    // 2. Total distance check
    newBadges.addAll(await _checkAndUnlock(
      type: BadgeType.totalDistance,
      currentValue: (await _db.getTotalDistanceKm()).toInt(),
      isPro: isPro,
    ));

    // 3. Single walk duration check
    newBadges.addAll(await _checkAndUnlock(
      type: BadgeType.singleWalkMinutes,
      currentValue: walkMinutes,
      isPro: isPro,
    ));

    // 4. Streak check
    newBadges.addAll(await _checkAndUnlock(
      type: BadgeType.streak,
      currentValue: await _db.calculateStreak(),
      isPro: isPro,
    ));

    // 5. Daily combo check
    if (dayData.hasDailyCombo) {
      newBadges.addAll(await _checkAndUnlock(
        type: BadgeType.dailyCombo,
        currentValue: 1,
        isPro: isPro,
      ));
    }

    return newBadges;
  }

  /// Chiamato quando si completa una routine (toggle ON)
  Future<List<BadgeModel>> onRoutineToggled({
    required DayData dayData,
    required bool isPro,
  }) async {
    final newBadges = <BadgeModel>[];

    // Prima routine mai completata
    if (dayData.routineCompleted >= 1) {
      newBadges.addAll(await _checkAndUnlock(
        type: BadgeType.firstRoutine,
        currentValue: 1,
        isPro: isPro,
      ));
    }

    // 50% routine
    if (dayData.routinePercent >= 50) {
      newBadges.addAll(await _checkAndUnlock(
        type: BadgeType.routinePercentage,
        currentValue: 50,
        isPro: isPro,
      ));
    }

    // 100% routine
    if (dayData.hasAllRoutinesDone) {
      newBadges.addAll(await _checkAndUnlock(
        type: BadgeType.routinePercentage,
        currentValue: 100,
        isPro: isPro,
      ));
    }

    // Streak
    newBadges.addAll(await _checkAndUnlock(
      type: BadgeType.streak,
      currentValue: await _db.calculateStreak(),
      isPro: isPro,
    ));

    // Daily combo
    if (dayData.hasDailyCombo) {
      newBadges.addAll(await _checkAndUnlock(
        type: BadgeType.dailyCombo,
        currentValue: 1,
        isPro: isPro,
      ));
    }

    return newBadges;
  }

  /// Chiamato quando si salva un brainstorm
  /// FIX BUG #3: non controlla flag per-giorno ma flag globale (hasBrainstormedEver)
  Future<List<BadgeModel>> onBrainstormSaved({
    required bool isFirstEver,     // Flag globale dal profilo utente
    required int totalBrainstorms, // Contatore globale
    required bool isPro,
    required DayData dayData,
  }) async {
    final newBadges = <BadgeModel>[];

    // Prima nota in assoluto (globale, non per-giorno — FIX BUG #3)
    if (isFirstEver) {
      newBadges.addAll(await _checkAndUnlock(
        type: BadgeType.firstBrainstorm,
        currentValue: 1,
        isPro: isPro,
      ));
    }

    // 10 brainstorm totali
    newBadges.addAll(await _checkAndUnlock(
      type: BadgeType.totalBrainstorms,
      currentValue: totalBrainstorms,
      isPro: isPro,
    ));

    // Daily combo
    if (dayData.hasDailyCombo) {
      newBadges.addAll(await _checkAndUnlock(
        type: BadgeType.dailyCombo,
        currentValue: 1,
        isPro: isPro,
      ));
    }

    return newBadges;
  }

  // ── Private ─────────────────────────────────────────────────────────

  Future<List<BadgeModel>> _checkAndUnlock({
    required BadgeType type,
    required int currentValue,
    required bool isPro,
  }) async {
    final newBadges = <BadgeModel>[];
    final unlockedIds = await _db.loadUnlockedBadgeIds();
    final badges = isPro ? AppBadges.all : AppBadges.freeOnly;

    for (final badge in badges.where((b) => b.type == type)) {
      if (unlockedIds.contains(badge.id)) continue;
      if (currentValue >= badge.requiredValue) {
        await _db.unlockBadge(badge.id); // Sequenziale — no race condition
        newBadges.add(badge);
        onBadgeUnlocked?.call(badge);
      }
    }

    return newBadges;
  }
}
