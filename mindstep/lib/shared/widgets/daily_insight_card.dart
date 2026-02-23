import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/daily_insight.dart';

/// Card che mostra l'insight giornaliero generato dall'AI.
/// Visualizza: analisi comportamento, suggerimento pratico, provider badge.
class DailyInsightCard extends StatelessWidget {
  const DailyInsightCard({
    super.key,
    required this.insight,
    this.isLoading = false,
    this.onRefresh,
  });

  final DailyInsight? insight;
  final bool isLoading;

  /// Callback per forzare rigenrazione insight (ignora cache)
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.cyan.withOpacity(0.12),
                  AppColors.cyan.withOpacity(0.04),
                ]
              : [
                  AppColors.cyan.withOpacity(0.08),
                  AppColors.cyan.withOpacity(0.02),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan.withOpacity(0.25)),
      ),
      child: isLoading ? _buildSkeleton(context) : _buildContent(context),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.cyan,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'AI sta elaborando il tuo insight...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.cyan,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (insight == null) return const SizedBox.shrink();

    final isAI = insight!.generatedBy != 'locale';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Row(
            children: [
              const Text('🤖', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAI
                      ? 'AI Insight · ${insight!.generatedBy}'
                      : 'Insight del giorno',
                  style: const TextStyle(
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (onRefresh != null)
                GestureDetector(
                  onTap: onRefresh,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.refresh_outlined,
                        color: AppColors.cyan, size: 16),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Insight text ───────────────────────────────────────────────
          Text(
            insight!.insight,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),

          // ── Suggestion pill ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.cyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: AppColors.cyan, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    insight!.suggestion,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.cyan,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Walk tip (se presente) ─────────────────────────────────────
          if (insight!.walkTip != null && insight!.walkTip!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🚶', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    insight!.walkTip!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
