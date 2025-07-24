import 'package:flutter/material.dart';

class AppColors {
  // Primary colors - Palestinian inspired
  static const Color primary = Color(0xFF2E8B57); // Sea Green
  static const Color primaryLight = Color(0xFF52B788);
  static const Color primaryDark = Color(0xFF1F5F3F);
  
  // Secondary colors
  static const Color secondary = Color(0xFFD4AC0D); // Golden
  static const Color secondaryLight = Color(0xFFF7DC6F);
  static const Color secondaryDark = Color(0xFFB7950B);
  
  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF6B7280);
  static const Color greyLight = Color(0xFFF3F4F6);
  static const Color greyDark = Color(0xFF374151);
  
  // Background colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Service category colors
  static const Color cleaningColor = Color(0xFF06B6D4);
  static const Color laundryColor = Color(0xFF8B5CF6);
  static const Color caregivingColor = Color(0xFFEC4899);
  static const Color movingColor = Color(0xFFF97316);
  static const Color elderlyColor = Color(0xFF84CC16);
  static const Color maintenanceColor = Color(0xFF6366F1);
  
  // Text colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  
  // Border colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  
  // Rating colors
  static const Color ratingFilled = Color(0xFFFBBF24);
  static const Color ratingEmpty = Color(0xFFE5E7EB);
  
  // Shadow colors
  static const Color shadow = Color(0x0A000000);
  static const Color shadowLight = Color(0x05000000);
  
  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryDark],
  );
  
  // Service status colors
  static const Color pendingStatus = Color(0xFFF59E0B);
  static const Color confirmedStatus = Color(0xFF10B981);
  static const Color inProgressStatus = Color(0xFF3B82F6);
  static const Color completedStatus = Color(0xFF059669);
  static const Color cancelledStatus = Color(0xFFEF4444);
} 