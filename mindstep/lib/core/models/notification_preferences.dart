import 'package:equatable/equatable.dart';

/// Preferenze notifiche impostate dall'utente durante l'onboarding
class NotificationPreferences extends Equatable {
  const NotificationPreferences({
    this.dailyReminderEnabled = true,
    this.dailyReminderHour = 8,
    this.dailyReminderMinute = 0,
    this.walkReminderEnabled = false,
    this.walkReminderHour = 18,
    this.walkReminderMinute = 0,
    this.routineReminderEnabled = true,
    this.routineReminderHour = 9,
    this.routineReminderMinute = 0,
    this.brainReminderEnabled = false,
    this.brainReminderHour = 21,
    this.brainReminderMinute = 0,
    this.streakWarningEnabled = true,
  });

  /// Notifica motivazionale giornaliera (con contenuto AI se configurato)
  final bool dailyReminderEnabled;
  final int dailyReminderHour;
  final int dailyReminderMinute;

  /// Reminder per iniziare la camminata
  final bool walkReminderEnabled;
  final int walkReminderHour;
  final int walkReminderMinute;

  /// Reminder per completare le routine
  final bool routineReminderEnabled;
  final int routineReminderHour;
  final int routineReminderMinute;

  /// Walking Brain reminder (Pro only)
  final bool brainReminderEnabled;
  final int brainReminderHour;
  final int brainReminderMinute;

  /// Avviso streak a rischio (sera, fisso alle 20:00)
  final bool streakWarningEnabled;

  String get dailyReminderTimeLabel =>
      '${dailyReminderHour.toString().padLeft(2, '0')}:'
      '${dailyReminderMinute.toString().padLeft(2, '0')}';

  String get walkReminderTimeLabel =>
      '${walkReminderHour.toString().padLeft(2, '0')}:'
      '${walkReminderMinute.toString().padLeft(2, '0')}';

  String get routineReminderTimeLabel =>
      '${routineReminderHour.toString().padLeft(2, '0')}:'
      '${routineReminderMinute.toString().padLeft(2, '0')}';

  String get brainReminderTimeLabel =>
      '${brainReminderHour.toString().padLeft(2, '0')}:'
      '${brainReminderMinute.toString().padLeft(2, '0')}';

  NotificationPreferences copyWith({
    bool? dailyReminderEnabled,
    int? dailyReminderHour,
    int? dailyReminderMinute,
    bool? walkReminderEnabled,
    int? walkReminderHour,
    int? walkReminderMinute,
    bool? routineReminderEnabled,
    int? routineReminderHour,
    int? routineReminderMinute,
    bool? brainReminderEnabled,
    int? brainReminderHour,
    int? brainReminderMinute,
    bool? streakWarningEnabled,
  }) {
    return NotificationPreferences(
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderHour: dailyReminderHour ?? this.dailyReminderHour,
      dailyReminderMinute: dailyReminderMinute ?? this.dailyReminderMinute,
      walkReminderEnabled: walkReminderEnabled ?? this.walkReminderEnabled,
      walkReminderHour: walkReminderHour ?? this.walkReminderHour,
      walkReminderMinute: walkReminderMinute ?? this.walkReminderMinute,
      routineReminderEnabled: routineReminderEnabled ?? this.routineReminderEnabled,
      routineReminderHour: routineReminderHour ?? this.routineReminderHour,
      routineReminderMinute: routineReminderMinute ?? this.routineReminderMinute,
      brainReminderEnabled: brainReminderEnabled ?? this.brainReminderEnabled,
      brainReminderHour: brainReminderHour ?? this.brainReminderHour,
      brainReminderMinute: brainReminderMinute ?? this.brainReminderMinute,
      streakWarningEnabled: streakWarningEnabled ?? this.streakWarningEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'dailyReminderEnabled': dailyReminderEnabled,
    'dailyReminderHour': dailyReminderHour,
    'dailyReminderMinute': dailyReminderMinute,
    'walkReminderEnabled': walkReminderEnabled,
    'walkReminderHour': walkReminderHour,
    'walkReminderMinute': walkReminderMinute,
    'routineReminderEnabled': routineReminderEnabled,
    'routineReminderHour': routineReminderHour,
    'routineReminderMinute': routineReminderMinute,
    'brainReminderEnabled': brainReminderEnabled,
    'brainReminderHour': brainReminderHour,
    'brainReminderMinute': brainReminderMinute,
    'streakWarningEnabled': streakWarningEnabled,
  };

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        dailyReminderEnabled: json['dailyReminderEnabled'] as bool? ?? true,
        dailyReminderHour: json['dailyReminderHour'] as int? ?? 8,
        dailyReminderMinute: json['dailyReminderMinute'] as int? ?? 0,
        walkReminderEnabled: json['walkReminderEnabled'] as bool? ?? false,
        walkReminderHour: json['walkReminderHour'] as int? ?? 18,
        walkReminderMinute: json['walkReminderMinute'] as int? ?? 0,
        routineReminderEnabled: json['routineReminderEnabled'] as bool? ?? true,
        routineReminderHour: json['routineReminderHour'] as int? ?? 9,
        routineReminderMinute: json['routineReminderMinute'] as int? ?? 0,
        brainReminderEnabled: json['brainReminderEnabled'] as bool? ?? false,
        brainReminderHour: json['brainReminderHour'] as int? ?? 21,
        brainReminderMinute: json['brainReminderMinute'] as int? ?? 0,
        streakWarningEnabled: json['streakWarningEnabled'] as bool? ?? true,
      );

  static const NotificationPreferences defaults = NotificationPreferences();

  @override
  List<Object?> get props => [
    dailyReminderEnabled, dailyReminderHour, dailyReminderMinute,
    walkReminderEnabled, walkReminderHour, walkReminderMinute,
    routineReminderEnabled, routineReminderHour, routineReminderMinute,
    brainReminderEnabled, brainReminderHour, brainReminderMinute,
    streakWarningEnabled,
  ];
}
