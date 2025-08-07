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
        return _buildEarningsWidget(languageService);
      },
    );
  }

  Widget _buildEarningsWidget(LanguageService languageService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            AppStrings.getString('earnings', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.greyDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.getString('manageEarningsRevenue', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 32),
          
          // Earnings Overview
          _buildEarningsOverview(languageService),
          
          const SizedBox(height: 32),
          
          // Earnings Chart
          _buildEarningsChart(languageService),
          
          const SizedBox(height: 32),
          
          // Recent Transactions
          _buildRecentTransactions(languageService),
        ],
      ),
    );
  }

  Widget _buildEarningsOverview(LanguageService languageService) {
    final earnings = [
      {
        'title': 'totalEarnings',
        'amount': '\$2,450',
        'change': '+12.5%',
        'isPositive': true,
        'icon': Icons.attach_money,
      },
      {
        'title': 'monthlyEarnings',
        'amount': '\$850',
        'change': '+8.2%',
        'isPositive': true,
        'icon': Icons.calendar_month,
      },
      {
        'title': 'weeklyEarnings',
        'amount': '\$320',
        'change': '+15.3%',
        'isPositive': true,
        'icon': Icons.date_range,
      },
      {
        'title': 'dailyEarnings',
        'amount': '\$45',
        'change': '-2.1%',
        'isPositive': false,
        'icon': Icons.today,
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
      itemCount: earnings.length,
      itemBuilder: (context, index) {
        return _buildEarningCard(earnings[index], languageService);
      },
    );
  }

  Widget _buildEarningCard(Map<String, dynamic> earning, LanguageService languageService) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    earning['icon'],
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: earning['isPositive'] 
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    earning['change'],
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: earning['isPositive'] ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              earning['amount'],
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.greyDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.getString(earning['title'], languageService.currentLanguage),
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsChart(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.getString('earningsOverview', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.greyDark,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 48,
                    color: AppColors.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.getString('chartComingSoon', languageService.currentLanguage),
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(LanguageService languageService) {
    final transactions = [
      {
        'id': '#TR001',
        'clientName': 'أحمد محمد',
        'service': 'homeCleaning',
        'amount': '\$50',
        'commission': '\$5',
        'status': 'completed',
        'date': '2024-12-15',
      },
      {
        'id': '#TR002',
        'clientName': 'Sarah Johnson',
        'service': 'homeBabysitting',
        'amount': '\$40',
        'commission': '\$4',
        'status': 'completed',
        'date': '2024-12-14',
      },
      {
        'id': '#TR003',
        'clientName': 'فاطمة علي',
        'service': 'homeElderlyCare',
        'amount': '\$60',
        'commission': '\$6',
        'status': 'pending',
        'date': '2024-12-13',
      },
      {
        'id': '#TR004',
        'clientName': 'Michael Brown',
        'service': 'homeCookingServices',
        'amount': '\$70',
        'commission': '\$7',
        'status': 'completed',
        'date': '2024-12-12',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.getString('recentTransactions', languageService.currentLanguage),
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
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            return _buildTransactionCard(transactions[index], languageService);
          },
        ),
      ],
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction, LanguageService languageService) {
    final statusColor = transaction['status'] == 'completed' ? AppColors.success : AppColors.warning;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        child: Row(
          children: [
            // Transaction icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.payment,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // Transaction details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        transaction['id'],
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
                          AppStrings.getString(transaction['status'], languageService.currentLanguage),
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
                    transaction['clientName'],
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.greyDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.getString(transaction['service'], languageService.currentLanguage),
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: AppColors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${AppStrings.getString('commission', languageService.currentLanguage)}: ${transaction['commission']}',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.grey,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        transaction['date'],
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
            
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transaction['amount'],
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.getString('completedOn', languageService.currentLanguage),
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: AppColors.grey,
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
