// lib/utils/responsive.dart
//
// Responsive breakpoint helpers for The Cafe Elite.
// These only affect LAYOUT decisions — no business logic, theme or data flow.
//
//   Mobile  : 0    - 599px
//   Tablet  : 600  - 1023px
//   Desktop : 1024px and above
import 'package:flutter/widgets.dart';

class Responsive {
  Responsive._();

  static const double mobileMax = 599;
  static const double tabletMax = 1023;
  static const double desktopMin = 1024;

  static double widthOf(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static bool isMobile(BuildContext context) =>
      widthOf(context) <= mobileMax;

  static bool isTablet(BuildContext context) {
    final w = widthOf(context);
    return w > mobileMax && w < desktopMin;
  }

  static bool isDesktop(BuildContext context) =>
      widthOf(context) >= desktopMin;

  /// True when the wide desktop shell (sidebar layout) should be used.
  static bool useDesktopShell(BuildContext context) =>
      widthOf(context) >= desktopMin;

  /// Number of product-grid columns that comfortably fit [availableWidth].
  /// Mirrors the original mobile look (3 columns) and scales up on wider
  /// screens so the grid never appears stretched on desktop.
  static int productGridColumns(double availableWidth) {
    if (availableWidth >= 1500) return 6;
    if (availableWidth >= 1200) return 5;
    if (availableWidth >= 900) return 4;
    if (availableWidth >= 560) return 3;
    return 2;
  }
}
