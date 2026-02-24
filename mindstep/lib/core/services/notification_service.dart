import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Servizio notifiche push — canali Android separati per tipo
class NotificationService {
  static const _channelWalk = 'walk_tracking';
  static const _channelReminders = 'reminders';
  static const _channelAchievements = 'achievements';

  static const _idWalkOngoing = 1001;
  static const _idMorningReminder = 2001;
  static const _idRoutineReminder = 2002;
  static const _idWalkReminder = 2003;
  static const _idBrainReminder = 2004;
  static const _idStreakWarning = 3001;
  static const _idBadgeBase = 4000; // +badgeIndex per evitare conflitti

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);
    await _createChannels();
  }

  Future<void> _createChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelWalk,
        'Camminata in corso',
        description: 'Notifica persistente durante il tracking GPS',
        importance: Importance.low,
        showBadge: false,
        playSound: false,
      ),
    );

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelReminders,
        'Promemoria',
        description: 'Reminder giornalieri per routine e camminate',
        importance: Importance.defaultImportance,
      ),
    );

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelAchievements,
        'Traguardi',
        description: 'Notifiche per badge sbloccati',
        importance: Importance.high,
        playSound: true,
      ),
    );
  }

  // ── WALK ONGOING (persistente durante tracciamento) ─────────────────

  Future<void> showWalkOngoing({
    required String distance,
    required String time,
    required bool isPaused,
  }) async {
    final title = isPaused ? '⏸ Camminata in pausa' : '🚶 Camminata in corso';
    final body = '$distance km · $time';

    await _plugin.show(
      _idWalkOngoing,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelWalk,
          'Camminata in corso',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          showWhen: false,
          actions: [
            if (!isPaused)
              const AndroidNotificationAction('pause', '⏸ Pausa')
            else
              const AndroidNotificationAction('resume', '▶ Riprendi'),
            const AndroidNotificationAction('stop', '⏹ Ferma'),
          ],
        ),
      ),
    );
  }

  Future<void> cancelWalkOngoing() async {
    await _plugin.cancel(_idWalkOngoing);
  }

  // ── BADGE SBLOCCATO ─────────────────────────────────────────────────

  Future<void> showBadgeUnlocked({
    required String badgeName,
    required String message,
    required int badgeIndex,
  }) async {
    await _plugin.show(
      _idBadgeBase + badgeIndex,
      '🏅 Traguardo sbloccato: $badgeName',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelAchievements,
          'Traguardi',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  // ── PROMEMORIA MATTUTINO ─────────────────────────────────────────────

  Future<void> scheduleMorningReminder({
    required int hour,
    required int minute,
    required String message,
  }) async {
    await _plugin.cancel(_idMorningReminder); // Cancella solo il reminder mattutino

    final scheduledDate = _nextInstanceOf(hour, minute);

    await _plugin.zonedSchedule(
      _idMorningReminder,
      'MindStep',
      message,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelReminders,
          'Promemoria',
          importance: Importance.defaultImportance,
          styleInformation: BigTextStyleInformation(message),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Ripeti ogni giorno
    );
  }

  // ── PROMEMORIA ROUTINE ───────────────────────────────────────────────

  Future<void> scheduleRoutineReminder({
    required int hour,
    required int minute,
  }) async {
    await _plugin.cancel(_idRoutineReminder);
    final scheduledDate = _nextInstanceOf(hour, minute);

    await _plugin.zonedSchedule(
      _idRoutineReminder,
      'Le tue routine ti aspettano',
      'Controlla le abitudini di oggi e completa la giornata.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelReminders,
          'Promemoria',
          importance: Importance.defaultImportance,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ── PROMEMORIA WALK ──────────────────────────────────────────────────

  Future<void> scheduleWalkReminder({
    required int hour,
    required int minute,
  }) async {
    await _plugin.cancel(_idWalkReminder);
    final scheduledDate = _nextInstanceOf(hour, minute);

    await _plugin.zonedSchedule(
      _idWalkReminder,
      'Ora di camminare! 🚶',
      'Una camminata di 20 minuti fa miracoli. Inizia adesso.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelReminders,
          'Promemoria',
          importance: Importance.defaultImportance,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ── STREAK WARNING (PRO) ─────────────────────────────────────────────

  Future<void> scheduleStreakWarning() async {
    // Ogni sera alle 20:00
    final scheduledDate = _nextInstanceOf(20, 0);

    await _plugin.zonedSchedule(
      _idStreakWarning,
      'Hai 5 minuti per te oggi?',
      'Anche un piccolo gesto conta. Il tuo momento di riflessione ti aspetta.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelReminders,
          'Promemoria',
          importance: Importance.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ── BRAIN REMINDER (PRO) ─────────────────────────────────────────────

  Future<void> scheduleBrainReminder({
    required int hour,
    required int minute,
  }) async {
    await _plugin.cancel(_idBrainReminder);
    final scheduledDate = _nextInstanceOf(hour, minute);

    await _plugin.zonedSchedule(
      _idBrainReminder,
      'Walking Brain 💭',
      'Stai per chiudere la giornata. Hai catturato i tuoi pensieri?',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelReminders,
          'Promemoria',
          importance: Importance.defaultImportance,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAll() async => await _plugin.cancelAll();

  // ── HELPER ───────────────────────────────────────────────────────────

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
