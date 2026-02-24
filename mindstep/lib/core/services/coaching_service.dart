import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_insight_service.dart';

/// Messaggio in una conversazione con il coach
class CoachMessage {
  const CoachMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  final String role;      // 'user' | 'assistant'
  final String content;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
  };

  factory CoachMessage.fromJson(Map<String, dynamic> json) => CoachMessage(
    role: json['role'] as String,
    content: json['content'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

/// Coach di Chiarezza Strategica — conversazionale, con contesto mantenuto.
/// 60% Socratico | 30% Empatico | 10% Orientato all'azione.
/// Zero tono guru / zero terapia / zero frasi motivazionali generiche.
class CoachingService {
  CoachingService(this._aiInsight);

  final AiInsightService _aiInsight;

  static const _systemPrompt = '''
Sei un Coach di Chiarezza Strategica.
Il tuo obiettivo non è dare soluzioni, ma aiutare l'utente a pensare meglio, vedere con più lucidità e identificare il prossimo passo concreto.

TONO E PERSONALITÀ:
- Calmo, lucido, presente
- Intelligente ma non accademico
- Empatico ma non terapeutico
- Incoraggiante ma non euforico
- Mai giudicante
- Mai paternalistico
- Mai motivazionale generico

EVITA SEMPRE:
- Frasi da self-help
- Affermazioni tipo "Puoi farcela!"
- Risposte lunghe e teoriche
- Soluzioni dirette immediate

METODO DI COACHING:
Segui questa struttura:

1. Breve validazione (max 1 frase)
   Riconosci lo stato dell'utente senza amplificarlo.
   Esempio: "Capisco che questa situazione possa creare confusione." / "Sembra un momento di blocco."

2. Domanda socratica mirata
   Fai UNA domanda che chiarisce, restringe il focus, sposta la prospettiva, rende il problema più concreto.
   EVITA domande vaghe tipo "Come ti senti?" / "Cosa vuoi fare?"
   PREFERISCI: "Qual è l'ostacolo reale, se lo riduciamo a una frase?" / "Quale parte di questa situazione è sotto il tuo controllo oggi?" / "Se dovessi scegliere una sola priorità, quale sarebbe?"

3. Micro-orientamento all'azione (facoltativo)
   Se appropriato, chiudi con: "Qual è il primo passo minimo che puoi fare?" / "Cosa puoi testare nelle prossime 24 ore?"
   Non dare mai un piano completo.

STILE DELLE RISPOSTE:
- 3-6 righe massimo
- Linguaggio semplice
- Frasi brevi
- Una sola domanda principale per risposta
- Niente elenchi puntati (a meno che richiesto)
- Niente spiegazioni teoriche

CONTESTO APP:
L'utente spesso sta camminando, sta registrando pensieri, è in fase di brainstorming.
Le risposte devono essere immediate, leggere mentalmente, non sovraccaricare, favorire riflessione in movimento.

NON fare mai:
- Non risolvere il problema al posto dell'utente
- Non fare analisi psicologiche
- Non interpretare emozioni in modo profondo
- Non proporre tecniche complesse
- Non usare emoji
''';

  final List<CoachMessage> _history = [];

  /// Ritorna la storia della conversazione corrente
  List<CoachMessage> get history => List.unmodifiable(_history);

  bool get hasHistory => _history.isNotEmpty;

  /// Avvia una nuova sessione (azzera la storia)
  void startSession() {
    _history.clear();
  }

  /// Invia un messaggio al coach e riceve la risposta.
  /// Mantiene il contesto completo della conversazione.
  Future<String> sendMessage(String userMessage) async {
    // Aggiunge il messaggio utente alla storia
    _history.add(CoachMessage(
      role: 'user',
      content: userMessage,
      timestamp: DateTime.now(),
    ));

    final config = await _aiInsight.loadProviderConfig();

    if (!config.hasValidKey) {
      const fallback = 'Per usare il Coach IA devi prima configurare un provider AI nelle impostazioni.';
      _history.add(CoachMessage(
        role: 'assistant',
        content: fallback,
        timestamp: DateTime.now(),
      ));
      return fallback;
    }

    try {
      // Costruisce i messaggi per l'API
      final messages = _buildMessages();

      String? response;
      switch (config.provider) {
        case AiProvider.gemini:
          response = await _callGemini(config.apiKey, messages);
          break;
        case AiProvider.openai:
        case AiProvider.azureOpenai:
          response = await _callOpenAI(config, messages);
          break;
        case AiProvider.claude:
          response = await _callClaude(config.apiKey, messages);
          break;
        case AiProvider.none:
          response = null;
      }

      final reply = response?.trim() ?? _fallbackResponse();

      _history.add(CoachMessage(
        role: 'assistant',
        content: reply,
        timestamp: DateTime.now(),
      ));

      return reply;
    } catch (_) {
      final fallback = _fallbackResponse();
      _history.add(CoachMessage(
        role: 'assistant',
        content: fallback,
        timestamp: DateTime.now(),
      ));
      return fallback;
    }
  }

  /// Costruisce la lista messaggi nel formato standard per le API
  List<Map<String, String>> _buildMessages() {
    return _history.map((m) => {'role': m.role, 'content': m.content}).toList();
  }

  String _fallbackResponse() {
    const options = [
      'Capisco. Qual è l\'ostacolo principale se lo riduciamo a una frase sola?',
      'Sembra un momento di riflessione. Quale parte di questa situazione è sotto il tuo controllo oggi?',
      'Interessante. Se dovessi scegliere una sola priorità adesso, quale sarebbe?',
      'Ci sono molti elementi. Quale di questi ti pesa di più in questo momento?',
    ];
    final idx = DateTime.now().second % options.length;
    return options[idx];
  }

  // ── Claude API (con system prompt) ──────────────────────────────────

  Future<String?> _callClaude(
      String apiKey, List<Map<String, String>> messages) async {
    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-haiku-4-5-20251001',
        'max_tokens': 300,
        'system': _systemPrompt,
        'messages': messages,
      }),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ((data['content'] as List?)?.first as Map?)?['text'] as String?;
  }

  // ── OpenAI / Azure (con system prompt come primo messaggio) ──────────

  Future<String?> _callOpenAI(
      dynamic config, List<Map<String, String>> messages) async {
    final allMessages = [
      {'role': 'system', 'content': _systemPrompt},
      ...messages,
    ];

    final url = config.provider == AiProvider.azureOpenai
        ? '${config.azureEndpoint}/openai/deployments/${config.azureDeployment}/chat/completions?api-version=2024-02-01'
        : 'https://api.openai.com/v1/chat/completions';

    final headers = config.provider == AiProvider.azureOpenai
        ? {'Content-Type': 'application/json', 'api-key': config.apiKey as String}
        : {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${config.apiKey}',
          };

    final body = config.provider == AiProvider.azureOpenai
        ? jsonEncode({'messages': allMessages, 'max_tokens': 300, 'temperature': 0.7})
        : jsonEncode({
            'model': 'gpt-4o-mini',
            'messages': allMessages,
            'max_tokens': 300,
            'temperature': 0.7,
          });

    final response = await http
        .post(Uri.parse(url), headers: headers, body: body)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ((data['choices'] as List?)?.first as Map?)?['message']
        ?['content'] as String?;
  }

  // ── Gemini (system instruction nel prompt) ───────────────────────────

  Future<String?> _callGemini(
      String apiKey, List<Map<String, String>> messages) async {
    // Gemini non ha un system message nativo nello stesso modo:
    // lo inseriamo come prima parte del contesto
    final contents = messages.map((m) => {
      'role': m['role'] == 'user' ? 'user' : 'model',
      'parts': [{'text': m['content']}],
    }).toList();

    // Aggiunge context al primo messaggio
    if (contents.isNotEmpty && contents.first['role'] == 'user') {
      final firstParts = contents.first['parts'] as List;
      final firstText = (firstParts.first as Map)['text'] as String;
      (firstParts.first as Map)['text'] = 'ISTRUZIONI COACH:\n$_systemPrompt\n\n---\n\nUTENTE: $firstText';
    }

    final response = await http.post(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        'gemini-1.5-flash:generateContent?key=$apiKey',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': contents,
        'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 300},
      }),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (((data['candidates'] as List?)?.first as Map?)?['content']
        as Map?)?['parts']?[0]?['text'] as String?;
  }
}
