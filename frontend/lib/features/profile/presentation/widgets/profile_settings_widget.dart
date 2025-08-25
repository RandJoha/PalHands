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
                      color: AppColors.primary.withValues(alpha: 0.1),
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
              readOnly: true,
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
                    final res = await auth.updateProfile(
                      firstName: first.isEmpty ? null : first,
                      lastName: last.isEmpty ? null : last,
                      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
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
            // Inline Change Password entry point
            const Divider(),
            Text(
              AppStrings.getString('security', languageService.currentLanguage),
              style: GoogleFonts.cairo(fontSize: 16.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8.h),
            const SecurityWidget(),
          ],
        ),
      ),
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