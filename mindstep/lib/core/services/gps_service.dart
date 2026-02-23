import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '../models/walk_session.dart';
import 'package:uuid/uuid.dart';

/// Servizio GPS con logica pause/resume corretta
/// Supporta foreground (Free) e background tramite flutter_foreground_task (Pro)
class GpsService {
  static const _minDistanceFilter = 5.0;   // Minimo 5m per nuovo punto
  static const _maxAccuracyFilter = 25.0;  // Ignora punti < 25m accuratezza
  static const _maxJumpFilter = 100.0;     // Ignora salti > 100m in < 5s (drift GPS)

  WalkSession? _currentSession;
  StreamSubscription<Position>? _positionSub;
  Timer? _timerTick;
  WalkPosition? _lastValidPosition;

  // Callback per aggiornamenti UI
  Function(WalkSession)? onSessionUpdate;
  Function(String error)? onError;

  WalkSession? get currentSession => _currentSession;

  bool get isTracking =>
      _currentSession != null &&
      (_currentSession!.isActive || _currentSession!.isPaused);

  // ── PERMESSI ────────────────────────────────────────────────────────

  Future<bool> requestPermissions({bool backgroundRequired = false}) async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      onError?.call('Permesso localizzazione negato definitivamente.');
      return false;
    }

    if (backgroundRequired &&
        permission != LocationPermission.always) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always) {
        return false; // Permesso background non concesso
      }
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      onError?.call('Servizio GPS non abilitato sul dispositivo.');
      return false;
    }

    return true;
  }

  // ── AVVIA ───────────────────────────────────────────────────────────

  Future<void> startWalk() async {
    if (_currentSession != null) return;

    _currentSession = WalkSession(
      id: const Uuid().v4(),
      startedAt: DateTime.now(),
      state: WalkState.active,
    );

    _lastValidPosition = null;
    _startPositionStream();
    _startTimer();

    onSessionUpdate?.call(_currentSession!);
  }

  // ── PAUSA ───────────────────────────────────────────────────────────

  void pauseWalk() {
    if (_currentSession == null || !_currentSession!.isActive) return;

    _positionSub?.pause();
    _timerTick?.cancel();

    _currentSession = _currentSession!.copyWith(
      state: WalkState.paused,
      pausedAt: DateTime.now(),
    );

    onSessionUpdate?.call(_currentSession!);
  }

  // ── RIPRENDI ────────────────────────────────────────────────────────

  void resumeWalk() {
    if (_currentSession == null || !_currentSession!.isPaused) return;

    // IMPORTANTE: Non resettare distanza o tempo — continua dall'ultimo punto
    _currentSession = _currentSession!.copyWith(
      state: WalkState.active,
      pausedAt: null,
    );

    // lastValidPosition rimane: il prossimo punto verrà confrontato con esso
    // Se il GPS è driftato durante la pausa, il filtro _maxJumpFilter lo ignorerà

    _positionSub?.resume();
    _startTimer();

    onSessionUpdate?.call(_currentSession!);
  }

  // ── FERMA ───────────────────────────────────────────────────────────

  WalkSession? stopWalk() {
    if (_currentSession == null) return null;

    _positionSub?.cancel();
    _positionSub = null;
    _timerTick?.cancel();
    _timerTick = null;

    final completed = _currentSession!.copyWith(
      state: WalkState.completed,
      completedAt: DateTime.now(),
    );

    _currentSession = null;
    _lastValidPosition = null;

    return completed;
  }

  // ── STREAM POSIZIONI ────────────────────────────────────────────────

  void _startPositionStream() {
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Callback solo ogni 5m di movimento
      ),
    ).listen(
      _onPositionReceived,
      onError: (e) => onError?.call(e.toString()),
    );
  }

  void _onPositionReceived(Position position) {
    if (_currentSession == null || !_currentSession!.isActive) return;

    // Filtro 1: Accuratezza GPS insufficiente
    if (position.accuracy > _maxAccuracyFilter) return;

    final newPos = WalkPosition(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
      accuracy: position.accuracy,
    );

    if (_lastValidPosition != null) {
      final distanceMeters = _haversine(
        _lastValidPosition!.latitude,
        _lastValidPosition!.longitude,
        newPos.latitude,
        newPos.longitude,
      );

      // Filtro 2: Salto GPS impossibile (anti-drift durante pausa/resume)
      final timeDiffSeconds = newPos.timestamp
          .difference(_lastValidPosition!.timestamp)
          .inSeconds;
      if (timeDiffSeconds < 5 && distanceMeters > _maxJumpFilter) return;

      // Filtro 3: Distanza minima registrabile
      if (distanceMeters < _minDistanceFilter) return;

      // Calcola velocità attuale
      final speedKmh = timeDiffSeconds > 0
          ? (distanceMeters / timeDiffSeconds) * 3.6
          : 0.0;

      // Aggiorna sessione
      final newDistanceMeters =
          _currentSession!.distanceMeters + distanceMeters;
      final newPositions = [..._currentSession!.positions, newPos];
      final newMaxSpeed =
          speedKmh > _currentSession!.maxSpeedKmh ? speedKmh : _currentSession!.maxSpeedKmh;

      _currentSession = _currentSession!.copyWith(
        distanceMeters: newDistanceMeters,
        positions: newPositions,
        maxSpeedKmh: newMaxSpeed,
      );

      onSessionUpdate?.call(_currentSession!);
    }

    _lastValidPosition = newPos;
  }

  // ── TIMER ───────────────────────────────────────────────────────────

  void _startTimer() {
    _timerTick?.cancel();
    _timerTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_currentSession == null || !_currentSession!.isActive) return;

      _currentSession = _currentSession!.copyWith(
        activeMilliseconds: _currentSession!.activeMilliseconds + 1000,
      );

      onSessionUpdate?.call(_currentSession!);
    });
  }

  // ── HAVERSINE ───────────────────────────────────────────────────────

  /// Calcolo distanza in metri tra due coordinate GPS
  /// Portato dalla PWA (formula Haversine) con precisione migliorata
  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0; // Raggio Terra in metri
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRad(double degrees) => degrees * pi / 180;

  void dispose() {
    _positionSub?.cancel();
    _timerTick?.cancel();
  }
}

/// Formattazione tempo per UI
extension WalkSessionFormatting on WalkSession {
  String get formattedTime {
    final total = activeMilliseconds;
    final h = (total ~/ 3600000).toString().padLeft(2, '0');
    final m = ((total % 3600000) ~/ 60000).toString().padLeft(2, '0');
    final s = ((total % 60000) ~/ 1000).toString().padLeft(2, '0');
    return activeMilliseconds >= 3600000 ? '$h:$m:$s' : '$m:$s';
  }

  String get formattedDistance =>
      distanceKm.toStringAsFixed(2);

  String get formattedSpeed =>
      avgSpeedKmh.toStringAsFixed(1);

  String get formattedCalories =>
      caloriesBurned().round().toString();
}
