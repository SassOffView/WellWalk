import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/ai_provider_config.dart';
import '../../core/models/user_profile.dart';
import '../../shared/widgets/ms_card.dart';
import '../onboarding/setup_ai_provider_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final services = context.read<AppServices>();
    final profile = await services.db.loadUserProfile();
    if (mounted) setState(() => _profile = profile);
  }

  @override
  Widget build(BuildContext context) {
    final services = context.read<AppServices>();
    final isPro = services.isPro;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(
                  AppStrings.settingsTitle,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
            ),

            // ── PRO Banner (se Free) ──────────────────────────────
            if (!isPro)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: GestureDetector(
                    onTap: () => context.push('/paywall'),
                    child: MsGradientCard(
                      child: Row(
                        children: [
                          PhosphorIcon(
                            PhosphorIcons.star(PhosphorIconsStyle.fill),
                            color: Colors.amber,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Upgrade a MindStep PRO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const Text(
                                  'GPS background, widget, Health Connect e molto altro',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ── Profilo ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: MsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.settingsProfile,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      if (_profile != null)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.cyan.withOpacity(0.15),
                            child: Text(
                              _profile!.firstName.isNotEmpty
                                  ? _profile!.firstName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: AppColors.cyan,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          title: Text(
                            _profile!.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${_profile!.age} anni · ${_profile!.genderLabel}',
                          ),
                          trailing: const Icon(Icons.edit_outlined, size: 18),
                          onTap: () => _editProfile(context),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Tema ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: MsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.settingsTheme,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      _ThemeSelector(
                        current: services.themeMode,
                        onChange: services.setThemeMode,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Notifiche ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: MsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.settingsNotifications,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      _NotificationSettings(services: services),
                    ],
                  ),
                ),
              ),
            ),

            // ── Health Connect (Pro) ──────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: MsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(AppStrings.settingsHealthConnect,
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(width: 8),
                          if (!isPro) const _ProChip(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (isPro)
                        ElevatedButton.icon(
                          onPressed: () => _connectHealth(services),
                          icon: const Icon(Icons.favorite_outline, size: 18),
                          label: const Text('Connetti Health Connect'),
                        )
                      else
                        Text(
                          'Sincronizza passi, distanza e calorie con Health Connect e Google Fit.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ── AI Coach ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _AiCoachSection(services: services),
              ),
            ),

            // ── Export ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: MsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dati', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.download_outlined,
                            color: AppColors.cyan),
                        title: const Text(AppStrings.settingsExportJSON),
                        trailing: const Icon(Icons.chevron_right, size: 18),
                        onTap: () => _exportData(services),
                      ),
                      if (isPro)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.picture_as_pdf_outlined,
                              color: AppColors.cyan),
                          title: const Text(AppStrings.settingsExportPDF),
                          trailing: const Icon(Icons.chevron_right, size: 18),
                          onTap: () {},
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Danger zone ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: OutlinedButton(
                  onPressed: () => _confirmReset(services),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(AppStrings.settingsReset),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editProfile(BuildContext context) {
    if (_profile == null) return;
    final nameCtrl = TextEditingController(text: _profile!.name);
    final ageCtrl = TextEditingController(text: _profile!.age.toString());
    var gender = _profile!.gender;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Modifica profilo',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ageCtrl,
                decoration: const InputDecoration(labelText: 'Età'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final services = context.read<AppServices>();
                  final updated = _profile!.copyWith(
                    name: nameCtrl.text.trim(),
                    age: int.tryParse(ageCtrl.text) ?? _profile!.age,
                  );
                  await services.db.saveUserProfile(updated);
                  Navigator.pop(ctx);
                  _loadProfile();
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Salva'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _connectHealth(AppServices services) async {
    final ok = await services.health.requestPermissions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'Health Connect connesso ✅'
              : 'Connessione fallita. Controlla i permessi.'),
        ),
      );
    }
  }

  Future<void> _exportData(AppServices services) async {
    final data = await services.db.exportAllData();
    final json = jsonEncode(data);
    await Share.share(json, subject: 'MindStep - Esporta dati');
  }

  Future<void> _confirmReset(AppServices services) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.settingsReset),
        content: const Text(AppStrings.settingsResetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.settingsCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.settingsResetConfirmButton,
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await services.db.resetAll();
      if (mounted) context.go('/onboarding');
    }
  }
}

// ── Theme Selector ────────────────────────────────────────────────────────────

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.current, required this.onChange});
  final ThemeMode current;
  final ValueChanged<ThemeMode> onChange;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ThemeChip(
          label: 'Chiaro',
          icon: PhosphorIcons.sun(),
          mode: ThemeMode.light,
          current: current,
          onChange: onChange,
        ),
        const SizedBox(width: 8),
        _ThemeChip(
          label: 'Scuro',
          icon: PhosphorIcons.moon(),
          mode: ThemeMode.dark,
          current: current,
          onChange: onChange,
        ),
        const SizedBox(width: 8),
        _ThemeChip(
          label: 'Auto',
          icon: PhosphorIcons.deviceMobile(),
          mode: ThemeMode.system,
          current: current,
          onChange: onChange,
        ),
      ],
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.label,
    required this.icon,
    required this.mode,
    required this.current,
    required this.onChange,
  });
  final String label;
  final PhosphorIconData icon;
  final ThemeMode mode;
  final ThemeMode current;
  final ValueChanged<ThemeMode> onChange;

  @override
  Widget build(BuildContext context) {
    final isSelected = current == mode;
    return GestureDetector(
      onTap: () => onChange(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cyan : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.cyan : AppColors.lightBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : null,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Notification Settings ─────────────────────────────────────────────────────

class _NotificationSettings extends StatefulWidget {
  const _NotificationSettings({required this.services});
  final AppServices services;

  @override
  State<_NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<_NotificationSettings> {
  bool _morning = true;
  bool _routine = true;
  bool _walk = false;
  bool _brain = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SwitchRow(
          label: 'Reminder mattutino (8:00)',
          icon: PhosphorIcons.sun(),
          iconColor: Colors.orange,
          value: _morning,
          onChange: (v) {
            setState(() => _morning = v);
            if (v) {
              widget.services.notifications.scheduleMorningReminder(
                hour: 8, minute: 0,
                message: AppStrings.morningMessages[0],
              );
            }
          },
        ),
        _SwitchRow(
          label: 'Reminder routine (10:00)',
          icon: PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
          iconColor: AppColors.success,
          value: _routine,
          onChange: (v) {
            setState(() => _routine = v);
            if (v) {
              widget.services.notifications.scheduleRoutineReminder(
                hour: 10, minute: 0,
              );
            }
          },
        ),
        _SwitchRow(
          label: 'Reminder camminata (18:00)',
          icon: PhosphorIcons.personSimpleWalk(),
          iconColor: AppColors.cyan,
          value: _walk,
          onChange: (v) {
            setState(() => _walk = v);
            if (v) {
              widget.services.notifications.scheduleWalkReminder(
                hour: 18, minute: 0,
              );
            }
          },
        ),
        if (widget.services.isPro)
          _SwitchRow(
            label: 'Walking Brain (21:00)',
            icon: PhosphorIcons.brain(),
            iconColor: const Color(0xFF9C27B0),
            value: _brain,
            onChange: (v) {
              setState(() => _brain = v);
              if (v) {
                widget.services.notifications.scheduleBrainReminder(
                  hour: 21, minute: 0,
                );
              }
            },
          ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.onChange,
  });
  final String label;
  final PhosphorIconData icon;
  final Color iconColor;
  final bool value;
  final ValueChanged<bool> onChange;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          PhosphorIcon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Switch(
            value: value,
            onChanged: onChange,
            activeColor: AppColors.cyan,
          ),
        ],
      ),
    );
  }
}

// ── AI Coach Section ──────────────────────────────────────────────────────────

class _AiCoachSection extends StatefulWidget {
  const _AiCoachSection({required this.services});
  final AppServices services;

  @override
  State<_AiCoachSection> createState() => _AiCoachSectionState();
}

class _AiCoachSectionState extends State<_AiCoachSection> {
  AiProviderConfig _config = AiProviderConfig.none;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await widget.services.aiInsight.loadProviderConfig();
    if (mounted) setState(() { _config = config; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return MsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('AI Coach',
                  style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              TextButton(
                onPressed: () => _showAiSetup(context),
                child: const Text('Cambia',
                    style: TextStyle(color: AppColors.cyan)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loading)
            const SizedBox(
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.cyan,
              ),
            )
          else
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Color(_config.providerColorValue),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _config.providerName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _config.isConfigured
                            ? (_config.isApiKeyValid
                                ? 'Connesso ✅'
                                : 'Chiave non testata ⚠️')
                            : 'Nessun AI configurato — tocca Cambia per aggiungerne uno',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showAiSetup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, _) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SetupAiProviderScreen(
            aiService: widget.services.aiInsight,
            onBack: () => Navigator.pop(ctx),
            onNext: (config) {
              Navigator.pop(ctx);
              _loadConfig();
            },
          ),
        ),
      ),
    );
  }
}

class _ProChip extends StatelessWidget {
  const _ProChip();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      gradient: AppColors.proGradient,
      borderRadius: BorderRadius.circular(4),
    ),
    child: const Text(
      'PRO',
      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
    ),
  );
}
