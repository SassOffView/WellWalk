import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/user_profile.dart';
import '../../core/models/routine_item.dart';
import '../../shared/widgets/ms_card.dart';

class SetupProfileScreen extends StatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {
  final _pageController = PageController();
  int _page = 0;

  // Page 1
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  Gender _gender = Gender.other;
  final _formKey1 = GlobalKey<FormState>();

  // Page 2
  final List<TextEditingController> _routineCtrl = [TextEditingController()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildProfilePage(),
            _buildRoutinesPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(AppStrings.setupTitle,
                style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 8),
            Text(AppStrings.setupSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                )),
            const SizedBox(height: 32),

            // Nome
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: AppStrings.setupNameLabel,
                hintText: AppStrings.setupNameHint,
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Inserisci il tuo nome' : null,
            ),
            const SizedBox(height: 16),

            // Età
            TextFormField(
              controller: _ageCtrl,
              decoration: const InputDecoration(
                labelText: AppStrings.setupAgeLabel,
                hintText: AppStrings.setupAgeHint,
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 10 || n > 120) return 'Inserisci un\'età valida';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Genere
            Text(AppStrings.setupGenderLabel,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                _GenderChip(
                  label: 'Uomo',
                  emoji: '👨',
                  selected: _gender == Gender.male,
                  onTap: () => setState(() => _gender = Gender.male),
                ),
                const SizedBox(width: 8),
                _GenderChip(
                  label: 'Donna',
                  emoji: '👩',
                  selected: _gender == Gender.female,
                  onTap: () => setState(() => _gender = Gender.female),
                ),
                const SizedBox(width: 8),
                _GenderChip(
                  label: 'Altro',
                  emoji: '🧑',
                  selected: _gender == Gender.other,
                  onTap: () => setState(() => _gender = Gender.other),
                ),
              ],
            ),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _goToRoutines,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(AppStrings.setupContinue,
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutinesPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _pageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
          ),
          const SizedBox(height: 8),
          Text(AppStrings.setupRoutinesTitle,
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(AppStrings.setupRoutinesSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              )),
          const SizedBox(height: 24),

          // Lista routine
          Expanded(
            child: ListView.separated(
              itemCount: _routineCtrl.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _routineCtrl[i],
                      decoration: InputDecoration(
                        hintText: AppStrings.setupRoutineHint,
                        prefixIcon: const Icon(Icons.check_circle_outline),
                      ),
                    ),
                  ),
                  if (_routineCtrl.length > 1)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: AppColors.error),
                      onPressed: () {
                        setState(() {
                          _routineCtrl[i].dispose();
                          _routineCtrl.removeAt(i);
                        });
                      },
                    ),
                ],
              ),
            ),
          ),

          // Add button (max 5 in free)
          if (_routineCtrl.length < 5)
            TextButton.icon(
              onPressed: () => setState(() => _routineCtrl.add(TextEditingController())),
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.setupRoutineAdd),
            ),

          // Hint Free limit
          Text(
            AppStrings.setupFreeLimit,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.cyan.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              TextButton(
                onPressed: _saveAndStart,
                child: const Text(AppStrings.setupRoutineSkip),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveAndStart,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(AppStrings.setupDone,
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _goToRoutines() {
    if (_formKey1.currentState?.validate() != true) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _page = 1);
  }

  Future<void> _saveAndStart() async {
    final services = context.read<AppServices>();

    // Salva profilo
    final profile = UserProfile(
      name: _nameCtrl.text.trim(),
      age: int.tryParse(_ageCtrl.text) ?? 25,
      gender: _gender,
      createdAt: DateTime.now(),
      hasCompletedOnboarding: true,
    );
    await services.db.saveUserProfile(profile);

    // Salva routine
    final uuid = const Uuid();
    for (int i = 0; i < _routineCtrl.length; i++) {
      final title = _routineCtrl[i].text.trim();
      if (title.isEmpty) continue;
      await services.db.saveRoutine(RoutineItem(
        id: uuid.v4(),
        title: title,
        createdAt: DateTime.now(),
        order: i,
      ));
    }

    if (mounted) context.go('/setup/extras');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    for (final c in _routineCtrl) c.dispose();
    _pageController.dispose();
    super.dispose();
  }
}

class _GenderChip extends StatelessWidget {
  const _GenderChip({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.cyan.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.cyan : AppColors.lightBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.cyan : null,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
