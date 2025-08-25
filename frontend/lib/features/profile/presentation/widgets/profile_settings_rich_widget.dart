import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/services/language_service.dart';

class ProfileSettingsRichWidget extends StatefulWidget {
  const ProfileSettingsRichWidget({super.key});

  @override
  State<ProfileSettingsRichWidget> createState() => _ProfileSettingsRichWidgetState();
}

class _ProfileSettingsRichWidgetState extends State<ProfileSettingsRichWidget> {
  bool _emailNotifs = true;
  bool _pushNotifs = true;

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
    ]
  };

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
    final List<dynamic> list = (auth.currentUser?['addresses'] as List<dynamic>?) ?? [];

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _t('savedAddresses'),
                style: GoogleFonts.cairo(fontSize: isMobile ? 18.0 : 20.0, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              ElevatedButton.icon(
                onPressed: _onAddOrEditAddress,
                icon: Icon(Icons.add, size: isMobile ? 16.0 : 18.0),
                label: Text(_t('addNewAddress'), style: GoogleFonts.cairo(fontSize: isMobile ? 14.0 : 16.0, fontWeight: FontWeight.w500)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 12.0 : 16.0, vertical: isMobile ? 8.0 : 10.0),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12.0 : 16.0),
          if (list.isEmpty)
            Container(
              padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(isMobile ? 8.0 : 12.0),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Text('No address saved', style: GoogleFonts.cairo(fontSize: isMobile ? 14.0 : 16.0, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
            )
          else ..._buildAddressCards(isMobile, list),
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
          const Icon(Icons.location_on, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(label, style: GoogleFonts.cairo(fontSize: isMobile ? 16.0 : 18.0, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ),
                    if (isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: Text('Default', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(address, style: GoogleFonts.cairo(fontSize: isMobile ? 14.0 : 16.0, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit, size: 18), label: const Text('Edit')),
                    const SizedBox(width: 8),
                    TextButton.icon(onPressed: onDelete, icon: const Icon(Icons.delete_outline, size: 18), label: const Text('Delete')),
                    const Spacer(),
                    if (!isDefault) TextButton(onPressed: onMakeDefault, child: const Text('Make Default')),
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
    // Normalize to lowercase and ensure it matches allowed list
    if (city != null) {
      final lc = city.toLowerCase().trim();
      city = cities.contains(lc) ? lc : null;
    }
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
                      value: (city != null && cities.contains(city)) ? city : null,
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
                        value: (_getStreetsForCity(city).contains(selectedStreet)) ? selectedStreet : null,
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
        'city': (city ?? '').toLowerCase().trim(),
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
