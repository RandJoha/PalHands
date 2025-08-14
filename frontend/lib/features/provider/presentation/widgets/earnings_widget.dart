import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';

class EarningsWidget extends StatefulWidget {
  const EarningsWidget({super.key});

  @override
  State<EarningsWidget> createState() => _EarningsWidgetState();
}

class _EarningsWidgetState extends State<EarningsWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            
            // Responsive breakpoints
            final isDesktop = screenWidth > 1200;
            final isTablet = screenWidth > 768 && screenWidth <= 1200;
            final isMobile = screenWidth <= 768;
            
            return _buildEarningsWidget(languageService, isMobile, isTablet, isDesktop, screenWidth);
          },
        );
      },
    );
  }

  Widget _buildEarningsWidget(LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop, double screenWidth) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 8.0 : (isTablet ? 12.0 : 16.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(languageService, isMobile, isTablet, isDesktop),
          
          SizedBox(height: isMobile ? 12.0 : (isTablet ? 16.0 : 20.0)),
          
          // Earnings Overview
          _buildEarningsOverview(languageService, isMobile, isTablet, isDesktop, screenWidth),
          
          SizedBox(height: isMobile ? 20.0 : (isTablet ? 24.0 : 28.0)),
          
          // Earnings Chart
          _buildEarningsChart(languageService, isMobile, isTablet, isDesktop),
          
          SizedBox(height: isMobile ? 20.0 : (isTablet ? 24.0 : 28.0)),
          
          // Recent Transactions
          _buildRecentTransactions(languageService, isMobile, isTablet, isDesktop),
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
          AppStrings.getString('earnings', languageService.currentLanguage),
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 20.0 : (isTablet ? 24.0 : 28.0),
            fontWeight: FontWeight.bold,
            color: AppColors.greyDark,
          ),
        ),
        SizedBox(height: isMobile ? 2.0 : (isTablet ? 4.0 : 6.0)),
        Text(
          AppStrings.getString('trackYourEarningsTransactions', languageService.currentLanguage),
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 12.0 : (isTablet ? 14.0 : 16.0),
            color: AppColors.grey,
          ),
        ),
        SizedBox(height: isMobile ? 12.0 : (isTablet ? 16.0 : 20.0)),
        
        // Action buttons
        Row(
          children: [
            // Export button
            Expanded(
              child: Container(
                height: isMobile ? 32 : (isTablet ? 36 : 40), // Reduced height
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      // TODO: Export earnings report
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.download,
                          size: isMobile ? 14 : (isTablet ? 16 : 18), // Smaller icon
                          color: AppColors.white,
                        ),
                        SizedBox(width: isMobile ? 4.0 : (isTablet ? 6.0 : 8.0)), // Reduced spacing
                        Text(
                          AppStrings.getString('exportReport', languageService.currentLanguage),
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 11.0 : (isTablet ? 12.0 : 13.0), // Smaller font
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
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

  Widget _buildEarningsOverview(LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop, double screenWidth) {
    final earnings = [
      {
        'title': 'totalEarnings',
        'amount': '\$2,450',
        'change': '+12.5%',
        'isPositive': true,
        'color': AppColors.success,
        'icon': Icons.trending_up,
      },
      {
        'title': 'thisMonth',
        'amount': '\$850',
        'change': '+8.2%',
        'isPositive': true,
        'color': AppColors.primary,
        'icon': Icons.calendar_month,
      },
      {
        'title': 'pendingPayments',
        'amount': '\$320',
        'change': '3 payments',
        'isPositive': true,
        'color': AppColors.warning,
        'icon': Icons.pending,
      },
      {
        'title': 'averagePerBooking',
        'amount': '\$45',
        'change': '+5.1%',
        'isPositive': true,
        'color': AppColors.secondary,
        'icon': Icons.analytics,
      },
    ];

    // Responsive grid configuration for earnings cards - More compact design
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
      itemCount: earnings.length,
      itemBuilder: (context, index) {
        return _buildEarningCard(earnings[index], languageService, isMobile, isTablet, isDesktop);
      },
    );
  }

  Widget _buildEarningCard(Map<String, dynamic> earning, LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and change indicator
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 4.0 : (isTablet ? 6.0 : 8.0)), // Reduced icon container padding
                  decoration: BoxDecoration(
                    color: earning['color'].withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    earning['icon'],
                    size: isMobile ? 16 : (isTablet ? 18 : 20), // Slightly smaller icons
                    color: earning['color'],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 3.0 : (isTablet ? 4.0 : 6.0), // Reduced padding
                    vertical: isMobile ? 1.0 : (isTablet ? 2.0 : 3.0) // Reduced padding
                  ),
                  decoration: BoxDecoration(
                    color: earning['isPositive'] 
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        earning['isPositive'] ? Icons.trending_up : Icons.trending_down,
                        size: isMobile ? 8 : (isTablet ? 10 : 12), // Smaller icons
                        color: earning['isPositive'] ? AppColors.success : AppColors.error,
                      ),
                      SizedBox(width: isMobile ? 1.0 : (isTablet ? 1.5 : 2.0)), // Reduced spacing
                      Text(
                        earning['change'],
                        style: GoogleFonts.cairo(
                          fontSize: isMobile ? 8.0 : (isTablet ? 9.0 : 10.0), // Smaller font
                          fontWeight: FontWeight.w600,
                          color: earning['isPositive'] ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 6.0 : (isTablet ? 8.0 : 10.0)), // Reduced spacing
            
            // Amount
            Text(
              earning['amount'],
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 16.0 : (isTablet ? 20.0 : 24.0), // Slightly smaller font
                fontWeight: FontWeight.bold,
                color: AppColors.greyDark,
              ),
            ),
            SizedBox(height: isMobile ? 1.0 : (isTablet ? 2.0 : 3.0)), // Reduced spacing
            
            // Title
            Text(
              AppStrings.getString(earning['title'], languageService.currentLanguage),
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 10.0 : (isTablet ? 11.0 : 12.0), // Slightly smaller font
                color: AppColors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsChart(LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.getString('earningsChart', languageService.currentLanguage),
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 18.0 : (isTablet ? 20.0 : 22.0),
            fontWeight: FontWeight.bold,
            color: AppColors.greyDark,
          ),
        ),
        SizedBox(height: isMobile ? 12.0 : (isTablet ? 16.0 : 20.0)),
        Container(
          height: isMobile ? 160 : (isTablet ? 200 : 240),
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
          child: Center(
            child: Text(
              AppStrings.getString('chartPlaceholder', languageService.currentLanguage),
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 12.0 : (isTablet ? 14.0 : 16.0),
                color: AppColors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop) {
    final transactions = [
      {
        'id': '#TR001',
        'clientName': 'أحمد محمد',
        'service': 'homeCleaning',
        'amount': '\$50',
        'commission': '\$5',
        'status': 'completed',
        'date': '2024-12-15',
        'type': 'credit',
        'description': 'Cleaning Service',
      },
      {
        'id': '#TR002',
        'clientName': 'Sarah Johnson',
        'service': 'homeBabysitting',
        'amount': '\$40',
        'commission': '\$4',
        'status': 'completed',
        'date': '2024-12-14',
        'type': 'credit',
        'description': 'babysittingService',
      },
      {
        'id': '#TR003',
        'clientName': 'فاطمة علي',
        'service': 'homeElderlyCare',
        'amount': '\$60',
        'commission': '\$6',
        'status': 'pending',
        'date': '2024-12-13',
        'type': 'debit',
        'description': 'elderlyCareService',
      },
      {
        'id': '#TR004',
        'clientName': 'Michael Brown',
        'service': 'homeCookingServices',
        'amount': '\$70',
        'commission': '\$7',
        'status': 'completed',
        'date': '2024-12-12',
        'type': 'credit',
        'description': 'Cooking Services',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.getString('recentTransactions', languageService.currentLanguage),
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
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            return _buildTransactionCard(transactions[index], languageService, isMobile, isTablet, isDesktop);
          },
        ),
      ],
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction, LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop) {
    final isCredit = transaction['type'] == 'credit';
    
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 8.0 : (isTablet ? 12.0 : 16.0)),
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
        padding: EdgeInsets.all(isMobile ? 12.0 : (isTablet ? 14.0 : 16.0)),
        child: Row(
          children: [
            // Transaction icon
            Container(
              padding: EdgeInsets.all(isMobile ? 8.0 : (isTablet ? 10.0 : 12.0)),
              decoration: BoxDecoration(
                color: isCredit 
                    ? AppColors.success.withValues(alpha: 0.08)
                    : AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isCredit ? Icons.add : Icons.remove,
                color: isCredit ? AppColors.success : AppColors.error,
                size: isMobile ? 18 : (isTablet ? 20 : 24),
              ),
            ),
            SizedBox(width: isMobile ? 10.0 : (isTablet ? 12.0 : 14.0)),
            
            // Transaction details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.getString(transaction['description'], languageService.currentLanguage),
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 14.0 : (isTablet ? 16.0 : 18.0),
                      fontWeight: FontWeight.w600,
                      color: AppColors.greyDark,
                    ),
                  ),
                  SizedBox(height: isMobile ? 2.0 : (isTablet ? 3.0 : 4.0)),
                  Text(
                    transaction['date'],
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 11.0 : (isTablet ? 12.0 : 13.0),
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transaction['amount'],
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14.0 : (isTablet ? 16.0 : 18.0),
                    fontWeight: FontWeight.bold,
                    color: isCredit ? AppColors.success : AppColors.error,
                  ),
                ),
                SizedBox(height: isMobile ? 2.0 : (isTablet ? 3.0 : 4.0)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 6.0 : (isTablet ? 8.0 : 10.0), 
                    vertical: isMobile ? 3.0 : (isTablet ? 4.0 : 6.0)
                  ),
                  decoration: BoxDecoration(
                    color: isCredit 
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AppStrings.getString(transaction['type'], languageService.currentLanguage),
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 10.0 : (isTablet ? 11.0 : 12.0),
                      fontWeight: FontWeight.w600,
                      color: isCredit ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


