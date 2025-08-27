import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';

// Admin models
import '../../domain/models/admin_menu_item.dart';

// Admin widgets
import 'language_toggle_widget.dart';

class AdminSidebar extends StatefulWidget {
  final List<AdminMenuItem> menuItems;
  final int selectedIndex;
  final bool isCollapsed;
  final Function(int) onItemSelected;
  final VoidCallback onToggleCollapse;

  const AdminSidebar({
    super.key,
    required this.menuItems,
    required this.selectedIndex,
    required this.isCollapsed,
    required this.onItemSelected,
    required this.onToggleCollapse,
  });

  @override
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return _buildSidebar(context, languageService);
      },
    );
  }

  Widget _buildSidebar(BuildContext context, LanguageService languageService) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Reduced sidebar width for better content space allocation
    double sidebarWidth;
    if (widget.isCollapsed) {
      // Collapsed: Show only icons with minimal space
      sidebarWidth = screenWidth > 1400 ? 70 : 60;
    } else {
      // Expanded: Reduced width for better balance
      sidebarWidth = screenWidth > 1400 ? 240 : screenWidth > 1200 ? 220 : 200;
    }
    
    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header - Reduced height
          _buildHeader(context, languageService),
          
          // Menu items
          Expanded(
            child: _buildMenuItems(),
          ),
          
          // Language toggle
          _buildLanguageToggle(),
          
          // Footer - More compact
          _buildFooter(languageService),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LanguageService languageService) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      height: screenWidth > 1400 ? 90 : 80, // Increased height to accommodate button
      padding: EdgeInsets.symmetric(horizontal: screenWidth > 1400 ? 16 : 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Removed redundant Back to Main Menu button (home icon exists in header)
          // Existing header content
          Row(
            children: [
              // Logo/Icon - Smaller
              Container(
                width: screenWidth > 1400 ? 36 : 32,
                height: screenWidth > 1400 ? 36 : 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.admin_panel_settings,
                  color: AppColors.primary,
                  size: screenWidth > 1400 ? 20 : 18,
                ),
              ),
              
              if (!widget.isCollapsed) ...[
                SizedBox(width: screenWidth > 1400 ? 10 : 8),
                
                // Title - More compact
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'PalHands',
                        style: GoogleFonts.cairo(
                          fontSize: screenWidth > 1400 ? 16 : 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        AppStrings.getString('adminPanel', languageService.currentLanguage),
                        style: GoogleFonts.cairo(
                          fontSize: screenWidth > 1400 ? 10 : 9,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Toggle button - Smaller
              IconButton(
                onPressed: widget.onToggleCollapse,
                icon: Icon(
                  widget.isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                  color: Colors.white,
                  size: screenWidth > 1400 ? 18 : 16,
                ),
                tooltip: widget.isCollapsed 
                  ? AppStrings.getString('expand', languageService.currentLanguage)
                  : AppStrings.getString('collapse', languageService.currentLanguage),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                  minWidth: screenWidth > 1400 ? 32 : 28,
                  minHeight: screenWidth > 1400 ? 32 : 28,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      itemCount: widget.menuItems.length,
      itemBuilder: (context, index) {
        final item = widget.menuItems[index];
        final isSelected = widget.selectedIndex == index;
        
        return _buildMenuItem(item, isSelected);
      },
    );
  }

  Widget _buildMenuItem(AdminMenuItem item, bool isSelected) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive sizing for menu items - more compact
    double iconSize, fontSize, padding;
    if (widget.isCollapsed) {
      // Collapsed: Compact icons
      iconSize = screenWidth > 1400 ? 36 : 32;
      fontSize = 0; // No text when collapsed
      padding = screenWidth > 1400 ? 10 : 8;
    } else {
      // Expanded: Compact design
      iconSize = screenWidth > 1400 ? 32 : 28;
      fontSize = screenWidth > 1400 ? 14 : 12;
      padding = screenWidth > 1400 ? 12 : 10;
    }
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: widget.isCollapsed ? 3 : 6,
        vertical: 1,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onItemSelected(item.index),
          borderRadius: BorderRadius.circular(widget.isCollapsed ? 6 : 8),
          child: Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: isSelected 
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.transparent,
              borderRadius: BorderRadius.circular(widget.isCollapsed ? 6 : 8),
              border: isSelected
                ? Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
            ),
            child: widget.isCollapsed 
              ? _buildCollapsedMenuItem(item, isSelected, iconSize)
              : _buildExpandedMenuItem(item, isSelected, iconSize, fontSize),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCollapsedMenuItem(AdminMenuItem item, bool isSelected, double iconSize) {
    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: isSelected 
          ? AppColors.primary
          : AppColors.textLight.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        item.icon,
        color: isSelected 
          ? Colors.white
          : AppColors.textLight,
        size: iconSize * 0.45,
      ),
    );
  }
  
  Widget _buildExpandedMenuItem(AdminMenuItem item, bool isSelected, double iconSize, double fontSize) {
    return Row(
      children: [
        // Icon - Smaller
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: isSelected 
              ? AppColors.primary
              : AppColors.textLight.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            item.icon,
            color: isSelected 
              ? Colors.white
              : AppColors.textLight,
            size: iconSize * 0.45,
          ),
        ),
        
        const SizedBox(width: 10),
        
        // Title - More compact
        Expanded(
          child: Text(
            item.title,
            style: GoogleFonts.cairo(
              fontSize: fontSize,
              fontWeight: isSelected 
                ? FontWeight.w600
                : FontWeight.normal,
              color: isSelected 
                ? AppColors.primary
                : AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageToggle() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth > 1400 ? 12 : 10,
        vertical: 8,
      ),
      child: LanguageToggleWidget(
        isCollapsed: widget.isCollapsed,
        screenWidth: screenWidth,
      ),
    );
  }

  Widget _buildFooter(LanguageService languageService) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      padding: EdgeInsets.all(screenWidth > 1400 ? 12 : 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Palestinian cultural element - Smaller
          if (!widget.isCollapsed)
            Container(
              height: 1.5.h,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.primary, // Palestinian red
                    AppColors.secondary, // Golden
                    Color(0xFF2E8B57), // Sea green
                  ],
                ),
                borderRadius: BorderRadius.circular(0.75.r),
              ),
            ),
        ],
      ),
    );
  }
} 