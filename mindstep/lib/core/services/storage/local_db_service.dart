import 'dart:convert';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/badge_model.dart';
import '../../models/day_data.dart';
import '../../models/routine_item.dart';
import '../../models/session_data.dart';
import '../../models/subscription_status.dart';
import '../../models/user_profile.dart';
import '../../models/walk_session.dart';
import '../../constants/app_badges.dart';

/// Servizio storage locale via SQLite + SharedPreferences
/// Usato da tutti gli utenti (Free e Pro come cache locale)
class LocalDbService {
  static const _dbName = 'mindstep.db';
  static const _dbVersion = 3; // v3: brainstorm_minutes + step_count

  static const _tableDay = 'day_data';
  static const _tableRoutines = 'routines';
  static const _tableWalks = 'walks';
  static const _tableBadges = 'badges';
  static const _tableSessions = 'sessions';

  Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableDay (
        date TEXT PRIMARY KEY,
        brainstorm_note TEXT DEFAULT '',
        brainstorm_count INTEGER DEFAULT 0,
        brainstorm_minutes INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE $_tableRoutines (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL,
        sort_order INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE day_routines (
        date TEXT NOT NULL,
        routine_id TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0,
        PRIMARY KEY (date, routine_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE $_tableWalks (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        data TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_tableBadges (
        id TEXT PRIMARY KEY,
        unlocked_at TEXT NOT NULL
      )
    ''');

    await _createSessionsTable(db);
  }

  /// Migrazione DB v1 → v3
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createSessionsTable(db);
    }
    if (oldVersion < 3) {
      // Aggiunge colonna brainstorm_minutes alla tabella day_data
      await db.execute(
        'ALTER TABLE $_tableDay ADD COLUMN brainstorm_minutes INTEGER DEFAULT 0',
      );
    }
  }

  Future<void> _createSessionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableSessions (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        motivational_phrase TEXT DEFAULT '',
        user_input TEXT DEFAULT '',
        duration_seconds INTEGER DEFAULT 0,
        had_walk INTEGER DEFAULT 0,
        inferred_mood TEXT DEFAULT 'normale',
        created_at TEXT NOT NULL
      )
    ''');
  }

  // ── USER PROFILE ────────────────────────────────────────────────────

  Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(profile.toJson()));
  }

  Future<UserProfile?> loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user_profile');
    if (raw == null) return null;
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  // ── SUBSCRIPTION ────────────────────────────────────────────────────

  Future<void> saveSubscription(SubscriptionStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subscription', jsonEncode(status.toJson()));
  }

  Future<SubscriptionStatus> loadSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('subscription');
    if (raw == null) return SubscriptionStatus.freePlan;
    return SubscriptionStatus.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  // ── ROUTINES ────────────────────────────────────────────────────────

  Future<void> saveRoutine(RoutineItem routine) async {
    final database = await db;
    await database.insert(
      _tableRoutines,
      {
        'id': routine.id,
        'title': routine.title,
        'created_at': routine.createdAt.toIso8601String(),
        'sort_order': routine.order,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteRoutine(String id) async {
    final database = await db;
    await database.delete(_tableRoutines, where: 'id = ?', whereArgs: [id]);
    // Rimuovi anche le istanze giornaliere
    await database.delete('day_routines', where: 'routine_id = ?', whereArgs: [id]);
  }

  Future<List<RoutineItem>> loadAllRoutines() async {
    final database = await db;
    final rows = await database.query(_tableRoutines, orderBy: 'sort_order ASC');
    return rows.map((r) => RoutineItem(
      id: r['id'] as String,
      title: r['title'] as String,
      createdAt: DateTime.parse(r['created_at'] as String),
      order: r['sort_order'] as int,
    )).toList();
  }

  // ── DAY DATA ────────────────────────────────────────────────────────

  Future<DayData> loadDayData(DateTime date) async {
    final database = await db;
    final dateKey = _dateKey(date);

    // Carica routine base
    final routines = await loadAllRoutines();
    final routineIds = routines.map((r) => r.id).toList();

    // Carica completamenti del giorno
    final dayRoutines = await database.query(
      'day_routines',
      where: 'date = ?',
      whereArgs: [dateKey],
    );
    final completedIds = dayRoutines
        .where((r) => (r['is_completed'] as int) == 1)
        .map((r) => r['routine_id'] as String)
        .toList();

    // Carica walk del giorno
    final walks = await database.query(
      _tableWalks,
      where: 'date = ?',
      whereArgs: [dateKey],
    );
    WalkSession? walk;
    if (walks.isNotEmpty) {
      walk = WalkSession.fromJson(
          jsonDecode(walks.last['data'] as String) as Map<String, dynamic>);
    }

    // Carica brainstorm
    final dayRows = await database.query(
      _tableDay,
      where: 'date = ?',
      whereArgs: [dateKey],
    );
    String brainstorm = '';
    int brainstormCount = 0;
    int brainstormMinutes = 0;
    if (dayRows.isNotEmpty) {
      brainstorm = dayRows.first['brainstorm_note'] as String? ?? '';
      brainstormCount = dayRows.first['brainstorm_count'] as int? ?? 0;
      brainstormMinutes = dayRows.first['brainstorm_minutes'] as int? ?? 0;
    }

    return DayData(
      date: date,
      walk: walk,
      routineIds: routineIds,
      completedRoutineIds: completedIds,
      brainstormNote: brainstorm,
      brainstormCount: brainstormCount,
      brainstormMinutes: brainstormMinutes,
    );
  }

  Future<void> toggleRoutineForDay(
      DateTime date, String routineId, bool completed) async {
    final database = await db;
    final dateKey = _dateKey(date);
    await database.insert(
      'day_routines',
      {'date': dateKey, 'routine_id': routineId, 'is_completed': completed ? 1 : 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveBrainstormNote(DateTime date, String note) async {
    final database = await db;
    final dateKey = _dateKey(date);
    final existing = await database.query(
      _tableDay,
      where: 'date = ?',
      whereArgs: [dateKey],
    );
    if (existing.isEmpty) {
      await database.insert(_tableDay, {
        'date': dateKey,
        'brainstorm_note': note,
        'brainstorm_count': 1,
      });
    } else {
      final currentCount = existing.first['brainstorm_count'] as int? ?? 0;
      await database.update(
        _tableDay,
        {'brainstorm_note': note, 'brainstorm_count': currentCount + 1},
        where: 'date = ?',
        whereArgs: [dateKey],
      );
    }
  }

  /// Aggiunge minuti di brainstorming al totale giornaliero
  Future<void> addBrainstormMinutes(DateTime date, int minutes) async {
    if (minutes <= 0) return;
    final database = await db;
    final dateKey = _dateKey(date);
    final existing = await database.query(
      _tableDay,
      where: 'date = ?',
      whereArgs: [dateKey],
    );
    if (existing.isEmpty) {
      await database.insert(_tableDay, {
        'date': dateKey,
        'brainstorm_note': '',
        'brainstorm_count': 0,
        'brainstorm_minutes': minutes,
      });
    } else {
      final current = existing.first['brainstorm_minutes'] as int? ?? 0;
      await database.update(
        _tableDay,
        {'brainstorm_minutes': current + minutes},
        where: 'date = ?',
        whereArgs: [dateKey],
      );
    }
  }

  Future<void> saveWalkSession(WalkSession session, DateTime date) async {
    final database = await db;
    final dateKey = _dateKey(date);
    await database.insert(
      _tableWalks,
      {'id': session.id, 'date': dateKey, 'data': jsonEncode(session.toJson())},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── SESSIONS (rituale quotidiano) ───────────────────────────────────

  Future<void> saveSession(SessionData session) async {
    final database = await db;
    await database.insert(
      _tableSessions,
      {
        'id': session.id,
        'date': _dateKey(session.date),
        'motivational_phrase': session.motivationalPhrase,
        'user_input': session.userInput,
        'duration_seconds': session.durationSeconds,
        'had_walk': session.hadWalk ? 1 : 0,
        'inferred_mood': session.inferredMood,
        'created_at': session.date.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> hasSessionToday() async {
    final database = await db;
    final rows = await database.query(
      _tableSessions,
      where: 'date = ?',
      whereArgs: [_dateKey(DateTime.now())],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Restituisce i giorni dall'ultima sessione completata.
  /// Ritorna null se l'utente non ha mai fatto una sessione (primo utilizzo).
  Future<int?> daysSinceLastSession() async {
    final database = await db;
    final rows = await database.query(
      _tableSessions,
      orderBy: 'date DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final lastDate = rows.first['date'] as String;
    final last = DateTime.parse(lastDate);
    final today = DateTime.now();
    final diff = DateTime(today.year, today.month, today.day)
        .difference(DateTime(last.year, last.month, last.day))
        .inDays;
    return diff;
  }

  // ── ANALYTICS ───────────────────────────────────────────────────────

  Future<int> countTotalWalks() async {
    final database = await db;
    final result = await database.rawQuery(
      "SELECT COUNT(*) as count FROM $_tableWalks WHERE json_extract(data, '\$.state') = ?",
      [WalkState.completed.index],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<double> getTotalDistanceKm() async {
    final database = await db;
    final rows = await database.query(_tableWalks);
    double total = 0;
    for (final row in rows) {
      final data = jsonDecode(row['data'] as String) as Map<String, dynamic>;
      final session = WalkSession.fromJson(data);
      if (session.isCompleted) {
        total += session.distanceKm;
      }
    }
    return total;
  }

  Future<int> calculateStreak() async {
    final database = await db;
    int streak = 0;
    final today = DateTime.now();

    for (int i = 0; i < 365; i++) {
      final checkDate = today.subtract(Duration(days: i));
      final dateKey = _dateKey(checkDate);

      // Controlla walk
      final walks = await database.query(
        _tableWalks,
        where: 'date = ?',
        whereArgs: [dateKey],
      );

      // Controlla routine completate
      final routines = await database.query(
        'day_routines',
        where: 'date = ? AND is_completed = 1',
        whereArgs: [dateKey],
      );

      // Controlla brainstorm
      final dayData = await database.query(
        _tableDay,
        where: 'date = ? AND brainstorm_note != ""',
        whereArgs: [dateKey],
      );

      // Controlla sessione rituale
      final sessions = await database.query(
        _tableSessions,
        where: 'date = ?',
        whereArgs: [dateKey],
      );

      final isActive = walks.isNotEmpty ||
          routines.isNotEmpty ||
          dayData.isNotEmpty ||
          sessions.isNotEmpty;

      if (isActive) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  Future<List<DayData>> loadDateRange(DateTime from, DateTime to) async {
    final days = <DayData>[];
    var current = from;
    while (!current.isAfter(to)) {
      days.add(await loadDayData(current));
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  // ── BADGES ──────────────────────────────────────────────────────────

  Future<void> unlockBadge(String badgeId) async {
    final database = await db;
    await database.insert(
      _tableBadges,
      {'id': badgeId, 'unlocked_at': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.ignore, // Non sovrascrivere
    );
  }

  Future<List<BadgeStatus>> loadAllBadgeStatuses(bool isPro) async {
    final database = await db;
    final rows = await database.query(_tableBadges);
    final unlockedMap = {
      for (final r in rows)
        r['id'] as String: DateTime.parse(r['unlocked_at'] as String),
    };

    // Mostra solo badge Free per utenti Free
    final badges = isPro ? AppBadges.all : AppBadges.freeOnly;

    return badges.map((badge) {
      final unlockedAt = unlockedMap[badge.id];
      return BadgeStatus(
        badge: badge,
        isUnlocked: unlockedAt != null,
        unlockedAt: unlockedAt,
      );
    }).toList();
  }

  Future<Set<String>> loadUnlockedBadgeIds() async {
    final database = await db;
    final rows = await database.query(_tableBadges);
    return rows.map((r) => r['id'] as String).toSet();
  }

  // ── RESET ───────────────────────────────────────────────────────────

  Future<void> resetAll() async {
    final database = await db;
    await database.delete(_tableDay);
    await database.delete(_tableRoutines);
    await database.delete('day_routines');
    await database.delete(_tableWalks);
    await database.delete(_tableBadges);
    await database.delete(_tableSessions);

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ── EXPORT ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> exportAllData() async {
    final profile = await loadUserProfile();
    final routines = await loadAllRoutines();
    final badgeStatuses = await loadAllBadgeStatuses(true);

    // Carica ultimi 90 giorni
    final to = DateTime.now();
    final from = to.subtract(const Duration(days: 90));
    final days = await loadDateRange(from, to);

    return {
      'exportedAt': DateTime.now().toIso8601String(),
      'appVersion': '1.0.0',
      'profile': profile?.toJson(),
      'routines': routines.map((r) => r.toJson()).toList(),
      'badges': badgeStatuses
          .where((b) => b.isUnlocked)
          .map((b) => {'id': b.badge.id, 'unlockedAt': b.unlockedAt?.toIso8601String()})
          .toList(),
      'days': days.map((d) => d.toJson()).toList(),
    };
  }

  // ── HELPERS ─────────────────────────────────────────────────────────

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
