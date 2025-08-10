import 'package:flutter/material.dart';

class ResponsiveService extends ChangeNotifier {
  // Fixed responsive service with proper breakpoints
  // Ensures consistent navigation behavior across all screen sizes

  // Breakpoint constants - Properly aligned for smooth transitions
  static const double mobileBreakpoint = 768;      // Mobile layout - Standard mobile breakpoint
  static const double tabletBreakpoint = 1024;     // Tablet layout - Standard tablet breakpoint
  static const double desktopBreakpoint = 1200;    // Desktop layout
  static const double largeDesktopBreakpoint = 1440; // Large desktop layout

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

  // Check if navigation should be compact (for medium screens)
  bool shouldUseCompactNavigation(double screenWidth) {
    // Use compact navigation only on medium screens to prevent overflow
    // This provides a smooth transition between mobile and full desktop
    return screenWidth > mobileBreakpoint && screenWidth <= 1100;
  }

  // Check if we should use very compact navigation (for small tablets)
  bool shouldUseVeryCompactNavigation(double screenWidth) {
    // Use very compact navigation only on small tablets
    // This prevents the need to hide navigation items
    return screenWidth > mobileBreakpoint && screenWidth <= 950;
  }

  // Unified collapsed navigation breakpoint for small/medium widths
  // This ensures the menu switches once and stays collapsed consistently
  bool shouldCollapseNavigation(double screenWidth) {
    return screenWidth <= 950; // collapsed at 950px and below
  }

  // Get all responsive states for debugging and testing
  Map<String, dynamic> getAllResponsiveStates(double screenWidth) {
    return {
      'isMobile': shouldUseMobileLayout(screenWidth),
      'isTablet': shouldUseTabletLayout(screenWidth),
      'isDesktop': shouldUseDesktopLayout(screenWidth),
      'isLargeDesktop': shouldUseLargeDesktopLayout(screenWidth),
      'shouldUseCompactNavigation': shouldUseCompactNavigation(screenWidth),
      'shouldUseVeryCompactNavigation': shouldUseVeryCompactNavigation(screenWidth),
      'responsiveMode': getResponsiveMode(screenWidth),
    };
  }
}
