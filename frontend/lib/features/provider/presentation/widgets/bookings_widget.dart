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
  Set<int> _selectedBookings = {};

  final List<Map<String, dynamic>> _bookings = [
    {
      'id': 1,
      'clientName': 'Ahmad Ali',
      'service': 'Home Cleaning',
      'date': '2024-01-15',
      'time': '10:00 AM',
      'status': 'pending',
      'amount': '\$50',
    },
    {
      'id': 2,
      'clientName': 'Fatima Hassan',
      'service': 'Elderly Care',
      'date': '2024-01-16',
      'time': '2:00 PM',
      'status': 'confirmed',
      'amount': '\$60',
    },
    {
      'id': 3,
      'clientName': 'Omar Khalil',
      'service': 'Home Cooking',
      'date': '2024-01-14',
      'time': '6:00 PM',
      'status': 'completed',
      'amount': '\$40',
    },
    {
      'id': 4,
      'clientName': 'Layla Ahmed',
      'service': 'Babysitting',
      'date': '2024-01-17',
      'time': '9:00 AM',
      'status': 'pending',
      'amount': '\$35',
    },
    {
      'id': 5,
      'clientName': 'Youssef Ibrahim',
      'service': 'Home Cleaning',
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
        return _buildBookingsWidget(languageService);
      },
    );
  }

  Widget _buildBookingsWidget(LanguageService languageService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with multi-edit controls
          _buildHeader(languageService),
          
          const SizedBox(height: 24),
          
          // Multi-edit action bar
          if (_isMultiEditMode) _buildMultiEditActionBar(languageService),
          
          if (_isMultiEditMode) const SizedBox(height: 16),
          
          // Stats Cards
          _buildStatsCards(languageService),
          
          const SizedBox(height: 32),
          
          // Recent Bookings
          _buildBookingsList(languageService),
        ],
      ),
    );
  }

  Widget _buildHeader(LanguageService languageService) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.getString('bookings', languageService.currentLanguage),
                style: GoogleFonts.cairo(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.greyDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.getString('manageBookingsAppointments', languageService.currentLanguage),
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
        ),
        // Multi-edit toggle button
        Container(
          decoration: BoxDecoration(
            color: _isMultiEditMode ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isMultiEditMode ? AppColors.primary : AppColors.grey.withValues(alpha: 0.3),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _isMultiEditMode = !_isMultiEditMode;
                  if (!_isMultiEditMode) {
                    _selectedBookings.clear();
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isMultiEditMode ? Icons.close : Icons.edit,
                      size: 20,
                      color: _isMultiEditMode ? AppColors.white : AppColors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isMultiEditMode 
                          ? AppStrings.getString('cancel', languageService.currentLanguage)
                          : AppStrings.getString('multiEdit', languageService.currentLanguage),
                      style: GoogleFonts.cairo(
                        fontSize: 14,
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
    );
  }

  Widget _buildMultiEditActionBar(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                fontSize: 14,
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
              ),
              const SizedBox(width: 8),
              _buildBulkActionButton(
                icon: Icons.cancel,
                label: AppStrings.getString('cancel', languageService.currentLanguage),
                onTap: _cancelSelectedBookings,
                languageService: languageService,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: AppColors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
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

  Widget _buildStatsCards(LanguageService languageService) {
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

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        return _buildStatCard(stats[index], languageService);
      },
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat, LanguageService languageService) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              stat['icon'],
              size: 32,
              color: stat['color'],
            ),
            const SizedBox(height: 8),
            Text(
              stat['count'],
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.greyDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.getString(stat['title'], languageService.currentLanguage),
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppColors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsList(LanguageService languageService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.getString('recentBookings', languageService.currentLanguage),
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.greyDark,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _bookings.length,
          itemBuilder: (context, index) {
            return _buildBookingCard(_bookings[index], index, languageService);
          },
        ),
      ],
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, int index, LanguageService languageService) {
    final statusColor = _getStatusColor(booking['status']);
    final isSelected = _selectedBookings.contains(index);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: isSelected 
            ? Border.all(color: AppColors.primary, width: 2)
            : Border.all(color: AppColors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Checkbox for multi-edit mode
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
                  ),
                  const SizedBox(width: 8),
                ],
                
                // Service icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.work,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
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
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              AppStrings.getString(booking['status'], languageService.currentLanguage),
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking['clientName'],
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.greyDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking['service'],
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: AppColors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: AppColors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${booking['date']} at ${booking['time']}',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Amount and actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      booking['amount'],
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (booking['status'] == 'pending') ...[
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              AppStrings.getString('accept', languageService.currentLanguage),
                              style: GoogleFonts.cairo(fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              AppStrings.getString('reject', languageService.currentLanguage),
                              style: GoogleFonts.cairo(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.message,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
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
