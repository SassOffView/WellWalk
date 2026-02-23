import 'package:equatable/equatable.dart';

enum WalkState { idle, active, paused, completed }

class WalkPosition {
  const WalkPosition({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.accuracy,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double accuracy; // metres

  Map<String, dynamic> toJson() => {
    'lat': latitude,
    'lng': longitude,
    'ts': timestamp.toIso8601String(),
    'acc': accuracy,
  };

  factory WalkPosition.fromJson(Map<String, dynamic> json) => WalkPosition(
    latitude: (json['lat'] as num).toDouble(),
    longitude: (json['lng'] as num).toDouble(),
    timestamp: DateTime.parse(json['ts'] as String),
    accuracy: (json['acc'] as num).toDouble(),
  );
}

class WalkSession extends Equatable {
  const WalkSession({
    required this.id,
    required this.startedAt,
    required this.state,
    this.distanceMeters = 0.0,
    this.activeMilliseconds = 0,
    this.positions = const [],
    this.pausedAt,
    this.completedAt,
    this.maxSpeedKmh = 0.0,
  });

  final String id;
  final DateTime startedAt;
  final WalkState state;
  final double distanceMeters;
  final int activeMilliseconds;       // Tempo ATTIVO (esclude pause)
  final List<WalkPosition> positions;
  final DateTime? pausedAt;
  final DateTime? completedAt;
  final double maxSpeedKmh;

  // ── Computed ────────────────────────────────────────────────────────
  double get distanceKm => distanceMeters / 1000.0;

  int get activeSeconds => (activeMilliseconds / 1000).round();

  int get activeMinutes => (activeMilliseconds / 60000).round();

  /// Velocità media km/h (solo quando la sessione è in corso o completata)
  double get avgSpeedKmh {
    final hours = activeMilliseconds / 3600000.0;
    if (hours <= 0) return 0.0;
    return distanceKm / hours;
  }

  /// Calorie bruciate: formula semplice (distanza_km * peso_kg * 1.036)
  double caloriesBurned({double weightKg = 65.0}) =>
      distanceKm * weightKg * 1.036;

  bool get isActive => state == WalkState.active;
  bool get isPaused => state == WalkState.paused;
  bool get isCompleted => state == WalkState.completed;

  WalkSession copyWith({
    WalkState? state,
    double? distanceMeters,
    int? activeMilliseconds,
    List<WalkPosition>? positions,
    DateTime? pausedAt,
    DateTime? completedAt,
    double? maxSpeedKmh,
  }) {
    return WalkSession(
      id: id,
      startedAt: startedAt,
      state: state ?? this.state,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      activeMilliseconds: activeMilliseconds ?? this.activeMilliseconds,
      positions: positions ?? this.positions,
      pausedAt: pausedAt ?? this.pausedAt,
      completedAt: completedAt ?? this.completedAt,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'state': state.index,
    'distanceMeters': distanceMeters,
    'activeMilliseconds': activeMilliseconds,
    'positions': positions.map((p) => p.toJson()).toList(),
    'pausedAt': pausedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'maxSpeedKmh': maxSpeedKmh,
  };

  factory WalkSession.fromJson(Map<String, dynamic> json) => WalkSession(
    id: json['id'] as String,
    startedAt: DateTime.parse(json['startedAt'] as String),
    state: WalkState.values[json['state'] as int],
    distanceMeters: (json['distanceMeters'] as num).toDouble(),
    activeMilliseconds: json['activeMilliseconds'] as int,
    positions: (json['positions'] as List<dynamic>)
        .map((p) => WalkPosition.fromJson(p as Map<String, dynamic>))
        .toList(),
    pausedAt: json['pausedAt'] != null
        ? DateTime.parse(json['pausedAt'] as String)
        : null,
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'] as String)
        : null,
    maxSpeedKmh: (json['maxSpeedKmh'] as num?)?.toDouble() ?? 0.0,
  );

  @override
  List<Object?> get props =>
      [id, startedAt, state, distanceMeters, activeMilliseconds, completedAt];
}
