import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Servizio TTS — usa il motore Google TTS del dispositivo (gratuito, offline).
/// Per la voce rituale dell'app (frase motivazionale all'apertura).
///
/// Velocità e pitch calibrati per un tono calmo e introspettivo.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isReady = false;
  bool _isSpeaking = false;

  bool get isReady => _isReady;
  bool get isSpeaking => _isSpeaking;

  Future<void> initialize() async {
    try {
      // Lingua italiana
      await _tts.setLanguage('it-IT');

      // Velocità ridotta — tono più riflessivo e deliberato
      // 0.0 = lentissimo, 1.0 = normale, >1 = veloce. 0.42 ≈ contemplativo
      await _tts.setSpeechRate(0.42);

      // Volume alto ma non al massimo
      await _tts.setVolume(0.85);

      // Pitch leggermente più basso = più calmo e maturo
      await _tts.setPitch(0.92);

      // Gestione stato
      _tts.setStartHandler(() => _isSpeaking = true);
      _tts.setCancelHandler(() => _isSpeaking = false);
      _tts.setErrorHandler((_) => _isSpeaking = false);

      _isReady = true;
    } catch (e) {
      // TTS non disponibile su questo dispositivo — degradazione silenziosa
      debugPrint('TtsService: init failed — $e');
      _isReady = false;
    }
  }

  /// Parla il testo. Chiama [onComplete] quando la sintesi è terminata.
  /// Se il TTS non è disponibile, chiama [onComplete] immediatamente.
  Future<void> speak(String text, {VoidCallback? onComplete}) async {
    if (!_isReady || text.isEmpty) {
      onComplete?.call();
      return;
    }

    if (onComplete != null) {
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        onComplete();
      });
    } else {
      _tts.setCompletionHandler(() => _isSpeaking = false);
    }

    _isSpeaking = true;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    if (_isSpeaking) {
      await _tts.stop();
      _isSpeaking = false;
    }
  }

  Future<void> dispose() async {
    await stop();
  }
}
