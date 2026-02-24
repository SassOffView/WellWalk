import 'package:equatable/equatable.dart';
import 'walk_session.dart';

/// Dati aggregati per un singolo giorno
class DayData extends Equatable {
  const DayData({
    required this.date,
    this.walk,
    this.routineIds = const [],
    this.completedRoutineIds = const [],
    this.brainstormNote = '',
    this.brainstormCount = 0,
    this.brainstormMinutes = 0,
  });

  final DateTime date;
  final WalkSession? walk;
  final List<String> routineIds;
  final List<String> completedRoutineIds;
  final String brainstormNote;
  final int brainstormCount;
  final int brainstormMinutes; // minuti totali di brainstorm oggi

  // ── Computed ────────────────────────────────────────────────────────
  String get dateKey {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  bool get hasWalk => walk != null;
  bool get hasBrainstorm => brainstormNote.isNotEmpty;
  int get routineTotal => routineIds.length;
  int get routineCompleted => completedRoutineIds.length;

  double get routinePercent {
    if (routineTotal == 0) return 0.0;
    return (routineCompleted / routineTotal) * 100.0;
  }

  bool get isActive =>
      hasWalk || routineCompleted > 0 || hasBrainstorm;

  bool get hasAllRoutinesDone =>
      routineTotal > 0 && routineCompleted >= routineTotal;

  bool get hasHalfRoutinesDone =>
      routineTotal > 0 && routinePercent >= 50;

  bool get hasDailyCombo =>
      hasWalk && routineCompleted > 0 && hasBrainstorm;

  DayData copyWith({
    WalkSession? walk,
    List<String>? routineIds,
    List<String>? completedRoutineIds,
    String? brainstormNote,
    int? brainstormCount,
    int? brainstormMinutes,
  }) {
    return DayData(
      date: date,
      walk: walk ?? this.walk,
      routineIds: routineIds ?? this.routineIds,
      completedRoutineIds: completedRoutineIds ?? this.completedRoutineIds,
      brainstormNote: brainstormNote ?? this.brainstormNote,
      brainstormCount: brainstormCount ?? this.brainstormCount,
      brainstormMinutes: brainstormMinutes ?? this.brainstormMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'walk': walk?.toJson(),
    'routineIds': routineIds,
    'completedRoutineIds': completedRoutineIds,
    'brainstormNote': brainstormNote,
    'brainstormCount': brainstormCount,
    'brainstormMinutes': brainstormMinutes,
  };

  factory DayData.fromJson(Map<String, dynamic> json) => DayData(
    date: DateTime.parse(json['date'] as String),
    walk: json['walk'] != null
        ? WalkSession.fromJson(json['walk'] as Map<String, dynamic>)
        : null,
    routineIds: (json['routineIds'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList() ?? [],
    completedRoutineIds: (json['completedRoutineIds'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList() ?? [],
    brainstormNote: json['brainstormNote'] as String? ?? '',
    brainstormCount: json['brainstormCount'] as int? ?? 0,
    brainstormMinutes: json['brainstormMinutes'] as int? ?? 0,
  );

  factory DayData.empty(DateTime date) => DayData(date: date);

  @override
  List<Object?> get props =>
      [date, walk, routineIds, completedRoutineIds, brainstormNote, brainstormCount, brainstormMinutes];
}
