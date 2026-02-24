import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/user_profile.dart';

/// Step onboarding: obiettivi giornalieri e lingua delle citazioni.
/// Viene chiamato dopo SetupExtrasScreen e prima di '/home'.
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
  late int _stepGoal;
  late int _walkMinutesGoal;
  late int _brainstormMinutesGoal;
  late String _language;

  @override
  void initState() {
    super.initState();
    _stepGoal = widget.profile.stepGoal;
    _walkMinutesGoal = widget.profile.walkMinutesGoal;
    _brainstormMinutesGoal = widget.profile.brainstormMinutesGoal;
    _language = widget.profile.preferredLanguage;
  }

  void _done() {
    final updated = widget.profile.copyWith(
      stepGoal: _stepGoal,
      walkMinutesGoal: _walkMinutesGoal,
      brainstormMinutesGoal: _brainstormMinutesGoal,
      preferredLanguage: _language,
      hasCompletedOnboarding: true,
    );
    widget.onDone(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  if (widget.onBack != null)
                    IconButton(
                      onPressed: widget.onBack,
                      icon: PhosphorIcon(
                        PhosphorIcons.arrowLeft(),
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.goalsTitle,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.goalsSubtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Lingua ─────────────────────────────────────────
                    _SectionLabel(
                      icon: PhosphorIcons.translate(),
                      label: AppStrings.goalsLanguageLabel,
                    ),
                    const SizedBox(height: 10),
                    _LanguageSelector(
                      selected: _language,
                      onChanged: (lang) => setState(() => _language = lang),
                    ),

                    const SizedBox(height: 28),

                    // ── Passi ─────────────────────────────────────────
                    _SectionLabel(
                      icon: PhosphorIcons.footprints(),
                      label: AppStrings.goalsStepLabel,
                    ),
                    const SizedBox(height: 4),
                    _GoalSlider(
                      value: _stepGoal.toDouble(),
                      min: 2000,
                      max: 20000,
                      divisions: 18,
                      displayValue: '$_stepGoal passi',
                      color: AppColors.cyan,
                      onChanged: (v) => setState(() => _stepGoal = v.round()),
                    ),

                    const SizedBox(height: 24),

                    // ── Minuti camminata ──────────────────────────────
                    _SectionLabel(
                      icon: PhosphorIcons.personSimpleWalk(),
                      label: AppStrings.goalsWalkLabel,
                    ),
                    const SizedBox(height: 4),
                    _GoalSlider(
                      value: _walkMinutesGoal.toDouble(),
                      min: 10,
                      max: 90,
                      divisions: 16,
                      displayValue: '$_walkMinutesGoal min',
                      color: const Color(0xFF4CAF50),
                      onChanged: (v) =>
                          setState(() => _walkMinutesGoal = v.round()),
                    ),

                    const SizedBox(height: 24),

                    // ── Minuti brainstorming ──────────────────────────
                    _SectionLabel(
                      icon: PhosphorIcons.brain(),
                      label: AppStrings.goalsBrainLabel,
                    ),
                    const SizedBox(height: 4),
                    _GoalSlider(
                      value: _brainstormMinutesGoal.toDouble(),
                      min: 3,
                      max: 30,
                      divisions: 9,
                      displayValue: '$_brainstormMinutesGoal min',
                      color: const Color(0xFF9C27B0),
                      onChanged: (v) =>
                          setState(() => _brainstormMinutesGoal = v.round()),
                    ),

                    const SizedBox(height: 40),

                    // Nota
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.cyan.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          PhosphorIcon(
                            PhosphorIcons.info(),
                            color: AppColors.cyan,
                            size: 16,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Puoi modificare questi obiettivi in qualsiasi momento dalle impostazioni.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.cyan),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _done,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    AppStrings.goalsContinue,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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
}

// ── Componenti interni ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});
  final PhosphorIconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PhosphorIcon(icon, size: 18, color: AppColors.cyan),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _GoalSlider extends StatelessWidget {
  const _GoalSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.color,
    required this.onChanged,
  });

  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final Color color;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: color,
            inactiveTrackColor: color.withOpacity(0.2),
            overlayColor: color.withOpacity(0.1),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${min.round()}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  displayValue,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '${max.round()}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LangChip(
          label: AppStrings.goalsLanguageIt,
          flag: '🇮🇹',
          isSelected: selected == 'it',
          onTap: () => onChanged('it'),
        ),
        const SizedBox(width: 12),
        _LangChip(
          label: AppStrings.goalsLanguageEn,
          flag: '🇬🇧',
          isSelected: selected == 'en',
          onTap: () => onChanged('en'),
        ),
      ],
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.flag,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String flag;
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
              ? AppColors.cyan.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.cyan : AppColors.lightBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? AppColors.cyan
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
