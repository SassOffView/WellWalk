import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/user_profile.dart';

/// Onboarding: completamento profilo (età + genere).
/// Nome e lingua già raccolti nelle slide precedenti.
class SetupProfileScreen extends StatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {
  final _ageCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  Gender _gender = Gender.other;
  bool _loading = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final services = context.read<AppServices>();
    final profile = await services.db.loadUserProfile();
    if (mounted) {
      setState(() {
        if (profile != null) {
          _nameCtrl.text = profile.name;
          _ageCtrl.text =
              profile.age > 0 ? profile.age.toString() : '';
          _gender = profile.gender;
        }
        _loading = false;
      });
    }
  }

  Future<void> _saveAndContinue() async {
    if (_formKey.currentState?.validate() != true) return;
    final services = context.read<AppServices>();

    final existing = await services.db.loadUserProfile();

    final profile = (existing ?? UserProfile(
      name: _nameCtrl.text.trim().isEmpty ? 'Amico' : _nameCtrl.text.trim(),
      age: int.tryParse(_ageCtrl.text) ?? 25,
      gender: _gender,
      createdAt: DateTime.now(),
    )).copyWith(
      name: _nameCtrl.text.trim().isEmpty ? 'Amico' : _nameCtrl.text.trim(),
      age: int.tryParse(_ageCtrl.text) ?? 25,
      gender: _gender,
    );

    await services.db.saveUserProfile(profile);
    if (mounted) context.go('/setup/extras');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.navyDark,
        body: Center(child: CircularProgressIndicator(color: AppColors.cyan)),
      );
    }

    return Scaffold(
      body: Container(
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
                const SizedBox(height: 32),
                _LogoArea(),
                const SizedBox(height: 16),
                const Text(
                  'MindStep',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Inter',
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: AppColors.cyan.withOpacity(0.35)),
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
                const SizedBox(height: 28),

                // ── Form card ────────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // NOME
                          _FieldBlock(
                            label: 'NOME',
                            child: TextFormField(
                              controller: _nameCtrl,
                              textCapitalization: TextCapitalization.words,
                              style: _inputStyle(),
                              decoration: _inputDeco('Il tuo nome'),
                              validator: (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Inserisci il tuo nome'
                                      : null,
                            ),
                          ),
                          _divider(),

                          // ETÀ
                          _FieldBlock(
                            label: 'ETÀ',
                            child: TextFormField(
                              controller: _ageCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              style: _inputStyle(),
                              decoration: _inputDeco('Es. 35'),
                              validator: (v) {
                                final n = int.tryParse(v ?? '');
                                if (n == null || n < 10 || n > 120) {
                                  return 'Inserisci un\'età valida';
                                }
                                return null;
                              },
                            ),
                          ),
                          _divider(),

                          // SESSO
                          _FieldBlock(
                            label: 'GENERE',
                            child: _GenderSelector(
                              value: _gender,
                              onChanged: (v) => setState(() => _gender = v),
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
                      onPressed: _saveAndContinue,
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
      ),
    );
  }

  Widget _divider() => Container(
        height: 1,
        color: const Color(0xFFF0F0F0),
      );

  static TextStyle _inputStyle() => const TextStyle(
        color: Colors.black87,
        fontSize: 16,
        fontFamily: 'Inter',
      );

  static InputDecoration _inputDeco(String hint) => InputDecoration(
        border: InputBorder.none,
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFFBDBDBD),
          fontSize: 16,
        ),
        isDense: true,
        contentPadding: EdgeInsets.zero,
      );

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }
}

// ── Logo area ─────────────────────────────────────────────────────────────────

class _LogoArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
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
            color: AppColors.cyan.withOpacity(0.25),
            blurRadius: 24,
            spreadRadius: 4,
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
              size: 36,
              color: AppColors.cyan,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Field block ───────────────────────────────────────────────────────────────

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9E9E9E),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// ── Gender selector ───────────────────────────────────────────────────────────

class _GenderSelector extends StatelessWidget {
  const _GenderSelector({required this.value, required this.onChanged});
  final Gender value;
  final ValueChanged<Gender> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: Gender.values.map((g) {
        final labels = {
          Gender.male: 'Uomo',
          Gender.female: 'Donna',
          Gender.other: 'Altro',
        };
        final isSelected = value == g;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(g),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.cyan.withOpacity(0.12)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.cyan : const Color(0xFFE0E0E0),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Text(
                labels[g]!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? AppColors.cyan : const Color(0xFF757575),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
