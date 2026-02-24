/// Modello per un singolo "momento di chiarezza" completato dall'utente.
/// Corrisponde a una riga nella tabella `sessions` del DB locale.
class SessionData {
  const SessionData({
    required this.id,
    required this.date,
    required this.motivationalPhrase,
    this.userInput = '',
    this.durationSeconds = 0,
    this.hadWalk = false,
    this.inferredMood = 'normale',
  });

  final String id;
  final DateTime date;

  /// Frase motivazionale mostrata durante la sessione
  final String motivationalPhrase;

  /// Testo scritto o parlato dall'utente nel micro-prompt
  final String userInput;

  /// Durata totale della sessione in secondi
  final int durationSeconds;

  /// Se l'utente ha avviato anche una camminata GPS durante la sessione
  final bool hadWalk;

  /// Stato emotivo inferito dal comportamento ('primo_giorno', 'normale',
  /// 'distante', 'rientro')
  final String inferredMood;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'motivational_phrase': motivationalPhrase,
    'user_input': userInput,
    'duration_seconds': durationSeconds,
    'had_walk': hadWalk ? 1 : 0,
    'inferred_mood': inferredMood,
  };

  factory SessionData.fromJson(Map<String, dynamic> json) => SessionData(
    id: json['id'] as String,
    date: DateTime.parse(json['date'] as String),
    motivationalPhrase: json['motivational_phrase'] as String? ?? '',
    userInput: json['user_input'] as String? ?? '',
    durationSeconds: json['duration_seconds'] as int? ?? 0,
    hadWalk: (json['had_walk'] as int? ?? 0) == 1,
    inferredMood: json['inferred_mood'] as String? ?? 'normale',
  );
}
