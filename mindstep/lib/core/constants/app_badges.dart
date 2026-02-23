import '../models/badge_model.dart';

/// Definizione completa dei 20 badge — con bug risolti rispetto alla PWA
class AppBadges {
  AppBadges._();

  static const List<BadgeModel> all = [
    // ── CAMMINATA ──────────────────────────────────────────────────────
    BadgeModel(
      id: 'first_walk',
      name: 'Primo Passo',
      description: 'Completa la tua prima camminata',
      unlockMessage: 'Ogni grande viaggio inizia con un solo passo. Il tuo è appena cominciato.',
      icon: 'shoe_track',
      category: BadgeCategory.walk,
      type: BadgeType.totalWalks,
      requiredValue: 1,
      tier: BadgeTier.free,
    ),
    BadgeModel(
      id: 'walk_10',
      name: 'Esploratore',
      description: '10 camminate completate',
      unlockMessage: 'Dieci camminate, dieci storie. Stai costruendo qualcosa di bello.',
      icon: 'map_route',
      category: BadgeCategory.walk,
      type: BadgeType.totalWalks,
      requiredValue: 10,
      tier: BadgeTier.free,
    ),
    BadgeModel(
      id: 'walk_50',
      name: 'Camminatore',
      description: '50 camminate totali',
      unlockMessage: 'Cinquanta volte hai scelto di muoverti. Sei un vero camminatore.',
      icon: 'hiking_boot',
      category: BadgeCategory.walk,
      type: BadgeType.totalWalks,
      requiredValue: 50,
      tier: BadgeTier.pro,
    ),
    BadgeModel(
      id: 'walk_100',
      name: 'Centurione',
      description: '100 camminate totali',
      unlockMessage: 'Cento passi verso una vita migliore. Sei straordinario.',
      icon: 'medal_100',
      category: BadgeCategory.walk,
      type: BadgeType.totalWalks,
      requiredValue: 100,
      tier: BadgeTier.pro,
    ),

    // ── DISTANZA ───────────────────────────────────────────────────────
    BadgeModel(
      id: 'km_5',
      name: 'Cinque Km',
      description: '5 km totali percorsi',
      unlockMessage: '5 km di strada percorsa. Il corpo ti ringrazia.',
      icon: 'finish_flag',
      category: BadgeCategory.distance,
      type: BadgeType.totalDistance,
      requiredValue: 5,
      tier: BadgeTier.free,
    ),
    BadgeModel(
      id: 'km_10',
      name: 'Decathlon',
      description: '10 km totali percorsi',
      unlockMessage: '10 km. Ogni chilometro è una scelta di vivere bene.',
      icon: 'target_bullseye',
      category: BadgeCategory.distance,
      type: BadgeType.totalDistance,
      requiredValue: 10,
      tier: BadgeTier.free,
    ),
    BadgeModel(
      id: 'km_50',
      name: 'Mezzo Centenario',
      description: '50 km totali percorsi',
      unlockMessage: '50 km sotto i piedi. Stai riscrivendo i tuoi limiti.',
      icon: 'star_50',
      category: BadgeCategory.distance,
      type: BadgeType.totalDistance,
      requiredValue: 50,
      tier: BadgeTier.pro,
    ),
    BadgeModel(
      id: 'km_100',
      name: 'Centochilomentri',
      description: '100 km totali percorsi',
      unlockMessage: '100 km. Una distanza che racconta chi sei diventato.',
      icon: 'trophy_gold',
      category: BadgeCategory.distance,
      type: BadgeType.totalDistance,
      requiredValue: 100,
      tier: BadgeTier.pro,
    ),

    // ── DURATA ─────────────────────────────────────────────────────────
    BadgeModel(
      id: 'time_20',
      name: 'Venti Minuti',
      description: 'Camminata di almeno 20 minuti',
      unlockMessage: '20 minuti di presenza. La mente si è già ringraziata.',
      icon: 'timer_20',
      category: BadgeCategory.duration,
      type: BadgeType.singleWalkMinutes,
      requiredValue: 20,
      tier: BadgeTier.free,
    ),
    BadgeModel(
      id: 'time_40',
      name: 'Quaranta Minuti',
      description: 'Camminata di almeno 40 minuti',
      unlockMessage: '40 minuti di libertà. Questo è il tuo tempo, ben speso.',
      icon: 'hourglass_full',
      category: BadgeCategory.duration,
      type: BadgeType.singleWalkMinutes,
      requiredValue: 40,
      tier: BadgeTier.free,
    ),
    BadgeModel(
      id: 'time_60',
      name: 'L\'Ora Intera',
      description: 'Camminata di almeno 60 minuti',
      unlockMessage: 'Un\'ora. Non tutti hanno questa dedizione. Tu sì.',
      icon: 'clock_crown',
      category: BadgeCategory.duration,
      type: BadgeType.singleWalkMinutes,
      requiredValue: 60,
      tier: BadgeTier.pro,
    ),

    // ── ROUTINE ────────────────────────────────────────────────────────
    BadgeModel(
      id: 'routine_first',
      name: 'Inizio',
      description: 'Prima routine completata',
      unlockMessage: 'La prima volta è sempre la più importante. Ottimo inizio.',
      icon: 'seedling',
      category: BadgeCategory.routine,
      type: BadgeType.firstRoutine,
      requiredValue: 1,
      tier: BadgeTier.free,
    ),
    BadgeModel(
      id: 'routine_50pct',
      name: 'A Metà',
      description: '50% delle routine completate in un giorno',
      unlockMessage: 'Metà fatta è già un grande risultato. Continua così.',
      icon: 'chart_half',
      category: BadgeCategory.routine,
      type: BadgeType.routinePercentage,
      requiredValue: 50,
      tier: BadgeTier.free,
    ),
    BadgeModel(
      id: 'routine_100pct',
      name: 'Perfetto',
      description: '100% delle routine completate in un giorno',
      unlockMessage: 'Giornata perfetta. Tutte le abitudini completate. Sei inarrestabile.',
      icon: 'star_check',
      category: BadgeCategory.routine,
      type: BadgeType.routinePercentage,
      requiredValue: 100,
      tier: BadgeTier.free,
    ),

    // ── STREAK ─────────────────────────────────────────────────────────
    BadgeModel(
      id: 'streak_7',
      name: 'Settimana di Fuoco',
      description: '7 giorni consecutivi di attività',
      unlockMessage: '7 giorni senza fermarsi. Stai creando un\'abitudine vera.',
      icon: 'flame_7',
      category: BadgeCategory.streak,
      type: BadgeType.streak,
      requiredValue: 7,
      tier: BadgeTier.free,
    ),
    BadgeModel(
      id: 'streak_30',
      name: 'Guerriero del Mese',
      description: '30 giorni consecutivi di attività',
      unlockMessage: 'Un mese intero. Questa non è più un\'abitudine, è il tuo stile di vita.',
      icon: 'lightning_crown',
      category: BadgeCategory.streak,
      type: BadgeType.streak,
      requiredValue: 30,
      tier: BadgeTier.pro,
    ),
    BadgeModel(
      id: 'streak_90',
      name: 'Mente di Acciaio',
      description: '90 giorni consecutivi di attività',
      unlockMessage: '90 giorni. Hai trasformato te stesso. Questo è il cambiamento reale.',
      icon: 'diamond',
      category: BadgeCategory.streak,
      type: BadgeType.streak,
      requiredValue: 90,
      tier: BadgeTier.pro,
    ),

    // ── MENTE ──────────────────────────────────────────────────────────
    BadgeModel(
      id: 'brain_first',
      name: 'Primo Pensiero',
      description: 'Prima nota brainstorm salvata',
      unlockMessage: 'Hai iniziato a dare voce ai tuoi pensieri. La mente cammina con te.',
      icon: 'thought_bubble',
      category: BadgeCategory.brainstorm,
      type: BadgeType.firstBrainstorm,
      requiredValue: 1,
      tier: BadgeTier.free,
    ),
    BadgeModel(
      id: 'brain_10',
      name: 'Pensatore',
      description: '10 note brainstorm salvate',
      unlockMessage: 'Dieci idee catturate. Ogni pensiero scritto vale oro.',
      icon: 'brain_waves',
      category: BadgeCategory.brainstorm,
      type: BadgeType.totalBrainstorms,
      requiredValue: 10,
      tier: BadgeTier.pro,
    ),

    // ── SPECIALE ───────────────────────────────────────────────────────
    BadgeModel(
      id: 'special_combo',
      name: 'Mente e Corpo',
      description: 'Walk + Routine + Brainstorm nello stesso giorno',
      unlockMessage: 'Corpo, mente e abitudini in un solo giorno. Sei completo.',
      icon: 'wave_double',
      category: BadgeCategory.special,
      type: BadgeType.dailyCombo,
      requiredValue: 1,
      tier: BadgeTier.pro,
    ),
  ];

  /// Badge disponibili per utenti Free (i primi 10 nell'elenco)
  static List<BadgeModel> get freeOnly =>
      all.where((b) => b.tier == BadgeTier.free).toList();

  /// Tutti i badge (Pro)
  static List<BadgeModel> get proAll => all;

  /// Trova badge per ID
  static BadgeModel? findById(String id) {
    try {
      return all.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}
