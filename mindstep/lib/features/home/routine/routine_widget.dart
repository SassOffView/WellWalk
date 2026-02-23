import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  @override
  void didUpdateWidget(RoutineWidget old) {
    super.didUpdateWidget(old);
    if (old.dayData != widget.dayData) _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    final services = context.read<AppServices>();
    final routines = await services.db.loadAllRoutines();

    // Applica stato completamento del giorno
    final completedIds = widget.dayData?.completedRoutineIds ?? [];
    final withStatus = routines.map((r) =>
      r.copyWith(isCompleted: completedIds.contains(r.id))
    ).toList();

    if (mounted) setState(() {
      _routines = withStatus;
      _loading = false;
    });
  }

  double get _completionPercent {
    if (_routines.isEmpty) return 0;
    return (_routines.where((r) => r.isCompleted).length / _routines.length) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final services = context.read<AppServices>();

    return MsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Add button
          Row(
            children: [
              const Text('✅', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.routineTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppColors.cyan),
                onPressed: () => _showAddRoutineDialog(services),
                tooltip: AppStrings.routineAdd,
              ),
            ],
          ),

          // Progress bar
          if (_routines.isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _completionPercent / 100,
                backgroundColor: AppColors.cyan.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${_routines.where((r) => r.isCompleted).length}/${_routines.length} ${AppStrings.routineProgress}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),

            // Milestone message
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

          const SizedBox(height: 12),

          // Routine list
          if (_loading)
            const Center(child: CircularProgressIndicator(color: AppColors.cyan))
          else if (_routines.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  AppStrings.routineEmpty,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...List.generate(_routines.length, (i) => _RoutineRow(
              routine: _routines[i],
              onToggle: (v) => _toggleRoutine(services, _routines[i], v),
              onDelete: () => _deleteRoutine(services, _routines[i]),
            )),
        ],
      ),
    );
  }

  Future<void> _toggleRoutine(
      AppServices services, RoutineItem routine, bool completed) async {
    await services.db.toggleRoutineForDay(
      DateTime.now(), routine.id, completed);

    // Aggiorna stato locale
    setState(() {
      final idx = _routines.indexWhere((r) => r.id == routine.id);
      if (idx >= 0) {
        _routines[idx] = _routines[idx].copyWith(isCompleted: completed);
      }
    });

    // Carica dayData aggiornato per il badge service
    final dayData = await services.db.loadDayData(DateTime.now());

    // Controlla badge routine (fix bug PWA — mancava check)
    await services.badges.onRoutineToggled(
      dayData: dayData,
      isPro: services.isPro,
    );

    widget.onChanged?.call();
  }

  Future<void> _deleteRoutine(AppServices services, RoutineItem routine) async {
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
      await _loadRoutines();
      widget.onChanged?.call();
    }
  }

  void _showAddRoutineDialog(AppServices services) {
    // Controlla limite Free
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

class _RoutineRow extends StatelessWidget {
  const _RoutineRow({
    required this.routine,
    required this.onToggle,
    required this.onDelete,
  });

  final RoutineItem routine;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

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
              // Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: routine.isCompleted ? AppColors.cyan : Colors.transparent,
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
