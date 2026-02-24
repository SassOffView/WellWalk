import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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

class _BrainstormWidgetState extends State<BrainstormWidget> {
  final _controller = TextEditingController();
  final _speechToText = SpeechToText();
  bool _isRecording = false;
  bool _speechAvailable = false;
  bool _hasChanges = false;

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

  @override
  Widget build(BuildContext context) {
    final services = context.read<AppServices>();

    return MsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              PhosphorIcon(PhosphorIcons.brain(), size: 20, color: AppColors.cyan),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.brainTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Coach IA (PRO) button ───────────────────────────────────
          _CoachButton(
            isPro: services.isPro,
            onTap: services.isPro
                ? () => context.push('/coach')
                : () => context.push('/paywall'),
          ),

          const SizedBox(height: 10),

          // Voice recording (Pro only, visible only when speech is available)
          if (services.isPro && _speechAvailable)
            GestureDetector(
              onTap: _isRecording ? _stopRecording : _startRecording,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _isRecording
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.cyan.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isRecording
                        ? AppColors.error
                        : AppColors.cyan.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PhosphorIcon(
                      _isRecording
                          ? PhosphorIcons.stopCircle(PhosphorIconsStyle.fill)
                          : PhosphorIcons.microphone(),
                      color: _isRecording ? AppColors.error : AppColors.cyan,
                      size: 16,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      _isRecording
                          ? AppStrings.brainStopRecord
                          : AppStrings.brainRecord,
                      style: TextStyle(
                        color: _isRecording ? AppColors.error : AppColors.cyan,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (_isRecording) ...[
                      const SizedBox(width: 8),
                      _PulseIndicator(),
                    ],
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),

          // AI prompt del giorno
          if (widget.aiPromptOfDay != null &&
              widget.aiPromptOfDay!.isNotEmpty) ...[
            GestureDetector(
              onTap: () {
                if (_controller.text.trim().isEmpty) {
                  _controller.text = widget.aiPromptOfDay!;
                  _controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: _controller.text.length),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cyan.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PhosphorIcon(PhosphorIcons.lightbulb(),
                        size: 14, color: AppColors.cyan),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Prompt AI di oggi',
                            style: TextStyle(
                              color: AppColors.cyan,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.aiPromptOfDay!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(height: 1.45),
                          ),
                        ],
                      ),
                    ),
                    PhosphorIcon(PhosphorIcons.cursorClick(),
                        color: AppColors.cyan, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Text area
          TextField(
            controller: _controller,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: AppStrings.brainPlaceholder,
              hintStyle: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withOpacity(0.6),
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _hasChanges ? () => _saveBrainstorm(services) : null,
                  icon: PhosphorIcon(PhosphorIcons.floppyDisk(), size: 16),
                  label: const Text(AppStrings.brainSave,
                      style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _controller.text.isNotEmpty
                    ? () => _exportToAI(context, services)
                    : null,
                icon: PhosphorIcon(PhosphorIcons.export(), size: 16),
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
      ),
    );
  }

  // ── Recording ─────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    if (!_speechAvailable) return;
    _sessionStart ??= DateTime.now();
    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
          _hasChanges = true;
        });
      },
      localeId: 'it_IT',
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 5),
    );
    setState(() => _isRecording = true);
  }

  void _stopRecording() {
    _speechToText.stop();
    setState(() => _isRecording = false);
  }

  // ── Save ─────────────────────────────────────────────────────────────

  Future<void> _saveBrainstorm(AppServices services) async {
    final note = _controller.text.trim();
    if (note.isEmpty) return;

    final today = DateTime.now();

    // Calcola e salva minuti di sessione
    if (_sessionStart != null) {
      final minutes = today.difference(_sessionStart!).inMinutes.clamp(0, 60);
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

    // Prompt strutturato
    final structuredPrompt =
        'Analizza i miei pensieri di oggi e aiutami a ragionare con più chiarezza. '
        'Identifica i pattern principali, le priorità implicite e suggeriscimi '
        'UNA domanda socratica che mi aiuti a fare il passo successivo.\n\n'
        'I MIEI PENSIERI:\n$text';

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
    _controller.dispose();
    _speechToText.stop();
    super.dispose();
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          color: isPro ? null : AppColors.cyan.withOpacity(0.05),
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
                  isPro ? PhosphorIconsStyle.fill : PhosphorIconsStyle.regular),
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
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.cyan.withOpacity(0.6),
                          ),
                    ),
                ],
              ),
            ),
            if (!isPro)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(_ctrl);
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
