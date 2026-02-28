import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/models/day_data.dart';
import '../../../core/models/routine_item.dart';
import '../../../shared/widgets/ms_card.dart';
import 'package:uuid/uuid.dart';

class RoutineWidget extends StatefulWidget {
  const RoutineWidget({
    super.key,
    this.dayData,
    this.onChanged,
  });

  final DayData? dayData;
  final VoidCallback? onChanged;

  @override
  State<RoutineWidget> createState() => _RoutineWidgetState();
}

class _RoutineWidgetState extends State<RoutineWidget> {
  List<RoutineItem> _routines = [];
  bool _loading = true;
  bool _expanded = true;

  /// routine id → TimeOfDay reminder
  final Map<String, TimeOfDay> _reminders = {};

  @override
  void initState() {
    super.initState();
    _loadRoutines();
    _loadReminders();
  }

  @override
  void didUpdateWidget(RoutineWidget old) {
    super.didUpdateWidget(old);
    if (old.dayData != widget.dayData) _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    final services = context.read<AppServices>();
    final routines = await services.db.loadAllRoutines();
    final completedIds = widget.dayData?.completedRoutineIds ?? [];
    final withStatus = routines
        .map((r) => r.copyWith(isCompleted: completedIds.contains(r.id)))
        .toList();

    if (mounted) {
      setState(() {
        _routines = withStatus;
        _loading = false;
      });
    }
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, TimeOfDay> loaded = {};
    for (final key in prefs.getKeys()) {
      if (key.startsWith('routine_reminder_')) {
        final id = key.replaceFirst('routine_reminder_', '');
        final value = prefs.getString(key);
        if (value != null) {
          final parts = value.split(':');
          if (parts.length == 2) {
            final h = int.tryParse(parts[0]);
            final m = int.tryParse(parts[1]);
            if (h != null && m != null) {
              loaded[id] = TimeOfDay(hour: h, minute: m);
            }
          }
        }
      }
    }
    if (mounted) setState(() => _reminders.addAll(loaded));
  }

  Future<void> _saveReminder(String routineId, TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'routine_reminder_$routineId', '${time.hour}:${time.minute}');
    setState(() => _reminders[routineId] = time);
  }

  Future<void> _removeReminder(String routineId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('routine_reminder_$routineId');
    final services = context.read<AppServices>();
    await services.notifications.cancelRoutineItemReminder(routineId);
    setState(() => _reminders.remove(routineId));
  }

  double get _completionPercent {
    if (_routines.isEmpty) return 0;
    return (_routines.where((r) => r.isCompleted).length / _routines.length) *
        100;
  }

  int get _completedCount => _routines.where((r) => r.isCompleted).length;

  @override
  Widget build(BuildContext context) {
    final services = context.read<AppServices>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header collapsible ──────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('✅', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppStrings.routineTitle,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  // PRO badge
                  if (!services.isPro)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppColors.warning.withOpacity(0.4)),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.warning,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  // Add button
                  GestureDetector(
                    onTap: () => _showAddRoutineDialog(services),
                    child: const Icon(Icons.add_circle_outline,
                        color: AppColors.cyan, size: 22),
                  ),
                  const SizedBox(width: 4),
                  // Chevron
                  AnimatedRotation(
                    turns: _expanded ? 0 : -0.5,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Contenuto collassabile ─────────────────────────────────
          AnimatedCrossFade(
            firstChild: _buildContent(context, services),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppServices services) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        if (_routines.isNotEmpty) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _completionPercent / 100,
              backgroundColor: AppColors.cyan.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          if (_completionPercent >= 100)
            Text(
              AppStrings.routineAllDone,
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            )
          else if (_completionPercent >= 50)
            Text(
              AppStrings.routineHalfDone,
              style: const TextStyle(
                color: AppColors.cyan,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
        ],

        const SizedBox(height: 10),

        // Routine list
        if (_loading)
          const Center(
              child: CircularProgressIndicator(color: AppColors.cyan))
        else if (_routines.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                AppStrings.routineEmpty,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...List.generate(
            _routines.length,
            (i) => _RoutineRow(
              routine: _routines[i],
              reminder: _reminders[_routines[i].id],
              isPro: services.isPro,
              onToggle: (v) => _toggleRoutine(services, _routines[i], v),
              onDelete: () => _deleteRoutine(services, _routines[i]),
              onClockTap: () =>
                  _showReminderPicker(services, _routines[i]),
            ),
          ),

        // Divider + footer row
        const SizedBox(height: 10),
        const Divider(height: 1),
        const SizedBox(height: 8),
        Row(
          children: [
            // Aggiungi Routine con PRO badge
            GestureDetector(
              onTap: () => _showAddRoutineDialog(services),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 16, color: AppColors.cyan),
                  const SizedBox(width: 4),
                  const Text(
                    'Aggiungi Routine',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.cyan,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!services.isPro) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Spacer(),
            // Counter
            Text(
              '$_completedCount/${_routines.length} ${AppStrings.routineProgress}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _toggleRoutine(
      AppServices services, RoutineItem routine, bool completed) async {
    await services.db.toggleRoutineForDay(
        DateTime.now(), routine.id, completed);
    setState(() {
      final idx = _routines.indexWhere((r) => r.id == routine.id);
      if (idx >= 0) {
        _routines[idx] = _routines[idx].copyWith(isCompleted: completed);
      }
    });
    final dayData = await services.db.loadDayData(DateTime.now());
    await services.badges.onRoutineToggled(
      dayData: dayData,
      isPro: services.isPro,
    );
    widget.onChanged?.call();
  }

  Future<void> _deleteRoutine(
      AppServices services, RoutineItem routine) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina abitudine?'),
        content: Text('Vuoi eliminare "${routine.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.settingsCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimina',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await services.db.deleteRoutine(routine.id);
      await _removeReminder(routine.id);
      await _loadRoutines();
      widget.onChanged?.call();
    }
  }

  Future<void> _showReminderPicker(
      AppServices services, RoutineItem routine) async {
    if (!services.isPro) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'I reminder per singola routine sono una funzione PRO.'),
          action: SnackBarAction(
            label: 'Upgrade',
            onPressed: () {},
          ),
        ),
      );
      return;
    }

    final existing = _reminders[routine.id];
    final picked = await showTimePicker(
      context: context,
      initialTime: existing ?? const TimeOfDay(hour: 8, minute: 0),
      helpText: 'Imposta reminder per "${routine.title}"',
    );
    if (picked == null) return;

    await _saveReminder(routine.id, picked);
    await services.notifications.scheduleRoutineItemReminder(
      routineId: routine.id,
      routineName: routine.title,
      hour: picked.hour,
      minute: picked.minute,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Reminder impostato alle ${picked.format(context)} per "${routine.title}"'),
        ),
      );
    }
  }

  void _showAddRoutineDialog(AppServices services) {
    if (!services.isPro && _routines.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.routineFreeLimitReached),
          action: SnackBarAction(
            label: 'Upgrade',
            onPressed: () {},
          ),
        ),
      );
      return;
    }

    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.routineAdd),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Es. Meditazione 10 min',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.settingsCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await services.db.saveRoutine(RoutineItem(
                id: const Uuid().v4(),
                title: ctrl.text.trim(),
                createdAt: DateTime.now(),
                order: _routines.length,
              ));
              Navigator.pop(ctx);
              await _loadRoutines();
              widget.onChanged?.call();
            },
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
  }
}

// ─── Routine Row ─────────────────────────────────────────────────────────────

class _RoutineRow extends StatelessWidget {
  const _RoutineRow({
    required this.routine,
    required this.isPro,
    required this.onToggle,
    required this.onDelete,
    required this.onClockTap,
    this.reminder,
  });

  final RoutineItem routine;
  final bool isPro;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final VoidCallback onClockTap;
  final TimeOfDay? reminder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () => onToggle(!routine.isCompleted),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              // Checkbox animato
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: routine.isCompleted
                      ? AppColors.cyan
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: routine.isCompleted
                        ? AppColors.cyan
                        : AppColors.lightBorder,
                    width: 2,
                  ),
                ),
                child: routine.isCompleted
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),

              // Label
              Expanded(
                child: Text(
                  routine.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    decoration: routine.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: routine.isCompleted
                        ? Theme.of(context).textTheme.bodySmall?.color
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),

              // Clock icon (reminder PRO)
              GestureDetector(
                onTap: onClockTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    reminder != null
                        ? Icons.alarm_on
                        : Icons.alarm_add,
                    size: 18,
                    color: reminder != null
                        ? AppColors.cyan
                        : (isPro
                            ? AppColors.lightTextSecondary
                            : AppColors.warning.withOpacity(0.6)),
                  ),
                ),
              ),

              // Delete
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.close,
                    size: 16, color: AppColors.lightTextSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
