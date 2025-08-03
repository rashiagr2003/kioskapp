import 'package:flutter/material.dart';

class ResponsiveHelper {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static double getResponsiveFontSize(
    BuildContext context,
    double baseFontSize,
  ) {
    final width = MediaQuery.of(context).size.width;
    // More conservative scaling for mobile devices
    if (width < 400) return baseFontSize * 0.9; // Smaller phones
    if (width < 600) return baseFontSize; // Regular phones
    if (width < 1200) return baseFontSize * 1.1; // Tablets
    return baseFontSize * 1.2; // Desktop
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return EdgeInsets.all(12); // Smaller phones
    if (width < 600) return EdgeInsets.all(16); // Regular phones
    if (width < 1200) return EdgeInsets.all(24); // Tablets
    return EdgeInsets.all(32); // Desktop
  }
}
