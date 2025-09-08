import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/location_service.dart';
import '../../../../shared/services/map_service.dart';

class ProfileSettingsRichWidget extends StatefulWidget {
  const ProfileSettingsRichWidget({super.key});

  @override
  State<ProfileSettingsRichWidget> createState() => _ProfileSettingsRichWidgetState();
}

class _ProfileSettingsRichWidgetState extends State<ProfileSettingsRichWidget> {
  bool _emailNotifs = true;
  bool _pushNotifs = true;
  bool _useGps = false;
  final TextEditingController _addressCtrl = TextEditingController();
  final LocationService _locationService = LocationService();
  final MapService _mapService = MapService();

  // City-street mapping for hierarchical location selection
  final Map<String, List<String>> _cityStreets = {
    'jerusalem': [
      'salahuddin_street', 'damascus_gate_road', 'jaffa_road', 'king_george_street', 
      'ben_yehuda_street', 'agron_street', 'mamilla_street', 'yafo_street',
      'sultan_suleiman_street', 'nablus_road', 'ramallah_road', 'bethlehem_road'
    ],
    'ramallah': [
      'al_manara_square', 'main_street', 'al_rasheed_street', 'al_quds_street',
      'al_nahda_street', 'al_amari_street', 'al_balou_street', 'al_tireh_street',
      'al_biereh_street', 'al_jalazoun_street', 'al_amari_street', 'al_balou_street'
    ],
    'nablus': [
      'rafidia_street', 'main_street', 'al_quds_street', 'al_rasheed_street',
      'al_amman_street', 'al_balata_street', 'al_asira_street', 'al_balata_street_2',
      'al_amman_street_2', 'al_balata_street_3', 'al_asira_street_2', 'al_quds_street_2'
    ],
    'hebron': [
      'al_shuhada_street', 'al_quds_street', 'al_rasheed_street', 'al_amman_street',
      'al_balata_street', 'al_asira_street', 'al_quds_street_2', 'al_rasheed_street_2',
      'al_amman_street_2', 'al_balata_street_2', 'al_asira_street_2', 'al_quds_street_3'
    ],
    'bethlehem': [
      'manger_street', 'star_street', 'milk_grotto_street', 'nativity_street',
      'al_quds_street', 'al_rasheed_street', 'al_amman_street', 'al_balata_street',
      'al_asira_street', 'al_quds_street_2', 'al_rasheed_street_2', 'al_amman_street_2'
    ],
    'jericho': [
      'main_street', 'al_quds_street', 'al_rasheed_street', 'al_amman_street',
      'al_balata_street', 'al_asira_street', 'al_quds_street_2', 'al_rasheed_street_2',
      'al_amman_street_2', 'al_balata_street_2', 'al_asira_street_2', 'al_quds_street_3'
    ],
    'tulkarm': [
      'main_street', 'al_quds_street', 'al_rasheed_street', 'al_amman_street',
      'al_balata_street', 'al_asira_street', 'al_quds_street_2', 'al_rasheed_street_2',
      'al_amman_street_2', 'al_balata_street_2', 'al_asira_street_2', 'al_quds_street_3'
    ],
    'qalqilya': [
      'main_street', 'al_quds_street', 'al_rasheed_street', 'al_amman_street',
      'al_balata_street', 'al_asira_street', 'al_quds_street_2', 'al_rasheed_street_2',
      'al_amman_street_2', 'al_balata_street_2', 'al_asira_street_2', 'al_quds_street_3'
    ],
    'jenin': [
      'main_street', 'al_quds_street', 'al_rasheed_street', 'al_amman_street',
      'al_balata_street', 'al_asira_street', 'al_quds_street_2', 'al_rasheed_street_2',
      'al_amman_street_2', 'al_balata_street_2', 'al_asira_street_2', 'al_quds_street_3'
    ],
    'salfit': [
      'main_street', 'al_quds_street', 'al_rasheed_street', 'al_amman_street',
      'al_balata_street', 'al_asira_street', 'al_quds_street_2', 'al_rasheed_street_2',
      'al_amman_street_2', 'al_balata_street_2', 'al_asira_street_2', 'al_quds_street_3'
    ],
    'tubas': [
      'main_street', 'al_quds_street', 'al_rasheed_street', 'al_amman_street',
      'al_balata_street', 'al_asira_street', 'al_quds_street_2', 'al_rasheed_street_2',
      'al_amman_street_2', 'al_balata_street_2', 'al_asira_street_2', 'al_quds_street_3'
    ],
    'gaza': [
      'omar_mukhtar_street', 'al_rasheed_street', 'al_quds_street', 'al_amman_street',
      'al_balata_street', 'al_asira_street', 'al_quds_street_2', 'al_rasheed_street_2',
      'al_amman_street_2', 'al_balata_street_2', 'al_asira_street_2', 'al_quds_street_3'
    ],
    'rafah': [
      'main_street', 'al_quds_street', 'al_rasheed_street', 'al_amman_street',
      'al_balata_street', 'al_asira_street', 'al_quds_street_2', 'al_rasheed_street_2',
      'al_amman_street_2', 'al_balata_street_2', 'al_asira_street_2', 'al_quds_street_3'
    ],
    'khan yunis': [
      'main_street', 'al_quds_street', 'al_rasheed_street', 'al_amman_street',
      'al_balata_street', 'al_asira_street', 'al_quds_street_2', 'al_rasheed_street_2',
      'al_amman_street_2', 'al_balata_street_2', 'al_asira_street_2', 'al_quds_street_3'
    ],
    'deir al-balah': [
      'main_street', 'al_quds_street', 'al_rasheed_street', 'al_amman_street',
      'al_balata_street', 'al_asira_street', 'al_quds_street_2', 'al_rasheed_street_2',
      'al_amman_street_2', 'al_balata_street_2', 'al_asira_street_2', 'al_quds_street_3'
    ],
    'north gaza': [
      'main_street', 'al_quds_street', 'al_rasheed_street', 'al_amman_street',
      'al_balata_street', 'al_asira_street', 'al_quds_street_2', 'al_rasheed_street_2',
      'al_amman_street_2', 'al_balata_street_2', 'al_asira_street_2', 'al_quds_street_3'
    ],
    'tulkarm': [
      'main_street', 'al_quds_street', 'al_rasheed_street', 'al_nour_street',
      'al_salam_street', 'al_watan_street', 'al_hurria_street', 'al_majd_street'
    ],
    'birzeit': [
      'main_street', 'university_street', 'al_quds_street', 'al_nour_street',
      'al_salam_street', 'al_watan_street', 'al_hurria_street', 'al_majd_street'
    ]
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGpsState();
    });
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  /// Initialize GPS state based on user role and existing preference
  void _initializeGpsState() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;
    final userRole = user?['role'] ?? 'client';
    final isProvider = userRole == 'provider';
    
    // For providers, GPS is mandatory and should be auto-enabled
    if (isProvider) {
      setState(() {
        _useGps = true;
      });
      _loadProviderGpsAddress();
    } else {
      // For admins and clients, GPS is optional
      final existingGpsPreference = user?['useGpsLocation'] ?? false;
      setState(() {
        _useGps = existingGpsPreference;
      });
      
      if (_useGps) {
        _simulateGpsAndFillFullAddress();
      }
    }
  }

  /// Load and set GPS address for existing providers
  Future<void> _loadProviderGpsAddress() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;
    
    if (user == null) return;
    
    // Try to get existing address from user profile
    String? existingAddress;
    
    // Check if there's already a GPS-compatible address
    if (user['address'] is String && user['address'].isNotEmpty) {
      existingAddress = user['address'];
    } else if (user['address'] is Map) {
      final addressMap = user['address'] as Map;
      existingAddress = addressMap['line1'] ?? '';
    }
    
    // If no existing address, generate one based on provider's location data
    if (existingAddress == null || existingAddress.isEmpty) {
      // Generate a GPS address based on provider's service area or default location
      await _generateProviderGpsAddress();
    } else {
      // Use existing address and ensure it's properly formatted
      setState(() {
        _addressCtrl.text = existingAddress!;
      });
    }
    
    // Ensure GPS is enabled for this provider
    try {
      await auth.updateProfile(useGpsLocation: true);
    } catch (e) {
      // Handle silently
    }
  }

  /// Generate GPS address for existing providers
  Future<void> _generateProviderGpsAddress() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;
    
    if (user == null) return;
    
    // Use provider's name or ID to generate consistent address
    final providerId = user['_id'] ?? user['id'] ?? '';
    final providerName = user['firstName'] ?? 'Provider';
    
    // Generate deterministic address based on provider data
    // Use the same city distribution as the map service for consistency
    final cities = [
      'ramallah', 'gaza', 'jerusalem', 'nablus', 'jerusalem',
      'bethlehem', 'jerusalem', 'hebron', 'jerusalem', 'ramallah',
      'ramallah', 'nablus', 'bethlehem', 'bethlehem', 'gaza',
      'gaza', 'nablus', 'nablus', 'gaza', 'hebron',
      'ramallah', 'hebron', 'tulkarm', 'hebron', 'gaza',
      'bethlehem', 'birzeit', 'hebron', 'hebron', 'jerusalem',
      'jerusalem', 'jerusalem', 'nablus', 'bethlehem', 'ramallah',
      'nablus', 'ramallah'
    ];
    
    // Use a more sophisticated index based on provider ID to match map distribution
    final providerIndex = (providerId.hashCode.abs() % 37); // Match 37 providers
    final selectedCity = cities[providerIndex % cities.length];
    
    final availableStreets = _getStreetOptionsForCity(selectedCity);
    final streetIndex = (providerId.hashCode.abs() ~/ 10) % availableStreets.length;
    final selectedStreet = availableStreets.isNotEmpty ? availableStreets[streetIndex] : 'main_street';
    
    // Generate building number based on provider ID
    final buildingNumber = 100 + (providerId.hashCode.abs() % 400); // 100-499
    
    // Create full address with proper localization
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final localizedCity = AppStrings.getString(selectedCity, languageService.currentLanguage);
    final localizedStreet = AppStrings.getString(selectedStreet, languageService.currentLanguage);
    
    final fullAddress = '$buildingNumber $localizedStreet, $localizedCity, Palestine';
    
    setState(() {
      _addressCtrl.text = fullAddress;
    });
    
    // Save this address to the provider's profile
    try {
      await auth.updateProfile(
        useGpsLocation: true,
        address: {
          'line1': fullAddress,
          'city': localizedCity,
          'street': localizedStreet,
        },
      );
    } catch (e) {
      // Handle silently
    }
  }

  /// Simulate GPS and fill a full, realistic Palestinian address
  Future<void> _simulateGpsAndFillFullAddress() async {
    try {
      // Get available cities and streets
      final cities = ['ramallah', 'nablus', 'jerusalem', 'hebron', 'bethlehem'];
      final selectedCity = cities[DateTime.now().millisecond % cities.length];
      final availableStreets = _getStreetOptionsForCity(selectedCity);
      final selectedStreet = availableStreets.isNotEmpty 
          ? availableStreets[DateTime.now().second % availableStreets.length]
          : 'main_street';
      
      // Generate building number
      final buildingNumber = 50 + (DateTime.now().millisecond % 450); // 50-499
      
      // Create full address with proper localization
      final languageService = Provider.of<LanguageService>(context, listen: false);
      final localizedCity = AppStrings.getString(selectedCity, languageService.currentLanguage);
      final localizedStreet = AppStrings.getString(selectedStreet, languageService.currentLanguage);
      
      final fullAddress = '$buildingNumber $localizedStreet, $localizedCity, Palestine';
      
      setState(() {
        _addressCtrl.text = fullAddress;
      });
    } catch (e) {
      setState(() {
        _addressCtrl.text = '123 Main Street, Ramallah, Palestine';
      });
    }
  }

  /// Get street options for a specific city
  List<String> _getStreetOptionsForCity(String city) {
    return _cityStreets[city.toLowerCase()] ?? ['main_street'];
  }

  /// Refresh GPS state from user profile
  void _refreshGpsStateFromProfile() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;
    final currentGpsState = user?['useGpsLocation'] ?? false;
    
    if (_useGps != currentGpsState) {
      setState(() {
        _useGps = currentGpsState;
      });
      
      if (_useGps) {
        _simulateGpsAndFillFullAddress();
      } else {
        _addressCtrl.clear();
      }
    }
  }

  /// Switch from GPS to a saved address
  void _switchToSavedAddress(VoidCallback? makeDefaultCallback) async {
    try {
      // Disable GPS
      setState(() {
        _useGps = false;
        _addressCtrl.clear();
      });

      // Notify maps immediately
      LocationService.notifyGpsStateChanged(false);

      // Update profile to disable GPS
      final auth = Provider.of<AuthService>(context, listen: false);
      await auth.updateProfile(useGpsLocation: false);

      // Make the selected address default
      if (makeDefaultCallback != null) {
        makeDefaultCallback();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Switched to saved address')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to switch: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= 768;
        final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(isMobile, isTablet),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              _buildProfileForm(isMobile, isTablet),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              _buildAddressesSection(isMobile, isTablet),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              _buildNotificationsSection(isMobile, isTablet),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              _buildSecuritySection(isMobile, isTablet),
            ],
          ),
        );
      },
    );
  }

  String _t(String key) {
    final lang = Provider.of<LanguageService>(context, listen: false).currentLanguage;
    return AppStrings.getString(key, lang);
  }

  // Get streets for selected city
  List<String> _getStreetsForCity(String? city) {
    if (city == null) return [];
    return _cityStreets[city] ?? [];
  }

  Widget _buildProfileHeader(bool isMobile, bool isTablet) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser ?? const {};
    final first = (user['firstName'] ?? '').toString();
    final last = (user['lastName'] ?? '').toString();
    final fullName = [first, last].where((e) => e.isNotEmpty).join(' ').trim();
    final createdAt = (user['createdAt'] ?? user['created_at'] ?? '').toString();
    String joinedText = _t('membersSince');
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.tryParse(createdAt);
        if (dt != null) {
          final monthNames = {
            'en': ['January','February','March','April','May','June','July','August','September','October','November','December'],
            'ar': ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'],
          };
          final lang = Provider.of<LanguageService>(context, listen: false).currentLanguage;
          final month = monthNames[lang]?[dt.month - 1] ?? dt.month.toString();
          joinedText = '${_t('membersSince')} $month ${dt.year}';
        }
      } catch (_) {}
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 16.0 : 20.0),
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 80.0 : 100.0,
            height: isMobile ? 80.0 : 100.0,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(isMobile ? 40.0 : 50.0),
            ),
            child: Icon(Icons.person, color: AppColors.white, size: isMobile ? 40.0 : 50.0),
          ),
          SizedBox(width: isMobile ? 16.0 : 20.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.isNotEmpty ? fullName : _t('fullName'),
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 24.0 : 28.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  joinedText,
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14.0 : 16.0,
                    fontWeight: FontWeight.w400,
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm(bool isMobile, bool isTablet) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser ?? const {};
    final currentFullName = [
      (user['firstName'] ?? '').toString(),
      (user['lastName'] ?? '').toString(),
    ].where((e) => e.isNotEmpty).join(' ').trim();
    final currentEmail = (user['email'] ?? '').toString();
    final currentPhone = (user['phone'] ?? '').toString();
    final currentAge = user['age'];

    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('personalInformation'),
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 18.0 : 20.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isMobile ? 16.0 : 20.0),

          _buildFormField(_t('fullName'), currentFullName, Icons.person, isMobile, onEdit: _onEditName),
          const SizedBox(height: 12.0),
          _buildFormField(_t('email'), currentEmail, Icons.email, isMobile, onEdit: _onEditEmail),
          const SizedBox(height: 12.0),
          _buildFormField(_t('phoneNumber'), currentPhone, Icons.phone, isMobile, onEdit: _onEditPhone),
          const SizedBox(height: 12.0),
          _buildFormField(_t('age'), (currentAge is int && currentAge > 0) ? currentAge.toString() : '-', Icons.cake, isMobile, onEdit: _onEditAge),
        ],
      ),
    );
  }

  Widget _buildFormField(String label, String value, IconData icon, bool isMobile, {VoidCallback? onEdit}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: isMobile ? 20.0 : 24.0),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.cairo(fontSize: isMobile ? 14.0 : 16.0, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
              Text(value, style: GoogleFonts.cairo(fontSize: isMobile ? 16.0 : 18.0, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
        ),
        IconButton(
          onPressed: onEdit,
          icon: Icon(Icons.edit, color: AppColors.primary, size: isMobile ? 20.0 : 24.0),
        ),
      ],
    );
  }

  Widget _buildAddressesSection(bool isMobile, bool isTablet) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;
    final userRole = user?['role'] ?? 'client';
    final isProvider = userRole == 'provider';
    final List<dynamic> savedAddresses = (user?['addresses'] as List<dynamic>?) ?? [];

    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Addresses section header
          Text(
            'Addresses',
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 18.0 : 20.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isMobile ? 16.0 : 20.0),

          // Current Location (GPS) Section
          Container(
            padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
            decoration: BoxDecoration(
              color: _useGps ? AppColors.primary.withOpacity(0.05) : AppColors.background,
              borderRadius: BorderRadius.circular(isMobile ? 8.0 : 12.0),
              border: Border.all(
                color: _useGps ? AppColors.primary.withOpacity(0.3) : AppColors.border,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with GPS status
                Row(
                  children: [
                    Icon(
                      Icons.my_location,
                      color: _useGps ? AppColors.primary : AppColors.textSecondary,
                      size: isMobile ? 20.0 : 24.0,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        _useGps ? 'Current Location (GPS Active)' : 'Current Location',
                        style: GoogleFonts.cairo(
                          fontSize: isMobile ? 16.0 : 18.0,
                          fontWeight: FontWeight.w600,
                          color: _useGps ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (_useGps)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: GoogleFonts.cairo(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 12.0),
                
                // Address field
                TextFormField(
                  controller: _addressCtrl,
                  readOnly: isProvider ? true : !_useGps, // Always read-only for providers
                  decoration: InputDecoration(
                    hintText: isProvider 
                        ? 'GPS address (locked for providers)' 
                        : (_useGps ? 'GPS address will appear here...' : 'Enter Address'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: isProvider 
                        ? AppColors.greyLight // Locked appearance for providers
                        : (_useGps ? Colors.white : AppColors.background),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12.0 : 16.0,
                      vertical: isMobile ? 12.0 : 16.0,
                    ),
                    suffixIcon: isProvider 
                        ? Icon(Icons.lock, color: AppColors.textSecondary, size: 20)
                        : null,
                  ),
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14.0 : 16.0,
                    color: isProvider ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                ),
                
                const SizedBox(height: 12.0),
                
                // GPS toggle and save section
                Row(
                  children: [
                    Switch(
                      value: _useGps,
                      onChanged: isProvider 
                        ? null // Providers must have GPS enabled
                        : (v) async {
                            setState(() { _useGps = v; });
                            
                            // Immediately notify maps about GPS state change
                            LocationService.notifyGpsStateChanged(v);
                            
                            // Update the AuthService to persist the change
                            final auth = Provider.of<AuthService>(context, listen: false);
                            
                            if (v) {
                              // GPS turned ON - fill address and update profile
                              await _simulateGpsAndFillFullAddress();
                              try {
                                await auth.updateProfile(useGpsLocation: true);
                              } catch (e) {
                                // Handle silently, user can still save manually
                              }
                            } else {
                              // GPS turned OFF - clear address and update profile
                              _addressCtrl.text = '';
                              try {
                                await auth.updateProfile(useGpsLocation: false);
                              } catch (e) {
                                // Handle silently, user can still save manually
                              }
                            }
                          },
                      activeColor: AppColors.primary,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Use GPS (simulated) for my location and auto-fill address',
                            style: GoogleFonts.cairo(
                              fontSize: isMobile ? 14.0 : 16.0,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (isProvider)
                            Text(
                              'GPS is mandatory for providers - address is locked',
                              style: GoogleFonts.cairo(
                                fontSize: 12.0,
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Save button - only show for non-providers
                if (!isProvider) ...[
                  const SizedBox(height: 12.0),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          final auth = Provider.of<AuthService>(context, listen: false);
                          
                          // Use the same logic as user dashboard
                          final res = await auth.updateProfile(
                            useGpsLocation: _useGps,
                            address: _useGps ? null : {
                              'line1': _addressCtrl.text.trim(),
                              'city': _addressCtrl.text.trim().split(',').length > 1 
                                  ? _addressCtrl.text.trim().split(',')[1].trim() 
                                  : _addressCtrl.text.trim().split(',').first.trim(),
                              'street': _addressCtrl.text.trim().contains(',') 
                                  ? _addressCtrl.text.trim().split(',').first.trim()
                                  : _addressCtrl.text.trim(),
                            },
                          );
                          
                          final ok = res['success'] == true;
                          if (ok && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Address settings updated successfully!')),
                            );
                            _refreshGpsStateFromProfile();
                          } else {
                            final msg = (res['message'] as String?) ?? 'Failed to update address';
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(backgroundColor: AppColors.error, content: Text(msg)),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(backgroundColor: AppColors.error, content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 12.0 : 16.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        'Save Changes',
                        style: GoogleFonts.cairo(
                          fontSize: isMobile ? 16.0 : 18.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          SizedBox(height: isMobile ? 16.0 : 20.0),
          
          // Saved Addresses Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _useGps ? 'Saved Addresses (Inactive)' : 'Saved Addresses',
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 16.0 : 18.0,
                  fontWeight: FontWeight.w600,
                  color: _useGps ? AppColors.textSecondary : AppColors.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _onAddOrEditAddress,
                icon: Icon(Icons.add, size: isMobile ? 16.0 : 18.0),
                label: Text(
                  'Add New Address',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14.0 : 16.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12.0 : 16.0,
                    vertical: isMobile ? 8.0 : 10.0,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: isMobile ? 12.0 : 16.0),
          
          if (savedAddresses.isEmpty)
            Container(
              padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(isMobile ? 8.0 : 12.0),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Text(
                'No address saved',
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 14.0 : 16.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else ..._buildAddressCards(isMobile, savedAddresses),
        ],
      ),
    );
  }

  List<Widget> _buildAddressCards(bool isMobile, List<dynamic> list) {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final totals = <String, int>{};
    for (final e in list) {
      final t = ((e as Map)['type'] ?? 'home').toString();
      totals[t] = (totals[t] ?? 0) + 1;
    }
    final counters = <String, int>{};
    final widgets = <Widget>[];
    for (int i = 0; i < list.length; i++) {
      final m = Map<String, dynamic>.from(list[i] as Map);
      final type = (m['type'] ?? 'home').toString();
      final baseLabel = _localizedTypeLabel(type, languageService.currentLanguage);
      final countForType = totals[type] ?? 0;
      final nextIndex = (counters[type] ?? 0) + 1;
      counters[type] = nextIndex;
      final numberedLabel = countForType > 1 ? '$baseLabel $nextIndex' : baseLabel;
      final line = [m['street'], m['city'], m['area']].whereType<String>().where((s) => s.trim().isNotEmpty).join(', ');
      widgets.add(Padding(
        padding: EdgeInsets.only(bottom: isMobile ? 8.0 : 12.0),
        child: _buildAddressCard(numberedLabel, line.isEmpty ? '-' : line, m['isDefault'] == true, isMobile, onMakeDefault: () => _setDefaultAddress(i), onEdit: () => _onAddOrEditAddress(editIndex: i), onDelete: () => _deleteAddress(i)),
      ));
    }
    return widgets;
  }

  Widget _buildAddressCard(String label, String address, bool isDefault, bool isMobile, {VoidCallback? onMakeDefault, VoidCallback? onEdit, VoidCallback? onDelete}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(isMobile ? 8.0 : 12.0),
        border: Border.all(color: isDefault ? AppColors.primary : AppColors.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.location_on,
            color: _useGps ? AppColors.textSecondary : AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.cairo(
                          fontSize: isMobile ? 16.0 : 18.0,
                          fontWeight: FontWeight.w600,
                          color: _useGps ? AppColors.textSecondary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isDefault && !_useGps)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Default',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    if (_useGps)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Inactive',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14.0 : 16.0,
                    color: _useGps ? AppColors.textSecondary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                    ),
                    const Spacer(),
                    if (!isDefault && !_useGps)
                      TextButton(
                        onPressed: onMakeDefault,
                        child: const Text('Make Default'),
                      ),
                    if (_useGps)
                      TextButton(
                        onPressed: () => _switchToSavedAddress(onMakeDefault),
                        child: const Text('Use This Address'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t('notificationPreferences'), style: GoogleFonts.cairo(fontSize: isMobile ? 18.0 : 20.0, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          SizedBox(height: isMobile ? 12.0 : 16.0),
          _buildToggleRow(_t('emailNotifications'), _emailNotifs, (v) => setState(() => _emailNotifs = v)),
          const Divider(),
          _buildToggleRow(_t('pushNotifications'), _pushNotifs, (v) => setState(() => _pushNotifs = v)),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String label, bool isEnabled, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.cairo(fontSize: 16.0, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        Switch(
          value: isEnabled,
          onChanged: (value) {
            onChanged(value);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_t('saveChanges')} · $label: ${value ? 'ON' : 'OFF'}')));
          },
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  // Helpers: edit actions (reuse AuthService)
  Future<void> _onEditName() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final firstName = TextEditingController(text: (auth.currentUser?['firstName'] ?? '').toString());
    final lastName = TextEditingController(text: (auth.currentUser?['lastName'] ?? '').toString());
    final okPressed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('fullName')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            TextField(controller: firstName, decoration: const InputDecoration(labelText: 'First name')),
            TextField(controller: lastName, decoration: const InputDecoration(labelText: 'Last name')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(_t('cancel'))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(_t('saveChanges'))),
        ],
      ),
    );
    if (okPressed == true) {
      try {
        await auth.updateProfile(firstName: firstName.text.trim(), lastName: lastName.text.trim());
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
        }
      } catch (_) {}
    }
  }

  Future<void> _onEditEmail() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final email = TextEditingController(text: (auth.currentUser?['email'] ?? '').toString());
    final okPressed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('email')),
        content: TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(_t('cancel'))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(_t('saveChanges'))),
        ],
      ),
    );
    if (okPressed == true) {
      try {
        final next = email.text.trim();
        final valid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(next);
        if (!valid) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid email address')));
          }
          return;
        }
        await auth.updateProfile(email: next);
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email updated. Check your inbox to verify.')));
          final proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(_t('profileSettings')),
              content: Text(_t('pleaseVerifyAccount')),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(_t('cancel'))),
                TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(_t('verify'))),
              ],
            ),
          );
          if (proceed == true) {
            try {
              await Provider.of<AuthService>(context, listen: false).requestVerification();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification email sent.')));
              }
            } catch (_) {}
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _onEditPhone() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final phone = TextEditingController(text: (auth.currentUser?['phone'] ?? '').toString());
    final okPressed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('phoneNumber')),
        content: TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(_t('cancel'))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(_t('saveChanges'))),
        ],
      ),
    );
    if (okPressed == true) {
      try {
        await auth.updateProfile(phone: phone.text.trim());
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone updated')));
        }
      } catch (e) {
        final msg = e.toString();
        final friendly = msg.contains('Phone number already registered') ? 'Phone number already registered' : 'Failed to update phone';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendly)));
        }
      }
    }
  }

  Future<void> _onEditAge() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final ageCtl = TextEditingController(text: (auth.currentUser?['age']?.toString() ?? ''));
    final okPressed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('age')),
        content: TextField(controller: ageCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Age')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(_t('cancel'))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(_t('saveChanges'))),
        ],
      ),
    );
    if (okPressed == true) {
      final parsed = int.tryParse(ageCtl.text.trim());
      if (parsed != null) {
        try {
          await auth.updateProfile(age: parsed);
          if (mounted) {
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Age updated')));
          }
        } catch (_) {}
      }
    }
  }

  Future<void> _onAddOrEditAddress({int? editIndex}) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final List<dynamic> existing = (auth.currentUser?['addresses'] as List<dynamic>?) ?? [];
    // Pre-fill fields if editing
    Map<String, dynamic>? current = (editIndex != null && editIndex >= 0 && editIndex < existing.length)
        ? Map<String, dynamic>.from(existing[editIndex] as Map)
        : null;
    String type = (current?['type'] ?? 'home').toString();
    // Cities whitelist aligned with backend
    const cities = [
      'jerusalem','ramallah','nablus','hebron','bethlehem','jericho','tulkarm','qalqilya','jenin','salfit','tubas',
      'gaza','rafah','khan yunis','deir al-balah','north gaza'
    ];
    String? city = (current?['city'] as String?);
    String? selectedStreet = (current?['street'] as String?);
    final area = TextEditingController(text: (current?['area'] ?? '').toString());
    bool makeDefault = current?['isDefault'] == true || existing.isEmpty; // first one becomes default
    
    // Validate that the existing street is valid for the current city
    if (city != null && selectedStreet != null) {
      final availableStreets = _getStreetsForCity(city);
      if (!availableStreets.contains(selectedStreet)) {
        selectedStreet = null; // Reset if street is not valid for current city
      }
    }

    final okPressed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final languageService = Provider.of<LanguageService>(context, listen: false);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(editIndex == null ? _t('addNewAddress') : _t('edit')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Address type dropdown
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(value: 'home', child: Text('Home')),
                        DropdownMenuItem(value: 'work', child: Text('Work')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (v) { 
                        setState(() {
                          type = v ?? 'home'; 
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // City dropdown with localized labels
                    DropdownButtonFormField<String>(
                      value: city,
                      decoration: const InputDecoration(
                        labelText: 'City *',
                        helperText: 'Please select a city first',
                      ),
                      items: [
                        for (final c in cities)
                          DropdownMenuItem(
                            value: c,
                            child: Text(AppStrings.getString(c, languageService.currentLanguage)),
                          ),
                      ],
                      onChanged: (v) { 
                        setState(() {
                          city = v;
                          // Reset street when city changes
                          selectedStreet = null;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'City is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Street dropdown - only appears after city is selected
                    if (city != null && city!.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: selectedStreet,
                        decoration: const InputDecoration(
                          labelText: 'Street *',
                          helperText: 'Please select a street',
                        ),
                        items: _getStreetsForCity(city).map((street) {
                          return DropdownMenuItem(
                            value: street,
                            child: Text(AppStrings.getString(street, languageService.currentLanguage)),
                          );
                        }).toList(),
                        onChanged: (v) { 
                          setState(() {
                            selectedStreet = v; 
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Street is required';
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 16),
                    // Area field (optional)
                    TextField(
                      controller: area,
                      decoration: const InputDecoration(
                        labelText: 'Area (Optional)',
                        hintText: 'Enter area if needed',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Default checkbox
                    if (existing.isNotEmpty)
                      CheckboxListTile(
                        value: makeDefault,
                        onChanged: (v) { 
                          setState(() {
                            makeDefault = v ?? false; 
                          });
                        },
                        title: Text(_t('defaultText')),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false), 
                  child: Text(_t('cancel'))
                ),
                TextButton(
                  onPressed: (city != null && city!.isNotEmpty && selectedStreet != null && selectedStreet!.isNotEmpty) 
                    ? () => Navigator.of(ctx).pop(true) 
                    : null,
                  child: Text(_t('saveChanges')),
                ),
              ],
            );
          },
        );
      },
    );

    if (okPressed == true) {
      final updated = [...existing.map((e) => Map<String, dynamic>.from(e as Map))];
      final payload = {
        'type': type,
        'street': selectedStreet ?? '', // Use selectedStreet instead of street.text
        'city': (city ?? '').trim(),
        'area': area.text.trim(),
        'isDefault': makeDefault,
      };
      if (editIndex != null && editIndex >= 0 && editIndex < updated.length) {
        updated[editIndex] = { ...updated[editIndex], ...payload };
      } else {
        updated.add(payload);
      }
      bool foundDefault = false;
      for (final m in updated) {
        if ((m['isDefault'] ?? false) && !foundDefault) {
          foundDefault = true;
        } else {
          m['isDefault'] = false;
        }
      }
      if (!foundDefault && updated.isNotEmpty) updated[0]['isDefault'] = true;
      try {
        await auth.updateProfile(addresses: updated.cast<Map<String, dynamic>>());
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(editIndex == null ? 'Address added' : 'Address updated')));
        }
      } catch (_) {}
    }
  }

  String _localizedTypeLabel(String type, String lang) {
    switch (type) {
      case 'work':
        return AppStrings.getString('work', lang);
      case 'other':
        return AppStrings.getString('other', lang);
      case 'home':
      default:
        return AppStrings.getString('home', lang);
    }
  }

  Future<void> _setDefaultAddress(int index) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final List<dynamic> existing = (auth.currentUser?['addresses'] as List<dynamic>?) ?? [];
    if (index < 0 || index >= existing.length) return;
    final updated = [
      for (int i = 0; i < existing.length; i++)
        { ...Map<String, dynamic>.from(existing[i] as Map), 'isDefault': i == index }
    ];
    try {
      await auth.updateProfile(addresses: updated.cast<Map<String, dynamic>>());
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Default address updated')));
      }
    } catch (_) {}
  }

  Future<void> _deleteAddress(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(_t('cancel'))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;

    final auth = Provider.of<AuthService>(context, listen: false);
    final List<dynamic> existing = (auth.currentUser?['addresses'] as List<dynamic>?) ?? [];
    if (index < 0 || index >= existing.length) return;
    final updated = [
      for (int i = 0; i < existing.length; i++)
        if (i != index) Map<String, dynamic>.from(existing[i] as Map)
    ];
    bool hasDefault = updated.any((e) => (e['isDefault'] ?? false) == true);
    if (updated.isNotEmpty && !hasDefault) {
      updated[0]['isDefault'] = true;
    }
    try {
      await auth.updateProfile(addresses: updated.cast<Map<String, dynamic>>());
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address deleted')));
      }
    } catch (_) {}
  }

  // Build security section
  Widget _buildSecuritySection(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('security'),
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 18.0 : 20.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isMobile ? 12.0 : 16.0),
          
          // Delete Account Option
          GestureDetector(
            onTap: () => _showDeleteAccountDialog(context),
            child: Container(
              padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(isMobile ? 8.0 : 12.0),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.delete_forever,
                    color: AppColors.error,
                    size: isMobile ? 24.0 : 28.0,
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t('deleteAccount'),
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 16.0 : 18.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                        Text(
                          _t('permanentlyDeleteAccount'),
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 14.0 : 16.0,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.textSecondary,
                    size: isMobile ? 16.0 : 18.0,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show delete account confirmation dialog
  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            _t('deleteAccount'),
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w700,
              color: AppColors.error,
            ),
          ),
          content: Text(
            _t('deleteAccountWarning') ?? 'Are you sure you want to delete your account? This action cannot be undone.',
            style: GoogleFonts.cairo(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                _t('cancel'),
                style: GoogleFonts.cairo(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteAccount(context);
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
              ),
              child: Text(
                _t('delete'),
                style: GoogleFonts.cairo(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Delete account
  Future<void> _deleteAccount(BuildContext context) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await authService.deleteAccount();
      
      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _t('accountDeleted') ?? 'Account deleted successfully',
                style: GoogleFonts.cairo(color: AppColors.white),
              ),
              backgroundColor: AppColors.success,
            ),
          );
          
          // Navigate to home screen and clear all routes
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/home',
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? _t('deleteAccountFailed') ?? 'Failed to delete account',
                style: GoogleFonts.cairo(color: AppColors.white),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t('deleteAccountFailed') ?? 'Failed to delete account: ${e.toString()}',
              style: GoogleFonts.cairo(color: AppColors.white),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

}
