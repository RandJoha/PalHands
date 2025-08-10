import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';

class DashboardOverview extends StatefulWidget {
  const DashboardOverview({super.key});

  @override
  State<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<DashboardOverview> {
  bool _isLoading = false;
  Map<String, dynamic> _dashboardData = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // Mock data for demonstration
    setState(() {
      _dashboardData = {
        'users': {
          'total': 1247,
          'active': 1189,
          'inactive': 58,
          'byRole': [
            {'_id': 'client', 'count': 892},
            {'_id': 'provider', 'count': 312},
            {'_id': 'admin', 'count': 43},
          ]
        },
        'services': {
          'total': 456,
          'active': 423,
          'featured': 23,
        },
        'bookings': {
          'total': 2341,
          'today': 12,
          'thisWeek': 89,
          'thisMonth': 342,
        },
        'revenue': {
          'monthly': 45678.50,
          'averageBooking': 133.56,
        },
        'reports': {
          'pending': 8,
          'urgent': 2,
        },
        'systemHealth': {
          'database': 'healthy',
          'api': 'healthy',
          'uptime': 99.8,
        }
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return _buildDashboard(context, languageService);
      },
    );
  }

  Widget _buildDashboard(BuildContext context, LanguageService languageService) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isArabic = languageService.isArabic;
    
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Directionality(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth > 1400 ? 24 : screenWidth > 1024 ? 20 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome section - More compact
                  _buildWelcomeSection(languageService),
                  
                  SizedBox(height: screenWidth > 1400 ? 32 : screenWidth > 1024 ? 28 : 24),
                  
                  // Statistics cards - Improved layout
                  _buildStatisticsCards(languageService),
                  
                  SizedBox(height: screenWidth > 1400 ? 32 : screenWidth > 1024 ? 28 : 24),
                  
                  // Charts and graphs - Better positioning
                  _buildChartsSection(languageService),
                  
                  SizedBox(height: screenWidth > 1400 ? 32 : screenWidth > 1024 ? 28 : 24),
                  
                  // Recent activity - More compact
                  _buildRecentActivity(languageService),
                ],
              ),
            ),
          );
  }

  Widget _buildWelcomeSection(LanguageService languageService) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isArabic = languageService.isArabic;
    
    return Container(
      padding: EdgeInsets.all(screenWidth > 1400 ? 28 : screenWidth > 1024 ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(screenWidth > 1400 ? 16 : screenWidth > 1024 ? 14 : 12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon - Smaller and more proportional
          Container(
            width: screenWidth > 1400 ? 60 : screenWidth > 1024 ? 50 : 40,
            height: screenWidth > 1400 ? 60 : screenWidth > 1024 ? 50 : 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(screenWidth > 1400 ? 12 : screenWidth > 1024 ? 10 : 8),
            ),
            child: Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: screenWidth > 1400 ? 30 : screenWidth > 1024 ? 26 : 22,
            ),
          ),
          
          SizedBox(width: screenWidth > 1400 ? 20 : screenWidth > 1024 ? 16 : 12),
          
          // Text - Better proportions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.getString('welcomeBackAdmin', languageService.currentLanguage),
                  style: GoogleFonts.cairo(
                    fontSize: screenWidth > 1400 ? 26 : screenWidth > 1024 ? 22 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: screenWidth > 1400 ? 8 : screenWidth > 1024 ? 6 : 4),
                Text(
                  AppStrings.getString('platformOverview', languageService.currentLanguage),
                  style: GoogleFonts.cairo(
                    fontSize: screenWidth > 1400 ? 16 : screenWidth > 1024 ? 14 : 12,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          
          // Palestinian cultural element - Bigger
          Container(
            width: screenWidth > 1400 ? 100 : screenWidth > 1024 ? 80 : 70,
            height: screenWidth > 1400 ? 50 : screenWidth > 1024 ? 40 : 35,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(screenWidth > 1400 ? 10 : screenWidth > 1024 ? 8 : 6),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '🇵🇸',
                style: TextStyle(fontSize: screenWidth > 1400 ? 28 : screenWidth > 1024 ? 24 : 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(LanguageService languageService) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Improved responsive breakpoints with better mobile optimization
    if (screenWidth <= 768) {
      // Mobile: Use 2-column grid layout instead of horizontal scrolling
      return _buildMobileStatisticsGrid(languageService);
    }
    
    // Desktop/Tablet: Use grid layout with consistent sizing
    int crossAxisCount;
    double childAspectRatio;
    double spacing;
    
    if (screenWidth > 1400) {
      // Large desktop - 4 columns
      crossAxisCount = 4;
      childAspectRatio = 1.6;
      spacing = 20;
    } else if (screenWidth > 1200) {
      // Desktop - 4 columns
      crossAxisCount = 4;
      childAspectRatio = 1.5;
      spacing = 18;
    } else if (screenWidth > 1024) {
      // Large tablet - 3 columns
      crossAxisCount = 3;
      childAspectRatio = 1.4;
      spacing = 16;
    } else {
      // Tablet - 2 columns
      crossAxisCount = 2;
      childAspectRatio = 1.3;
      spacing = 14;
    }
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      childAspectRatio: childAspectRatio,
      children: [
        _buildStatCard(
          title: AppStrings.getString('totalUsers', languageService.currentLanguage),
          value: _dashboardData['users']?['total']?.toString() ?? '0',
          icon: Icons.people,
          color: AppColors.primary,
          trend: '+12%',
          trendUp: true,
          languageService: languageService,
        ),
        _buildStatCard(
          title: AppStrings.getString('activeServices', languageService.currentLanguage),
          value: _dashboardData['services']?['active']?.toString() ?? '0',
          icon: Icons.business_center,
          color: AppColors.secondary,
          trend: '+5%',
          trendUp: true,
          languageService: languageService,
        ),
        _buildStatCard(
          title: AppStrings.getString('todaysBookings', languageService.currentLanguage),
          value: _dashboardData['bookings']?['today']?.toString() ?? '0',
          icon: Icons.calendar_today,
          color: const Color(0xFF2E8B57),
          trend: '+8%',
          trendUp: true,
          languageService: languageService,
        ),
        _buildStatCard(
          title: AppStrings.getString('monthlyRevenue', languageService.currentLanguage),
          value: '₪${_dashboardData['revenue']?['monthly']?.toStringAsFixed(0) ?? '0'}',
          icon: Icons.attach_money,
          color: const Color(0xFF9C27B0),
          trend: '+15%',
          trendUp: true,
          languageService: languageService,
        ),
        _buildStatCard(
          title: AppStrings.getString('pendingReports', languageService.currentLanguage),
          value: _dashboardData['reports']?['pending']?.toString() ?? '0',
          icon: Icons.report_problem,
          color: const Color(0xFFFF5722),
          trend: '-3',
          trendUp: false,
          languageService: languageService,
        ),
        _buildStatCard(
          title: AppStrings.getString('systemUptime', languageService.currentLanguage),
          value: '${_dashboardData['systemHealth']?['uptime']?.toStringAsFixed(1) ?? '99.9'}%',
          icon: Icons.check_circle,
          color: const Color(0xFF4CAF50),
          trend: AppStrings.getString('stable', languageService.currentLanguage),
          trendUp: true,
          languageService: languageService,
        ),
      ],
    );
  }
  
  // Mobile-optimized statistics grid with 2 columns
  Widget _buildMobileStatisticsGrid(LanguageService languageService) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2, // Slightly taller for mobile
      children: [
        _buildMobileStatCard(
          title: AppStrings.getString('totalUsers', languageService.currentLanguage),
          value: _dashboardData['users']?['total']?.toString() ?? '0',
          icon: Icons.people,
          color: AppColors.primary,
          trend: '+12%',
          trendUp: true,
          languageService: languageService,
        ),
        _buildMobileStatCard(
          title: AppStrings.getString('activeServices', languageService.currentLanguage),
          value: _dashboardData['services']?['active']?.toString() ?? '0',
          icon: Icons.business_center,
          color: AppColors.secondary,
          trend: '+5%',
          trendUp: true,
          languageService: languageService,
        ),
        _buildMobileStatCard(
          title: AppStrings.getString('todaysBookings', languageService.currentLanguage),
          value: _dashboardData['bookings']?['today']?.toString() ?? '0',
          icon: Icons.calendar_today,
          color: const Color(0xFF2E8B57),
          trend: '+8%',
          trendUp: true,
          languageService: languageService,
        ),
        _buildMobileStatCard(
          title: AppStrings.getString('monthlyRevenue', languageService.currentLanguage),
          value: '₪${_dashboardData['revenue']?['monthly']?.toStringAsFixed(0) ?? '0'}',
          icon: Icons.attach_money,
          color: const Color(0xFF9C27B0),
          trend: '+15%',
          trendUp: true,
          languageService: languageService,
        ),
        _buildMobileStatCard(
          title: AppStrings.getString('pendingReports', languageService.currentLanguage),
          value: _dashboardData['reports']?['pending']?.toString() ?? '0',
          icon: Icons.report_problem,
          color: const Color(0xFFFF5722),
          trend: '-3',
          trendUp: false,
          languageService: languageService,
        ),
        _buildMobileStatCard(
          title: AppStrings.getString('systemUptime', languageService.currentLanguage),
          value: '${_dashboardData['systemHealth']?['uptime']?.toStringAsFixed(1) ?? '99.9'}%',
          icon: Icons.check_circle,
          color: const Color(0xFF4CAF50),
          trend: AppStrings.getString('stable', languageService.currentLanguage),
          trendUp: true,
          languageService: languageService,
        ),
      ],
    );
  }
  
  // Compact mobile stat card optimized for grid layout
  Widget _buildMobileStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
    required bool trendUp,
    required LanguageService languageService,
  }) {
    String formattedValue = _formatValueForDisplay(value, 400); // Mobile width
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon and trend - More compact
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 12,
                ),
              ),
              const Spacer(),
              // Larger trend indicator for mobile
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: trendUp ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: trendUp ? Colors.green.withValues(alpha: 0.6) : Colors.red.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (trendUp ? Colors.green : Colors.red).withValues(alpha: 0.3),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trendUp ? Icons.trending_up : Icons.trending_down,
                      color: trendUp ? Colors.green : Colors.red,
                      size: 14,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      trend,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: trendUp ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Value and title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formattedValue,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
    required bool trendUp,
    required LanguageService languageService,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Consistent responsive sizing with better proportions
    double padding, iconSize, fontSize, borderRadius, spacing;
    
    if (screenWidth > 1400) {
      padding = 18;
      iconSize = 40;
      fontSize = 24;
      borderRadius = 12;
      spacing = 10;
    } else if (screenWidth > 1200) {
      padding = 16;
      iconSize = 36;
      fontSize = 22;
      borderRadius = 10;
      spacing = 8;
    } else if (screenWidth > 1024) {
      padding = 14;
      iconSize = 32;
      fontSize = 20;
      borderRadius = 8;
      spacing = 6;
    } else {
      padding = 12;
      iconSize = 28;
      fontSize = 18;
      borderRadius = 6;
      spacing = 4;
    }
    
    // Smart value formatting to prevent overflow
    String formattedValue = _formatValueForDisplay(value, screenWidth);
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with icon and trend - More compact
          Row(
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(borderRadius * 0.6),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: iconSize * 0.45,
                ),
              ),
              const Spacer(),
              // Prominent trend indicator
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing * 1.5,
                  vertical: spacing * 1.0,
                ),
                decoration: BoxDecoration(
                  color: trendUp 
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(borderRadius * 1.0),
                  border: Border.all(
                    color: trendUp ? Colors.green.withValues(alpha: 0.5) : Colors.red.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (trendUp ? Colors.green : Colors.red).withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trendUp ? Icons.trending_up : Icons.trending_down,
                      color: trendUp ? Colors.green : Colors.red,
                      size: fontSize * 0.7,
                    ),
                    if (screenWidth > 768) ...[
                      SizedBox(width: spacing * 0.5),
                      Text(
                        trend,
                        style: GoogleFonts.cairo(
                          fontSize: fontSize * 0.6,
                          fontWeight: FontWeight.w800,
                          color: trendUp ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: spacing),
          
          // Value with overflow protection - Better emphasis
          Flexible(
            child: Text(
              formattedValue,
              style: GoogleFonts.cairo(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          
          SizedBox(height: spacing * 0.2),
          
          // Title with overflow protection
          Flexible(
            child: Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: fontSize * 0.4,
                color: AppColors.textLight,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
  
  // Improved value formatting to prevent overflow
  String _formatValueForDisplay(String value, double screenWidth) {
    // Handle currency values
    if (value.startsWith('₪')) {
      String number = value.substring(1);
      double? numValue = double.tryParse(number);
      if (numValue != null) {
        if (screenWidth <= 768) {
          // Mobile: Use K format for large numbers
          if (numValue >= 1000) {
            return '₪${(numValue / 1000).toStringAsFixed(1)}K';
          }
        } else if (screenWidth <= 1024) {
          // Tablet: Use K format for very large numbers
          if (numValue >= 10000) {
            return '₪${(numValue / 1000).toStringAsFixed(0)}K';
          }
        }
      }
    }
    
    // Handle regular numbers
    double? numValue = double.tryParse(value);
    if (numValue != null) {
      if (screenWidth <= 768) {
        // Mobile: Use K format for large numbers
        if (numValue >= 1000) {
          return '${(numValue / 1000).toStringAsFixed(1)}K';
        }
      } else if (screenWidth <= 1024) {
        // Tablet: Use K format for very large numbers
        if (numValue >= 10000) {
          return '${(numValue / 1000).toStringAsFixed(0)}K';
        }
      }
    }
    
    return value;
  }

  Widget _buildChartsSection(LanguageService languageService) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Better responsive layout for charts
    if (screenWidth > 1024) {
      // Desktop/Tablet - side by side
      return Row(
        children: [
          // User growth chart
          Expanded(
            flex: 1,
            child: _buildChartCard(
              title: AppStrings.getString('userGrowth', languageService.currentLanguage),
              subtitle: AppStrings.getString('last30Days', languageService.currentLanguage),
              child: Container(
                height: screenWidth > 1400 ? 300 : screenWidth > 1200 ? 280 : 250,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '📈 ${AppStrings.getString('chartPlaceholder', languageService.currentLanguage)}',
                    style: GoogleFonts.cairo(
                      fontSize: screenWidth > 1400 ? 18 : screenWidth > 1200 ? 16 : 14,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          SizedBox(width: screenWidth > 1400 ? 24 : screenWidth > 1200 ? 20 : 16),
          
          // Revenue chart
          Expanded(
            flex: 1,
            child: _buildChartCard(
              title: AppStrings.getString('revenueTrend', languageService.currentLanguage),
              subtitle: AppStrings.getString('monthlyEarnings', languageService.currentLanguage),
              child: Container(
                height: screenWidth > 1400 ? 300 : screenWidth > 1200 ? 280 : 250,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '💰 ${AppStrings.getString('chartPlaceholder', languageService.currentLanguage)}',
                    style: GoogleFonts.cairo(
                      fontSize: screenWidth > 1400 ? 18 : screenWidth > 1200 ? 16 : 14,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // Mobile - stacked with better spacing
      return Column(
        children: [
          // User growth chart
          _buildChartCard(
            title: AppStrings.getString('userGrowth', languageService.currentLanguage),
            subtitle: AppStrings.getString('last30Days', languageService.currentLanguage),
            child: Container(
              height: 180, // Reduced height for mobile
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '📈 ${AppStrings.getString('chartPlaceholder', languageService.currentLanguage)}',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: AppColors.textLight,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Revenue chart
          _buildChartCard(
            title: AppStrings.getString('revenueTrend', languageService.currentLanguage),
            subtitle: AppStrings.getString('monthlyEarnings', languageService.currentLanguage),
            child: Container(
              height: 180, // Reduced height for mobile
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '💰 ${AppStrings.getString('chartPlaceholder', languageService.currentLanguage)}',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: AppColors.textLight,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Consistent responsive sizing for chart cards
    double padding, fontSize, borderRadius;
    
    if (screenWidth > 1400) {
      padding = 20;
      fontSize = 18;
      borderRadius = 16;
    } else if (screenWidth > 1200) {
      padding = 18;
      fontSize = 16;
      borderRadius = 14;
    } else if (screenWidth > 1024) {
      padding = 16;
      fontSize = 14;
      borderRadius = 12;
    } else {
      padding = 14;
      fontSize = 12;
      borderRadius = 10;
    }
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: padding * 0.15),
          Text(
            subtitle,
            style: GoogleFonts.cairo(
              fontSize: fontSize * 0.75,
              color: AppColors.textLight,
            ),
          ),
          SizedBox(height: padding * 0.6),
          Flexible(child: child),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(LanguageService languageService) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      padding: EdgeInsets.all(screenWidth > 1400 ? 24 : screenWidth > 1024 ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth > 1400 ? 16 : screenWidth > 1024 ? 14 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.getString('recentActivity', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: screenWidth > 1400 ? 20 : screenWidth > 1024 ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: screenWidth > 1400 ? 16 : screenWidth > 1024 ? 12 : 10),
          
          // Activity items - More compact
          _buildActivityItem(
            icon: Icons.person_add,
            title: AppStrings.getString('newUserRegistered', languageService.currentLanguage),
            subtitle: AppStrings.getString('ahmedHassanJoined', languageService.currentLanguage),
            time: '2 ${AppStrings.getString('minutesAgo', languageService.currentLanguage)}',
            color: AppColors.primary,
            languageService: languageService,
          ),
          _buildActivityItem(
            icon: Icons.calendar_today,
            title: AppStrings.getString('bookingCompleted', languageService.currentLanguage),
            subtitle: AppStrings.getString('cleaningServiceRamallah', languageService.currentLanguage),
            time: '15 ${AppStrings.getString('minutesAgo', languageService.currentLanguage)}',
            color: AppColors.secondary,
            languageService: languageService,
          ),
          _buildActivityItem(
            icon: Icons.report_problem,
            title: AppStrings.getString('reportSubmitted', languageService.currentLanguage),
            subtitle: AppStrings.getString('userReportedInappropriate', languageService.currentLanguage),
            time: '1 ${AppStrings.getString('hourAgo', languageService.currentLanguage)}',
            color: const Color(0xFFFF5722),
            languageService: languageService,
          ),
          _buildActivityItem(
            icon: Icons.payment,
            title: AppStrings.getString('paymentProcessed', languageService.currentLanguage),
            subtitle: AppStrings.getString('paymentForHomeMaintenance', languageService.currentLanguage),
            time: '2 ${AppStrings.getString('hoursAgo', languageService.currentLanguage)}',
            color: const Color(0xFF4CAF50),
            languageService: languageService,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
    required LanguageService languageService,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth > 1400 ? 12 : screenWidth > 1024 ? 10 : 8),
      child: Row(
        children: [
          // Icon - Balanced sizing
          Container(
            width: screenWidth > 1400 ? 40 : screenWidth > 1024 ? 36 : 32,
            height: screenWidth > 1400 ? 40 : screenWidth > 1024 ? 36 : 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(screenWidth > 1400 ? 8 : screenWidth > 1024 ? 6 : 4),
            ),
            child: Icon(
              icon,
              color: color,
              size: screenWidth > 1400 ? 20 : screenWidth > 1024 ? 18 : 16,
            ),
          ),
          
          SizedBox(width: screenWidth > 1400 ? 14 : screenWidth > 1024 ? 12 : 10),
          
          // Content - Balanced text sizing
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: screenWidth > 1400 ? 15 : screenWidth > 1024 ? 14 : 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    fontSize: screenWidth > 1400 ? 13 : screenWidth > 1024 ? 12 : 11,
                    color: AppColors.textLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          
          // Time - Balanced text sizing
          Text(
            time,
            style: GoogleFonts.cairo(
              fontSize: screenWidth > 1400 ? 13 : screenWidth > 1024 ? 12 : 11,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
} 