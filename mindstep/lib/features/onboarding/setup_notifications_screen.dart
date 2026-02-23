import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/notification_preferences.dart';
import '../../shared/widgets/ms_card.dart';

/// Step onboarding 3: scegli l'orario della notifica giornaliera
/// e abilita/disabilita i promemoria specifici.
class SetupNotificationsScreen extends StatefulWidget {
  const SetupNotificationsScreen({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  final ValueChanged<NotificationPreferences> onNext;
  final VoidCallback onBack;

  @override
  State<SetupNotificationsScreen> createState() =>
      _SetupNotificationsScreenState();
}

class _SetupNotificationsScreenState extends State<SetupNotificationsScreen> {
  NotificationPreferences _prefs = NotificationPreferences.defaults;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Back
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onBack,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'Le tue notifiche',
            style: Theme.of(context)
                .textTheme
                .displaySmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Scegli quando vuoi ricevere il tuo promemoria giornaliero personalizzato.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Notifica principale AI ─────────────────────────
                  MsCard(
                    color: AppColors.cyan.withOpacity(0.06),
                    borderColor: AppColors.cyan.withOpacity(0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('🌅', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Promemoria giornaliero',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge,
                                  ),
                                  Text(
                                    'Con insight AI personalizzato sul tuo progresso',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _prefs.dailyReminderEnabled,
                              onChanged: (v) => setState(() =>
                                  _prefs = _prefs.copyWith(
                                      dailyReminderEnabled: v)),
                              activeColor: AppColors.cyan,
                            ),
                          ],
                        ),

                        if (_prefs.dailyReminderEnabled) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Orario',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium,
                          ),
                          const SizedBox(height: 8),

                          // Time picker a griglia (ore)
                          _TimePicker(
                            hour: _prefs.dailyReminderHour,
                            minute: _prefs.dailyReminderMinute,
                            onChanged: (h, m) => setState(() =>
                                _prefs = _prefs.copyWith(
                                  dailyReminderHour: h,
                                  dailyReminderMinute: m,
                                )),
                          ),

                          const SizedBox(height: 12),

                          // Preview notifica
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.navyDark.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.cyan.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                const Text('📱', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Anteprima notifica:',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.lightTextSecondary,
                                        ),
                                      ),
                                      Text(
                                        '"Buongiorno! Il tuo coach AI ha un\'insight per te oggi."',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Altri promemoria ──────────────────────────────
                  Text(
                    'Altri promemoria',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),

                  _ReminderRow(
                    emoji: '🚶',
                    label: 'Reminder camminata',
                    enabled: _prefs.walkReminderEnabled,
                    hour: _prefs.walkReminderHour,
                    minute: _prefs.walkReminderMinute,
                    onEnabledChanged: (v) => setState(() =>
                        _prefs = _prefs.copyWith(walkReminderEnabled: v)),
                    onTimeChanged: (h, m) => setState(() =>
                        _prefs = _prefs.copyWith(
                          walkReminderHour: h,
                          walkReminderMinute: m,
                        )),
                  ),
                  const SizedBox(height: 8),

                  _ReminderRow(
                    emoji: '✅',
                    label: 'Reminder routine',
                    enabled: _prefs.routineReminderEnabled,
                    hour: _prefs.routineReminderHour,
                    minute: _prefs.routineReminderMinute,
                    onEnabledChanged: (v) => setState(() =>
                        _prefs = _prefs.copyWith(routineReminderEnabled: v)),
                    onTimeChanged: (h, m) => setState(() =>
                        _prefs = _prefs.copyWith(
                          routineReminderHour: h,
                          routineReminderMinute: m,
                        )),
                  ),
                  const SizedBox(height: 8),

                  _ReminderRow(
                    emoji: '💭',
                    label: 'Walking Brain (sera)',
                    enabled: _prefs.brainReminderEnabled,
                    hour: _prefs.brainReminderHour,
                    minute: _prefs.brainReminderMinute,
                    onEnabledChanged: (v) => setState(() =>
                        _prefs = _prefs.copyWith(brainReminderEnabled: v)),
                    onTimeChanged: (h, m) => setState(() =>
                        _prefs = _prefs.copyWith(
                          brainReminderHour: h,
                          brainReminderMinute: m,
                        )),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onNext(_prefs),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Continua',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Time Picker ───────────────────────────────────────────────────────────────

class _TimePicker extends StatelessWidget {
  const _TimePicker({
    required this.hour,
    required this.minute,
    required this.onChanged,
  });

  final int hour;
  final int minute;
  final void Function(int hour, int minute) onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: minute),
          helpText: 'Scegli l\'orario',
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.cyan,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onChanged(picked.hour, picked.minute);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cyan.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cyan.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time, color: AppColors.cyan, size: 20),
            const SizedBox(width: 8),
            Text(
              '${hour.toString().padLeft(2, '0')}:'
              '${minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.cyan,
                fontFamily: 'Courier New',
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.edit, size: 14, color: AppColors.cyan),
          ],
        ),
      ),
    );
  }
}

// ── Reminder Row ──────────────────────────────────────────────────────────────

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.emoji,
    required this.label,
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.onEnabledChanged,
    required this.onTimeChanged,
  });

  final String emoji;
  final String label;
  final bool enabled;
  final int hour;
  final int minute;
  final ValueChanged<bool> onEnabledChanged;
  final void Function(int h, int m) onTimeChanged;

  @override
  Widget build(BuildContext context) {
    return MsCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          if (enabled)
            GestureDetector(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: hour, minute: minute),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(primary: AppColors.cyan),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) onTimeChanged(picked.hour, picked.minute);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
                ),
                child: Text(
                  '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 8),
          Switch(
            value: enabled,
            onChanged: onEnabledChanged,
            activeColor: AppColors.cyan,
          ),
        ],
      ),
    );
  }
}
