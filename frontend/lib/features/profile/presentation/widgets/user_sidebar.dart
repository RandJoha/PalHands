import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';

// User models
import '../../domain/models/user_menu_item.dart';

class UserSidebar extends StatelessWidget {
  final int selectedIndex;
  final List<UserMenuItem> menuItems;
  final bool isCollapsed;
  final Function(int) onItemSelected;
  final VoidCallback onToggleCollapse;

  const UserSidebar({
    super.key,
    required this.selectedIndex,
    required this.menuItems,
    required this.isCollapsed,
    required this.onItemSelected,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isCollapsed ? 80.w : 280.w,
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Menu items
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return _buildMenuItem(item);
              },
            ),
          ),
          
          // Footer
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 80.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16.r),
          bottomRight: Radius.circular(16.r),
        ),
      ),
      child: Row(
        children: [
          // Logo/App name
          if (!isCollapsed) ...[
            Icon(
              Icons.handshake,
              size: 24.sp,
              color: AppColors.white,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'PalHands',
                style: GoogleFonts.cairo(
                  fontSize: 18.sp,
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else ...[
            Icon(
              Icons.handshake,
              size: 24.sp,
              color: AppColors.white,
            ),
          ],
          
          // Toggle button
          IconButton(
            onPressed: onToggleCollapse,
            icon: Icon(
              isCollapsed ? Icons.chevron_right : Icons.chevron_left,
              color: AppColors.white,
              size: 20.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(UserMenuItem item) {
    final isSelected = selectedIndex == item.index;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onItemSelected(item.index),
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12.r),
              border: isSelected
                  ? Border.all(color: AppColors.primary, width: 1)
                  : null,
            ),
            child: Row(
              children: [
                // Icon
                Icon(
                  item.icon,
                  size: 20.sp,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                
                // Title and badge
                if (!isCollapsed) ...[
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: GoogleFonts.cairo(
                              fontSize: 14.sp,
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (item.badge != null) ...[
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              item.badge!,
                              style: GoogleFonts.cairo(
                                fontSize: 10.sp,
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
      ),
      child: Column(
        children: [
          if (!isCollapsed) ...[
            Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Icon(
                    Icons.person,
                    color: AppColors.white,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ahmed Hassan',
                        style: GoogleFonts.cairo(
                          fontSize: 14.sp,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Premium User',
                        style: GoogleFonts.cairo(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
          ] else ...[
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                Icons.person,
                color: AppColors.white,
                size: 20.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }
} 