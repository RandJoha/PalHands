import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/favorites_service.dart';
import '../../../../shared/services/auth_service.dart';

class MobileSavedProvidersWidget extends StatefulWidget {
  const MobileSavedProvidersWidget({super.key});

  @override
  State<MobileSavedProvidersWidget> createState() => _MobileSavedProvidersWidgetState();
}

class _MobileSavedProvidersWidgetState extends State<MobileSavedProvidersWidget> {
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.getString('savedProviders', languageService.currentLanguage),
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                onPressed: refreshProviders,
                icon: const Icon(
                  Icons.refresh,
                  color: AppColors.primary,
                  size: 24,
                ),
                tooltip: 'Refresh providers',
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Providers list
          _buildProvidersList(languageService),
        ],
      ),
    );
  }

  Widget _buildProvidersList(LanguageService languageService) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (_favoriteProviders.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(
                Icons.favorite_border,
                size: 64,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: 16),
              Text(
                'No favorite providers yet',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Add providers to your favorites by tapping the heart icon on their cards',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
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
              const SizedBox(height: 16),
            ],
          );
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error building provider item: $e');
            print('Provider data: $provider');
          }
          return Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.error, width: 1),
            ),
            child: Text(
              'Error loading provider data',
              style: GoogleFonts.cairo(
                color: AppColors.error,
                fontSize: 14,
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
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
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
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(35),
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.primary,
              size: 35,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  serviceName,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: AppColors.ratingFilled,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      rating > 0 ? rating.toStringAsFixed(1) : 'No rating',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (ratingCount > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '($ratingCount)',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isAvailable ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isAvailable ? AppStrings.getString('available', languageService.currentLanguage) : AppStrings.getString('unavailable', languageService.currentLanguage),
                        style: GoogleFonts.cairo(
                          fontSize: 14,
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
                    fontSize: 22,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: providerId.isNotEmpty ? () => _removeFromFavorites(providerId) : null,
                    icon: const Icon(
                      Icons.favorite,
                      color: AppColors.error,
                      size: 24,
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text(
                      AppStrings.getString('bookAgain', languageService.currentLanguage),
                      style: GoogleFonts.cairo(
                        fontSize: 14,
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
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error, width: 1),
        ),
        child: Text(
          'Error loading provider data: ${e.toString()}',
          style: GoogleFonts.cairo(
            color: AppColors.error,
            fontSize: 14,
          ),
        ),
      );
    }
  }
} 