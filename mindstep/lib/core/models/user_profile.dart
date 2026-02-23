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
    this.hasBrainstormedEver = false, // FLAG GLOBALE (fix bug PWA)
    this.totalBrainstormCount = 0,
  });

  final String name;
  final int age;
  final Gender gender;
  final DateTime createdAt;
  final double? weightKg;
  final String? customMusicUrl;
  final bool hasCompletedOnboarding;

  /// TRUE dopo il PRIMO brainstorm mai salvato (globale, non per-giorno)
  /// Questo risolve il bug della PWA dove firstBrainstorm era per-giorno
  final bool hasBrainstormedEver;
  final int totalBrainstormCount;

  String get firstName => name.split(' ').first;

  String get genderLabel {
    switch (gender) {
      case Gender.male:
        return 'Uomo';
      case Gender.female:
        return 'Donna';
      case Gender.other:
        return 'Altro';
    }
  }

  // Peso di default per calcolo calorie (65kg se non specificato)
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
  };

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
  );

  @override
  List<Object?> get props => [
    name, age, gender, createdAt, weightKg,
    customMusicUrl, hasCompletedOnboarding,
    hasBrainstormedEver, totalBrainstormCount,
  ];
}
