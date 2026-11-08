import 'package:flutter/material.dart';

/// Casama Spacing & Layout Rhythm (8-point grid)
class CasamaSpacing {
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double huge = 40.0;

  // Corner Radii
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusPill = 999.0;

  static const BorderRadius roundedSm = BorderRadius.all(
    Radius.circular(radiusSm),
  );
  static const BorderRadius roundedMd = BorderRadius.all(
    Radius.circular(radiusMd),
  );
  static const BorderRadius roundedLg = BorderRadius.all(
    Radius.circular(radiusLg),
  );
  static const BorderRadius roundedXl = BorderRadius.all(
    Radius.circular(radiusXl),
  );
  static const BorderRadius roundedPill = BorderRadius.all(
    Radius.circular(radiusPill),
  );

  // Common Touch Target
  static const double minTouchTarget = 48.0;
}
