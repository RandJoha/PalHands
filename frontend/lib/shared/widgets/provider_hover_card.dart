import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../shared/services/language_service.dart';
import '../../shared/models/provider.dart';
// import '../../shared/models/service.dart' as svc;
import '../../shared/services/services_service.dart';
import '../../shared/widgets/booking_dialog.dart';

/// A hover card that displays real provider information when hovering over map markers
/// Reuses the exact same design as the "Our Services" provider cards
class ProviderHoverCard extends StatelessWidget {
  final ProviderModel provider;
  final VoidCallback? onClose;
  final bool isPinned;
  final bool isMobile;

  const ProviderHoverCard({
    Key? key,
    required this.provider,
    this.onClose,
    this.isPinned = false,
    this.isMobile = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final lang = languageService.currentLanguage;
    
    return Container(
      width: isMobile ? 300 : 350,
      constraints: BoxConstraints(
        maxHeight: isMobile ? 400 : 450,
      ),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with provider info (exact same as "Our Services" card)
          Row(
            children: [
              CircleAvatar(
                radius: isMobile ? 24 : 28,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: provider.avatarUrl != null ? NetworkImage(provider.avatarUrl!) : null,
                child: provider.avatarUrl == null ? const Icon(Icons.person, size: 28) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            provider.name,
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (provider.providerId != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              '#${provider.providerId}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Languages
                    Row(
                      children: [
                        const Icon(Icons.language, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _localizedLanguages(provider.languages, lang).join(', '),
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Location - use GPS city instead of manual city
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          _getProviderGpsCity(provider, lang),
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Rating
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RatingBarIndicator(
                    rating: provider.ratingAverage,
                    itemSize: 16,
                    itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
                  ),
                  Text(
                    '${provider.ratingAverage.toStringAsFixed(1)} (${provider.ratingCount})',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Services section - simplified without service API
          _buildServicesSection(lang),
          
          const SizedBox(height: 12),
          
          // Action buttons (exact same as "Our Services" card)
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => BookingDialog(
                        provider: provider,
                        selectedService: null,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12),
                  ),
                  child: Text(AppStrings.getString('bookNow', lang)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: provider.phone.isNotEmpty 
                    ? () => _launchPhone(provider.phone)
                    : null,
                icon: const Icon(Icons.call, size: 16),
                label: Text(AppStrings.getString('contact', lang)),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 12,
                    vertical: isMobile ? 10 : 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _openChatWithProvider(context, provider),
                icon: const Icon(Icons.chat, size: 16),
                label: Text(AppStrings.getString('chat', lang)),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 12,
                    vertical: isMobile ? 10 : 12,
                  ),
                ),
              ),
            ],
          ),
          
          // Close button for pinned cards
          if (isPinned) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: onClose,
                child: Text(
                  AppStrings.getString('close', lang),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Services section without API dependency
  Widget _buildServicesSection(String lang) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show provider's services from the model
          ...provider.services.take(3).map((service) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${AppStrings.getString(service, lang)} — ₪${provider.hourlyRate.toStringAsFixed(0)}/${AppStrings.getString('hourly', lang)} · ${provider.experienceYears} ${lang == 'ar' ? AppStrings.getString('years', lang) : 'yrs'}',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (provider.services.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+${provider.services.length - 3} ${AppStrings.getString("more", lang)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          // Fallback if no services
          if (provider.services.isEmpty)
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _kv(Icons.work_history, '${provider.experienceYears} ${AppStrings.getString('years', lang)}'),
                _kv(Icons.attach_money, '${provider.hourlyRate.toStringAsFixed(0)} ${AppStrings.getString('hourly', lang)}'),
              ],
            ),
        ],
      ),
    );
  }

  // Helper methods (exact same as "Our Services" card)
  Widget _kv(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade700),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: Colors.grey.shade800, fontSize: 12)),
      ],
    );
  }

  // Language localization for display purposes
  List<String> _localizedLanguages(List<String> langs, String langCode) {
    return langs.map((lang) {
      switch (lang.toLowerCase()) {
        case 'arabic':
          return langCode == 'ar' ? 'العربية' : 'Arabic';
        case 'english':
          return langCode == 'ar' ? 'الإنجليزية' : 'English';
        case 'hebrew':
          return langCode == 'ar' ? 'العبرية' : 'Hebrew';
        default:
          return lang;
      }
    }).toList();
  }

  void _launchPhone(String phone) {
    // Launch phone dialer
    try {
      final uri = Uri(scheme: 'tel', path: phone);
      // launchUrl(uri); // Uncomment when url_launcher is properly imported
    } catch (e) {
      // Handle error silently
    }
  }

  void _openChatWithProvider(BuildContext context, ProviderModel provider) {
    // Show a simple message for now
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chat with ${provider.name} - Feature coming soon!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Get the GPS-derived city name for a provider (same logic as category widgets)
  String _getProviderGpsCity(ProviderModel provider, String lang) {
    // Same GPS override mapping as used in category widgets and MapProviderService
    final Map<String, String> providerGpsOverrides = {
      // Provider name -> actual GPS city (different from manual city)
      'ليلى حسن': 'hebron',        // Manual: Gaza -> GPS: Hebron  
      'رند 2': 'nablus',           // Manual: Tulkarm -> GPS: Nablus
      'rand 2': 'nablus',          // Manual: Tulkarm -> GPS: Nablus (English version)
      'أحمد علي': 'jerusalem',     // Manual: Ramallah -> GPS: Jerusalem
      'فاطمة محمد': 'bethlehem',   // Manual: Hebron -> GPS: Bethlehem
      'سارة يوسف': 'jenin',        // Manual: Nablus -> GPS: Jenin
      'محمد أحمد': 'ramallah',     // Manual: Gaza -> GPS: Ramallah
      'علياء سليم': 'tulkarm',     // Manual: Jenin -> GPS: Tulkarm
    };

    // Check if this provider has a GPS override (different GPS vs manual location)
    String gpsCity = providerGpsOverrides[provider.name] ?? provider.city.toLowerCase();
    
    // Ensure the GPS city is valid, fallback to ramallah if not found
    final validCities = ['ramallah', 'nablus', 'jerusalem', 'hebron', 'bethlehem', 'gaza', 'jenin', 'tulkarm', 'birzeit', 'qalqilya', 'salfit'];
    if (!validCities.contains(gpsCity)) {
      gpsCity = 'ramallah';
    }
    
    // Return localized city name
    return AppStrings.getString(gpsCity, lang);
  }
}
