import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/user_profile.dart';
import '../../core/models/routine_item.dart';

/// Onboarding: profilo utente — dark navy con header MindStep brandizzato.
class SetupProfileScreen extends StatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {
  final _pageController = PageController();

  // Page 1 — Profilo
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  Gender _gender = Gender.other;
  String _language = 'it';
  final _formKey = GlobalKey<FormState>();

  // Page 2 — Routine
  final List<TextEditingController> _routineCtrl = [TextEditingController()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildProfilePage(),
          _buildRoutinesPage(),
        ],
      ),
    );
  }

  // ── Page 1: Profilo ─────────────────────────────────────────────────────────

  Widget _buildProfilePage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.navyDark, Color(0xFF0D1B3E)],
        ),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────
              const SizedBox(height: 36),
              const Text(
                'MindStep',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Inter',
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cyan.withOpacity(0.4)),
                ),
                child: const Text(
                  'AI WALKING INTELLIGENCE',
                  style: TextStyle(
                    color: AppColors.cyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Il tuo coach vocale mentre cammini.\nRegistra, pensa, analizza, migliora.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    height: 1.5,
                    fontFamily: 'Inter',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              // ── Form card ────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
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
                        _FormRow(
                          label: 'LINGUA / LANGUAGE',
                          child: _LanguageDropdown(
                            value: _language,
                            onChanged: (v) => setState(() => _language = v!),
                          ),
                        ),
                        _divider(),

                        // NOME
                        _FormRow(
                          label: 'NOME',
                          child: Expanded(
                            child: TextFormField(
                              controller: _nameCtrl,
                              textCapitalization: TextCapitalization.words,
                              style: _inputStyle(),
                              decoration: _inputDeco('Il tuo nome'),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Obbligatorio'
                                  : null,
                            ),
                          ),
                        ),
                        _divider(),

                        // ETÀ + SESSO (side by side)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          child: Row(
                            children: [
                              // ETÀ
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('ETÀ', style: _labelStyle),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _ageCtrl,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly
                                      ],
                                      style: _inputStyle(),
                                      decoration: _inputDeco('35'),
                                      validator: (v) {
                                        final n = int.tryParse(v ?? '');
                                        if (n == null || n < 10 || n > 120) {
                                          return 'Età non valida';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),

                              // SESSO
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('SESSO', style: _labelStyle),
                                    const SizedBox(height: 6),
                                    _GenderDropdown(
                                      value: _gender,
                                      onChanged: (v) =>
                                          setState(() => _gender = v!),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        _divider(),

                        // PESO (KG)
                        _FormRow(
                          label: 'PESO (KG)',
                          child: SizedBox(
                            width: 80,
                            child: TextFormField(
                              controller: _weightCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[\d.]'))
                              ],
                              textAlign: TextAlign.right,
                              style: _inputStyle(),
                              decoration: _inputDeco('70'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── CTA ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _goToRoutines,
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

  // ── Page 2: Routine ─────────────────────────────────────────────────────────

  Widget _buildRoutinesPage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.navyDark, Color(0xFF0D1B3E)],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 0, 0),
              child: IconButton(
                icon: PhosphorIcon(
                  PhosphorIcons.arrowLeft(),
                  color: Colors.white60,
                ),
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Le tue prime abitudini',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Aggiungi le routine che vuoi completare ogni giorno\n(puoi modificarle in seguito)',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      height: 1.5,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Lista routine
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _routineCtrl.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      PhosphorIcon(
                        PhosphorIcons.checkCircle(),
                        color: AppColors.cyan.withOpacity(0.6),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _routineCtrl[i],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Inter',
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Es. Meditazione 10 min',
                            hintStyle: TextStyle(
                              color: Colors.white30,
                              fontSize: 14,
                            ),
                            isDense: true,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      if (_routineCtrl.length > 1)
                        IconButton(
                          icon: PhosphorIcon(
                            PhosphorIcons.x(),
                            color: Colors.white30,
                            size: 18,
                          ),
                          onPressed: () => setState(() {
                            _routineCtrl[i].dispose();
                            _routineCtrl.removeAt(i);
                          }),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Add button (max 5 free)
            if (_routineCtrl.length < 5)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 0, 0),
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() => _routineCtrl.add(TextEditingController())),
                  icon: PhosphorIcon(
                    PhosphorIcons.plus(),
                    color: AppColors.cyan,
                    size: 18,
                  ),
                  label: const Text(
                    'Aggiungi abitudine',
                    style: TextStyle(
                      color: AppColors.cyan,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
              child: Text(
                'Piano Free: max 5 abitudini',
                style: TextStyle(
                  color: AppColors.cyan.withOpacity(0.5),
                  fontSize: 11,
                  fontFamily: 'Inter',
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _saveAndContinue,
                    child: const Text(
                      'Salta',
                      style: TextStyle(color: Colors.white38, fontFamily: 'Inter'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveAndContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyan,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Continua',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _goToRoutines() {
    if (_formKey.currentState?.validate() != true) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _saveAndContinue() async {
    final services = context.read<AppServices>();
    final weight = double.tryParse(_weightCtrl.text.replaceAll(',', '.'));

    final profile = UserProfile(
      name: _nameCtrl.text.trim().isEmpty ? 'Amico' : _nameCtrl.text.trim(),
      age: int.tryParse(_ageCtrl.text) ?? 25,
      gender: _gender,
      createdAt: DateTime.now(),
      weightKg: weight,
      preferredLanguage: _language,
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

  Widget _divider() => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.white.withOpacity(0.07),
      );

  static TextStyle _inputStyle() => const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontFamily: 'Inter',
      );

  static InputDecoration _inputDeco(String hint) => InputDecoration(
        border: InputBorder.none,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
        isDense: true,
        contentPadding: EdgeInsets.zero,
      );

  static const _labelStyle = TextStyle(
    color: Colors.white54,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    fontFamily: 'Inter',
  );

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    for (final c in _routineCtrl) c.dispose();
    _pageController.dispose();
    super.dispose();
  }
}

// ── _FormRow ──────────────────────────────────────────────────────────────────

class _FormRow extends StatelessWidget {
  const _FormRow({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 2,
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
          Expanded(flex: 3, child: child),
        ],
      ),
    );
  }
}

// ── _LanguageDropdown ─────────────────────────────────────────────────────────

class _LanguageDropdown extends StatelessWidget {
  const _LanguageDropdown({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        dropdownColor: AppColors.navyMid,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontFamily: 'Inter',
        ),
        icon: PhosphorIcon(
          PhosphorIcons.caretDown(),
          size: 14,
          color: Colors.white54,
        ),
        items: const [
          DropdownMenuItem(value: 'it', child: Text('IT — Italiano')),
          DropdownMenuItem(value: 'en', child: Text('EN — English')),
        ],
      ),
    );
  }
}

// ── _GenderDropdown ───────────────────────────────────────────────────────────

class _GenderDropdown extends StatelessWidget {
  const _GenderDropdown({required this.value, required this.onChanged});
  final Gender value;
  final ValueChanged<Gender?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<Gender>(
        value: value,
        onChanged: onChanged,
        dropdownColor: AppColors.navyMid,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontFamily: 'Inter',
        ),
        icon: PhosphorIcon(
          PhosphorIcons.caretDown(),
          size: 14,
          color: Colors.white54,
        ),
        items: const [
          DropdownMenuItem(value: Gender.male, child: Text('Uomo')),
          DropdownMenuItem(value: Gender.female, child: Text('Donna')),
          DropdownMenuItem(value: Gender.other, child: Text('Altro')),
        ],
      ),
    );
  }
}
