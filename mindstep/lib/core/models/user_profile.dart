import 'package:equatable/equatable.dart';

enum Gender { male, female, other }

class UserProfile extends Equatable {
  const UserProfile({
    required this.name,
    required this.age,
    required this.gender,
    required this.createdAt,
    this.weightKg,
    this.customMusicUrl,
    this.hasCompletedOnboarding = false,
    this.hasBrainstormedEver = false,
    this.totalBrainstormCount = 0,
    this.stepGoal = 8000,
    this.walkMinutesGoal = 30,
    this.brainstormMinutesGoal = 10,
    this.dailyVoiceSessionsGoal = 2,
    this.preferredLanguage = 'it',
  });

  final String name;
  final int age;
  final Gender gender;
  final DateTime createdAt;
  final double? weightKg;
  final String? customMusicUrl;
  final bool hasCompletedOnboarding;

  /// TRUE dopo il PRIMO brainstorm mai salvato (globale, non per-giorno)
  final bool hasBrainstormedEver;
  final int totalBrainstormCount;

  // ── Daily goals ──────────────────────────────────────────────────────
  final int stepGoal;                // passi obiettivo giornaliero
  final int walkMinutesGoal;         // minuti camminata obiettivo
  final int brainstormMinutesGoal;   // minuti brainstorm obiettivo
  final int dailyVoiceSessionsGoal;  // sessioni voice obiettivo
  final String preferredLanguage;    // 'it' | 'en'

  String get firstName => name.split(' ').first;

  String get genderLabel {
    switch (gender) {
      case Gender.male:   return 'Uomo';
      case Gender.female: return 'Donna';
      case Gender.other:  return 'Altro';
    }
  }

  double get effectiveWeightKg => weightKg ?? 65.0;

  UserProfile copyWith({
    String? name,
    int? age,
    Gender? gender,
    DateTime? createdAt,
    double? weightKg,
    String? customMusicUrl,
    bool? hasCompletedOnboarding,
    bool? hasBrainstormedEver,
    int? totalBrainstormCount,
    int? stepGoal,
    int? walkMinutesGoal,
    int? brainstormMinutesGoal,
    int? dailyVoiceSessionsGoal,
    String? preferredLanguage,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
      weightKg: weightKg ?? this.weightKg,
      customMusicUrl: customMusicUrl ?? this.customMusicUrl,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      hasBrainstormedEver: hasBrainstormedEver ?? this.hasBrainstormedEver,
      totalBrainstormCount: totalBrainstormCount ?? this.totalBrainstormCount,
      stepGoal: stepGoal ?? this.stepGoal,
      walkMinutesGoal: walkMinutesGoal ?? this.walkMinutesGoal,
      brainstormMinutesGoal: brainstormMinutesGoal ?? this.brainstormMinutesGoal,
      dailyVoiceSessionsGoal: dailyVoiceSessionsGoal ?? this.dailyVoiceSessionsGoal,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'age': age,
    'gender': gender.index,
    'createdAt': createdAt.toIso8601String(),
    'weightKg': weightKg,
    'customMusicUrl': customMusicUrl,
    'hasCompletedOnboarding': hasCompletedOnboarding,
    'hasBrainstormedEver': hasBrainstormedEver,
    'totalBrainstormCount': totalBrainstormCount,
    'stepGoal': stepGoal,
    'walkMinutesGoal': walkMinutesGoal,
    'brainstormMinutesGoal': brainstormMinutesGoal,
    'dailyVoiceSessionsGoal': dailyVoiceSessionsGoal,
    'preferredLanguage': preferredLanguage,
  };

  factory UserProfile.guest() => UserProfile(
    name: '',
    age: 0,
    gender: Gender.other,
    createdAt: DateTime.now(),
  );

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] as String,
    age: json['age'] as int,
    gender: Gender.values[json['gender'] as int],
    createdAt: DateTime.parse(json['createdAt'] as String),
    weightKg: (json['weightKg'] as num?)?.toDouble(),
    customMusicUrl: json['customMusicUrl'] as String?,
    hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool? ?? false,
    hasBrainstormedEver: json['hasBrainstormedEver'] as bool? ?? false,
    totalBrainstormCount: json['totalBrainstormCount'] as int? ?? 0,
    stepGoal: json['stepGoal'] as int? ?? 8000,
    walkMinutesGoal: json['walkMinutesGoal'] as int? ?? 30,
    brainstormMinutesGoal: json['brainstormMinutesGoal'] as int? ?? 10,
    dailyVoiceSessionsGoal: json['dailyVoiceSessionsGoal'] as int? ?? 2,
    preferredLanguage: json['preferredLanguage'] as String? ?? 'it',
  );

  @override
  List<Object?> get props => [
    name, age, gender, createdAt, weightKg,
    customMusicUrl, hasCompletedOnboarding,
    hasBrainstormedEver, totalBrainstormCount,
    stepGoal, walkMinutesGoal, brainstormMinutesGoal,
    dailyVoiceSessionsGoal, preferredLanguage,
  ];
}
