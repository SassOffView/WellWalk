import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_provider_config.dart';
import '../models/daily_insight.dart';
import '../models/day_data.dart';
import '../models/user_profile.dart';
import 'storage/local_db_service.dart';

/// Servizio AI: genera insight personalizzati basati sui dati utente.
/// Supporta Gemini, OpenAI, Claude (Anthropic), Azure OpenAI.
/// Con caching giornaliero per evitare chiamate API eccessive.
class AiInsightService {
  AiInsightService(this._db);

  final LocalDbService _db;
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _cacheKeyPrefix = 'ai_insight_';
  static const _configKey = 'ai_provider_config';
  static const _secureKeyName = 'ai_api_key';

  // ── Configurazione provider ──────────────────────────────────────────

  Future<void> saveProviderConfig(AiProviderConfig config, {String? apiKey}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configKey, jsonEncode(config.toJson()));

    // Chiave API salvata separatamente in secure storage
    if (apiKey != null && apiKey.isNotEmpty) {
      await _secureStorage.write(key: _secureKeyName, value: apiKey);
    }
  }

  Future<AiProviderConfig> loadProviderConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_configKey);
    if (raw == null) return AiProviderConfig.none;

    final config = AiProviderConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    final apiKey = await _secureStorage.read(key: _secureKeyName) ?? '';
    return config.copyWith(apiKey: apiKey);
  }

  Future<void> deleteProviderConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_configKey);
    await _secureStorage.delete(key: _secureKeyName);
  }

  // ── Test connessione ─────────────────────────────────────────────────

  /// Verifica che la chiave API funzioni con una chiamata di test minimale
  Future<AiTestResult> testConnection(AiProviderConfig config, String apiKey) async {
    try {
      switch (config.provider) {
        case AiProvider.gemini:
          return await _testGemini(apiKey);
        case AiProvider.openai:
          return await _testOpenAI(apiKey);
        case AiProvider.claude:
          return await _testClaude(apiKey);
        case AiProvider.azureOpenai:
          return await _testAzureOpenAI(config, apiKey);
        case AiProvider.none:
          return AiTestResult.success('Nessun AI configurato');
      }
    } catch (e) {
      return AiTestResult.failure('Errore di rete: ${e.toString()}');
    }
  }

  // ── Generazione insight giornaliero ──────────────────────────────────

  /// Genera o restituisce l'insight cached per oggi
  Future<DailyInsight> getDailyInsight(UserProfile profile) async {
    final today = DateTime.now();
    final cacheKey = '$_cacheKeyPrefix${_dateKey(today)}';

    // Controlla cache giornaliera
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      return DailyInsight.fromJson(jsonDecode(cached) as Map<String, dynamic>);
    }

    // Genera nuovo insight
    final config = await loadProviderConfig();
    if (!config.hasValidKey) {
      final fallback = DailyInsight.localFallback(today);
      _cacheInsight(prefs, cacheKey, fallback);
      return fallback;
    }

    // Raccoglie contesto utente (ultimi 7 giorni)
    final context = await _buildUserContext(profile);
    final insight = await _generateInsight(config, context, today);
    _cacheInsight(prefs, cacheKey, insight);
    return insight;
  }

  /// Forza la rigenerazione dell'insight di oggi (ignora cache)
  Future<DailyInsight> refreshTodayInsight(UserProfile profile) async {
    final today = DateTime.now();
    final cacheKey = '$_cacheKeyPrefix${_dateKey(today)}';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(cacheKey);
    return getDailyInsight(profile);
  }

  // ── Contesto utente ──────────────────────────────────────────────────

  Future<String> _buildUserContext(UserProfile profile) async {
    final today = DateTime.now();
    final weekAgo = today.subtract(const Duration(days: 7));
    final days = await _db.loadDateRange(weekAgo, today);
    final streak = await _db.calculateStreak();
    final totalKm = await _db.getTotalDistanceKm();
    final totalWalks = await _db.countTotalWalks();

    // Costruisce il contesto in italiano
    final sb = StringBuffer();
    sb.writeln('UTENTE: ${profile.name}, ${profile.age} anni, ${profile.genderLabel}');
    sb.writeln('Streak attuale: $streak giorni consecutivi');
    sb.writeln('Totale km percorsi: ${totalKm.toStringAsFixed(1)} km');
    sb.writeln('Totale camminate: $totalWalks');
    sb.writeln('Note brainstorm mai scritte: ${profile.totalBrainstormCount}');
    sb.writeln();
    sb.writeln('ULTIMI 7 GIORNI:');

    const dayNames = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
    for (final day in days) {
      final name = dayNames[day.date.weekday - 1];
      final walkInfo = day.hasWalk
          ? '${day.walk!.distanceKm.toStringAsFixed(1)}km/${day.walk!.activeMinutes}min'
          : 'nessuna camminata';
      final routineInfo = day.routineTotal > 0
          ? '${day.routineCompleted}/${day.routineTotal} routine (${day.routinePercent.round()}%)'
          : 'nessuna routine';
      final brainInfo = day.hasBrainstorm ? 'brainstorm ✓' : 'nessun brainstorm';
      sb.writeln('$name: $walkInfo | $routineInfo | $brainInfo');
    }

    return sb.toString();
  }

  // ── Chiamata AI ──────────────────────────────────────────────────────

  Future<DailyInsight> _generateInsight(
    AiProviderConfig config,
    String userContext,
    DateTime date,
  ) async {
    final prompt = _buildPrompt(userContext);

    try {
      String? rawResponse;
      switch (config.provider) {
        case AiProvider.gemini:
          rawResponse = await _callGemini(config.apiKey, prompt);
          break;
        case AiProvider.openai:
          rawResponse = await _callOpenAI(config.apiKey, prompt);
          break;
        case AiProvider.claude:
          rawResponse = await _callClaude(config.apiKey, prompt);
          break;
        case AiProvider.azureOpenai:
          rawResponse = await _callAzureOpenAI(config, prompt);
          break;
        case AiProvider.none:
          return DailyInsight.localFallback(date);
      }

      if (rawResponse == null) return DailyInsight.localFallback(date);
      return _parseInsight(rawResponse, date, config.providerName);
    } catch (_) {
      return DailyInsight.localFallback(date);
    }
  }

  String _buildPrompt(String userContext) => '''
Sei un coach di benessere personale. Analizza i seguenti dati di attività dell'utente e fornisci supporto personalizzato.

$userContext

Rispondi ESCLUSIVAMENTE con un JSON valido (nessun testo prima o dopo) in questo formato:
{
  "insight": "Analisi breve del comportamento (1-2 frasi, caldo e personale)",
  "suggestion": "Suggerimento pratico e specifico per migliorare (1 frase)",
  "brainstorm_prompt": "Domanda stimolante per la riflessione di oggi (1 frase)",
  "motivational_message": "Messaggio motivazionale brevissimo per la notifica push (max 10 parole)",
  "routine_tip": "Suggerimento specifico per le routine (1 frase, può essere null)",
  "walk_tip": "Suggerimento specifico per la camminata (1 frase, può essere null)"
}

Tono: caldo, empatico, motivante. Lingua: italiano.''';

  DailyInsight _parseInsight(String raw, DateTime date, String provider) {
    // Estrae JSON dalla risposta (alcuni modelli aggiungono markdown ```json```)
    String cleaned = raw.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceAll(RegExp(r'```json?\n?'), '').replaceAll('```', '');
    }

    try {
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      return DailyInsight(
        date: date,
        insight: json['insight'] as String? ?? '',
        suggestion: json['suggestion'] as String? ?? '',
        brainstormPrompt: json['brainstorm_prompt'] as String? ?? '',
        motivationalMessage: json['motivational_message'] as String? ?? '',
        generatedBy: provider,
        routineTip: json['routine_tip'] as String?,
        walkTip: json['walk_tip'] as String?,
      );
    } catch (_) {
      // Se il parsing JSON fallisce, estrai il testo grezzo come insight
      return DailyInsight(
        date: date,
        insight: cleaned.length > 200 ? '${cleaned.substring(0, 200)}...' : cleaned,
        suggestion: 'Continua con costanza ogni giorno.',
        brainstormPrompt: 'Cosa ti ha fatto sorridere oggi?',
        motivationalMessage: 'Un passo alla volta. Stai crescendo.',
        generatedBy: provider,
      );
    }
  }

  // ── Gemini API ───────────────────────────────────────────────────────

  Future<String?> _callGemini(String apiKey, String prompt) async {
    final response = await http.post(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        'gemini-1.5-flash:generateContent?key=$apiKey',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [{'parts': [{'text': prompt}]}],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 600,
        },
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (((data['candidates'] as List?)?.first as Map?)?['content']
        as Map?)?['parts']?[0]?['text'] as String?;
  }

  Future<AiTestResult> _testGemini(String apiKey) async {
    final response = await http.post(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        'gemini-1.5-flash:generateContent?key=$apiKey',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [{'parts': [{'text': 'Rispondi solo "ok"'}]}],
        'generationConfig': {'maxOutputTokens': 10},
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return AiTestResult.success('Gemini connesso ✅');
    } else if (response.statusCode == 400) {
      return AiTestResult.failure('Chiave API non valida');
    } else {
      return AiTestResult.failure('Errore ${response.statusCode}');
    }
  }

  // ── OpenAI API ───────────────────────────────────────────────────────

  Future<String?> _callOpenAI(String apiKey, String prompt) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 600,
        'temperature': 0.7,
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ((data['choices'] as List?)?.first as Map?)?['message']
        ?['content'] as String?;
  }

  Future<AiTestResult> _testOpenAI(String apiKey) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [{'role': 'user', 'content': 'ok'}],
        'max_tokens': 5,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) return AiTestResult.success('ChatGPT connesso ✅');
    if (response.statusCode == 401) return AiTestResult.failure('Chiave API non valida');
    if (response.statusCode == 429) return AiTestResult.failure('Quota esaurita');
    return AiTestResult.failure('Errore ${response.statusCode}');
  }

  // ── Anthropic Claude API ─────────────────────────────────────────────

  Future<String?> _callClaude(String apiKey, String prompt) async {
    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-haiku-4-5-20251001',
        'max_tokens': 600,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ((data['content'] as List?)?.first as Map?)?['text'] as String?;
  }

  Future<AiTestResult> _testClaude(String apiKey) async {
    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-haiku-4-5-20251001',
        'max_tokens': 5,
        'messages': [{'role': 'user', 'content': 'ok'}],
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) return AiTestResult.success('Claude connesso ✅');
    if (response.statusCode == 401) return AiTestResult.failure('Chiave API non valida');
    return AiTestResult.failure('Errore ${response.statusCode}');
  }

  // ── Azure OpenAI / Copilot ───────────────────────────────────────────

  Future<String?> _callAzureOpenAI(AiProviderConfig config, String prompt) async {
    if (config.azureEndpoint.isEmpty || config.azureDeployment.isEmpty) return null;

    final url = '${config.azureEndpoint}/openai/deployments/'
        '${config.azureDeployment}/chat/completions?api-version=2024-02-01';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'api-key': config.apiKey,
      },
      body: jsonEncode({
        'messages': [{'role': 'user', 'content': prompt}],
        'max_tokens': 600,
        'temperature': 0.7,
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ((data['choices'] as List?)?.first as Map?)?['message']
        ?['content'] as String?;
  }

  Future<AiTestResult> _testAzureOpenAI(
      AiProviderConfig config, String apiKey) async {
    if (config.azureEndpoint.isEmpty) {
      return AiTestResult.failure('Endpoint Azure non configurato');
    }

    final url = '${config.azureEndpoint}/openai/deployments/'
        '${config.azureDeployment}/chat/completions?api-version=2024-02-01';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'api-key': apiKey,
      },
      body: jsonEncode({
        'messages': [{'role': 'user', 'content': 'ok'}],
        'max_tokens': 5,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) return AiTestResult.success('Azure OpenAI connesso ✅');
    if (response.statusCode == 401) return AiTestResult.failure('Chiave API non valida');
    return AiTestResult.failure('Errore ${response.statusCode}');
  }

  // ── Cache ────────────────────────────────────────────────────────────

  void _cacheInsight(SharedPreferences prefs, String key, DailyInsight insight) {
    prefs.setString(key, jsonEncode(insight.toJson()));
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Risultato del test di connessione
class AiTestResult {
  const AiTestResult({required this.success, required this.message});

  factory AiTestResult.success(String message) =>
      AiTestResult(success: true, message: message);

  factory AiTestResult.failure(String message) =>
      AiTestResult(success: false, message: message);

  final bool success;
  final String message;
}
