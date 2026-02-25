import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/models/day_data.dart';
import '../../../core/models/ai_provider_config.dart';
import '../../../shared/widgets/ms_card.dart';
import '../../export/ai_webview_screen.dart';

class BrainstormWidget extends StatefulWidget {
  const BrainstormWidget({
    super.key,
    this.dayData,
    this.onSaved,
    this.aiPromptOfDay,
  });

  final DayData? dayData;
  final VoidCallback? onSaved;
  final String? aiPromptOfDay;

  @override
  State<BrainstormWidget> createState() => _BrainstormWidgetState();
}

// Stato della registrazione vocale
enum _RecordState { idle, recording, paused }

class _BrainstormWidgetState extends State<BrainstormWidget> {
  final _controller = TextEditingController();
  final _speechToText = SpeechToText();

  _RecordState _recordState = _RecordState.idle;
  bool _speechAvailable = false;
  bool _hasChanges = false;
  bool _expanded = true; // aperto di default

  // Testo accumulato prima di riavviare la registrazione
  String _accumulatedText = '';

  // Timer display per elapsed brainstorm time
  Timer? _displayTimer;
  int _elapsedSeconds = 0;

  // Tracciamento durata sessione brainstorm
  DateTime? _sessionStart;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _controller.text = widget.dayData?.brainstormNote ?? '';
    _controller.addListener(() {
      if (!_hasChanges) {
        _sessionStart ??= DateTime.now();
        setState(() => _hasChanges = true);
        _startDisplayTimer();
      }
    });
  }

  @override
  void didUpdateWidget(BrainstormWidget old) {
    super.didUpdateWidget(old);
    if (old.dayData?.brainstormNote != widget.dayData?.brainstormNote &&
        !_hasChanges) {
      _controller.text = widget.dayData?.brainstormNote ?? '';
    }
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speechToText.initialize();
    if (mounted) setState(() {});
  }

  void _startDisplayTimer() {
    if (_displayTimer?.isActive ?? false) return;
    _displayTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  String get _formattedElapsed {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Recording logic ─────────────────────────────────────────────────

  Future<void> _startRecording() async {
    if (!_speechAvailable) return;
    _sessionStart ??= DateTime.now();

    // Preserva il testo già scritto prima di iniziare
    _accumulatedText = _controller.text.trim();

    await _speechToText.listen(
      onResult: (result) {
        if (!mounted) return;
        // Appende il testo riconosciuto a quello già presente
        final newPart = result.recognizedWords;
        final separator =
            _accumulatedText.isNotEmpty && newPart.isNotEmpty ? ' ' : '';
        setState(() {
          _controller.text = '$_accumulatedText$separator$newPart';
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
          _hasChanges = true;
        });
      },
      localeId: 'it_IT',
      listenFor: const Duration(minutes: 10),
      pauseFor: const Duration(seconds: 8),
    );

    setState(() => _recordState = _RecordState.recording);
    _startDisplayTimer();
  }

  void _stopRecording() {
    _speechToText.stop();
    // Aggiorna l'accumulato con il testo corrente (per eventuale ripresa)
    _accumulatedText = _controller.text.trim();
    setState(() => _recordState = _RecordState.paused);
  }

  Future<void> _resumeRecording() async {
    if (!_speechAvailable) return;
    // Riprende senza cancellare il testo precedente
    _accumulatedText = _controller.text.trim();

    await _speechToText.listen(
      onResult: (result) {
        if (!mounted) return;
        final newPart = result.recognizedWords;
        final separator =
            _accumulatedText.isNotEmpty && newPart.isNotEmpty ? ' ' : '';
        setState(() {
          _controller.text = '$_accumulatedText$separator$newPart';
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
          _hasChanges = true;
        });
      },
      localeId: 'it_IT',
      listenFor: const Duration(minutes: 10),
      pauseFor: const Duration(seconds: 8),
    );

    setState(() => _recordState = _RecordState.recording);
  }

  @override
  Widget build(BuildContext context) {
    final services = context.read<AppServices>();

    return MsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header collassabile ─────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                PhosphorIcon(
                  PhosphorIcons.brain(
                    _recordState == _RecordState.recording
                        ? PhosphorIconsStyle.fill
                        : PhosphorIconsStyle.regular,
                  ),
                  size: 22,
                  color: _recordState == _RecordState.recording
                      ? AppColors.error
                      : AppColors.cyan,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Brainstorming $_formattedElapsed',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontSize: 17),
                  ),
                ),
                // Mic quick-action
                if (_speechAvailable)
                  GestureDetector(
                    onTap: () {
                      if (!_expanded) setState(() => _expanded = true);
                      if (_recordState == _RecordState.recording) {
                        _stopRecording();
                      } else if (_recordState == _RecordState.paused) {
                        _resumeRecording();
                      } else {
                        _startRecording();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: PhosphorIcon(
                        _recordState == _RecordState.recording
                            ? PhosphorIcons.stopCircle(PhosphorIconsStyle.fill)
                            : PhosphorIcons.microphone(),
                        size: 22,
                        color: _recordState == _RecordState.recording
                            ? AppColors.error
                            : AppColors.cyan,
                      ),
                    ),
                  ),
                PhosphorIcon(
                  _expanded
                      ? PhosphorIcons.caretUp()
                      : PhosphorIcons.caretDown(),
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),

          // ── Contenuto espandibile ───────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _expanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // ── Coach IA (PRO) button ─────────────────────
                      _CoachButton(
                        isPro: services.isPro,
                        onTap: services.isPro
                            ? () => context.push('/coach')
                            : () => context.push('/paywall'),
                      ),
                      const SizedBox(height: 12),

                      // ── Recording buttons (FREE + PRO) ───────────
                      if (_speechAvailable)
                        _RecordingBar(
                          state: _recordState,
                          onRecord: _startRecording,
                          onStop: _stopRecording,
                          onResume: _resumeRecording,
                        ),

                      if (_speechAvailable) const SizedBox(height: 12),

                      // ── Prompt AI del giorno (solo icona, no titolo)
                      if (widget.aiPromptOfDay != null &&
                          widget.aiPromptOfDay!.isNotEmpty)
                        _AiPromptHint(
                          prompt: widget.aiPromptOfDay!,
                          onTap: () {
                            if (_controller.text.trim().isEmpty) {
                              _controller.text = widget.aiPromptOfDay!;
                              _controller.selection =
                                  TextSelection.fromPosition(
                                TextPosition(
                                    offset: _controller.text.length),
                              );
                            }
                          },
                        ),

                      if (widget.aiPromptOfDay != null &&
                          widget.aiPromptOfDay!.isNotEmpty)
                        const SizedBox(height: 10),

                      // ── Text area ────────────────────────────────
                      TextField(
                        controller: _controller,
                        maxLines: 7,
                        style: const TextStyle(fontSize: 15, height: 1.6),
                        decoration: InputDecoration(
                          hintText: AppStrings.brainPlaceholder,
                          hintStyle: TextStyle(
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withOpacity(0.5),
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Action buttons ──────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _hasChanges
                                  ? () => _saveBrainstorm(services)
                                  : null,
                              icon: PhosphorIcon(
                                  PhosphorIcons.floppyDisk(), size: 16),
                              label: const Text(AppStrings.brainSave,
                                  style: TextStyle(fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _controller.text.isNotEmpty
                                ? () => _exportToAI(context, services)
                                : null,
                            icon: PhosphorIcon(PhosphorIcons.export(),
                                size: 16),
                            label: const Text(AppStrings.brainExport,
                                style: TextStyle(fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ── Save ─────────────────────────────────────────────────────────────

  Future<void> _saveBrainstorm(AppServices services) async {
    final note = _controller.text.trim();
    if (note.isEmpty) return;

    final today = DateTime.now();

    if (_sessionStart != null) {
      final minutes =
          today.difference(_sessionStart!).inMinutes.clamp(0, 60);
      if (minutes > 0) {
        await services.db.addBrainstormMinutes(today, minutes);
      }
      _sessionStart = null;
    }

    await services.db.saveBrainstormNote(today, note);

    var profile = await services.db.loadUserProfile();
    final isFirstEver = !(profile?.hasBrainstormedEver ?? false);
    final totalCount = (profile?.totalBrainstormCount ?? 0) + 1;

    if (profile != null) {
      profile = profile.copyWith(
        hasBrainstormedEver: true,
        totalBrainstormCount: totalCount,
      );
      await services.db.saveUserProfile(profile);
    }

    final dayData = await services.db.loadDayData(today);
    await services.badges.onBrainstormSaved(
      isFirstEver: isFirstEver,
      totalBrainstorms: totalCount,
      isPro: services.isPro,
      dayData: dayData,
    );

    setState(() => _hasChanges = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.brainSaved)),
      );
    }

    widget.onSaved?.call();
  }

  // ── Export → AI webview ───────────────────────────────────────────────

  Future<void> _exportToAI(BuildContext context, AppServices services) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Data e ora formattate
    final now = DateTime.now();
    final dateStr =
        DateFormat("d MMMM yyyy 'alle' HH:mm", 'it').format(now);

    // Prompt strutturato con ruolo, data e istruzioni organizzative
    final structuredPrompt =
        'Sei un coach personale esperto in produttività, pensiero critico e '
        'crescita personale. Il tuo stile è riflessivo, socratico e non giudicante.\n\n'
        'Analizza la seguente trascrizione dei miei pensieri di oggi ($dateStr). '
        'Per ogni analisi:\n'
        '1. Identifica i TEMI principali e i pattern ricorrenti\n'
        '2. Evidenzia le PRIORITÀ implicite (cosa mi preme davvero?)\n'
        '3. Rileva eventuali BLOCCHI o tensioni nascoste\n'
        '4. Proponi UNA domanda socratica che mi aiuti a fare il passo successivo\n'
        '5. Suggerisci UNA azione concreta per oggi\n\n'
        '--- TRASCRIZIONE ($dateStr) ---\n'
        '$text\n'
        '--- FINE TRASCRIZIONE ---';

    // Copia negli appunti
    await Clipboard.setData(ClipboardData(text: structuredPrompt));

    final config = await services.aiInsight.loadProviderConfig();
    final aiUrl = _getAiUrl(config);

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiWebviewScreen(
          url: aiUrl,
          aiName: config.providerName,
        ),
      ),
    );
  }

  String _getAiUrl(AiProviderConfig config) {
    switch (config.provider) {
      case AiProvider.claude:
        return 'https://claude.ai/new';
      case AiProvider.openai:
        return 'https://chat.openai.com';
      case AiProvider.gemini:
        return 'https://gemini.google.com';
      case AiProvider.azureOpenai:
        return 'https://copilot.microsoft.com';
      case AiProvider.none:
        return 'https://claude.ai/new';
    }
  }

  @override
  void dispose() {
    _displayTimer?.cancel();
    _controller.dispose();
    _speechToText.stop();
    super.dispose();
  }
}

// ── Recording Bar ──────────────────────────────────────────────────────────────

class _RecordingBar extends StatelessWidget {
  const _RecordingBar({
    required this.state,
    required this.onRecord,
    required this.onStop,
    required this.onResume,
  });

  final _RecordState state;
  final VoidCallback onRecord;
  final VoidCallback onStop;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (state == _RecordState.idle)
          _RecordBtn(
            icon: PhosphorIcons.microphone(),
            label: AppStrings.brainRecord,
            color: AppColors.cyan,
            isActive: false,
            onTap: onRecord,
          ),

        if (state == _RecordState.recording) ...[
          _RecordBtn(
            icon: PhosphorIcons.stopCircle(PhosphorIconsStyle.fill),
            label: AppStrings.brainStopRecord,
            color: AppColors.error,
            isActive: true,
            onTap: onStop,
          ),
          const SizedBox(width: 8),
          _PulseIndicator(),
          const SizedBox(width: 6),
          Text(
            'In ascolto...',
            style: TextStyle(
              color: AppColors.error.withOpacity(0.7),
              fontSize: 12,
              fontFamily: 'Inter',
            ),
          ),
        ],

        if (state == _RecordState.paused) ...[
          _RecordBtn(
            icon: PhosphorIcons.play(PhosphorIconsStyle.fill),
            label: 'Riprendi',
            color: AppColors.cyan,
            isActive: false,
            onTap: onResume,
          ),
          const SizedBox(width: 8),
          _RecordBtn(
            icon: PhosphorIcons.microphone(),
            label: 'Nuova',
            color: Colors.grey,
            isActive: false,
            onTap: onRecord,
          ),
        ],
      ],
    );
  }
}

class _RecordBtn extends StatelessWidget {
  const _RecordBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  final PhosphorIconData icon;
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? color.withOpacity(0.12)
              : color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(isActive ? 0.8 : 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(icon, color: color, size: 16),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── AI Prompt Hint (senza titolo, solo icona) ─────────────────────────────────

class _AiPromptHint extends StatelessWidget {
  const _AiPromptHint({required this.prompt, required this.onTap});
  final String prompt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cyan.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cyan.withOpacity(0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PhosphorIcon(PhosphorIcons.lightbulb(),
                size: 14, color: AppColors.cyan),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                prompt,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(height: 1.45),
              ),
            ),
            PhosphorIcon(PhosphorIcons.cursorClick(),
                color: AppColors.cyan, size: 14),
          ],
        ),
      ),
    );
  }
}

// ── Coach IA Button ────────────────────────────────────────────────────────────

class _CoachButton extends StatelessWidget {
  const _CoachButton({required this.isPro, required this.onTap});
  final bool isPro;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: isPro
              ? LinearGradient(
                  colors: [
                    AppColors.cyan.withOpacity(0.15),
                    const Color(0xFF9C27B0).withOpacity(0.12),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color:
              isPro ? null : AppColors.cyan.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPro ? AppColors.cyan : AppColors.cyan.withOpacity(0.2),
            width: isPro ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            PhosphorIcon(
              PhosphorIcons.chatCircleDots(
                  isPro
                      ? PhosphorIconsStyle.fill
                      : PhosphorIconsStyle.regular),
              color: AppColors.cyan,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPro
                        ? AppStrings.coachStart
                        : AppStrings.coachStartFree,
                    style: const TextStyle(
                      color: AppColors.cyan,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  if (!isPro)
                    Text(
                      AppStrings.coachStartFreeDesc,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                            color: AppColors.cyan.withOpacity(0.6),
                          ),
                    ),
                ],
              ),
            ),
            if (!isPro)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: AppColors.proGradient,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            else
              PhosphorIcon(PhosphorIcons.arrowRight(),
                  size: 16, color: AppColors.cyan),
          ],
        ),
      ),
    );
  }
}

// ── Pulse Indicator ───────────────────────────────────────────────────────────

class _PulseIndicator extends StatefulWidget {
  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.error,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}
