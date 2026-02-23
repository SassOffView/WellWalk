import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Card di base MindStep — bordo sottile, niente elevation
class MsCard extends StatelessWidget {
  const MsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = color ??
        (isDark ? AppColors.darkSurface : AppColors.lightBackground);
    final effectiveBorder = borderColor ??
        (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: effectiveBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Card con intestazione colorata (gradiente cyan)
class MsGradientCard extends StatelessWidget {
  const MsGradientCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cyanGlow,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Chip con lock per feature Pro
class ProBadge extends StatelessWidget {
  const ProBadge({super.key, this.small = false});
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 3,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.proGradient,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'PRO',
        style: TextStyle(
          color: Colors.white,
          fontSize: small ? 8 : 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Lock overlay per feature Pro non acquistata
class ProLockOverlay extends StatelessWidget {
  const ProLockOverlay({
    super.key,
    required this.child,
    required this.onTap,
    this.message = 'Disponibile con PRO',
  });

  final Widget child;
  final VoidCallback onTap;
  final String message;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Opacity(opacity: 0.4, child: child),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black.withOpacity(0.1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, color: AppColors.cyan, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: const TextStyle(
                      color: AppColors.cyan,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Separatore con label
class MsSectionHeader extends StatelessWidget {
  const MsSectionHeader({super.key, required this.title, this.action});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
