/// GreenBin Genius – Responsive Utility
/// ─────────────────────────────────────
/// Single import for all responsive size helpers.
///
/// Usage:
///   R.w(context, 24)   → 24% of screen width
///   R.h(context, 35)   → 35% of screen height
///   R.fs(context, 18)  → font size scaled to screen
///   R.sp(context)      → base spacing unit (adaptive padding/gap)
///   R.isSmall(context) → true if screen width < 360dp

import 'package:flutter/material.dart';

abstract class R {
  // ── Screen dimensions ─────────────────────────────────────

  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  // ── Breakpoints ──────────────────────────────────────────
  // Small  : width < 360  (J5, J2, older Androids)
  // Medium : 360–600      (most modern phones)
  // Large  : > 600        (tablets, foldables)

  static bool isSmall(BuildContext context) => screenWidth(context) < 360;
  static bool isMedium(BuildContext context) =>
      screenWidth(context) >= 360 && screenWidth(context) < 600;
  static bool isLarge(BuildContext context) => screenWidth(context) >= 600;

  // ── Percentage-based sizing ───────────────────────────────

  /// Returns [percent]% of screen WIDTH.  e.g. R.w(ctx, 24) = 24% of width.
  static double w(BuildContext context, double percent) =>
      screenWidth(context) * percent / 100;

  /// Returns [percent]% of screen HEIGHT. e.g. R.h(ctx, 35) = 35% of height.
  static double h(BuildContext context, double percent) =>
      screenHeight(context) * percent / 100;

  // ── Adaptive font size ────────────────────────────────────

  /// Scales [size] proportionally to the screen width.
  /// Base design width = 390dp (iPhone 14 / Pixel 7 area).
  /// Clamps to prevent text being absurdly tiny or huge.
  static double fs(BuildContext context, double size) {
    final scale = screenWidth(context) / 390;
    return (size * scale).clamp(size * 0.72, size * 1.3);
  }

  // ── Adaptive spacing ──────────────────────────────────────

  /// Base spacing unit.
  /// Small screens → 14px, Medium → 16px, Large → 20px.
  static double sp(BuildContext context) {
    if (isSmall(context)) return 14.0;
    if (isLarge(context)) return 20.0;
    return 16.0;
  }

  // ── Adaptive padding ──────────────────────────────────────

  /// Horizontal page padding.
  /// Small → 18,  Medium → 24,  Large → 32.
  static EdgeInsets pagePadding(BuildContext context) {
    final h = isSmall(context) ? 18.0 : isLarge(context) ? 32.0 : 24.0;
    return EdgeInsets.symmetric(horizontal: h);
  }

  // ── Adaptive button height ────────────────────────────────

  /// Standard full-width button height.
  static double buttonHeight(BuildContext context) {
    if (isSmall(context)) return 48.0;
    if (isLarge(context)) return 60.0;
    return 56.0;
  }

  // ── Adaptive icon size ────────────────────────────────────

  static double icon(BuildContext context, double size) {
    final scale = screenWidth(context) / 390;
    return (size * scale).clamp(size * 0.75, size * 1.2);
  }

  // ── Clamp helper ─────────────────────────────────────────

  /// Shorthand: value clamped between [min] and [max].
  static double clamp(double value, double min, double max) =>
      value.clamp(min, max);
}
