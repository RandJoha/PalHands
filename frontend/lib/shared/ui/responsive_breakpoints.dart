import 'package:flutter/material.dart';

/// Centralized responsive breakpoints and helper utilities
class ResponsiveBreakpoints {
  // Core breakpoints
  static const double mobile = 768;
  static const double tablet = 1091;
  static const double desktop = 1250;
  static const double wideDesktop = 1400;
  
  // Problem areas identified in TECHNICAL_MEMORY
  static const double problemRangeStart = 1091;
  static const double problemRangeEnd = 1249;
  
  // Grid columns based on width
  static int getProviderGridColumns(double width) {
    if (width >= wideDesktop) return 3;
    if (width >= desktop) return 2;
    if (width >= tablet) return 2;
    return 1; // mobile
  }
  
  // Check if we're in the problematic width range
  static bool isInProblematicRange(double width) {
    return width >= problemRangeStart && width <= problemRangeEnd;
  }
  
  // Should use mobile layout (categories modal)
  static bool shouldUseMobileLayout(double width) {
    return width <= tablet;
  }
  
  // Should use side-by-side layout
  static bool shouldUseSideBySideLayout(double width) {
    return width > tablet;
  }
  
  // Get horizontal padding based on width
  static double getHorizontalPadding(double width) {
    if (width <= mobile) return 16.0;
    if (width <= tablet) return 20.0;
    if (isInProblematicRange(width)) return 16.0; // Tighter for problem range
    if (width <= desktop) return 24.0;
    return 32.0;
  }
  
  // Get filter controls spacing
  static double getFilterSpacing(double width) {
    if (width <= mobile) return 8.0;
    if (isInProblematicRange(width)) return 6.0; // Tighter for problem range
    return 12.0;
  }
  
  // Should wrap filter controls
  static bool shouldWrapFilters(double width) {
    return width <= desktop;
  }
  
  // Get minimum button width for filters
  static double getMinButtonWidth(double width) {
    if (width <= mobile) return 80.0;
    if (isInProblematicRange(width)) return 90.0; // Controlled size in problem range
    return 120.0;
  }
  
  // Get maximum button width for filters
  static double getMaxButtonWidth(double width) {
    if (width <= mobile) return 140.0;
    if (isInProblematicRange(width)) return 160.0; // Controlled size in problem range
    return 200.0;
  }
  
  // Tap target size (minimum 44px for accessibility)
  static const double minTapTarget = 44.0;
  
  // Get button height
  static double getButtonHeight(double width) {
    if (width <= mobile) return minTapTarget;
    if (isInProblematicRange(width)) return 40.0; // Slightly smaller in problem range
    return 48.0;
  }
}

/// Extension to easily check breakpoints from MediaQuery
extension ResponsiveExtension on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  
  bool get isMobile => screenWidth <= ResponsiveBreakpoints.mobile;
  bool get isTablet => screenWidth > ResponsiveBreakpoints.mobile && screenWidth <= ResponsiveBreakpoints.tablet;
  bool get isDesktop => screenWidth > ResponsiveBreakpoints.tablet;
  bool get isWideDesktop => screenWidth >= ResponsiveBreakpoints.wideDesktop;
  
  bool get shouldUseMobileLayout => ResponsiveBreakpoints.shouldUseMobileLayout(screenWidth);
  bool get shouldUseSideBySideLayout => ResponsiveBreakpoints.shouldUseSideBySideLayout(screenWidth);
  bool get isInProblematicRange => ResponsiveBreakpoints.isInProblematicRange(screenWidth);
}
