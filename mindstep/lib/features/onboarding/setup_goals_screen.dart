import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/user_profile.dart';

/// Schermata onboarding: obiettivi giornalieri — dark navy, text fields.
class SetupGoalsScreen extends StatefulWidget {
  const SetupGoalsScreen({
    super.key,
    required this.profile,
    required this.onDone,
    this.onBack,
  });

  final UserProfile profile;
  final void Function(UserProfile updated) onDone;
  final VoidCallback? onBack;

  @override
  State<SetupGoalsScreen> createState() => _SetupGoalsScreenState();
}

class _SetupGoalsScreenState extends State<SetupGoalsScreen> {
  late final TextEditingController _stepsCtrl;
  late final TextEditingController _walkCtrl;
  late final TextEditingController _voiceCtrl;
  late final TextEditingController _brainstormCtrl;
  late String _language;

  @override
  void initState() {
    super.initState();
    _stepsCtrl = TextEditingController(text: widget.profile.stepGoal.toString());
    _walkCtrl = TextEditingController(text: widget.profile.walkMinutesGoal.toString());
    _voiceCtrl = TextEditingController(text: widget.profile.dailyVoiceSessionsGoal.toString());
    _brainstormCtrl = TextEditingController(text: widget.profile.brainstormMinutesGoal.toString());
    _language = widget.profile.preferredLanguage;
  }

  @override
  void dispose() {
    _stepsCtrl.dispose();
    _walkCtrl.dispose();
    _voiceCtrl.dispose();
    _brainstormCtrl.dispose();
    super.dispose();
  }

  void _done() {
    final updated = widget.profile.copyWith(
      stepGoal: int.tryParse(_stepsCtrl.text) ?? 8000,
      walkMinutesGoal: int.tryParse(_walkCtrl.text) ?? 30,
      dailyVoiceSessionsGoal: int.tryParse(_voiceCtrl.text) ?? 2,
      brainstormMinutesGoal: int.tryParse(_brainstormCtrl.text) ?? 10,
      preferredLanguage: _language,
      hasCompletedOnboarding: true,
    );
    widget.onDone(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.navyDark, Color(0xFF0D1B3E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (widget.onBack != null)
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 0, 0),
                    child: IconButton(
                      onPressed: widget.onBack,
                      icon: PhosphorIcon(
                        PhosphorIcons.arrowLeft(),
                        color: Colors.white60,
                      ),
                    ),
                  ),
                ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ── Header Icon ──────────────────────────────────
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.cyan.withOpacity(0.3),
                          ),
                        ),
                        child: Center(
                          child: PhosphorIcon(
                            PhosphorIcons.target(PhosphorIconsStyle.fill),
                            color: AppColors.cyan,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Title ───────────────────────────────────────
                      const Text(
                        'Obiettivi Personali',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Inter',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Definisci i tuoi target giornalieri.\nModificabili in qualsiasi momento dalle Impostazioni.',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                          height: 1.5,
                          fontFamily: 'Inter',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // ── Info box ─────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.cyan.withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            PhosphorIcon(
                              PhosphorIcons.info(PhosphorIconsStyle.fill),
                              color: AppColors.cyan,
                              size: 16,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'I 3 anelli del timer si riempiranno progressivamente al raggiungimento di questi obiettivi.',
                                style: TextStyle(
                                  color: AppColors.cyan,
                                  fontSize: 12,
                                  height: 1.5,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Form card ────────────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.10),
                          ),
                        ),
                        child: Column(
                          children: [
                            // LINGUA
                            _GoalRow(
                              label: 'LINGUA / LANGUAGE',
                              child: _LanguageRow(
                                selected: _language,
                                onChanged: (v) => setState(() => _language = v),
                              ),
                            ),
                            _divider(),

                            // PASSI / GIORNO
                            _GoalRow(
                              label: 'PASSI / GIORNO',
                              child: _NumInput(
                                controller: _stepsCtrl,
                                hint: '8000',
                                suffix: 'passi',
                                color: AppColors.cyan,
                              ),
                            ),
                            _divider(),

                            // MINUTI CAMMINO
                            _GoalRow(
                              label: 'MINUTI CAMMINO',
                              child: _NumInput(
                                controller: _walkCtrl,
                                hint: '30',
                                suffix: 'min',
                                color: const Color(0xFF4CAF50),
                              ),
                            ),
                            _divider(),

                            // SESSIONI VOICE / GIORNO
                            _GoalRow(
                              label: 'SESSIONI VOICE / GIORNO',
                              child: _NumInput(
                                controller: _voiceCtrl,
                                hint: '2',
                                suffix: 'sess.',
                                color: const Color(0xFF9C27B0),
                              ),
                            ),
                            _divider(),

                            // MIN BRAINSTORMING
                            _GoalRow(
                              label: 'MIN BRAINSTORMING',
                              child: _NumInput(
                                controller: _brainstormCtrl,
                                hint: '10',
                                suffix: 'min',
                                color: const Color(0xFF2196F3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),

              // ── CTA ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _done,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cyan,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Continua',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.white.withOpacity(0.07),
      );
}

// ── _GoalRow ──────────────────────────────────────────────────────────────────

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                fontFamily: 'Inter',
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

// ── _NumInput ─────────────────────────────────────────────────────────────────

class _NumInput extends StatelessWidget {
  const _NumInput({
    required this.controller,
    required this.hint,
    required this.suffix,
    required this.color,
  });
  final TextEditingController controller;
  final String hint;
  final String suffix;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 68,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: TextStyle(
                color: color.withOpacity(0.35),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          suffix,
          style: TextStyle(
            color: color.withOpacity(0.65),
            fontSize: 12,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}

// ── _LanguageRow ──────────────────────────────────────────────────────────────

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LangBtn(
          label: 'IT — Italiano',
          code: 'it',
          isSelected: selected == 'it',
          onTap: () => onChanged('it'),
        ),
        const SizedBox(width: 8),
        _LangBtn(
          label: 'EN',
          code: 'en',
          isSelected: selected == 'en',
          onTap: () => onChanged('en'),
        ),
      ],
    );
  }
}

class _LangBtn extends StatelessWidget {
  const _LangBtn({
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyan.withOpacity(0.18)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.cyan : Colors.white24,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.cyan : Colors.white54,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}
