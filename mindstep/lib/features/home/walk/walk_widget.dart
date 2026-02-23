import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/models/day_data.dart';
import '../../../core/models/walk_session.dart';
import '../../../core/services/gps_service.dart';
import '../../../shared/widgets/ms_card.dart';

class WalkWidget extends StatefulWidget {
  const WalkWidget({
    super.key,
    this.initialDayData,
    this.onWalkCompleted,
  });

  final DayData? initialDayData;
  final VoidCallback? onWalkCompleted;

  @override
  State<WalkWidget> createState() => _WalkWidgetState();
}

class _WalkWidgetState extends State<WalkWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  WalkSession? _session;
  bool _requestingPermission = false;

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

  @override
  Widget build(BuildContext context) {
    final services = context.read<AppServices>();
    final session = _session;

    return MsCard(
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const Text('🚶', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                AppStrings.walkTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress ring + timer
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background ring
                CustomPaint(
                  size: const Size(180, 180),
                  painter: _RingPainter(
                    progress: _ringProgress(session),
                    color: AppColors.cyan,
                    backgroundColor: AppColors.cyan.withOpacity(0.1),
                    strokeWidth: 12,
                    isActive: session?.isActive ?? false,
                  ),
                ),

                // Timer text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      session?.formattedTime ?? '00:00',
                      style: TextStyle(
                        fontFamily: 'Courier New',
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                        color: session?.isActive ?? false
                            ? AppColors.cyan
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    if (session?.isPaused ?? false)
                      Text(
                        'IN PAUSA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                          letterSpacing: 1.5,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatChip(
                label: AppStrings.walkKm,
                value: session?.formattedDistance ?? '0.00',
                emoji: '📍',
              ),
              _StatChip(
                label: AppStrings.walkSpeed,
                value: session?.formattedSpeed ?? '0.0',
                emoji: '⚡',
              ),
              _StatChip(
                label: AppStrings.walkCalories,
                value: session?.formattedCalories ?? '0',
                emoji: '🔥',
              ),
            ],
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
              : const Icon(Icons.play_arrow),
          label: Text(AppStrings.walkStart),
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
              icon: const Icon(Icons.pause),
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
              icon: const Icon(Icons.play_arrow),
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
          icon: const Icon(Icons.stop, color: AppColors.error),
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

  Future<void> _startWalk(AppServices services) async {
    setState(() => _requestingPermission = true);

    final hasPerm = await _gps.requestPermissions(
      backgroundRequired: services.isPro,
    );

    setState(() => _requestingPermission = false);

    if (!hasPerm) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.walkLocationPermissionDeny)),
        );
      }
      return;
    }

    await _gps.startWalk();

    // Notifica ongoing per foreground
    if (mounted) {
      await services.notifications.showWalkOngoing(
        distance: '0.00',
        time: '00:00',
        isPaused: false,
      );
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

    // Cancella notifica ongoing
    await services.notifications.cancelWalkOngoing();

    if (!mounted) return;

    // Mostra riepilogo
    _showWalkSummary(services, completed);
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

    // Salva nel DB
    await services.db.saveWalkSession(session, today);

    // Controlla badge walk (FIX BUG #2 PWA)
    final dayData = await services.db.loadDayData(today);
    final newBadges = await services.badges.onWalkCompleted(
      walkMinutes: session.activeMinutes,
      isPro: services.isPro,
      dayData: dayData,
    );

    // Sync Health Connect (Pro)
    if (services.isPro) {
      final profile = await services.db.loadUserProfile();
      await services.health.syncWalkSession(
        session,
        weightKg: profile?.effectiveWeightKg ?? 65,
      );
    }

    setState(() => _session = null);
    widget.onWalkCompleted?.call();

    // Mostra badge sbloccati
    if (newBadges.isNotEmpty && mounted) {
      for (final badge in newBadges) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🏅 Traguardo: ${badge.name}!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  double _ringProgress(WalkSession? session) {
    if (session == null) return 0.0;
    // Anello basato sui minuti (obiettivo 30 min = 100%)
    return (session.activeMinutes / 30.0).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _gps.onSessionUpdate = null;
    _gps.onError = null;
    super.dispose();
  }
}

// ── Ring Painter ─────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
    required this.isActive,
  });

  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;
  final bool isActive;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (progress <= 0) return;

    // Progress arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -pi / 2, // Start from top
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
      old.progress != progress || old.isActive != isActive;
}

// ── Stat Chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.emoji,
  });

  final String label;
  final String value;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Courier New',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.cyan,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
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
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          const Text('🎉', style: TextStyle(fontSize: 48)),
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

          // Stats grid
          Row(
            children: [
              _SummaryStat(label: 'Distanza', value: '${session.formattedDistance} km', emoji: '📍'),
              _SummaryStat(label: 'Tempo', value: session.formattedTime, emoji: '⏱️'),
              _SummaryStat(label: 'Velocità', value: '${session.formattedSpeed} km/h', emoji: '⚡'),
              _SummaryStat(label: 'Calorie', value: '${session.formattedCalories} kcal', emoji: '🔥'),
            ],
          ),
          const SizedBox(height: 24),

          // Buttons
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
                  icon: const Icon(Icons.check),
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
    required this.emoji,
  });

  final String label;
  final String value;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
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
