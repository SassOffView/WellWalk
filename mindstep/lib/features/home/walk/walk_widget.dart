import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pedometer/pedometer.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/models/daily_insight.dart';
import '../../../core/models/day_data.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/walk_session.dart';
import '../../../core/services/gps_service.dart';
import '../../../shared/widgets/ms_card.dart';

class WalkWidget extends StatefulWidget {
  const WalkWidget({
    super.key,
    this.initialDayData,
    this.onWalkCompleted,
    this.insightForPopup,
    this.userProfile,
  });

  final DayData? initialDayData;
  final VoidCallback? onWalkCompleted;

  /// Insight AI da mostrare come popup al avvio camminata
  final DailyInsight? insightForPopup;

  /// Profilo utente per leggere gli obiettivi giornalieri
  final UserProfile? userProfile;

  @override
  State<WalkWidget> createState() => _WalkWidgetState();
}

class _WalkWidgetState extends State<WalkWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  WalkSession? _session;
  bool _requestingPermission = false;
  bool _insightShown = false;

  // Pedometro
  int _stepCountBase = 0;
  int _currentSteps = 0;
  Stream<StepCount>? _stepCountStream;

  GpsService get _gps => context.read<AppServices>().gps;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _gps.onSessionUpdate = (session) {
      if (mounted) setState(() => _session = session);
    };
    _gps.onError = (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
    };
  }

  void _initPedometer() {
    try {
      _stepCountStream = Pedometer.stepCountStream;
      _stepCountStream?.listen(
        (event) {
          if (!mounted) return;
          if (_stepCountBase == 0) {
            _stepCountBase = event.steps;
          }
          final steps = event.steps - _stepCountBase;
          setState(() => _currentSteps = steps > 0 ? steps : 0);
          // Aggiorna session con i passi
          final s = _session;
          if (s != null && s.isActive) {
            _gps.currentSession; // trigger update
          }
        },
        onError: (_) {},
        cancelOnError: false,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final services = context.read<AppServices>();
    final session = _session;
    final profile = widget.userProfile;

    final stepGoal = profile?.stepGoal ?? 8000;
    final walkMinGoal = profile?.walkMinutesGoal ?? 30;
    // brainstorm minutes viene dai dayData
    final brainstormMin = widget.initialDayData?.brainstormMinutes ?? 0;
    final brainstormGoal = profile?.brainstormMinutesGoal ?? 10;

    return MsCard(
      child: Column(
        children: [
          // Header
          Row(
            children: [
              PhosphorIcon(PhosphorIcons.personSimpleWalk(),
                  size: 20, color: AppColors.cyan),
              const SizedBox(width: 8),
              Text(
                AppStrings.walkTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Tre anelli concentrici + timer centrale ──────────────────
          SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Anello esterno: Cammino (minuti walk) — cyan
                CustomPaint(
                  size: const Size(220, 220),
                  painter: _RingPainter(
                    progress: _walkMinProgress(session, walkMinGoal),
                    color: AppColors.cyan,
                    bgColor: AppColors.cyan.withOpacity(0.1),
                    strokeWidth: 10,
                    radius: 107,
                  ),
                ),

                // Anello medio: Passi — purple
                CustomPaint(
                  size: const Size(220, 220),
                  painter: _RingPainter(
                    progress: _stepsProgress(session, stepGoal),
                    color: const Color(0xFF9C27B0),
                    bgColor: const Color(0xFF9C27B0).withOpacity(0.1),
                    strokeWidth: 10,
                    radius: 87,
                  ),
                ),

                // Anello interno: Brain (brainstorm) — green
                CustomPaint(
                  size: const Size(220, 220),
                  painter: _RingPainter(
                    progress: (brainstormMin / brainstormGoal).clamp(0.0, 1.0),
                    color: const Color(0xFF4CAF50),
                    bgColor: const Color(0xFF4CAF50).withOpacity(0.1),
                    strokeWidth: 10,
                    radius: 67,
                  ),
                ),

                // Timer centrale
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      session?.formattedTimeFull ?? '00:00:00',
                      style: TextStyle(
                        fontFamily: 'Courier New',
                        fontSize: 38,
                        fontWeight: FontWeight.w600,
                        color: session?.isActive ?? false
                            ? AppColors.cyan
                            : Theme.of(context).textTheme.bodyLarge?.color,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session?.isPaused ?? false ? 'IN PAUSA' : 'WALK TIME',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: session?.isPaused ?? false
                            ? AppColors.warning
                            : Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withOpacity(0.5),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Legenda anelli: Cammino • Passi • Brain
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RingLegend(color: AppColors.cyan, label: 'Cammino'),
              const SizedBox(width: 16),
              _RingLegend(color: const Color(0xFF9C27B0), label: 'Passi'),
              const SizedBox(width: 16),
              _RingLegend(color: const Color(0xFF4CAF50), label: 'Brain'),
            ],
          ),

          const SizedBox(height: 16),

          // Stats inline: X.X KM  |  X.X KM/H  |  X KCAL
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _InlineStat(
                value: session?.formattedDistance ?? '0.0',
                unit: 'KM',
              ),
              _statSep(),
              _InlineStat(
                value: session?.formattedSpeed ?? '0.0',
                unit: 'KM/H',
              ),
              _statSep(),
              _InlineStat(
                value: session?.formattedCalories ?? '0',
                unit: 'KCAL',
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Riga Passi (stima) con progress bar ──────────────────────
          _PassiRow(
            steps: _currentSteps > 0
                ? _currentSteps
                : (session?.stepCount ?? 0),
            goal: stepGoal,
          ),

          const SizedBox(height: 20),

          // Controls
          _buildControls(services, session),
        ],
      ),
    );
  }

  Widget _buildControls(AppServices services, WalkSession? session) {
    if (session == null || session.state == WalkState.idle) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _requestingPermission ? null : () => _startWalk(services),
          icon: _requestingPermission
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : PhosphorIcon(PhosphorIcons.play(PhosphorIconsStyle.fill),
                  size: 18),
          label: const Text('Inizia WalkingBrain'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        if (session.isActive)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _pauseWalk,
              icon: PhosphorIcon(PhosphorIcons.pause(), size: 18),
              label: Text(AppStrings.walkPause),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        if (session.isPaused)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _resumeWalk,
              icon: PhosphorIcon(
                  PhosphorIcons.play(PhosphorIconsStyle.fill), size: 18),
              label: Text(AppStrings.walkResume),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => _stopWalk(services),
          icon: PhosphorIcon(PhosphorIcons.stop(PhosphorIconsStyle.fill),
              color: AppColors.error, size: 18),
          label: Text(
            AppStrings.walkStop,
            style: const TextStyle(color: AppColors.error),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.error),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  // ── Walk logic ────────────────────────────────────────────────────────

  Future<void> _startWalk(AppServices services) async {
    setState(() => _requestingPermission = true);

    final hasPerm = await _gps.requestPermissions(
      backgroundRequired: services.isPro,
    );

    setState(() => _requestingPermission = false);

    if (!hasPerm) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(AppStrings.walkLocationPermissionDeny)),
        );
      }
      return;
    }

    // Reset pedometro
    _stepCountBase = 0;
    _currentSteps = 0;
    _initPedometer();

    await _gps.startWalk();

    if (mounted) {
      await services.notifications.showWalkOngoing(
        distance: '0.00',
        time: '00:00',
        isPaused: false,
      );

      // Mostra insight come popup (solo la prima volta)
      if (!_insightShown && widget.insightForPopup != null) {
        _insightShown = true;
        _showInsightPopup(widget.insightForPopup!);
      }
    }
  }

  void _pauseWalk() {
    _gps.pauseWalk();
    final session = _gps.currentSession;
    if (session != null) {
      context.read<AppServices>().notifications.showWalkOngoing(
        distance: session.formattedDistance,
        time: session.formattedTime,
        isPaused: true,
      );
    }
  }

  void _resumeWalk() {
    _gps.resumeWalk();
    final session = _gps.currentSession;
    if (session != null) {
      context.read<AppServices>().notifications.showWalkOngoing(
        distance: session.formattedDistance,
        time: session.formattedTime,
        isPaused: false,
      );
    }
  }

  Future<void> _stopWalk(AppServices services) async {
    final completed = _gps.stopWalk();
    if (completed == null) return;

    // Aggiorna step count nella session
    final withSteps = completed.copyWith(stepCount: _currentSteps);

    await services.notifications.cancelWalkOngoing();
    if (!mounted) return;
    _showWalkSummary(services, withSteps);
  }

  void _showWalkSummary(AppServices services, WalkSession session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _WalkSummarySheet(
        session: session,
        onSave: () async {
          Navigator.pop(ctx);
          await _saveWalk(services, session);
        },
        onDiscard: () => Navigator.pop(ctx),
      ),
    );
  }

  Future<void> _saveWalk(AppServices services, WalkSession session) async {
    final today = DateTime.now();
    await services.db.saveWalkSession(session, today);

    final dayData = await services.db.loadDayData(today);
    final newBadges = await services.badges.onWalkCompleted(
      walkMinutes: session.activeMinutes,
      isPro: services.isPro,
      dayData: dayData,
    );

    if (services.isPro) {
      final profile = await services.db.loadUserProfile();
      await services.health.syncWalkSession(
        session,
        weightKg: profile?.effectiveWeightKg ?? 65,
      );
    }

    setState(() {
      _session = null;
      _currentSteps = 0;
      _stepCountBase = 0;
    });
    widget.onWalkCompleted?.call();

    if (newBadges.isNotEmpty && mounted) {
      for (final badge in newBadges) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Traguardo: ${badge.name}!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  // ── Insight popup ─────────────────────────────────────────────────────

  void _showInsightPopup(DailyInsight insight) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PhosphorIcon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                      color: AppColors.cyan, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Il tuo insight di oggi',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                insight.insight,
                style: Theme.of(ctx)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.55),
              ),
              if (insight.walkTip != null && insight.walkTip!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    insight.walkTip!,
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: AppColors.cyan,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Inizia la camminata'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Progressi anelli ─────────────────────────────────────────────────

  double _stepsProgress(WalkSession? session, int goal) {
    final steps = _currentSteps > 0 ? _currentSteps : (session?.stepCount ?? 0);
    if (goal <= 0) return 0.0;
    return (steps / goal).clamp(0.0, 1.0);
  }

  double _walkMinProgress(WalkSession? session, int goal) {
    if (session == null || goal <= 0) return 0.0;
    return (session.activeMinutes / goal).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _gps.onSessionUpdate = null;
    _gps.onError = null;
    super.dispose();
  }
}

// ── Triple Ring Painter ────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
    required this.strokeWidth,
    required this.radius,
  });

  final double progress;
  final Color color;
  final Color bgColor;
  final double strokeWidth;
  final double radius; // distanza dal centro

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (progress <= 0) return;

    // Progress arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.radius != radius;
}

// ── Ring Legend chip ──────────────────────────────────────────────────────────

class _RingLegend extends StatelessWidget {
  const _RingLegend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(fontSize: 10),
        ),
      ],
    );
  }
}

// ── Inline Stat (X.X KM | X.X KM/H | X KCAL) ────────────────────────────────

class _InlineStat extends StatelessWidget {
  const _InlineStat({required this.value, required this.unit});
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Courier New',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.cyan,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 9,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

Widget _statSep() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        '|',
        style: TextStyle(
          color: Colors.grey.withOpacity(0.3),
          fontSize: 18,
        ),
      ),
    );

// ── Passi Row (stima) ─────────────────────────────────────────────────────────

class _PassiRow extends StatelessWidget {
  const _PassiRow({required this.steps, required this.goal});
  final int steps;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (steps / goal).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          PhosphorIcon(
            PhosphorIcons.personSimpleWalk(),
            size: 18,
            color: const Color(0xFF9C27B0),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$steps PASSI (STIMA)',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9C27B0),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '/ $goal',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: const Color(0xFF9C27B0).withOpacity(0.12),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF9C27B0)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Walk Summary Bottom Sheet ─────────────────────────────────────────────────

class _WalkSummarySheet extends StatelessWidget {
  const _WalkSummarySheet({
    required this.session,
    required this.onSave,
    required this.onDiscard,
  });

  final WalkSession session;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 24, 24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          PhosphorIcon(
            PhosphorIcons.star(PhosphorIconsStyle.fill),
            size: 48,
            color: AppColors.warning,
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.walkCompleted,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.walkSummary,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              _SummaryStat(
                  label: 'Distanza',
                  value: '${session.formattedDistance} km',
                  icon: PhosphorIcons.mapPin()),
              _SummaryStat(
                  label: 'Tempo',
                  value: session.formattedTime,
                  icon: PhosphorIcons.timer()),
              _SummaryStat(
                  label: 'Passi',
                  value: '${session.stepCount}',
                  icon: PhosphorIcons.footprints()),
              _SummaryStat(
                  label: 'Calorie',
                  value: '${session.formattedCalories} kcal',
                  icon: PhosphorIcons.flame()),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDiscard,
                  child: const Text(AppStrings.walkDiscard),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onSave,
                  icon: PhosphorIcon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                      size: 18),
                  label: const Text(AppStrings.walkSave),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final PhosphorIconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          PhosphorIcon(icon, size: 20, color: AppColors.cyan),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: AppColors.cyan,
            ),
            textAlign: TextAlign.center,
          ),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
