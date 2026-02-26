import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
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

            // ── Accordion sections ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _AccordionSection(
                  title: AppStrings.settingsProfile,
                  icon: PhosphorIcons.user(PhosphorIconsStyle.fill),
                  initiallyExpanded: true,
                  child: _ProfileContent(
                    profile: _profile,
                    onEdit: () => _editProfile(context),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: _AccordionSection(
                  title: AppStrings.settingsTheme,
                  icon: PhosphorIcons.palette(PhosphorIconsStyle.fill),
                  child: _ThemeSelector(
                    current: services.themeMode,
                    onChange: services.setThemeMode,
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: _AccordionSection(
                  title: AppStrings.settingsNotifications,
                  icon: PhosphorIcons.bell(PhosphorIconsStyle.fill),
                  child: _NotificationSettings(services: services),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: _AccordionSection(
                  title: 'AI Coach',
                  icon: PhosphorIcons.robot(PhosphorIconsStyle.fill),
                  child: _AiCoachContent(services: services),
                ),
              ),
            ),

            // ── Dati: Export CSV + Invia all'AI ──────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: _AccordionSection(
                  title: 'Dati',
                  icon: PhosphorIcons.database(PhosphorIconsStyle.fill),
                  child: Column(
                    children: [
                      _ExportTile(
                        icon: PhosphorIcons.fileCsv(PhosphorIconsStyle.fill),
                        label: AppStrings.settingsExportCSV,
                        onTap: () => _exportCSV(services),
                      ),
                      const SizedBox(height: 8),
                      _ExportTile(
                        icon: PhosphorIcons.robot(PhosphorIconsStyle.fill),
                        label: AppStrings.settingsExportAI,
                        iconColor: const Color(0xFF9C27B0),
                        onTap: () => _sendToAI(services),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Danger zone ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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

  /// Genera un CSV con i dati degli ultimi 90 giorni e lo condivide
  Future<void> _exportCSV(AppServices services) async {
    try {
      final data = await services.db.exportAllData();
      final days = data['days'] as List<dynamic>? ?? [];

      final buffer = StringBuffer();
      buffer.writeln('Data,Passi,Distanza(km),Minuti Walk,Brainstorm Min,Note Brainstorm');

      for (final day in days) {
        final d = day as Map<String, dynamic>;
        final walk = d['walk'] as Map<String, dynamic>?;
        final steps = walk?['stepCount'] ?? 0;
        final distKm = ((walk?['distanceMeters'] ?? 0) as num) / 1000.0;
        final walkMs = (walk?['activeMilliseconds'] ?? 0) as num;
        final walkMin = (walkMs / 60000).round();
        final brainstormMin = d['brainstormMinutes'] ?? 0;
        final note = (d['brainstormNote'] ?? '').toString()
            .replaceAll('"', '""');

        buffer.writeln(
          '${d['date']},$steps,${distKm.toStringAsFixed(2)},$walkMin,$brainstormMin,"$note"',
        );
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/mindstep_report.csv');
      await file.writeAsString(buffer.toString());

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: 'MindStep — Report attività',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore export: $e')),
        );
      }
    }
  }

  /// Prepara un riassunto testuale e lo condivide con l'assistente AI
  Future<void> _sendToAI(AppServices services) async {
    try {
      final data = await services.db.exportAllData();
      final profile = data['profile'] as Map<String, dynamic>?;
      final days = data['days'] as List<dynamic>? ?? [];

      int totalSteps = 0;
      int totalWalkMin = 0;
      int totalBrainstormMin = 0;
      final notes = <String>[];

      for (final day in days) {
        final d = day as Map<String, dynamic>;
        final walk = d['walk'] as Map<String, dynamic>?;
        totalSteps += (walk?['stepCount'] ?? 0) as int;
        totalWalkMin += ((walk?['activeMilliseconds'] ?? 0) as int) ~/ 60000;
        totalBrainstormMin += (d['brainstormMinutes'] ?? 0) as int;
        final note = (d['brainstormNote'] ?? '').toString().trim();
        if (note.isNotEmpty) notes.add('• $note');
      }

      final name = profile?['firstName'] ?? 'Utente';
      final summary = '''
Ciao! Ecco il mio report MindStep degli ultimi 90 giorni:

👤 Nome: $name
👟 Passi totali: $totalSteps
🚶 Minuti di camminata: $totalWalkMin
🧠 Minuti brainstorm: $totalBrainstormMin
📝 Note vocali (ultime 5):
${notes.reversed.take(5).join('\n')}

Puoi analizzare questi dati e darmi consigli personalizzati?
''';

      await Share.share(summary, subject: 'MindStep — Dati per il mio assistente');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
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

// ── Accordion Section ─────────────────────────────────────────────────────────

class _AccordionSection extends StatefulWidget {
  const _AccordionSection({
    required this.title,
    required this.icon,
    required this.child,
    this.initiallyExpanded = false,
  });

  final String title;
  final PhosphorIconData icon;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<_AccordionSection> createState() => _AccordionSectionState();
}

class _AccordionSectionState extends State<_AccordionSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isDark ? AppColors.navyMid : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _expanded
              ? AppColors.cyan.withOpacity(0.3)
              : AppColors.lightBorder.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          // Header row
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  PhosphorIcon(
                    widget.icon,
                    size: 18,
                    color: AppColors.cyan,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: AppColors.cyan.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content (animated)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: widget.child,
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

// ── Profile Content ───────────────────────────────────────────────────────────

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.profile, required this.onEdit});
  final UserProfile? profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return Text(
        'Nessun profilo trovato',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.cyan.withOpacity(0.15),
        child: Text(
          profile!.firstName.isNotEmpty
              ? profile!.firstName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: AppColors.cyan,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(
        profile!.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('${profile!.age} anni · ${profile!.genderLabel}'),
      trailing: const Icon(Icons.edit_outlined, size: 18),
      onTap: onEdit,
    );
  }
}

// ── Export Tile ───────────────────────────────────────────────────────────────

class _ExportTile extends StatelessWidget {
  const _ExportTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = AppColors.cyan,
  });

  final PhosphorIconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : iconColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: iconColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            PhosphorIcon(icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: iconColor.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ── AI Coach Content (accordion body) ────────────────────────────────────────

class _AiCoachContent extends StatefulWidget {
  const _AiCoachContent({required this.services});
  final AppServices services;

  @override
  State<_AiCoachContent> createState() => _AiCoachContentState();
}

class _AiCoachContentState extends State<_AiCoachContent> {
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
    if (_loading) {
      return const SizedBox(
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyan),
      );
    }

    return Row(
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
                    : 'Nessun AI configurato',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => _showAiSetup(context),
          child: const Text('Cambia',
              style: TextStyle(color: AppColors.cyan)),
        ),
      ],
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
