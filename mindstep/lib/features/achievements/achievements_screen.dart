import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/badge_model.dart';
import '../../shared/widgets/ms_card.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

// Gruppi di visualizzazione per gli achievements (4 categorie)
enum _AchievementGroup { tutti, walk, routine, mente }

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<BadgeStatus> _statuses = [];
  bool _loading = true;
  _AchievementGroup _group = _AchievementGroup.tutti;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final services = context.read<AppServices>();
    final statuses = await services.db.loadAllBadgeStatuses(services.isPro);
    if (mounted) setState(() {
      _statuses = statuses;
      _loading = false;
    });
  }

  List<BadgeStatus> get _filtered {
    switch (_group) {
      case _AchievementGroup.tutti:
        return _statuses;
      case _AchievementGroup.walk:
        return _statuses.where((s) => const {
          BadgeCategory.walk,
          BadgeCategory.distance,
          BadgeCategory.duration,
          BadgeCategory.streak,
        }.contains(s.badge.category)).toList();
      case _AchievementGroup.routine:
        return _statuses
            .where((s) => s.badge.category == BadgeCategory.routine)
            .toList();
      case _AchievementGroup.mente:
        return _statuses.where((s) => const {
          BadgeCategory.brainstorm,
          BadgeCategory.special,
        }.contains(s.badge.category)).toList();
    }
  }

  int get _unlockedCount => _statuses.where((s) => s.isUnlocked).length;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.achievementsTitle,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 8),
                    if (!_loading)
                      Text(
                        '$_unlockedCount / ${_statuses.length} traguardi sbloccati',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ),

            // Progress overview
            if (!_loading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _ProgressOverview(
                    unlocked: _unlockedCount,
                    total: _statuses.length,
                  ),
                ),
              ),

            // Category filter
            SliverToBoxAdapter(
              child: _CategoryFilter(
                selected: _group,
                onSelected: (g) => setState(() => _group = g),
              ),
            ),

            // Grid badges — FIX BUG #4: niente max-height, scrollabile nativo
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.cyan)),
              )
            else if (_filtered.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    AppStrings.achievementsEmpty,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _BadgeTile(
                      status: _filtered[i],
                      onTap: () => _showBadgeDetail(_filtered[i]),
                    ),
                    childCount: _filtered.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,   // 3 colonne su telefono
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetail(BadgeStatus status) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _BadgeDetailSheet(status: status),
    );
  }
}

// ── Progress Overview ────────────────────────────────────────────────────────

class _ProgressOverview extends StatelessWidget {
  const _ProgressOverview({required this.unlocked, required this.total});
  final int unlocked;
  final int total;

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? unlocked / total : 0.0;

    return MsGradientCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$unlocked su $total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Traguardi sbloccati',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          PhosphorIcon(
            PhosphorIcons.medal(PhosphorIconsStyle.fill),
            color: Colors.amber,
            size: 48,
          ),
        ],
      ),
    );
  }
}

// ── Category Filter (4 gruppi) ────────────────────────────────────────────────

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({
    required this.selected,
    required this.onSelected,
  });

  final _AchievementGroup selected;
  final ValueChanged<_AchievementGroup> onSelected;

  @override
  Widget build(BuildContext context) {
    const groups = _AchievementGroup.values;
    const labels = {
      _AchievementGroup.tutti: 'Tutti',
      _AchievementGroup.walk: 'Walk',
      _AchievementGroup.routine: 'Routine',
      _AchievementGroup.mente: 'Mente',
    };

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        itemCount: groups.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final group = groups[i];
          final isSelected = group == selected;
          return GestureDetector(
            onTap: () => onSelected(group),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.cyan : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.cyan : AppColors.lightBorder,
                ),
              ),
              child: Text(
                labels[group]!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Badge Tile ───────────────────────────────────────────────────────────────

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.status, required this.onTap});
  final BadgeStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUnlocked = status.isUnlocked;

    Color bgColor;
    Color borderColor;

    if (isUnlocked) {
      bgColor = isDark ? AppColors.badgeUnlockedBgDark : AppColors.badgeUnlockedBg;
      borderColor = AppColors.badgeGoldBorder;
    } else {
      bgColor = isDark ? AppColors.darkSurface : AppColors.badgeLockedBg;
      borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: isUnlocked ? [
            BoxShadow(
              color: AppColors.badgeGoldBorder.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icona (emoji per ora, SVG custom in futuro)
              ColorFiltered(
                colorFilter: isUnlocked
                    ? const ColorFilter.mode(Colors.transparent, BlendMode.saturation)
                    : const ColorFilter.matrix([
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0,      0,      0,      1, 0,
                      ]),
                child: Text(
                  _badgeEmoji(status.badge.icon),
                  style: const TextStyle(fontSize: 32),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                status.badge.name,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isUnlocked
                      ? (isDark ? Colors.amber.shade300 : const Color(0xFF8B6914))
                      : Theme.of(context).textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (!isUnlocked && status.badge.isPro)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      gradient: AppColors.proGradient,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'PRO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _badgeEmoji(String iconName) {
    const map = {
      'shoe_track': '👟',
      'map_route': '🗺️',
      'hiking_boot': '🥾',
      'medal_100': '🏅',
      'finish_flag': '🏁',
      'target_bullseye': '🎯',
      'star_50': '⭐',
      'trophy_gold': '🏆',
      'timer_20': '⏱️',
      'hourglass_full': '⌛',
      'clock_crown': '🕐',
      'seedling': '🌱',
      'chart_half': '📊',
      'star_check': '✨',
      'flame_7': '🔥',
      'lightning_crown': '⚡',
      'diamond': '💎',
      'thought_bubble': '💭',
      'brain_waves': '🧠',
      'wave_double': '🌊',
    };
    return map[iconName] ?? '🏅';
  }
}

// ── Badge Detail Sheet ───────────────────────────────────────────────────────

class _BadgeDetailSheet extends StatelessWidget {
  const _BadgeDetailSheet({required this.status});
  final BadgeStatus status;

  @override
  Widget build(BuildContext context) {
    final isUnlocked = status.isUnlocked;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Icon grande
          Text(
            _badgeEmoji(status.badge.icon),
            style: TextStyle(
              fontSize: 80,
              color: isUnlocked ? null : null,
            ),
          ),
          const SizedBox(height: 16),

          // Badge PRO label
          if (status.badge.isPro)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppColors.proGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'PRO Exclusive',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),

          Text(
            status.badge.name,
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          Text(
            status.badge.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.cyan.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PhosphorIcon(
                  isUnlocked
                      ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                      : PhosphorIcons.lockSimple(PhosphorIconsStyle.fill),
                  color: isUnlocked ? AppColors.success : AppColors.cyan,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isUnlocked
                        ? status.badge.unlockMessage
                        : status.badge.description,
                    style: TextStyle(
                      color: isUnlocked ? AppColors.success : null,
                      fontStyle: isUnlocked ? FontStyle.italic : null,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          if (isUnlocked && status.unlockedAt != null) ...[
            const SizedBox(height: 12),
            Text(
              'Sbloccato il ${_formatDate(status.unlockedAt!)}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _badgeEmoji(String iconName) {
    const map = {
      'shoe_track': '👟', 'map_route': '🗺️', 'hiking_boot': '🥾',
      'medal_100': '🏅', 'finish_flag': '🏁', 'target_bullseye': '🎯',
      'star_50': '⭐', 'trophy_gold': '🏆', 'timer_20': '⏱️',
      'hourglass_full': '⌛', 'clock_crown': '🕐', 'seedling': '🌱',
      'chart_half': '📊', 'star_check': '✨', 'flame_7': '🔥',
      'lightning_crown': '⚡', 'diamond': '💎', 'thought_bubble': '💭',
      'brain_waves': '🧠', 'wave_double': '🌊',
    };
    return map[iconName] ?? '🏅';
  }

  String _formatDate(DateTime date) {
    final months = [
      '', 'gen', 'feb', 'mar', 'apr', 'mag', 'giu',
      'lug', 'ago', 'set', 'ott', 'nov', 'dic',
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }
}
