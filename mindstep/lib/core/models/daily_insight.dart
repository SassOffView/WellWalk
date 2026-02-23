import 'package:equatable/equatable.dart';

/// Insight giornaliero generato dall'AI
class DailyInsight extends Equatable {
  const DailyInsight({
    required this.date,
    required this.insight,
    required this.suggestion,
    required this.brainstormPrompt,
    required this.motivationalMessage,
    required this.generatedBy,
    this.routineTip,
    this.walkTip,
  });

  final DateTime date;

  /// Analisi breve del comportamento recente
  /// Es. "Cammini di più nei giorni feriali. La tua costanza è notevole."
  final String insight;

  /// Suggerimento pratico specifico
  /// Es. "Prova ad aggiungere 5 min di stretching dopo la camminata"
  final String suggestion;

  /// Domanda stimolante per il brainstorming
  /// Es. "Qual è una cosa che hai rimandato questa settimana? Perché?"
  final String brainstormPrompt;

  /// Messaggio motivazionale breve per la notifica push
  final String motivationalMessage;

  /// Provider che ha generato l'insight
  final String generatedBy;

  /// Tip specifica per le routine (opzionale)
  final String? routineTip;

  /// Tip specifica per il walk (opzionale)
  final String? walkTip;

  String get dateKey {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'insight': insight,
    'suggestion': suggestion,
    'brainstormPrompt': brainstormPrompt,
    'motivationalMessage': motivationalMessage,
    'generatedBy': generatedBy,
    'routineTip': routineTip,
    'walkTip': walkTip,
  };

  factory DailyInsight.fromJson(Map<String, dynamic> json) => DailyInsight(
    date: DateTime.parse(json['date'] as String),
    insight: json['insight'] as String,
    suggestion: json['suggestion'] as String,
    brainstormPrompt: json['brainstormPrompt'] as String,
    motivationalMessage: json['motivationalMessage'] as String,
    generatedBy: json['generatedBy'] as String? ?? 'AI',
    routineTip: json['routineTip'] as String?,
    walkTip: json['walkTip'] as String?,
  );

  /// Fallback locale quando AI non è configurato
  static DailyInsight localFallback(DateTime date) => DailyInsight(
    date: date,
    insight: 'Ogni giorno che ti muovi è un giorno vinto. Continua così.',
    suggestion: 'Aggiungi 5 minuti in più alla tua prossima camminata.',
    brainstormPrompt: 'Qual è una cosa che vorresti cambiare nella tua routine questa settimana?',
    motivationalMessage: 'Buongiorno! Un passo alla volta verso la versione migliore di te.',
    generatedBy: 'locale',
  );

  @override
  List<Object?> get props =>
      [date, insight, suggestion, brainstormPrompt, motivationalMessage];
}
