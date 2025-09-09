import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/services/location_service.dart';
import '../../../../shared/services/map_service.dart';
import 'security_widget.dart';

class ProfileSettingsWidget extends StatefulWidget {
  const ProfileSettingsWidget({super.key});

  @override
  State<ProfileSettingsWidget> createState() => _ProfileSettingsWidgetState();
}

class _ProfileSettingsWidgetState extends State<ProfileSettingsWidget> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _useGps = false;
  final LocationService _locationService = LocationService();
  final MapService _mapService = MapService();

  @override
  void initState() {
    super.initState();
    // Prefill from current user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      final user = auth.currentUser ?? {};
      final first = (user['firstName'] ?? '').toString();
      final last = (user['lastName'] ?? '').toString();
      _nameCtrl.text = [first, last].where((e) => e.isNotEmpty).join(' ');
      _emailCtrl.text = (user['email'] ?? '').toString();
      _phoneCtrl.text = (user['phone'] ?? '').toString();
      _addressCtrl.text = (user['address'] is String)
          ? user['address']
          : (user['address']?['line1'] ?? '').toString();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }
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
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.getString('profileSettings', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 24.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 24.h),
          
          // Profile form
      _buildProfileForm(languageService),
        ],
      ),
    );
  }

  Widget _buildProfileForm(LanguageService languageService) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile picture
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100.w,
                    height: 100.w,
                    decoration: BoxDecoration(
                      // withValues is unstable / newer API; use withOpacity for wider SDK compatibility
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50.r),
                    ),
                    child: Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 50.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextButton(
                    onPressed: () {
                      // Handle change photo
                    },
                    child: Text(
                      'Change Photo',
                      style: GoogleFonts.cairo(
                        fontSize: 14.sp,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            // Form fields
            _buildTextField(
              AppStrings.getString('fullName', languageService.currentLanguage),
              _nameCtrl,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            SizedBox(height: 16.h),
            _buildTextField(
              AppStrings.getString('email', languageService.currentLanguage),
              _emailCtrl,
              readOnly: true,
            ),
            SizedBox(height: 16.h),
            _buildTextField(
              AppStrings.getString('phone', languageService.currentLanguage),
              _phoneCtrl,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            SizedBox(height: 16.h),
            // Address is read-only here; will be moved to registration form in future
            _buildTextField(
              AppStrings.getString('address', languageService.currentLanguage),
              _addressCtrl,
              readOnly: _useGps,
            ),
            SizedBox(height: 12.h),
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
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Use GPS (simulated) for my location and auto-fill address',
                    style: GoogleFonts.cairo(fontSize: 14.sp, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  final auth = Provider.of<AuthService>(context, listen: false);
                  // Split name into first/last (best-effort)
                  final parts = _nameCtrl.text.trim().split(RegExp(r'\s+'));
                  final first = parts.isNotEmpty ? parts.first : '';
                  final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';

                  try {
                    final addressText = _addressCtrl.text.trim();
                    final res = await auth.updateProfile(
                      firstName: first.isEmpty ? null : first,
                      lastName: last.isEmpty ? null : last,
                      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
                      useGpsLocation: _useGps,
                      address: _useGps || addressText.isEmpty
                          ? null
                          : { 'line1': addressText },
                    );
                    final ok = res['success'] == true;
                    if (ok) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile updated successfully')),
                        );
                      }
                    } else {
                      final msg = (res['message'] as String?) ?? 'Failed to update profile';
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
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.cairo(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            // Security section (Delete Account - same design as Admin/Provider)
            const Divider(),
            Text(
              AppStrings.getString('security', languageService.currentLanguage),
              style: GoogleFonts.cairo(fontSize: 16.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8.h),
            GestureDetector(
              onTap: () => _showDeleteAccountDialog(context, languageService),
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.delete_forever, color: AppColors.error),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.getString('deleteAccount', languageService.currentLanguage),
                            style: GoogleFonts.cairo(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            AppStrings.getString('permanentlyDeleteAccount', languageService.currentLanguage),
                            style: GoogleFonts.cairo(fontSize: 14.sp, color: AppColors.textSecondary),
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
      ),
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

  Widget _buildTextField(String label, TextEditingController controller, {String? Function(String?)? validator, bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          validator: validator,
          readOnly: readOnly,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ),
        ),
      ],
    );
  }
} 