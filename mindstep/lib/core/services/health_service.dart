import 'package:health/health.dart';
import '../models/walk_session.dart';

/// Integrazione Health Connect (Android 14+) e Google Fit (fallback)
/// Disponibile solo per utenti PRO
class HealthService {
  final HealthFactory _health = HealthFactory(useHealthConnectIfAvailable: true);

  static const _types = [
    HealthDataType.STEPS,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.EXERCISE_TIME,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_ASLEEP,
  ];

  static const _writeTypes = [
    HealthDataType.STEPS,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.EXERCISE_TIME,
  ];

  Future<bool> requestPermissions() async {
    final permissions = _types.map((_) => HealthDataAccess.READ_WRITE).toList();
    try {
      return await _health.requestAuthorization(_types, permissions: permissions);
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasPermissions() async {
    try {
      return await _health.hasPermissions(_types) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Sincronizza una camminata completata su Health Connect
  Future<bool> syncWalkSession(WalkSession session, {double weightKg = 65.0}) async {
    if (!session.isCompleted) return false;

    final from = session.startedAt;
    final to = session.completedAt ?? DateTime.now();

    try {
      bool allOk = true;

      // 1. STEPS (stima: 1300 passi per km)
      final estimatedSteps = (session.distanceKm * 1300).round();
      allOk &= await _health.writeHealthData(
        value: estimatedSteps.toDouble(),
        type: HealthDataType.STEPS,
        startTime: from,
        endTime: to,
      );

      // 2. DISTANCE
      allOk &= await _health.writeHealthData(
        value: session.distanceMeters,
        type: HealthDataType.DISTANCE_WALKING_RUNNING,
        startTime: from,
        endTime: to,
        unit: HealthDataUnit.METER,
      );

      // 3. CALORIES
      final calories = session.caloriesBurned(weightKg: weightKg);
      allOk &= await _health.writeHealthData(
        value: calories,
        type: HealthDataType.ACTIVE_ENERGY_BURNED,
        startTime: from,
        endTime: to,
        unit: HealthDataUnit.KILOCALORIE,
      );

      // 4. EXERCISE TIME
      allOk &= await _health.writeHealthData(
        value: session.activeMinutes.toDouble(),
        type: HealthDataType.EXERCISE_TIME,
        startTime: from,
        endTime: to,
        unit: HealthDataUnit.MINUTE,
      );

      return allOk;
    } catch (_) {
      return false;
    }
  }

  /// Leggi passi odierni da Health Connect
  Future<int> getTodaySteps() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    try {
      final data = await _health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: [HealthDataType.STEPS],
      );

      if (data.isEmpty) return 0;
      return data
          .map((d) => (d.value as NumericHealthValue).numericValue.round())
          .fold(0, (a, b) => a + b);
    } catch (_) {
      return 0;
    }
  }

  /// Leggi frequenza cardiaca media degli ultimi 7 giorni
  Future<double?> getAvgHeartRate7Days() async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    try {
      final data = await _health.getHealthDataFromTypes(
        startTime: weekAgo,
        endTime: now,
        types: [HealthDataType.HEART_RATE],
      );

      if (data.isEmpty) return null;
      final values = data
          .map((d) => (d.value as NumericHealthValue).numericValue)
          .toList();
      return values.reduce((a, b) => a + b) / values.length;
    } catch (_) {
      return null;
    }
  }

  /// Leggi ore di sonno ultima notte
  Future<double?> getLastNightSleepHours() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    try {
      final data = await _health.getHealthDataFromTypes(
        startTime: yesterday,
        endTime: now,
        types: [HealthDataType.SLEEP_ASLEEP],
      );

      if (data.isEmpty) return null;
      final totalMinutes = data
          .map((d) => (d.value as NumericHealthValue).numericValue)
          .fold(0.0, (a, b) => a + b);
      return totalMinutes / 60.0;
    } catch (_) {
      return null;
    }
  }
}
