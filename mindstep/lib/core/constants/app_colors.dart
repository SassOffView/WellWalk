import 'package:flutter/material.dart';

/// Palette colori MindStep — identica alla PWA v5.0
class AppColors {
  AppColors._();

  // ── BRAND ──────────────────────────────────────────────────────────────
  static const cyan = Color(0xFF00D4FF);
  static const cyanDark = Color(0xFF00B4D8);
  static const cyanLight = Color(0xFF5CE1E6);
  static const navy = Color(0xFF3B4FA0);
  static const navyDark = Color(0xFF0A1128);
  static const navyMid = Color(0xFF1A2357);
  static const navyLight = Color(0xFF2B3A7F);

  // ── LIGHT MODE ─────────────────────────────────────────────────────────
  static const lightBackground = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFF5F7FA);
  static const lightText = Color(0xFF0F1419);
  static const lightTextSecondary = Color(0xFF4A5568);
  static const lightBorder = Color(0xFFE5E7EB);

  // ── DARK MODE ──────────────────────────────────────────────────────────
  static const darkBackground = Color(0xFF0A1128);
  static const darkSurface = Color(0xFF1A2357);
  static const darkText = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFF8B92A3);
  static const darkBorder = Color(0xFF2B3A7F);

  // ── SEMANTIC ───────────────────────────────────────────────────────────
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // ── BADGE ──────────────────────────────────────────────────────────────
  static const badgeLocked = Color(0xFFD1D5DB);
  static const badgeLockedBg = Color(0xFFF3F4F6);
  static const badgeUnlockedGold = Color(0xFFFFDC73);
  static const badgeUnlockedBg = Color(0xFFFFF9E6);
  static const badgeUnlockedBgDark = Color(0xFF4A3C1F);
  static const badgeGoldBorder = Color(0xFFFFDC73);

  // ── PRO BADGE ──────────────────────────────────────────────────────────
  static const proGradientStart = Color(0xFF667EEA);
  static const proGradientEnd = Color(0xFF764BA2);

  // ── GRADIENT ───────────────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    colors: [cyan, cyanLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient navyGradient = LinearGradient(
    colors: [navyDark, navyMid],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient walkActiveGradient = LinearGradient(
    colors: [cyan, cyanLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient proGradient = LinearGradient(
    colors: [proGradientStart, proGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── SHADOWS ────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF0F1419).withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get cardShadowMd => [
    BoxShadow(
      color: const Color(0xFF0F1419).withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get cyanGlow => [
    BoxShadow(
      color: cyan.withOpacity(0.3),
      blurRadius: 20,
      spreadRadius: 0,
    ),
  ];
}
