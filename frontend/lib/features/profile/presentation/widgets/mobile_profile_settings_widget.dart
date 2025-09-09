import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/services/auth_service.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/location_service.dart';

class MobileProfileSettingsWidget extends StatefulWidget {
  const MobileProfileSettingsWidget({super.key});

  @override
  State<MobileProfileSettingsWidget> createState() => _MobileProfileSettingsWidgetState();
}

class _MobileProfileSettingsWidgetState extends State<MobileProfileSettingsWidget> {
  final TextEditingController _addressCtrl = TextEditingController();
  bool _useGps = false;
  final LocationService _locationService = LocationService();
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return _buildProfile(context, languageService);
      },
    );
  }

  Widget _buildProfile(BuildContext context, LanguageService languageService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.getString('profileSettings', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 24,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          
          // Profile form
          _buildProfileForm(languageService),
        ],
      ),
    );
  }

  Widget _buildProfileForm(LanguageService languageService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile picture
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    // Handle change photo
                  },
                  child: Text(
                    'Change Photo',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Form fields
          _buildFormField(
            AppStrings.getString('fullName', languageService.currentLanguage),
            [
              (Provider.of<AuthService>(context, listen: false).currentUser?['firstName'] ?? '').toString(),
              (Provider.of<AuthService>(context, listen: false).currentUser?['lastName'] ?? '').toString(),
            ].where((e) => e.isNotEmpty).join(' ').trim(),
          ),
          const SizedBox(height: 16),
          _buildFormField(AppStrings.getString('email', languageService.currentLanguage), 'ahmed@example.com'),
          const SizedBox(height: 16),
          _buildFormField(AppStrings.getString('phone', languageService.currentLanguage), '+970 59 123 4567'),
          const SizedBox(height: 16),
          _buildAddressSection(languageService),
          const SizedBox(height: 24),
          
          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Handle save
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Save Changes',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(),
          Text(
            AppStrings.getString('security', languageService.currentLanguage),
            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showDeleteAccountDialog(context, languageService),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.delete_forever, color: AppColors.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.getString('deleteAccount', languageService.currentLanguage),
                          style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.error),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.getString('permanentlyDeleteAccount', languageService.currentLanguage),
                          style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  void _showDeleteAccountDialog(BuildContext context, LanguageService languageService) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            AppStrings.getString('deleteAccount', languageService.currentLanguage),
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700, color: AppColors.error),
          ),
          content: Text(
            AppStrings.getString('deleteAccountWarning', languageService.currentLanguage).isNotEmpty
                ? AppStrings.getString('deleteAccountWarning', languageService.currentLanguage)
                : 'Are you sure you want to delete your account? This action cannot be undone.',
            style: GoogleFonts.cairo(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppStrings.getString('cancel', languageService.currentLanguage)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _deleteAccount(context);
              },
              style: TextButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: AppColors.white),
              child: Text(AppStrings.getString('delete', languageService.currentLanguage)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await authService.deleteAccount();
      if (response['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to delete account'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete account: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildAddressSection(LanguageService languageService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.getString('address', languageService.currentLanguage),
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _addressCtrl,
          readOnly: _useGps,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Switch(
              value: _useGps,
              onChanged: (v) async {
                setState(() { _useGps = v; });
                if (v) {
                  final userLoc = await _locationService.simulateGpsForAddress();
                  final coupled = await _locationService.coupleAddressFromGps(userLoc.position);
                  final city = (coupled.city ?? '').toString();
                  final street = (coupled.street ?? '').toString();
                  setState(() {
                    _addressCtrl.text = [street, city].where((e) => e.isNotEmpty).join(', ');
                  });
                }
              },
              activeColor: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Use GPS (simulated) for my location and auto-fill address',
                style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ],
    );
  }
} 