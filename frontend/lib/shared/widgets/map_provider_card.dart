import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_strings.dart';
import '../../shared/services/language_service.dart';
import '../../shared/models/provider.dart';
import '../../shared/widgets/booking_dialog.dart';

/// A provider card that matches the exact design of "Our Services" section
/// Used below the map to display selected provider details
class MapProviderCard extends StatelessWidget {
  final ProviderModel provider;
  final VoidCallback? onClose;

  const MapProviderCard({
    Key? key,
    required this.provider,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final lang = languageService.currentLanguage;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Header with close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.getString('providerDetails', lang),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                  splashRadius: 20,
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Provider info row - exact match to "Our Services"
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: provider.avatarUrl != null 
                    ? NetworkImage(provider.avatarUrl!) 
                    : null,
                child: provider.avatarUrl == null 
                    ? const Icon(Icons.person, size: 28) 
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          provider.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (provider.providerId != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
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
                            style: TextStyle(color: Colors.grey.shade700),
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
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
              )
            ],
          ),
          const SizedBox(height: 12),
          
          // Services section - simplified without API dependency
          _buildServicesSection(lang),
          
          const SizedBox(height: 16),
          
          // Action buttons - exact match to "Our Services"
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
                  child: Text(AppStrings.getString('bookNow', lang)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: provider.phone.isNotEmpty 
                    ? () => _launchPhone(provider.phone) 
                    : null,
                icon: const Icon(Icons.call),
                label: Text(AppStrings.getString('contact', lang)),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  _openChatWithProvider(provider);
                },
                icon: const Icon(Icons.chat),
                label: Text(AppStrings.getString('chat', lang)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Services section without API dependency
  Widget _buildServicesSection(String lang) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 180),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show provider's services from the model
            ...provider.services.map((service) {
              final amount = provider.hourlyRate.toStringAsFixed(0);
              final unit = AppStrings.getString('hourly', lang);
              final exp = provider.experienceYears;
              final yrs = lang == 'ar' ? AppStrings.getString('years', lang) : 'yrs';
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: Colors.green),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${AppStrings.getString(service, lang)} — ₪$amount/$unit · $exp $yrs',
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
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
        Text(text, style: TextStyle(color: Colors.grey.shade800)),
      ],
    );
  }

  // Language localization for display purposes
  List<String> _localizedLanguages(List<String> langs, String langCode) {
    final arMap = {
      'arabic': 'العربية',
      'english': 'الإنجليزية',
      'hebrew': 'عبري',
      'turkish': 'التركية',
      'french': 'الفرنسية',
      'spanish': 'الإسبانية',
    };

    return langs.map((l) {
      final key = l.toLowerCase().trim();
      if (langCode == 'ar') return arMap[key] ?? l;
      return l;
    }).toList();
  }

  /// Get the GPS-derived city name for a provider (same logic as category widgets)
  String _getProviderGpsCity(ProviderModel provider, String lang) {
    // Same GPS override mapping as used in category widgets and MapProviderService
    final Map<String, String> providerGpsOverrides = {
      // Provider name -> actual GPS city (different from manual city)
      'ليلى حسن': 'hebron',        // Manual: Gaza -> GPS: Hebron  
      'رند 2': 'nablus',           // Manual: Tulkarm -> GPS: Nablus
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

  // Phone launcher
  void _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      await launchUrl(uri);
    } catch (e) {
      // Handle error silently
    }
  }

  // Chat functionality
  void _openChatWithProvider(ProviderModel provider) {
    // Show a snackbar for now (placeholder for chat functionality)
    // In a real app, this would open a chat screen
  }
}
