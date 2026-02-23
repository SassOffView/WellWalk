import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/models/day_data.dart';
import '../../../shared/widgets/ms_card.dart';

class BrainstormWidget extends StatefulWidget {
  const BrainstormWidget({
    super.key,
    this.dayData,
    this.onSaved,
    this.aiPromptOfDay,
  });

  final DayData? dayData;
  final VoidCallback? onSaved;

  /// Prompt brainstorming generato dall'AI per oggi (se configurato)
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

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _controller.text = widget.dayData?.brainstormNote ?? '';
    _controller.addListener(() => setState(() => _hasChanges = true));
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
              const Text('💭', style: TextStyle(fontSize: 20)),
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

          // Voice button (Pro only)
          if (services.isPro && _speechAvailable)
            GestureDetector(
              onTap: _isRecording ? _stopRecording : _startRecording,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isRecording
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.cyan.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isRecording
                        ? AppColors.error
                        : AppColors.cyan.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: _isRecording ? AppColors.error : AppColors.cyan,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isRecording
                          ? AppStrings.brainStopRecord
                          : AppStrings.brainRecord,
                      style: TextStyle(
                        color: _isRecording ? AppColors.error : AppColors.cyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_isRecording) ...[
                      const SizedBox(width: 8),
                      // Pulse indicator
                      _PulseIndicator(),
                    ],
                  ],
                ),
              ),
            ),

          // Voice Pro lock (Free users)
          if (!services.isPro)
            GestureDetector(
              onTap: () => context.push('/paywall'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cyan.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mic_off, color: AppColors.cyan, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        AppStrings.brainVoiceProOnly,
                        style: TextStyle(
                          color: AppColors.cyan,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
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
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),

          // ── AI prompt del giorno ────────────────────────────────────
          if (widget.aiPromptOfDay != null &&
              widget.aiPromptOfDay!.isNotEmpty) ...[
            GestureDetector(
              onTap: () {
                // Usa il prompt come starter se l'area è vuota
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
                    const Text('💡', style: TextStyle(fontSize: 13)),
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
                    const Icon(Icons.touch_app_outlined,
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
              // Save
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _hasChanges ? () => _saveBrainstorm(services) : null,
                  icon: const Icon(Icons.save_alt, size: 16),
                  label: const Text(AppStrings.brainSave,
                      style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Export
              OutlinedButton.icon(
                onPressed: _controller.text.isNotEmpty
                    ? () => _exportText()
                    : null,
                icon: const Icon(Icons.ios_share, size: 16),
                label: const Text(AppStrings.brainExport,
                    style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 12),
                ),
              ),

              // AI (Pro only)
              if (services.isPro) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _controller.text.isNotEmpty
                      ? () => _showAIMenu(context)
                      : null,
                  icon: const Text('🤖', style: TextStyle(fontSize: 14)),
                  label: const Text('AI', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 12),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _startRecording() async {
    if (!_speechAvailable) return;

    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
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

  Future<void> _saveBrainstorm(AppServices services) async {
    final note = _controller.text.trim();
    if (note.isEmpty) return;

    // Salva nel DB
    await services.db.saveBrainstormNote(DateTime.now(), note);

    // Carica profilo per flag globale (FIX BUG #3 PWA)
    var profile = await services.db.loadUserProfile();
    final isFirstEver = !(profile?.hasBrainstormedEver ?? false);
    final totalCount = (profile?.totalBrainstormCount ?? 0) + 1;

    // Aggiorna profilo con flag globale
    if (profile != null) {
      profile = profile.copyWith(
        hasBrainstormedEver: true,
        totalBrainstormCount: totalCount,
      );
      await services.db.saveUserProfile(profile);
    }

    // Check badge brainstorm
    final dayData = await services.db.loadDayData(DateTime.now());
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

  void _exportText() {
    // Share via share_plus
    // Share.share(_controller.text, subject: 'MindStep - Brainstorm');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nota copiata negli appunti')),
    );
  }

  void _showAIMenu(BuildContext context) {
    final prompt = Uri.encodeComponent(
      AppStrings.aiPromptPrefix + _controller.text,
    );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.brainAIOptions,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 20),
              _AIOption(
                name: AppStrings.aiClaude,
                emoji: '🟠',
                url: 'https://claude.ai/new?q=$prompt',
              ),
              _AIOption(
                name: AppStrings.aiChatGPT,
                emoji: '🟢',
                url: 'https://chat.openai.com/?q=$prompt',
              ),
              _AIOption(
                name: AppStrings.aiGemini,
                emoji: '🔵',
                url: 'https://gemini.google.com/?q=$prompt',
              ),
              _AIOption(
                name: AppStrings.aiCopilot,
                emoji: '🟣',
                url: 'https://copilot.microsoft.com/?q=$prompt',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _speechToText.stop();
    super.dispose();
  }
}

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

class _AIOption extends StatelessWidget {
  const _AIOption({
    required this.name,
    required this.emoji,
    required this.url,
  });

  final String name;
  final String emoji;
  final String url;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(emoji, style: const TextStyle(fontSize: 24)),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.open_in_new, size: 16),
      onTap: () async {
        Navigator.pop(context);
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      },
    );
  }
}
