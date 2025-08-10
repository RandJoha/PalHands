import 'package:flutter/material.dart';

class ResponsiveService extends ChangeNotifier {
  // Enhanced responsive service with multiple breakpoints
  // Prevents button overlap and provides smooth transitions

  // Breakpoint constants
  static const double mobileBreakpoint = 600;      // Mobile layout
  static const double tabletBreakpoint = 900;      // Tablet layout  
  static const double desktopBreakpoint = 1200;    // Desktop layout
  static const double largeDesktopBreakpoint = 1600; // Large desktop layout

  // Check if current screen should use mobile layout based on screen width
  bool shouldUseMobileLayout(double screenWidth) {
    return screenWidth <= mobileBreakpoint;
  }

  // Check if current screen should use tablet layout
  bool shouldUseTabletLayout(double screenWidth) {
    return screenWidth > mobileBreakpoint && screenWidth <= tabletBreakpoint;
  }

  // Check if current screen should use desktop layout
  bool shouldUseDesktopLayout(double screenWidth) {
    return screenWidth > tabletBreakpoint && screenWidth <= desktopBreakpoint;
  }

  // Check if current screen should use large desktop layout
  bool shouldUseLargeDesktopLayout(double screenWidth) {
    return screenWidth > desktopBreakpoint;
  }

  // Get responsive state for any given screen width
  bool getResponsiveState(double screenWidth) {
    return screenWidth <= mobileBreakpoint;
  }

  // Get the current responsive mode as a string
  String getResponsiveMode(double screenWidth) {
    if (screenWidth <= mobileBreakpoint) return 'mobile';
    if (screenWidth <= tabletBreakpoint) return 'tablet';
    if (screenWidth <= desktopBreakpoint) return 'desktop';
    return 'large-desktop';
  }

  // Check if buttons should be stacked to prevent overlap
  bool shouldStackButtons(double screenWidth) {
    // Stack buttons when there's not enough space for them to be side by side
    // This prevents overlap issues in the intermediate range
    return screenWidth <= 700;
  }

  // Check if navigation should be compact
  bool shouldUseCompactNavigation(double screenWidth) {
    // Use compact navigation when space is limited but not quite mobile
    return screenWidth > mobileBreakpoint && screenWidth <= 800;
  }

  // Get all responsive states for debugging and testing
  Map<String, dynamic> getAllResponsiveStates(double screenWidth) {
    return {
      'isMobile': shouldUseMobileLayout(screenWidth),
      'isTablet': shouldUseTabletLayout(screenWidth),
      'isDesktop': shouldUseDesktopLayout(screenWidth),
      'isLargeDesktop': shouldUseLargeDesktopLayout(screenWidth),
      'shouldStackButtons': shouldStackButtons(screenWidth),
      'shouldUseCompactNavigation': shouldUseCompactNavigation(screenWidth),
      'responsiveMode': getResponsiveMode(screenWidth),
    };
  }
}
