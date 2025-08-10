import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';

class BookingsWidget extends StatefulWidget {
  const BookingsWidget({super.key});

  @override
  State<BookingsWidget> createState() => _BookingsWidgetState();
}

class _BookingsWidgetState extends State<BookingsWidget> {
  bool _isMultiEditMode = false;
  final Set<int> _selectedBookings = {};

  final List<Map<String, dynamic>> _bookings = [
    {
      'id': 1,
      'clientName': 'Ahmad Ali',
      'service': 'homeCleaning',
      'date': '2024-01-15',
      'time': '10:00 AM',
      'status': 'pending',
      'amount': '\$50',
    },
    {
      'id': 2,
      'clientName': 'Fatima Hassan',
      'service': 'elderlyCare',
      'date': '2024-01-16',
      'time': '2:00 PM',
      'status': 'confirmed',
      'amount': '\$60',
    },
    {
      'id': 3,
      'clientName': 'Omar Khalil',
      'service': 'homeCooking',
      'date': '2024-01-14',
      'time': '6:00 PM',
      'status': 'completed',
      'amount': '\$40',
    },
    {
      'id': 4,
      'clientName': 'Layla Ahmed',
      'service': 'babysitting',
      'date': '2024-01-17',
      'time': '9:00 AM',
      'status': 'pending',
      'amount': '\$35',
    },
    {
      'id': 5,
      'clientName': 'Youssef Ibrahim',
      'service': 'homeCleaning',
      'date': '2024-01-13',
      'time': '11:00 AM',
      'status': 'cancelled',
      'amount': '\$50',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            
            // Responsive breakpoints
            final isDesktop = screenWidth > 1200;
            final isTablet = screenWidth > 768 && screenWidth <= 1200;
            final isMobile = screenWidth <= 768;
            
            return _buildBookingsWidget(languageService, isMobile, isTablet, isDesktop, screenWidth);
          },
        );
      },
    );
  }

  Widget _buildBookingsWidget(LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop, double screenWidth) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 8.0 : (isTablet ? 12.0 : 16.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with multi-edit controls
          _buildHeader(languageService, isMobile, isTablet, isDesktop),
          
          SizedBox(height: isMobile ? 12.0 : (isTablet ? 16.0 : 20.0)),
          
          // Multi-edit action bar
          if (_isMultiEditMode) _buildMultiEditActionBar(languageService, isMobile, isTablet, isDesktop),
          
          if (_isMultiEditMode) SizedBox(height: isMobile ? 8.0 : (isTablet ? 12.0 : 16.0)),
          
          // Stats Cards
          _buildStatsCards(languageService, isMobile, isTablet, isDesktop, screenWidth),
          
          SizedBox(height: isMobile ? 20.0 : (isTablet ? 24.0 : 28.0)),
          
          // Recent Bookings
          _buildBookingsList(languageService, isMobile, isTablet, isDesktop),
        ],
      ),
    );
  }

  Widget _buildHeader(LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and subtitle
        Text(
          AppStrings.getString('bookings', languageService.currentLanguage),
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 20.0 : (isTablet ? 24.0 : 28.0),
            fontWeight: FontWeight.bold,
            color: AppColors.greyDark,
          ),
        ),
        SizedBox(height: isMobile ? 2.0 : (isTablet ? 4.0 : 6.0)),
        Text(
          AppStrings.getString('manageBookingsAppointments', languageService.currentLanguage),
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 12.0 : (isTablet ? 14.0 : 16.0),
            color: AppColors.grey,
          ),
        ),
        SizedBox(height: isMobile ? 12.0 : (isTablet ? 16.0 : 20.0)),
        
        // Action buttons
        Row(
          children: [
            // Multi-edit toggle button
            Expanded(
              child: Container(
                height: isMobile ? 32 : (isTablet ? 36 : 40), // Reduced height
                decoration: BoxDecoration(
                  color: _isMultiEditMode ? AppColors.primary : AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isMultiEditMode ? AppColors.primary : AppColors.grey.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: _isMultiEditMode ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setState(() {
                        _isMultiEditMode = !_isMultiEditMode;
                        if (!_isMultiEditMode) {
                          _selectedBookings.clear();
                        }
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isMultiEditMode ? Icons.close : Icons.edit,
                          size: isMobile ? 14 : (isTablet ? 16 : 18), // Smaller icon
                          color: _isMultiEditMode ? AppColors.white : AppColors.grey,
                        ),
                        SizedBox(width: isMobile ? 4.0 : (isTablet ? 6.0 : 8.0)), // Reduced spacing
                        Text(
                          _isMultiEditMode 
                              ? AppStrings.getString('cancel', languageService.currentLanguage)
                              : AppStrings.getString('multiEdit', languageService.currentLanguage),
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 11.0 : (isTablet ? 12.0 : 13.0), // Smaller font
                            fontWeight: FontWeight.w600,
                            color: _isMultiEditMode ? AppColors.white : AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMultiEditActionBar(LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12.0 : (isTablet ? 14.0 : 16.0)),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Selection info
          Expanded(
            child: Text(
              '${_selectedBookings.length} ${AppStrings.getString('selected', languageService.currentLanguage)}',
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 12.0 : (isTablet ? 13.0 : 14.0),
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          // Bulk actions
          Row(
            children: [
              _buildBulkActionButton(
                icon: Icons.check_circle,
                label: AppStrings.getString('confirm', languageService.currentLanguage),
                onTap: _confirmSelectedBookings,
                languageService: languageService,
                isMobile: isMobile,
                isTablet: isTablet,
                isDesktop: isDesktop,
              ),
              SizedBox(width: isMobile ? 6.0 : (isTablet ? 7.0 : 8.0)),
              _buildBulkActionButton(
                icon: Icons.cancel,
                label: AppStrings.getString('cancel', languageService.currentLanguage),
                onTap: _cancelSelectedBookings,
                languageService: languageService,
                isMobile: isMobile,
                isTablet: isTablet,
                isDesktop: isDesktop,
                isDestructive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required LanguageService languageService,
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDestructive ? AppColors.error : AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8.0 : (isTablet ? 10.0 : 12.0), 
              vertical: isMobile ? 6.0 : (isTablet ? 7.0 : 8.0)
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: isMobile ? 14 : (isTablet ? 15 : 16),
                  color: AppColors.white,
                ),
                SizedBox(width: isMobile ? 3.0 : (isTablet ? 3.5 : 4.0)),
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 10.0 : (isTablet ? 11.0 : 12.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards(LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop, double screenWidth) {
    final stats = [
      {
        'title': 'pending',
        'count': '5',
        'color': AppColors.warning,
        'icon': Icons.schedule,
      },
      {
        'title': 'confirmed',
        'count': '12',
        'color': AppColors.success,
        'icon': Icons.check_circle,
      },
      {
        'title': 'completed',
        'count': '28',
        'color': AppColors.primary,
        'icon': Icons.done_all,
      },
      {
        'title': 'cancelled',
        'count': '3',
        'color': AppColors.error,
        'icon': Icons.cancel,
      },
    ];

    // Responsive grid configuration for stats cards - More compact design
    int crossAxisCount;
    double childAspectRatio;
    double crossAxisSpacing;
    double mainAxisSpacing;
    
    if (isMobile) {
      crossAxisCount = 2; // 2x2 grid on mobile
      childAspectRatio = 2.5; // More compact cards on mobile
      crossAxisSpacing = 8.0;
      mainAxisSpacing = 8.0;
    } else if (isTablet) {
      crossAxisCount = 2; // 2x2 grid on tablet
      childAspectRatio = 2.2; // More compact cards on tablet
      crossAxisSpacing = 12.0;
      mainAxisSpacing = 12.0;
    } else {
      crossAxisCount = 4; // 4 columns on desktop
      childAspectRatio = 2.0; // More compact cards on desktop
      crossAxisSpacing = 16.0;
      mainAxisSpacing = 16.0;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        return _buildStatCard(stats[index], languageService, isMobile, isTablet, isDesktop);
      },
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat, LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 8.0 : (isTablet ? 10.0 : 12.0)), // Reduced padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 4.0 : (isTablet ? 6.0 : 8.0)), // Reduced icon container padding
              decoration: BoxDecoration(
                color: stat['color'].withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                stat['icon'],
                size: isMobile ? 18 : (isTablet ? 20 : 24), // Slightly smaller icons
                color: stat['color'],
              ),
            ),
            SizedBox(height: isMobile ? 4.0 : (isTablet ? 6.0 : 8.0)), // Reduced spacing
            Text(
              stat['count'],
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 16.0 : (isTablet ? 20.0 : 24.0), // Slightly smaller font
                fontWeight: FontWeight.bold,
                color: AppColors.greyDark,
              ),
            ),
            SizedBox(height: isMobile ? 1.0 : (isTablet ? 2.0 : 3.0)), // Reduced spacing
            Text(
              AppStrings.getString(stat['title'], languageService.currentLanguage),
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 9.0 : (isTablet ? 10.0 : 11.0), // Slightly smaller font
                color: AppColors.grey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsList(LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.getString('recentBookings', languageService.currentLanguage),
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 18.0 : (isTablet ? 20.0 : 22.0),
            fontWeight: FontWeight.bold,
            color: AppColors.greyDark,
          ),
        ),
        SizedBox(height: isMobile ? 12.0 : (isTablet ? 16.0 : 20.0)),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _bookings.length,
          itemBuilder: (context, index) {
            return _buildBookingCard(_bookings[index], index, languageService, isMobile, isTablet, isDesktop);
          },
        ),
      ],
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, int index, LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop) {
    final statusColor = _getStatusColor(booking['status']);
    final isSelected = _selectedBookings.contains(index);
    
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 8.0 : (isTablet ? 12.0 : 16.0)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: isSelected 
            ? Border.all(color: AppColors.primary, width: 2)
            : Border.all(color: AppColors.grey.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (_isMultiEditMode) {
              setState(() {
                if (isSelected) {
                  _selectedBookings.remove(index);
                } else {
                  _selectedBookings.add(index);
                }
              });
            } else {
              // TODO: Navigate to booking details
            }
          },
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12.0 : (isTablet ? 14.0 : 16.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with checkbox and status
                Row(
                  children: [
                    if (_isMultiEditMode) ...[
                      Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedBookings.add(index);
                            } else {
                              _selectedBookings.remove(index);
                            }
                          });
                        },
                        activeColor: AppColors.primary,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      SizedBox(width: isMobile ? 6.0 : (isTablet ? 8.0 : 10.0)),
                    ],
                    
                    // Service icon
                    Container(
                      padding: EdgeInsets.all(isMobile ? 8.0 : (isTablet ? 10.0 : 12.0)),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.work,
                        color: AppColors.primary,
                        size: isMobile ? 18 : (isTablet ? 20 : 24),
                      ),
                    ),
                    SizedBox(width: isMobile ? 10.0 : (isTablet ? 12.0 : 14.0)),
                    
                    // Booking details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '#${booking['id']}',
                                style: GoogleFonts.cairo(
                                  fontSize: isMobile ? 12.0 : (isTablet ? 14.0 : 16.0),
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 6.0 : (isTablet ? 8.0 : 10.0), 
                                  vertical: isMobile ? 3.0 : (isTablet ? 4.0 : 6.0)
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: isMobile ? 4 : (isTablet ? 6 : 8),
                                      height: isMobile ? 4 : (isTablet ? 6 : 8),
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: isMobile ? 3.0 : (isTablet ? 4.0 : 6.0)),
                                    Text(
                                      AppStrings.getString(booking['status'], languageService.currentLanguage),
                                      style: GoogleFonts.cairo(
                                        fontSize: isMobile ? 10.0 : (isTablet ? 11.0 : 12.0),
                                        fontWeight: FontWeight.w600,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isMobile ? 6.0 : (isTablet ? 8.0 : 10.0)),
                          Text(
                            booking['clientName'],
                            style: GoogleFonts.cairo(
                              fontSize: isMobile ? 14.0 : (isTablet ? 16.0 : 18.0),
                              fontWeight: FontWeight.w600,
                              color: AppColors.greyDark,
                            ),
                          ),
                          SizedBox(height: isMobile ? 2.0 : (isTablet ? 3.0 : 4.0)),
                          Text(
                            AppStrings.getString(booking['service'], languageService.currentLanguage),
                            style: GoogleFonts.cairo(
                              fontSize: isMobile ? 12.0 : (isTablet ? 13.0 : 14.0),
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 8.0 : (isTablet ? 10.0 : 12.0)),
                
                // Date, time and amount
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: isMobile ? 14 : (isTablet ? 16 : 18),
                      color: AppColors.grey,
                    ),
                    SizedBox(width: isMobile ? 6.0 : (isTablet ? 8.0 : 10.0)),
                    Expanded(
                      child: Text(
                        '${booking['date']} at ${booking['time']}',
                        style: GoogleFonts.cairo(
                          fontSize: isMobile ? 11.0 : (isTablet ? 12.0 : 13.0),
                          color: AppColors.grey,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8.0 : (isTablet ? 10.0 : 12.0), 
                        vertical: isMobile ? 6.0 : (isTablet ? 8.0 : 10.0)
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        booking['amount'],
                        style: GoogleFonts.cairo(
                          fontSize: isMobile ? 12.0 : (isTablet ? 14.0 : 16.0),
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
        return AppColors.success;
      case 'completed':
        return AppColors.primary;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }

  void _confirmSelectedBookings() {
    // TODO: Implement bulk confirm
    setState(() {
      _isMultiEditMode = false;
      _selectedBookings.clear();
    });
  }

  void _cancelSelectedBookings() {
    // TODO: Implement bulk cancel
    setState(() {
      _isMultiEditMode = false;
      _selectedBookings.clear();
    });
  }
}
