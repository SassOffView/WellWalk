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

// ─── Dati raccolti durante l'onboarding ──────────────────────────────────────

class _OnboardingData {
  String language = 'it';
  int stepGoal = 8000;
  List<String> routines = [''];
  String name = '';
  int age = 25;
  Gender gender = Gender.other;
  int brainstormMinutes = 10;
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
  static const _totalPages = 4;

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

    // 1. Salva profilo completo con tutti i dati raccolti nelle slide
    final profile = UserProfile(
      name: _data.name.trim().isEmpty ? '' : _data.name.trim(),
      age: _data.age,
      gender: _data.gender,
      createdAt: DateTime.now(),
      preferredLanguage: _data.language,
      stepGoal: _data.stepGoal,
      brainstormMinutesGoal: _data.brainstormMinutes,
      hasCompletedOnboarding: true,
    );
    await services.db.saveUserProfile(profile);

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

    if (mounted) context.go('/home');
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
                    onPressed: () => context.go('/home'),
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
                    onGenderChanged: (v) => setState(() => _data.gender = v),
                    onAgeChanged: (v) => setState(() => _data.age = v),
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
                        : 'Inizia MindStep',
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo grande e centrale
          _LogoArea(),
          const SizedBox(height: 32),

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
          const SizedBox(height: 14),
          const Text(
            'Movimento, pensiero libero e crescita personale.\nTutto questo in un solo posto.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 16,
              height: 1.6,
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),

          // Language selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                  mainAxisAlignment: MainAxisAlignment.center,
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

// ─── Slide 1 — Ogni passo conta ──────────────────────────────────────────────

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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _SlideIcon(icon: PhosphorIcons.footprints(PhosphorIconsStyle.fill)),
          const SizedBox(height: 28),

          const Text(
            'Ogni passo conta',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'La distanza che percorri\nconstruisce la persona che diventi.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 16,
              height: 1.6,
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Passi obiettivo — numero editabile + preset chips
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Column(
              children: [
                const Text(
                  'OBIETTIVO PASSI GIORNALIERI',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 12),
                // Editable large number
                IntrinsicWidth(
                  child: TextField(
                    controller: _ctrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.cyan,
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Inter',
                      height: 1.0,
                      letterSpacing: -2,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const Text(
                  'passi',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 15,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 20),
                // Preset chips 2x2
                Column(
                  children: [
                    Row(
                      children: [3000, 5000].map((v) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: v == 3000 ? 5 : 0, left: v == 5000 ? 5 : 0),
                          child: _PresetChip(
                            label: '${(v / 1000).toStringAsFixed(0)}k',
                            isSelected: widget.data.stepGoal == v,
                            onTap: () {
                              _ctrl.text = v.toString();
                              widget.onStepGoalChanged(v);
                            },
                          ),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [7000, 10000].map((v) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: v == 7000 ? 5 : 0, left: v == 10000 ? 5 : 0),
                          child: _PresetChip(
                            label: '${(v / 1000).toStringAsFixed(0)}k',
                            isSelected: widget.data.stepGoal == v,
                            onTap: () {
                              _ctrl.text = v.toString();
                              widget.onStepGoalChanged(v);
                            },
                          ),
                        ),
                      )).toList(),
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

// ─── Slide 2 — Le piccole routine ────────────────────────────────────────────

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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _SlideIcon(icon: PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)),
          const SizedBox(height: 28),

          const Text(
            'Le piccole routine',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'fanno i grandi cambiamenti.\nAggiungi le routine che vuoi coltivare ogni giorno.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 16,
              height: 1.6,
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Routine list
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Column(
              children: List.generate(_ctrls.length, (i) => Column(
                children: [
                  if (i > 0)
                    Container(
                      height: 1,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  Row(
                    children: [
                      const SizedBox(width: 16),
                      PhosphorIcon(
                        PhosphorIcons.checkCircle(),
                        color: AppColors.cyan.withOpacity(0.6),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _ctrls[i],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: 'Inter',
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            filled: true,
                            fillColor: Colors.transparent,
                            hintText: i == 0
                                ? 'Es. Meditazione 10 min'
                                : 'Es. Lettura 15 min',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 15,
                            ),
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      if (_ctrls.length > 1)
                        IconButton(
                          icon: PhosphorIcon(
                            PhosphorIcons.x(),
                            color: Colors.white30,
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
              padding: const EdgeInsets.only(top: 12),
              child: TextButton.icon(
                onPressed: _addRoutine,
                icon: PhosphorIcon(
                  PhosphorIcons.plus(),
                  color: AppColors.cyan,
                  size: 18,
                ),
                label: const Text(
                  'Aggiungi routine',
                  style: TextStyle(
                    color: AppColors.cyan,
                    fontFamily: 'Inter',
                    fontSize: 14,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 10),
          const Text(
            'Puoi aggiungere fino a 5 routine ora. Sono modificabili in seguito.',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Slide 3 — Organizza i tuoi pensieri ─────────────────────────────────────

class _Slide3Brainstorm extends StatefulWidget {
  const _Slide3Brainstorm({
    required this.data,
    required this.onNameChanged,
    required this.onMinutesChanged,
    required this.onGenderChanged,
    required this.onAgeChanged,
  });
  final _OnboardingData data;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<int> onMinutesChanged;
  final ValueChanged<Gender> onGenderChanged;
  final ValueChanged<int> onAgeChanged;

  @override
  State<_Slide3Brainstorm> createState() => _Slide3BrainstormState();
}

class _Slide3BrainstormState extends State<_Slide3Brainstorm> {
  late TextEditingController _nameCtrl;
  late TextEditingController _ageCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.data.name);
    _ageCtrl = TextEditingController(
      text: widget.data.age > 0 ? widget.data.age.toString() : '',
    );
    _nameCtrl.addListener(() => widget.onNameChanged(_nameCtrl.text));
    _ageCtrl.addListener(() {
      final v = int.tryParse(_ageCtrl.text);
      if (v != null && v > 0) widget.onAgeChanged(v);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _SlideIcon(icon: PhosphorIcons.brain(PhosphorIconsStyle.fill)),
          const SizedBox(height: 28),

          const Text(
            'Organizza i tuoi pensieri',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Le idee migliori nascono mentre cammini.\nRegistrale e organizzale con MindStep.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 16,
              height: 1.6,
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Nome + Genere + Età
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome
                const Text(
                  'COME TI CHIAMI?',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
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
                    filled: true,
                    fillColor: Colors.transparent,
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
                const SizedBox(height: 16),

                // Età
                const Text(
                  'QUANTI ANNI HAI?',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _ageCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.transparent,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'La tua età',
                    hintStyle: TextStyle(
                      color: Colors.white24,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Genere
                const Text(
                  'GENERE',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _GenderChip(
                      label: 'Uomo',
                      gender: Gender.male,
                      selected: widget.data.gender,
                      onTap: widget.onGenderChanged,
                    ),
                    const SizedBox(width: 8),
                    _GenderChip(
                      label: 'Donna',
                      gender: Gender.female,
                      selected: widget.data.gender,
                      onTap: widget.onGenderChanged,
                    ),
                    const SizedBox(width: 8),
                    _GenderChip(
                      label: 'Altro',
                      gender: Gender.other,
                      selected: widget.data.gender,
                      onTap: widget.onGenderChanged,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Minuti brainstorming — preset 2x2
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Column(
              children: [
                const Text(
                  'MINUTI DI BRAINSTORMING AL GIORNO',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 14),
                // 2x2 grid
                Column(
                  children: [
                    Row(
                      children: [5, 10].map((v) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: v == 5 ? 5 : 0, left: v == 10 ? 5 : 0),
                          child: _BigPresetChip(
                            label: '$v min',
                            isSelected: widget.data.brainstormMinutes == v,
                            onTap: () => widget.onMinutesChanged(v),
                          ),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [15, 20].map((v) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: v == 15 ? 5 : 0, left: v == 20 ? 5 : 0),
                          child: _BigPresetChip(
                            label: '$v min',
                            isSelected: widget.data.brainstormMinutes == v,
                            onTap: () => widget.onMinutesChanged(v),
                          ),
                        ),
                      )).toList(),
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

// ─── Shared Widgets ──────────────────────────────────────────────────────────

/// Logo area: mostra l'immagine ufficiale se presente, altrimenti il fallback
class _LogoArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withOpacity(0.22),
            blurRadius: 40,
            spreadRadius: 6,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.cyan.withOpacity(0.20),
                  AppColors.cyanLight.withOpacity(0.10),
                ],
              ),
            ),
            child: Center(
              child: PhosphorIcon(
                PhosphorIcons.waves(PhosphorIconsStyle.fill),
                size: 64,
                color: AppColors.cyan,
              ),
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
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.cyan.withOpacity(0.10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cyan.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withOpacity(0.12),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: PhosphorIcon(icon, size: 48, color: AppColors.cyan),
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

class _GenderChip extends StatelessWidget {
  const _GenderChip({
    required this.label,
    required this.gender,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final Gender gender;
  final Gender selected;
  final ValueChanged<Gender> onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(gender),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.cyan.withOpacity(0.15)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.cyan
                  : Colors.white.withOpacity(0.12),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppColors.cyan : Colors.white54,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }
}

class _BigPresetChip extends StatelessWidget {
  const _BigPresetChip({
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyan.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.cyan : Colors.white.withOpacity(0.12),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppColors.cyan : Colors.white54,
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}
