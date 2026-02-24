import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/session_data.dart';
import '../../core/models/user_profile.dart';

// ─── Fasi del rituale ────────────────────────────────────────────────────────
enum _Phase {
  opening,    // 0–1 s: silenzio, fade-in icona
  loading,    // attesa frase AI (spinner discreto)
  phrase,     // frase appare + TTS inizia
  breathe,    // pausa silenziosa dopo TTS
  cta,        // pulsante "Inizia il tuo momento" appare
  capturing,  // utente scrive/parla
  saving,     // salvataggio in corso
}

// ─── Screen principale ────────────────────────────────────────────────────────
class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen>
    with TickerProviderStateMixin {

  _Phase _phase = _Phase.opening;

  // Animazioni
  late final AnimationController _bgCtrl;
  late final Animation<double> _bgFade;
  late final AnimationController _phraseCtrl;
  late final Animation<double> _phraseFade;
  late final AnimationController _ctaCtrl;
  late final Animation<double> _ctaFade;
  late final Animation<Offset> _ctaSlide;

  // Contenuto
  String _phrase = '';
  UserProfile? _profile;

  // Micro-prompt
  final _inputCtrl = TextEditingController();
  final _speech = SpeechToText();
  bool _listening = false;
  bool _speechReady = false;

  // Timing
  final _sessionStart = DateTime.now();
  Timer? _safetyTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _start();
  }

  void _setupAnimations() {
    _bgCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900),
    );
    _bgFade = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeIn);

    _phraseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100),
    );
    _phraseFade = CurvedAnimation(parent: _phraseCtrl, curve: Curves.easeIn);

    _ctaCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700),
    );
    _ctaFade = CurvedAnimation(parent: _ctaCtrl, curve: Curves.easeIn);
    _ctaSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctaCtrl, curve: Curves.easeOut));

    _bgCtrl.forward();
  }

  Future<void> _start() async {
    final services = context.read<AppServices>();

    // Carica profilo e inizializza speech (in parallelo)
    final results = await Future.wait([
      services.db.loadUserProfile(),
      if (services.isPro) _speech.initialize().then((v) => v),
    ]);
    _profile = results[0] as UserProfile?;
    if (services.isPro && results.length > 1) {
      _speechReady = results[1] as bool;
    }

    // Pausa silenzio apertura (1 s)
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() => _phase = _Phase.loading);

    // Carica frase AI (già cached se aperta prima oggi)
    try {
      final p = await services.aiInsight
          .getMotivationalPhrase(_profile ?? UserProfile.guest());
      if (!mounted) return;
      setState(() {
        _phrase = p;
        _phase = _Phase.phrase;
      });

      // Anima apparizione frase
      await _phraseCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      // TTS: parla la frase
      // Safety timer: se TTS non completa in 12 s → vai avanti comunque
      _safetyTimer = Timer(const Duration(seconds: 12), _afterTts);
      await services.tts.speak(_phrase, onComplete: _afterTts);
    } catch (_) {
      if (!mounted) return;
      _phrase = _localFallback();
      setState(() => _phase = _Phase.phrase);
      _phraseCtrl.forward();
      _safetyTimer = Timer(const Duration(seconds: 6), _afterTts);
    }
  }

  /// Chiamato quando TTS finisce (o per timeout di sicurezza)
  void _afterTts() {
    _safetyTimer?.cancel();
    if (!mounted || _phase == _Phase.cta || _phase == _Phase.capturing) return;
    setState(() => _phase = _Phase.breathe);

    // Pausa contemplativa: 2.5 s poi mostra CTA
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      setState(() => _phase = _Phase.cta);
      _ctaCtrl.forward();
    });
  }

  void _startCapturing() {
    context.read<AppServices>().tts.stop();
    setState(() => _phase = _Phase.capturing);
  }

  Future<void> _saveAndClose() async {
    if (_phase == _Phase.saving) return;
    setState(() => _phase = _Phase.saving);

    final services = context.read<AppServices>();
    services.tts.stop();
    _speech.stop();

    final input = _inputCtrl.text.trim();
    final duration = DateTime.now().difference(_sessionStart).inSeconds;

    final session = SessionData(
      id: const Uuid().v4(),
      date: DateTime.now(),
      motivationalPhrase: _phrase,
      userInput: input,
      durationSeconds: duration,
      inferredMood: await _inferMood(services),
    );

    await services.db.saveSession(session);

    // Se l'utente ha scritto qualcosa → salva come nota brainstorm
    // e aggiorna contatore globale
    if (input.isNotEmpty) {
      await services.db.saveBrainstormNote(DateTime.now(), input);
      var profile = await services.db.loadUserProfile();
      if (profile != null) {
        final isFirstEver = !profile.hasBrainstormedEver;
        final newCount = profile.totalBrainstormCount + 1;
        profile = profile.copyWith(
          hasBrainstormedEver: true,
          totalBrainstormCount: newCount,
        );
        await services.db.saveUserProfile(profile);
        final dayData = await services.db.loadDayData(DateTime.now());
        await services.badges.onBrainstormSaved(
          isFirstEver: isFirstEver,
          totalBrainstorms: newCount,
          isPro: services.isPro,
          dayData: dayData,
        );
      }
    }

    if (!mounted) return;
    context.pop();
  }

  Future<String> _inferMood(AppServices services) async {
    final days = await services.db.daysSinceLastSession();
    if (days == null) return 'primo_giorno';
    if (days <= 1) return 'normale';
    if (days <= 6) return 'distante';
    return 'rientro';
  }

  String _localFallback() {
    const phrases = [
      'Respira. I tuoi pensieri aspettano.',
      'La chiarezza inizia adesso.',
      'Cosa conta davvero in questo momento?',
      'Un pensiero alla volta.',
    ];
    return phrases[DateTime.now().day % phrases.length];
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: FadeTransition(
        opacity: _bgFade,
        child: _buildBackground(child: _buildPhase()),
      ),
    );
  }

  Widget _buildBackground({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.navyDark, Color(0xFF0F1D4A)],
        ),
      ),
      child: SafeArea(child: child),
    );
  }

  Widget _buildPhase() {
    switch (_phase) {
      case _Phase.opening:
      case _Phase.loading:
        return _Opening(isLoading: _phase == _Phase.loading);
      case _Phase.phrase:
      case _Phase.breathe:
        return _PhraseView(
          phrase: _phrase,
          animation: _phraseFade,
          showBreath: _phase == _Phase.breathe,
        );
      case _Phase.cta:
        return _CtaView(
          phrase: _phrase,
          animation: _phraseFade,
          ctaFade: _ctaFade,
          ctaSlide: _ctaSlide,
          onStart: _startCapturing,
          onSkip: () => context.pop(),
        );
      case _Phase.capturing:
        return _CapturingView(
          inputCtrl: _inputCtrl,
          phrase: _phrase,
          isPro: context.read<AppServices>().isPro,
          speechReady: _speechReady,
          isListening: _listening,
          onToggleSpeech: _toggleSpeech,
          onDone: _saveAndClose,
          onClose: _saveAndClose,
        );
      case _Phase.saving:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.cyan, strokeWidth: 2),
        );
    }
  }

  void _toggleSpeech() async {
    if (_listening) {
      _speech.stop();
      setState(() => _listening = false);
    } else {
      setState(() => _listening = true);
      await _speech.listen(
        onResult: (r) => setState(() {
          _inputCtrl.text = r.recognizedWords;
          _inputCtrl.selection = TextSelection.fromPosition(
            TextPosition(offset: _inputCtrl.text.length),
          );
        }),
        localeId: 'it_IT',
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 6),
      );
    }
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _bgCtrl.dispose();
    _phraseCtrl.dispose();
    _ctaCtrl.dispose();
    _inputCtrl.dispose();
    _speech.stop();
    // TTS si ferma — gestito da AppServices
    super.dispose();
  }
}

// ─── Widget fasi (separati per leggibilità) ──────────────────────────────────

class _Opening extends StatelessWidget {
  const _Opening({required this.isLoading});
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(
            PhosphorIcons.waves(PhosphorIconsStyle.fill),
            color: AppColors.cyan,
            size: 52,
          ),
          if (isLoading) ...[
            const SizedBox(height: 36),
            const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.cyan,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhraseView extends StatelessWidget {
  const _PhraseView({
    required this.phrase,
    required this.animation,
    required this.showBreath,
  });
  final String phrase;
  final Animation<double> animation;
  final bool showBreath;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 44),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PhosphorIcon(
            PhosphorIcons.waves(PhosphorIconsStyle.fill),
            color: AppColors.cyan,
            size: 30,
          ),
          const SizedBox(height: 44),
          FadeTransition(
            opacity: animation,
            child: Text(
              phrase,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w300,
                height: 1.7,
                letterSpacing: 0.15,
              ),
            ),
          ),
          if (showBreath) ...[
            const SizedBox(height: 44),
            const _BreathDots(),
          ],
        ],
      ),
    );
  }
}

class _CtaView extends StatelessWidget {
  const _CtaView({
    required this.phrase,
    required this.animation,
    required this.ctaFade,
    required this.ctaSlide,
    required this.onStart,
    required this.onSkip,
  });
  final String phrase;
  final Animation<double> animation;
  final Animation<double> ctaFade;
  final Animation<Offset> ctaSlide;
  final VoidCallback onStart;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PhosphorIcon(
            PhosphorIcons.waves(PhosphorIconsStyle.fill),
            color: AppColors.cyan,
            size: 28,
          ),
          const SizedBox(height: 36),
          FadeTransition(
            opacity: animation,
            child: Text(
              phrase,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 18,
                fontWeight: FontWeight.w300,
                height: 1.65,
              ),
            ),
          ),
          const SizedBox(height: 60),
          SlideTransition(
            position: ctaSlide,
            child: FadeTransition(
              opacity: ctaFade,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onStart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyan,
                        foregroundColor: AppColors.navyDark,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      child: const Text('Inizia il tuo momento'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Puoi camminare o restare seduto',
                    style: TextStyle(color: Colors.white30, fontSize: 13),
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: onSkip,
                    child: const Text(
                      'Continua dopo',
                      style: TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CapturingView extends StatelessWidget {
  const _CapturingView({
    required this.inputCtrl,
    required this.phrase,
    required this.isPro,
    required this.speechReady,
    required this.isListening,
    required this.onToggleSpeech,
    required this.onDone,
    required this.onClose,
  });

  final TextEditingController inputCtrl;
  final String phrase;
  final bool isPro;
  final bool speechReady;
  final bool isListening;
  final VoidCallback onToggleSpeech;
  final VoidCallback onDone;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra superiore
          Row(
            children: [
              PhosphorIcon(
                PhosphorIcons.waves(PhosphorIconsStyle.fill),
                color: AppColors.cyan,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  phrase,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close, color: Colors.white30, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Prompt domanda
          const Text(
            'Cosa ti sta occupando\nla mente oggi?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w300,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Scrivi o parla liberamente. Non c\'è un modo giusto.',
            style: TextStyle(color: Colors.white30, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Voice button (Pro only)
          if (isPro && speechReady) ...[
            GestureDetector(
              onTap: onToggleSpeech,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isListening
                      ? Colors.red.withOpacity(0.12)
                      : AppColors.cyan.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isListening
                        ? Colors.red.withOpacity(0.4)
                        : AppColors.cyan.withOpacity(0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isListening ? Icons.stop_circle_outlined : Icons.mic_outlined,
                      color: isListening ? Colors.red : AppColors.cyan,
                      size: 17,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      isListening ? 'In ascolto…' : 'Parla',
                      style: TextStyle(
                        color: isListening ? Colors.red : AppColors.cyan,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Area di testo
          Expanded(
            child: TextField(
              controller: inputCtrl,
              maxLines: null,
              expands: true,
              autofocus: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.65,
              ),
              cursorColor: AppColors.cyan,
              decoration: InputDecoration(
                hintText: 'Inizia a scrivere…',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 15),
                filled: true,
                fillColor: Colors.white.withOpacity(0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.cyan.withOpacity(0.35)),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Pulsante Termina
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: AppColors.navyDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Termina il momento'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Animazione respiro ──────────────────────────────────────────────────────
class _BreathDots extends StatefulWidget {
  const _BreathDots();

  @override
  State<_BreathDots> createState() => _BreathDotsState();
}

class _BreathDotsState extends State<_BreathDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.2, end: 0.7).animate(_anim),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Container(
            width: 5, height: 5,
            decoration: const BoxDecoration(
              color: AppColors.cyan,
              shape: BoxShape.circle,
            ),
          ),
        )),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}
