import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_strings.dart';
import '../../shared/services/language_service.dart';
import '../../shared/models/provider.dart';
import '../../shared/widgets/booking_dialog.dart';
import '../../shared/services/provider_services_service.dart';

/// A provider card that matches the exact design of "Our Services" section
/// Used below the map to display selected provider details
class MapProviderCard extends StatefulWidget {
  final ProviderModel provider;
  final VoidCallback? onClose;

  const MapProviderCard({
    Key? key,
    required this.provider,
    this.onClose,
  }) : super(key: key);

  @override
  State<MapProviderCard> createState() => _MapProviderCardState();
}

class _MapProviderCardState extends State<MapProviderCard> {
  List<Map<String, dynamic>> _providerServices = [];
  bool _isLoadingServices = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadProviderServices();
    
    // Add a periodic refresh to catch service updates
    _startPeriodicRefresh();
    
    // Also trigger an immediate refresh after a short delay to catch any recent updates
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        print('🔄 MapProviderCard: Initial delayed refresh...');
        _loadProviderServices(forceRefresh: true);
      }
    });
  }

  void _startPeriodicRefresh() {
    // Refresh every 5 seconds to catch service updates more quickly
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) {
        print('🔄 MapProviderCard: Auto-refreshing services...');
        _loadProviderServices(forceRefresh: true);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(MapProviderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh services if provider changed
    if (oldWidget.provider.providerId != widget.provider.providerId) {
      _loadProviderServices();
    }
  }

  Future<void> _loadProviderServices({bool forceRefresh = false}) async {
    if (widget.provider.providerId == null) {
      setState(() {
        _isLoadingServices = false;
      });
      return;
    }

    setState(() {
      _isLoadingServices = true;
    });

    try {
      final api = ProviderServicesApi();
      final providerId = widget.provider.providerId!.toString();
      print('🔍 MapProviderCard: Loading services for provider $providerId (forceRefresh: $forceRefresh)');
      final services = await api.listPublic(providerId, forceRefresh: forceRefresh);
      
      // Debug logging
      print('🔍 MapProviderCard: Received ${services.length} services');
      for (int i = 0; i < services.length; i++) {
        final service = services[i];
        final title = service['title'] ?? 'Unknown';
        final pricing = service['pricing'] as Map<String, dynamic>? ?? {};
        final amount = (pricing['amount'] as num?)?.toDouble() ?? 0.0;
        final experienceYears = (service['experienceYears'] as num?)?.toInt() ?? 0;
        print('🔍 MapProviderCard Service $i: $title - ₪$amount/hour - $experienceYears years');
      }
      
      // Check if we have the expected number of services
      if (services.length < 7) {
        print('⚠️ MapProviderCard: Expected 7 services but got ${services.length}. This might be a caching issue.');
      }
      
      // Log the services that are being displayed
      print('🔍 MapProviderCard: Services to be displayed:');
      for (int i = 0; i < services.length; i++) {
        final service = services[i];
        final title = service['title'] ?? 'Unknown';
        final pricing = service['pricing'] as Map<String, dynamic>? ?? {};
        final amount = (pricing['amount'] as num?)?.toDouble() ?? 0.0;
        final experienceYears = (service['experienceYears'] as num?)?.toInt() ?? 0;
        print('🔍 MapProviderCard Display Service $i: $title - ₪$amount/hour - $experienceYears years');
      }
      
      if (mounted) {
        setState(() {
          _providerServices = services;
          _isLoadingServices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _providerServices = [];
          _isLoadingServices = false;
        });
      }
    }
  }

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
              if (widget.onClose != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
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
                backgroundImage: widget.provider.avatarUrl != null 
                    ? NetworkImage(widget.provider.avatarUrl!) 
                    : null,
                child: widget.provider.avatarUrl == null 
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
                          widget.provider.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (widget.provider.providerId != null) ...[
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
                              '#${widget.provider.providerId}',
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
                            _localizedLanguages(widget.provider.languages, lang).join(', '),
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
                          _getProviderGpsCity(widget.provider, lang),
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
                    rating: widget.provider.ratingAverage,
                    itemSize: 16,
                    itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
                  ),
                  Text(
                    '${widget.provider.ratingAverage.toStringAsFixed(1)} (${widget.provider.ratingCount})',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          
          // Services section - fetch from database
          Row(
            children: [
              Text(
                AppStrings.getString('services', lang),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () {
                  print('🔄 MapProviderCard: Manual refresh triggered');
                  _loadProviderServices(forceRefresh: true);
                },
                tooltip: AppStrings.getString('refresh', lang),
              ),
            ],
          ),
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
                        provider: widget.provider,
                        selectedService: null,
                      ),
                    );
                  },
                  child: Text(AppStrings.getString('bookNow', lang)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: widget.provider.phone.isNotEmpty 
                    ? () => _launchPhone(widget.provider.phone) 
                    : null,
                icon: const Icon(Icons.call),
                label: Text(AppStrings.getString('contact', lang)),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  _openChatWithProvider(widget.provider);
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

  // Services section with database fetch
  Widget _buildServicesSection(String lang) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 180),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoadingServices)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_providerServices.isEmpty)
              // Fallback if no services from database
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _kv(Icons.work_history, '${widget.provider.experienceYears} ${AppStrings.getString('years', lang)}'),
                  _kv(Icons.attach_money, '${widget.provider.hourlyRate.toStringAsFixed(0)} ${AppStrings.getString('hourly', lang)}'),
                ],
              )
            else
              // Show provider's services from database
              ..._providerServices.map((serviceData) {
                // Handle new API structure from backend
                final serviceTitle = serviceData['title'] ?? '';
                final pricing = serviceData['pricing'] as Map<String, dynamic>? ?? {};
                final hourlyRate = (pricing['amount'] as num?)?.toDouble() ?? 0.0;
                final experienceYears = (serviceData['experienceYears'] as num?)?.toInt() ?? 0;
                final unit = AppStrings.getString('hourly', lang);
                final yrs = lang == 'ar' ? AppStrings.getString('years', lang) : 'yrs';
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '$serviceTitle — ₪${hourlyRate.toStringAsFixed(0)}/$unit · $experienceYears $yrs',
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
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
