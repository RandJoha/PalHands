import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/favorites_service.dart';
import '../../../../shared/services/auth_service.dart';

class SavedProvidersWidget extends StatefulWidget {
  const SavedProvidersWidget({super.key});

  @override
  State<SavedProvidersWidget> createState() => _SavedProvidersWidgetState();
}

class _SavedProvidersWidgetState extends State<SavedProvidersWidget> {
  List<Map<String, dynamic>> _favoriteProviders = [];
  bool _loading = true;
  final FavoritesService _favoritesService = FavoritesService();

  @override
  void initState() {
    super.initState();
    _loadFavoriteProviders();
  }

  // Method to refresh the providers list
  void refreshProviders() {
    _loadFavoriteProviders();
  }

  Future<void> _loadFavoriteProviders() async {
    try {
      setState(() {
        _loading = true;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final providers = await _favoritesService.getFavoriteProviders(authService: authService);
      
      // Debug logging to identify null values
      if (kDebugMode) {
        print('🔍 Loaded ${providers.length} favorite providers');
        print('🔍 Raw providers data: $providers');
        for (int i = 0; i < providers.length; i++) {
          final provider = providers[i];
          final providerData = provider['providerData'] as Map<String, dynamic>? ?? provider;
          print('Provider $i: ${providerData['firstName']} ${providerData['lastName']} (ID: ${provider['_id'] ?? provider['id'] ?? provider['providerId']})');
          print('  - Provider data structure: ${provider.keys.toList()}');
          print('  - Provider data content: ${providerData.keys.toList()}');
          print('  - Full provider data: $provider');
        }
      }
      
      setState(() {
        _favoriteProviders = providers;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load favorite providers: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _removeFromFavorites(String providerId) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await _favoritesService.removeFromFavorites(providerId, authService: authService);
      
      // Remove from local list
      setState(() {
        _favoriteProviders.removeWhere((provider) => provider['_id'] == providerId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Provider removed from favorites'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove provider: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return _buildProviders(context, languageService);
      },
    );
  }

  Widget _buildProviders(BuildContext context, LanguageService languageService) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.getString('savedProviders', languageService.currentLanguage),
                style: GoogleFonts.cairo(
                  fontSize: 24.sp,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                onPressed: refreshProviders,
                icon: Icon(
                  Icons.refresh,
                  color: AppColors.primary,
                  size: 24.sp,
                ),
                tooltip: 'Refresh providers',
              ),
            ],
          ),
          SizedBox(height: 24.h),
          
          // Providers list
          _buildProvidersList(languageService),
        ],
      ),
    );
  }

  Widget _buildProvidersList(LanguageService languageService) {
    if (_loading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(40.w),
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (_favoriteProviders.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(40.w),
          child: Column(
            children: [
              Icon(
                Icons.favorite_border,
                size: 64.sp,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: 16.h),
              Text(
                'No favorite providers yet',
                style: GoogleFonts.cairo(
                  fontSize: 18.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Add providers to your favorites by tapping the heart icon on their cards',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _favoriteProviders.map((provider) {
        try {
          return Column(
            children: [
              _buildProviderItem(
                provider: provider,
                languageService: languageService,
              ),
              SizedBox(height: 16.h),
            ],
          );
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error building provider item: $e');
            print('Provider data: $provider');
          }
          return Container(
            padding: EdgeInsets.all(16.w),
            margin: EdgeInsets.only(bottom: 16.h),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.error, width: 1),
            ),
            child: Text(
              'Error loading provider data',
              style: GoogleFonts.cairo(
                color: AppColors.error,
                fontSize: 14.sp,
              ),
            ),
          );
        }
      }).toList(),
    );
  }

  Widget _buildProviderItem({
    required Map<String, dynamic> provider,
    required LanguageService languageService,
  }) {
    try {
      // Handle the new data structure from savedProviders collection
      final providerData = provider['providerData'] as Map<String, dynamic>? ?? provider;
      
      // Safely extract all fields with comprehensive null checking
      final firstName = (providerData['firstName'] ?? '').toString();
      final lastName = (providerData['lastName'] ?? '').toString();
      final name = '$firstName $lastName'.trim();
      
      // Safely extract rating data
      final ratingData = providerData['rating'] as Map<String, dynamic>? ?? {};
      final rating = (ratingData['average'] ?? 0.0).toDouble();
      final ratingCount = (ratingData['count'] ?? 0).toInt();
      
      // Safely extract services data
      final services = (providerData['services'] as List<dynamic>?) ?? [];
      final primaryService = services.isNotEmpty ? services.first as Map<String, dynamic>? : null;
      final serviceName = (primaryService?['title'] ?? 'Service Provider').toString();
      final hourlyRate = (primaryService?['hourlyRate'] ?? 0).toInt();
      
      final isAvailable = providerData['isAvailable'] ?? true;
      final providerId = (provider['_id'] ?? provider['id'] ?? provider['providerId'] ?? '').toString();

    return Container(
      padding: EdgeInsets.all(28.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40.r),
            ),
            child: Icon(
              Icons.person,
              color: AppColors.primary,
              size: 40.sp,
            ),
          ),
          SizedBox(width: 20.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.cairo(
                    fontSize: 20.sp,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  serviceName,
                  style: GoogleFonts.cairo(
                    fontSize: 16.sp,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: AppColors.ratingFilled,
                      size: 18.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      rating > 0 ? rating.toStringAsFixed(1) : 'No rating',
                      style: GoogleFonts.cairo(
                        fontSize: 16.sp,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (ratingCount > 0) ...[
                      SizedBox(width: 6.w),
                      Text(
                        '($ratingCount)',
                        style: GoogleFonts.cairo(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                    SizedBox(width: 16.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: isAvailable ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        isAvailable ? AppStrings.getString('available', languageService.currentLanguage) : AppStrings.getString('unavailable', languageService.currentLanguage),
                        style: GoogleFonts.cairo(
                          fontSize: 14.sp,
                          color: isAvailable ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (hourlyRate > 0) ...[
                Text(
                  '₪$hourlyRate/hr',
                  style: GoogleFonts.cairo(
                    fontSize: 22.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 12.h),
              ],
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: providerId.isNotEmpty ? () => _removeFromFavorites(providerId) : null,
                    icon: Icon(
                      Icons.favorite,
                      color: AppColors.error,
                      size: 24.sp,
                    ),
                    tooltip: 'Remove from favorites',
                  ),
                  ElevatedButton(
                    onPressed: isAvailable ? () {
                      // Handle book again - navigate to booking flow
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    ),
                    child: Text(
                      AppStrings.getString('bookAgain', languageService.currentLanguage),
                      style: GoogleFonts.cairo(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in _buildProviderItem: $e');
        print('Provider data: $provider');
      }
      return Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.error, width: 1),
        ),
        child: Text(
          'Error loading provider data: ${e.toString()}',
          style: GoogleFonts.cairo(
            color: AppColors.error,
            fontSize: 14.sp,
          ),
        ),
      );
    }
  }
} 