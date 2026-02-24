import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/day_data.dart';
import '../../shared/widgets/ms_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _currentMonth = DateTime.now();
  Map<String, DayData> _daysData = {};
  DateTime? _selectedDay;
  DayData? _selectedDayData;

  @override
  void initState() {
    super.initState();
    _loadMonth();
  }

  Future<void> _loadMonth() async {
    final services = context.read<AppServices>();
    final from = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final to = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    // Rispetta limite 30 giorni per Free
    DateTime effectiveFrom = from;
    if (!services.isPro) {
      final limit = DateTime.now().subtract(const Duration(days: 30));
      if (from.isBefore(limit)) effectiveFrom = limit;
    }

    final days = await services.db.loadDateRange(effectiveFrom, to);
    if (mounted) {
      setState(() {
        _daysData = {for (final d in days) d.dateKey: d};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(
                  AppStrings.historyTitle,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
            ),

            // Calendar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: MsCard(
                  child: Column(
                    children: [
                      // Month navigation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () => _changeMonth(-1),
                          ),
                          Text(
                            _monthLabel(),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: _currentMonth.month == DateTime.now().month &&
                                _currentMonth.year == DateTime.now().year
                                ? null
                                : () => _changeMonth(1),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Day of week headers
                      Row(
                        children: ['L', 'M', 'M', 'G', 'V', 'S', 'D']
                            .map((d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                        ))
                            .toList(),
                      ),

                      const SizedBox(height: 8),

                      // Calendar grid
                      _CalendarGrid(
                        month: _currentMonth,
                        daysData: _daysData,
                        selectedDay: _selectedDay,
                        onDayTap: _onDayTap,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Selected day detail
            if (_selectedDay != null && _selectedDayData != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _DayDetail(
                    date: _selectedDay!,
                    data: _selectedDayData!,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  void _onDayTap(DateTime day) async {
    final key = '${day.year}-${day.month.toString().padLeft(2,'0')}-${day.day.toString().padLeft(2,'0')}';
    setState(() {
      _selectedDay = day;
      _selectedDayData = _daysData[key];
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + delta,
        1,
      );
      _selectedDay = null;
      _selectedDayData = null;
    });
    _loadMonth();
  }

  String _monthLabel() {
    const months = [
      'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
      'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre',
    ];
    return '${months[_currentMonth.month - 1]} ${_currentMonth.year}';
  }
}

// ── Calendar Grid ─────────────────────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.month,
    required this.daysData,
    required this.selectedDay,
    required this.onDayTap,
  });

  final DateTime month;
  final Map<String, DayData> daysData;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    // weekday: 1=Mon, 7=Sun → offset per iniziare da Lunedì
    int startOffset = firstDay.weekday - 1;

    final cells = <Widget>[];

    // Empty cells before month start
    for (int i = 0; i < startOffset; i++) {
      cells.add(const SizedBox());
    }

    // Day cells
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      final key = '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
      final dayData = daysData[key];
      final isToday = _isToday(date);
      final isSelected = selectedDay?.day == d &&
          selectedDay?.month == month.month &&
          selectedDay?.year == month.year;
      final isActive = dayData?.isActive ?? false;
      final isFuture = date.isAfter(DateTime.now());

      cells.add(_DayCell(
        day: d,
        isToday: isToday,
        isSelected: isSelected,
        isActive: isActive,
        isFuture: isFuture,
        hasWalk: dayData?.hasWalk ?? false,
        hasRoutine: (dayData?.routineCompleted ?? 0) > 0,
        hasBrain: dayData?.hasBrainstorm ?? false,
        onTap: isFuture ? null : () => onDayTap(date),
      ));
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cells,
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.isActive,
    required this.isFuture,
    required this.hasWalk,
    required this.hasRoutine,
    required this.hasBrain,
    this.onTap,
  });

  final int day;
  final bool isToday, isSelected, isActive, isFuture;
  final bool hasWalk, hasRoutine, hasBrain;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.transparent;
    Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    if (isSelected) {
      bgColor = AppColors.cyan;
      textColor = Colors.white;
    } else if (isToday) {
      bgColor = AppColors.cyan.withOpacity(0.15);
      textColor = AppColors.cyan;
    } else if (isActive) {
      bgColor = AppColors.cyan.withOpacity(0.08);
    } else if (isFuture) {
      textColor = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w400,
                color: textColor,
              ),
            ),
            if (isActive && !isSelected)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasWalk) _Dot(AppColors.cyan),
                  if (hasRoutine) _Dot(AppColors.success),
                  if (hasBrain) _Dot(AppColors.navy),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 4, height: 4,
    margin: const EdgeInsets.symmetric(horizontal: 1),
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

// ── Day Detail ───────────────────────────────────────────────────────────────

class _DayDetail extends StatelessWidget {
  const _DayDetail({required this.date, required this.data});
  final DateTime date;
  final DayData data;

  @override
  Widget build(BuildContext context) {
    return MsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDate(date),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          if (!data.isActive)
            Text(
              'Nessuna attività in questo giorno.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else ...[
            // Walk info
            if (data.hasWalk && data.walk != null) ...[
              _DetailRow(
                icon: PhosphorIcons.personSimpleWalk(),
                iconColor: AppColors.cyan,
                label: 'Camminata',
                value: '${data.walk!.distanceKm.toStringAsFixed(2)} km · ${data.walk!.activeMinutes} min',
              ),
              const SizedBox(height: 8),
            ],

            // Routine
            if (data.routineCompleted > 0) ...[
              _DetailRow(
                icon: PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                iconColor: AppColors.success,
                label: 'Routine',
                value: '${data.routineCompleted}/${data.routineTotal} completate (${data.routinePercent.round()}%)',
              ),
              const SizedBox(height: 8),
            ],

            // Brain
            if (data.hasBrainstorm) ...[
              _DetailRow(
                icon: PhosphorIcons.brain(PhosphorIconsStyle.fill),
                iconColor: const Color(0xFF9C27B0),
                label: 'Brainstorm',
                value: 'Nota salvata',
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  data.brainstormNote,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const days = ['lunedì','martedì','mercoledì','giovedì','venerdì','sabato','domenica'];
    const months = ['','gennaio','febbraio','marzo','aprile','maggio','giugno',
      'luglio','agosto','settembre','ottobre','novembre','dicembre'];
    return '${days[d.weekday-1].capitalize()}, ${d.day} ${months[d.month]} ${d.year}';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });
  final PhosphorIconData icon;
  final Color iconColor;
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PhosphorIcon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              Text(value, style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

extension StringExt on String {
  String capitalize() =>
      isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : this;
}
