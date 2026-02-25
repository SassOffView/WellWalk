import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/routine_item.dart';
import '../../core/models/user_profile.dart';
import '../../core/models/ai_provider_config.dart';

// ─── Dati raccolti durante l'onboarding ──────────────────────────────────────

class _OnboardingData {
  String language = 'it';
  int stepGoal = 8000;
  List<String> routines = [''];
  String name = '';
  int brainstormMinutes = 10;
  String aiProvider = 'none'; // 'gemini' | 'openai' | 'claude' | 'none'
}

// ─── OnboardingScreen ─────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _data = _OnboardingData();
  int _currentPage = 0;
  static const _totalPages = 5;

  void _goNext() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _goBack() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    final services = context.read<AppServices>();
    final uuid = const Uuid();

    // 1. Salva profilo parziale con i dati raccolti nelle slide
    final partialProfile = UserProfile(
      name: _data.name.trim().isEmpty ? '' : _data.name.trim(),
      age: 0, // verrà completato in setup_profile_screen
      gender: Gender.other,
      createdAt: DateTime.now(),
      preferredLanguage: _data.language,
      stepGoal: _data.stepGoal,
      brainstormMinutesGoal: _data.brainstormMinutes,
      hasCompletedOnboarding: false,
    );
    await services.db.saveUserProfile(partialProfile);

    // 2. Salva le routine raccolte nello step 2
    int order = 0;
    for (final title in _data.routines) {
      final t = title.trim();
      if (t.isEmpty) continue;
      await services.db.saveRoutine(RoutineItem(
        id: uuid.v4(),
        title: t,
        createdAt: DateTime.now(),
        order: order++,
      ));
    }

    // 3. Salva la preferenza AI (senza API key — gestita da backend)
    if (_data.aiProvider != 'none') {
      final providerMap = {
        'gemini': AiProvider.gemini,
        'openai': AiProvider.openai,
        'claude': AiProvider.claude,
      };
      final provider = providerMap[_data.aiProvider] ?? AiProvider.none;
      if (provider != AiProvider.none) {
        final config = AiProviderConfig(
          provider: provider,
          isEnabled: true,
          isApiKeyValid: false, // la chiave viene dal backend
        );
        await services.aiInsight.saveProviderConfig(config, apiKey: '');
      }
    }

    if (mounted) context.go('/setup');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      icon: PhosphorIcon(
                        PhosphorIcons.arrowLeft(),
                        color: Colors.white54,
                        size: 22,
                      ),
                      onPressed: _goBack,
                    )
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/setup'),
                    child: const Text(
                      'Salta',
                      style: TextStyle(
                        color: Colors.white38,
                        fontFamily: 'Inter',
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Progress dots ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalPages, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentPage == i ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? AppColors.cyan
                        : Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),
            ),

            // ── Slides ────────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _Slide0Welcome(
                    data: _data,
                    onLanguageChanged: (lang) =>
                        setState(() => _data.language = lang),
                  ),
                  _Slide1Steps(
                    data: _data,
                    onStepGoalChanged: (v) =>
                        setState(() => _data.stepGoal = v),
                  ),
                  _Slide2Habits(
                    data: _data,
                    onRoutinesChanged: (list) =>
                        setState(() => _data.routines = list),
                  ),
                  _Slide3Brainstorm(
                    data: _data,
                    onNameChanged: (v) => setState(() => _data.name = v),
                    onMinutesChanged: (v) =>
                        setState(() => _data.brainstormMinutes = v),
                  ),
                  _Slide4Journey(
                    data: _data,
                    onAiChanged: (v) =>
                        setState(() => _data.aiProvider = v),
                  ),
                ],
              ),
            ),

            // ── CTA button ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _goNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentPage < _totalPages - 1
                        ? 'Avanti'
                        : 'Inizia il viaggio',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

// ─── Slide 0 — Benvenuto ──────────────────────────────────────────────────────

class _Slide0Welcome extends StatelessWidget {
  const _Slide0Welcome({required this.data, required this.onLanguageChanged});
  final _OnboardingData data;
  final ValueChanged<String> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
      child: Column(
        children: [
          // Logo
          _LogoArea(),
          const SizedBox(height: 28),

          // Title
          const Text(
            'Benvenuto in MindStep',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              fontFamily: 'Inter',
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Movimento, pensiero libero, organizzazione e coaching.\nTutto questo in un solo posto.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 15,
              height: 1.6,
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Language selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LINGUA / LANGUAGE',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _LangChip(
                      label: '🇮🇹  Italiano',
                      code: 'it',
                      isSelected: data.language == 'it',
                      onTap: () => onLanguageChanged('it'),
                    ),
                    const SizedBox(width: 10),
                    _LangChip(
                      label: '🇬🇧  English',
                      code: 'en',
                      isSelected: data.language == 'en',
                      onTap: () => onLanguageChanged('en'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Slide 1 — Traccia ogni passo ────────────────────────────────────────────

class _Slide1Steps extends StatefulWidget {
  const _Slide1Steps({required this.data, required this.onStepGoalChanged});
  final _OnboardingData data;
  final ValueChanged<int> onStepGoalChanged;

  @override
  State<_Slide1Steps> createState() => _Slide1StepsState();
}

class _Slide1StepsState extends State<_Slide1Steps> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.data.stepGoal.toString());
    _ctrl.addListener(() {
      final v = int.tryParse(_ctrl.text);
      if (v != null && v > 0) widget.onStepGoalChanged(v);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SlideIcon(icon: PhosphorIcons.footprints(PhosphorIconsStyle.fill)),
          const SizedBox(height: 24),

          const Text(
            'Traccia ogni passo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'La distanza che percorri\nconstruisce la persona che diventi.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 15,
              height: 1.6,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 28),

          // Step goal input
          _InputCard(
            label: 'OBIETTIVO PASSI GIORNALIERI',
            hint: 'Quanti passi vuoi fare ogni giorno?',
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      color: AppColors.cyan,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Inter',
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: '8000',
                      hintStyle: TextStyle(
                        color: Color(0xFF2A5A7A),
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const Text(
                  'passi',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 16,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Presets
          Wrap(
            spacing: 8,
            children: [5000, 8000, 10000, 12000].map((v) => _PresetChip(
              label: '$v',
              isSelected: widget.data.stepGoal == v,
              onTap: () {
                _ctrl.text = v.toString();
                widget.onStepGoalChanged(v);
              },
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Slide 2 — Le piccole abitudini ──────────────────────────────────────────

class _Slide2Habits extends StatefulWidget {
  const _Slide2Habits({required this.data, required this.onRoutinesChanged});
  final _OnboardingData data;
  final ValueChanged<List<String>> onRoutinesChanged;

  @override
  State<_Slide2Habits> createState() => _Slide2HabitsState();
}

class _Slide2HabitsState extends State<_Slide2Habits> {
  late List<TextEditingController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = widget.data.routines.map((r) {
      final c = TextEditingController(text: r);
      c.addListener(_notify);
      return c;
    }).toList();
  }

  void _notify() {
    widget.onRoutinesChanged(_ctrls.map((c) => c.text).toList());
  }

  void _addRoutine() {
    if (_ctrls.length >= 5) return;
    setState(() {
      final c = TextEditingController();
      c.addListener(_notify);
      _ctrls.add(c);
    });
    _notify();
  }

  void _removeRoutine(int i) {
    if (_ctrls.length <= 1) return;
    setState(() {
      _ctrls[i].dispose();
      _ctrls.removeAt(i);
    });
    _notify();
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SlideIcon(icon: PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)),
          const SizedBox(height: 24),

          const Text(
            'Le piccole abitudini',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'fanno i grandi cambiamenti.\nAggiungi le routine che vuoi completare ogni giorno.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 15,
              height: 1.6,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 24),

          // Routine list
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Column(
              children: List.generate(_ctrls.length, (i) => Column(
                children: [
                  if (i > 0)
                    Container(
                      height: 1,
                      color: Colors.white.withOpacity(0.07),
                    ),
                  Row(
                    children: [
                      const SizedBox(width: 16),
                      PhosphorIcon(
                        PhosphorIcons.checkCircle(),
                        color: AppColors.cyan.withOpacity(0.5),
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _ctrls[i],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Inter',
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: i == 0
                                ? 'Es. Meditazione 10 min'
                                : 'Es. Lettura 15 min',
                            hintStyle: const TextStyle(
                              color: Colors.white24,
                              fontSize: 14,
                            ),
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      if (_ctrls.length > 1)
                        IconButton(
                          icon: PhosphorIcon(
                            PhosphorIcons.x(),
                            color: Colors.white24,
                            size: 16,
                          ),
                          onPressed: () => _removeRoutine(i),
                        ),
                    ],
                  ),
                ],
              )),
            ),
          ),

          if (_ctrls.length < 5)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: TextButton.icon(
                onPressed: _addRoutine,
                icon: PhosphorIcon(
                  PhosphorIcons.plus(),
                  color: AppColors.cyan,
                  size: 16,
                ),
                label: const Text(
                  'Aggiungi abitudine',
                  style: TextStyle(color: AppColors.cyan, fontFamily: 'Inter'),
                ),
              ),
            ),

          const SizedBox(height: 8),
          Text(
            'Puoi aggiungerne fino a 5 ora. Modificabili in seguito.',
            style: TextStyle(
              color: AppColors.cyan.withOpacity(0.4),
              fontSize: 11,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Slide 3 — Cattura i tuoi pensieri ───────────────────────────────────────

class _Slide3Brainstorm extends StatefulWidget {
  const _Slide3Brainstorm({
    required this.data,
    required this.onNameChanged,
    required this.onMinutesChanged,
  });
  final _OnboardingData data;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<int> onMinutesChanged;

  @override
  State<_Slide3Brainstorm> createState() => _Slide3BrainstormState();
}

class _Slide3BrainstormState extends State<_Slide3Brainstorm> {
  late TextEditingController _nameCtrl;
  late TextEditingController _minCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.data.name);
    _minCtrl =
        TextEditingController(text: widget.data.brainstormMinutes.toString());
    _nameCtrl.addListener(() => widget.onNameChanged(_nameCtrl.text));
    _minCtrl.addListener(() {
      final v = int.tryParse(_minCtrl.text);
      if (v != null && v > 0) widget.onMinutesChanged(v);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SlideIcon(icon: PhosphorIcons.brain(PhosphorIconsStyle.fill)),
          const SizedBox(height: 24),

          const Text(
            'Cattura i tuoi pensieri',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Le idee migliori nascono mentre cammini.\nRegistrale prima che svaniscano.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 15,
              height: 1.6,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 28),

          // Nome
          _InputCard(
            label: 'COME TI CHIAMI?',
            hint: 'Il tuo nome — verrà usato per personalizzare l\'esperienza',
            child: TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Il tuo nome',
                hintStyle: TextStyle(
                  color: Colors.white24,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Minuti brainstorming
          _InputCard(
            label: 'MINUTI DI BRAINSTORMING AL GIORNO',
            hint: 'Quanto tempo vuoi dedicare ai tuoi pensieri?',
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      color: AppColors.cyan,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Inter',
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: '10',
                      hintStyle: TextStyle(
                        color: Color(0xFF2A5A7A),
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const Text(
                  'min / giorno',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: [5, 10, 15, 20].map((v) => _PresetChip(
              label: '$v min',
              isSelected: widget.data.brainstormMinutes == v,
              onTap: () {
                _minCtrl.text = v.toString();
                widget.onMinutesChanged(v);
              },
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Slide 4 — Il viaggio inizia adesso ──────────────────────────────────────

class _Slide4Journey extends StatelessWidget {
  const _Slide4Journey(
      {required this.data, required this.onAiChanged});
  final _OnboardingData data;
  final ValueChanged<String> onAiChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SlideIcon(icon: PhosphorIcons.target(PhosphorIconsStyle.fill)),
          const SizedBox(height: 24),

          const Text(
            'Il tuo viaggio inizia adesso',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Movimento, pensiero libero, organizzazione e coaching.\nScegli il tuo AI coach per un\'esperienza personalizzata.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 14,
              height: 1.6,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 24),

          // AI provider selection
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SCEGLI IL TUO AI COACH',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 14),
                ...[
                  (
                    'gemini',
                    '✨',
                    'Google Gemini',
                    'Ottimo in italiano • Potente e veloce'
                  ),
                  (
                    'openai',
                    '🤖',
                    'ChatGPT (OpenAI)',
                    'GPT-4o-mini • Preciso e versatile'
                  ),
                  (
                    'claude',
                    '🧠',
                    'Claude (Anthropic)',
                    'Riflessivo e naturale • Ideale per coaching'
                  ),
                  (
                    'none',
                    '⏭️',
                    'Sceglierò dopo',
                    'Puoi configurarlo in seguito dalle Impostazioni'
                  ),
                ].map((item) {
                  final (code, emoji, name, desc) = item;
                  final isSelected = data.aiProvider == code;
                  return GestureDetector(
                    onTap: () => onAiChanged(code),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.cyan.withOpacity(0.10)
                            : Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.cyan
                              : Colors.white.withOpacity(0.08),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(emoji,
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.cyan
                                        : Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                Text(
                                  desc,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.cyan.withOpacity(0.65)
                                        : Colors.white38,
                                    fontSize: 11,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            PhosphorIcon(
                              PhosphorIcons.checkCircle(
                                  PhosphorIconsStyle.fill),
                              color: AppColors.cyan,
                              size: 18,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ──────────────────────────────────────────────────────────

/// Logo area: mostra l'immagine ufficiale se presente, altrimenti il fallback
class _LogoArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.cyan.withOpacity(0.15),
            AppColors.cyanLight.withOpacity(0.08),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withOpacity(0.18),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
            child: PhosphorIcon(
              PhosphorIcons.waves(PhosphorIconsStyle.fill),
              size: 52,
              color: AppColors.cyan,
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideIcon extends StatelessWidget {
  const _SlideIcon({required this.icon});
  final PhosphorIconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.cyan.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cyan.withOpacity(0.25)),
      ),
      child: Center(
        child: PhosphorIcon(icon, size: 34, color: AppColors.cyan),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.label,
    required this.hint,
    required this.child,
  });
  final String label;
  final String hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: const TextStyle(
              color: Colors.white24,
              fontSize: 11,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyan.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.cyan : Colors.white.withOpacity(0.12),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.cyan : Colors.white38,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.code,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final String code;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyan.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.cyan : Colors.white.withOpacity(0.12),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.cyan : Colors.white54,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}
