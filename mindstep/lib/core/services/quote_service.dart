import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Quote giornaliera (stessa quote per tutto il giorno, aggiornata il giorno dopo)
class DailyQuote {
  const DailyQuote({required this.text, required this.author});
  final String text;
  final String author;

  String get formatted => '"$text" — $author';

  Map<String, dynamic> toJson() => {'text': text, 'author': author};
  factory DailyQuote.fromJson(Map<String, dynamic> json) => DailyQuote(
    text: json['text'] as String,
    author: json['author'] as String,
  );
}

class QuoteService {
  static const _prefsKeyQuote = 'daily_quote';
  static const _prefsKeyDate = 'daily_quote_date';

  // Fallback in caso di errore
  static const _fallbackIt = DailyQuote(
    text: 'Ogni grande viaggio inizia con un solo passo.',
    author: 'Lao Tzu',
  );
  static const _fallbackEn = DailyQuote(
    text: 'The secret of getting ahead is getting started.',
    author: 'Mark Twain',
  );

  List<DailyQuote>? _italianQuotes;

  /// Restituisce la quote del giorno (cached 24h).
  /// [language] → 'it' oppure 'en'
  Future<DailyQuote> getDailyQuote(String language) async {
    final today = _todayKey();
    final prefs = await SharedPreferences.getInstance();
    final cachedDate = prefs.getString(_prefsKeyDate);
    final cachedRaw = prefs.getString('${_prefsKeyQuote}_$language');

    // Usa cache se è ancora oggi
    if (cachedDate == today && cachedRaw != null) {
      try {
        return DailyQuote.fromJson(
          jsonDecode(cachedRaw) as Map<String, dynamic>,
        );
      } catch (_) {}
    }

    // Fetch nuova quote
    final quote = language == 'en'
        ? await _fetchEnglishQuote()
        : await _fetchItalianQuote();

    // Salva in cache
    await prefs.setString(_prefsKeyDate, today);
    await prefs.setString(
      '${_prefsKeyQuote}_$language',
      jsonEncode(quote.toJson()),
    );

    return quote;
  }

  /// Fetch da ZenQuotes API (gratuita, no key, EN)
  Future<DailyQuote> _fetchEnglishQuote() async {
    try {
      final response = await http
          .get(Uri.parse('https://zenquotes.io/api/random'))
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        if (data.isNotEmpty) {
          final item = data.first as Map<String, dynamic>;
          return DailyQuote(
            text: item['q'] as String? ?? _fallbackEn.text,
            author: item['a'] as String? ?? _fallbackEn.author,
          );
        }
      }
    } catch (_) {}
    return _fallbackEn;
  }

  /// Legge da asset locale quotes_it.json (con rotazione giornaliera)
  Future<DailyQuote> _fetchItalianQuote() async {
    try {
      _italianQuotes ??= await _loadItalianQuotes();
      if (_italianQuotes != null && _italianQuotes!.isNotEmpty) {
        // Rotazione deterministica basata sul giorno dell'anno
        final dayOfYear = DateTime.now()
            .difference(DateTime(DateTime.now().year, 1, 1))
            .inDays;
        final index = dayOfYear % _italianQuotes!.length;
        return _italianQuotes![index];
      }
    } catch (_) {}
    return _fallbackIt;
  }

  Future<List<DailyQuote>> _loadItalianQuotes() async {
    final raw = await rootBundle.loadString('assets/quotes/quotes_it.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((item) {
      final map = item as Map<String, dynamic>;
      return DailyQuote(
        text: map['q'] as String,
        author: map['a'] as String,
      );
    }).toList();
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Restituisce una quote casuale dall'elenco italiano (per fallback immediato)
  DailyQuote randomItalianFallback() {
    final quotes = [
      _fallbackIt,
      const DailyQuote(text: 'La mente è tutto. Sei ciò che pensi.', author: 'Buddha'),
      const DailyQuote(text: 'Ogni passo che fai oggi è un passo lontano da ieri.', author: 'Anonimo'),
      const DailyQuote(text: 'Il coraggio è iniziare.', author: 'Anonimo'),
    ];
    return quotes[Random().nextInt(quotes.length)];
  }
}
