import 'package:equatable/equatable.dart';

enum BadgeCategory { walk, distance, duration, routine, streak, brainstorm, special }

enum BadgeTier { free, pro }

/// Tipo di condizione per sbloccare il badge
enum BadgeType {
  totalWalks,          // Numero camminate totali
  totalDistance,       // Km totali percorsi
  singleWalkMinutes,   // Minuti in una singola camminata
  firstRoutine,        // Prima routine completata (qualsiasi)
  routinePercentage,   // % routine completate in un giorno
  streak,              // Giorni consecutivi
  firstBrainstorm,     // Prima nota globale (FLAG GLOBALE, non per giorno)
  totalBrainstorms,    // Note totali salvate
  dailyCombo,          // Walk + Routine + Brainstorm stesso giorno
}

class BadgeModel extends Equatable {
  const BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.unlockMessage,
    required this.icon,
    required this.category,
    required this.type,
    required this.requiredValue,
    required this.tier,
  });

  final String id;
  final String name;
  final String description;
  final String unlockMessage;
  final String icon;           // nome icona SVG in assets/icons/badges/
  final BadgeCategory category;
  final BadgeType type;
  final int requiredValue;
  final BadgeTier tier;

  bool get isFree => tier == BadgeTier.free;
  bool get isPro => tier == BadgeTier.pro;

  String get categoryLabel {
    switch (category) {
      case BadgeCategory.walk:
        return 'Camminata';
      case BadgeCategory.distance:
        return 'Distanza';
      case BadgeCategory.duration:
        return 'Durata';
      case BadgeCategory.routine:
        return 'Routine';
      case BadgeCategory.streak:
        return 'Streak';
      case BadgeCategory.brainstorm:
        return 'Mente';
      case BadgeCategory.special:
        return 'Speciale';
    }
  }

  @override
  List<Object?> get props =>
      [id, name, description, icon, category, type, requiredValue, tier];
}

/// Stato di un badge per un utente specifico
class BadgeStatus extends Equatable {
  const BadgeStatus({
    required this.badge,
    required this.isUnlocked,
    this.unlockedAt,
  });

  final BadgeModel badge;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  BadgeStatus copyWith({bool? isUnlocked, DateTime? unlockedAt}) {
    return BadgeStatus(
      badge: badge,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': badge.id,
    'isUnlocked': isUnlocked,
    'unlockedAt': unlockedAt?.toIso8601String(),
  };

  @override
  List<Object?> get props => [badge.id, isUnlocked, unlockedAt];
}
