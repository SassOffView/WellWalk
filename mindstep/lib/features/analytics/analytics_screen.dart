import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/day_data.dart';
import '../../shared/widgets/ms_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<DayData> _weekData = [];
  int _streak = 0;
  int _totalWalks = 0;
  double _totalKm = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final services = context.read<AppServices>();
    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    final weekData = await services.db.loadDateRange(
      weekStart,
      today,
    );

    final streak = await services.db.calculateStreak();
    final totalWalks = await services.db.countTotalWalks();
    final totalKm = await services.db.getTotalDistanceKm();

    if (mounted) {
      setState(() {
        _weekData = weekData;
        _streak = streak;
        _totalWalks = totalWalks;
        _totalKm = totalKm;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = context.read<AppServices>();

    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.cyan))
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Text(
                        AppStrings.analyticsTitle,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    ),
                  ),

                  // ── Streak card ─────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: MsGradientCard(
                        child: Row(
                          children: [
                            PhosphorIcon(
                              PhosphorIcons.flame(PhosphorIconsStyle.fill),
                              color: Colors.orange,
                              size: 40,
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$_streak ${AppStrings.analyticsStreakDays}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Text(
                                  'Consecutivi',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Stats grid ───────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(
                        children: [
                          _StatCard(
                            label: AppStrings.analyticsTotalKm,
                            value: _totalKm.toStringAsFixed(1),
                            unit: 'km',
                            icon: PhosphorIcons.mapPin(),
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            label: 'Camminate',
                            value: '$_totalWalks',
                            unit: 'totali',
                            icon: PhosphorIcons.personSimpleWalk(),
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            label: 'Giorni attivi',
                            value: '${_weekData.where((d) => d.isActive).length}',
                            unit: 'questa settimana',
                            icon: PhosphorIcons.calendarCheck(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Weekly activity grid ──────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: MsCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Settimana in corso',
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 16),
                            _WeekActivityGrid(weekData: _weekData),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Km bar chart ──────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: MsCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Km questa settimana',
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 160,
                              child: _KmBarChart(weekData: _weekData),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Pro analytics lock ────────────────────────────
                  if (!services.isPro)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: GestureDetector(
                          onTap: () => context.push('/paywall'),
                          child: MsCard(
                            borderColor: AppColors.cyan.withOpacity(0.3),
                            child: Column(
                              children: [
                                const Icon(Icons.lock, color: AppColors.cyan, size: 32),
                                const SizedBox(height: 8),
                                Text(
                                  'Analytics mensili e annuali',
                                  style: Theme.of(context).textTheme.titleMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Sblocca trend, comparazioni e report avanzati con PRO',
                                  style: TextStyle(
                                    color: AppColors.lightTextSecondary,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.proGradient,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Upgrade a PRO →',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
      ),
    );
  }
}

// ── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });
  final String label, value, unit;
  final PhosphorIconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MsCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PhosphorIcon(icon, size: 20, color: AppColors.cyan),
            const SizedBox(height: 8),
            Text(value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.cyan,
              ),
            ),
            Text(unit,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Week Activity Grid ───────────────────────────────────────────────────────

class _WeekActivityGrid extends StatelessWidget {
  const _WeekActivityGrid({required this.weekData});
  final List<DayData> weekData;

  @override
  Widget build(BuildContext context) {
    const dayLabels = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];

    return Row(
      children: List.generate(7, (i) {
        final dayData = i < weekData.length ? weekData[i] : null;
        final isToday = i == DateTime.now().weekday - 1;

        return Expanded(
          child: Column(
            children: [
              Text(
                dayLabels[i],
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 6),
              Container(
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  gradient: dayData?.isActive ?? false
                      ? AppColors.brandGradient
                      : null,
                  color: dayData?.isActive ?? false
                      ? null
                      : AppColors.cyan.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: isToday
                      ? Border.all(color: AppColors.cyan, width: 2)
                      : null,
                ),
                child: Center(
                  child: dayData?.isActive ?? false
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ── Km Bar Chart ─────────────────────────────────────────────────────────────

class _KmBarChart extends StatelessWidget {
  const _KmBarChart({required this.weekData});
  final List<DayData> weekData;

  @override
  Widget build(BuildContext context) {
    const dayLabels = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _maxKm > 0 ? _maxKm * 1.3 : 5,
        barGroups: List.generate(7, (i) {
          final km = i < weekData.length
              ? (weekData[i].walk?.distanceKm ?? 0)
              : 0.0;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: km,
                gradient: km > 0 ? AppColors.brandGradient : null,
                color: km > 0 ? null : AppColors.cyan.withOpacity(0.08),
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Text(
                dayLabels[v.round()],
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (v, _) => v > 0
                  ? Text('${v.toInt()}', style: Theme.of(context).textTheme.labelSmall)
                  : const SizedBox(),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: _maxKm > 0 ? _maxKm / 3 : 1,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.cyan.withOpacity(0.1),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  double get _maxKm => weekData
      .map((d) => d.walk?.distanceKm ?? 0.0)
      .fold(0.0, (a, b) => a > b ? a : b);
}
