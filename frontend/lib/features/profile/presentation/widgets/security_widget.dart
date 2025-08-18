import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/widgets/app_toast.dart';

class SecurityWidget extends StatefulWidget {
  const SecurityWidget({super.key});

  @override
  State<SecurityWidget> createState() => _SecurityWidgetState();

  // Expose a static helper so other screens (e.g., Login) can open this dialog
  static void showChangePasswordDialog(BuildContext context) {
  final auth = Provider.of<AuthService>(context, listen: false);
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        bool submitting = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Change Password',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 380,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!auth.isAuthenticated) ...[
                        TextFormField(
                          controller: emailCtrl,
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (!v.contains('@')) return 'Invalid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: currentCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Current Password'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: newCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'New Password'),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v.length < 6) return 'Min 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Confirm New Password'),
                        validator: (v) => (v != newCtrl.text) ? 'Passwords do not match' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setState(() => submitting = true);
                          try {
                            Map<String, dynamic> res;
                            if (auth.isAuthenticated) {
                              res = await auth.changePassword(
                                currentPassword: currentCtrl.text,
                                newPassword: newCtrl.text,
                              );
                            } else {
                              res = await auth.changePasswordDirect(
                                email: emailCtrl.text.trim(),
                                currentPassword: currentCtrl.text,
                                newPassword: newCtrl.text,
                              );
                            }
                            final ok = res['success'] == true;
                            if (ok) {
                              if (context.mounted) {
                                AppToast.show(context, message: 'Password changed successfully', type: AppToastType.success);
                                Navigator.of(context).pop();
                              }
                            } else {
                              final msg = (res['message'] as String?) ?? 'Failed to change password';
                              if (context.mounted) {
                                AppToast.show(context, message: msg, type: AppToastType.error);
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              AppToast.show(context, message: 'Error: $e', type: AppToastType.error);
                            }
                          } finally {
                            if (context.mounted) setState(() => submitting = false);
                          }
                        },
                  child: submitting
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SecurityWidgetState extends State<SecurityWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return _buildSecurity(context, languageService);
      },
    );
  }

  Widget _buildSecurity(BuildContext context, LanguageService languageService) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security',
            style: GoogleFonts.cairo(
              fontSize: 24.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 24.h),
          ListTile(
            leading: const Icon(Icons.lock, color: AppColors.primary),
            title: Text('Change Password', style: GoogleFonts.cairo(fontSize: 16.sp)),
            onTap: () => SecurityWidget.showChangePasswordDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.error),
            title: Text('Delete Account', style: GoogleFonts.cairo(fontSize: 16.sp)),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.history, color: AppColors.primary),
            title: Text('Login History', style: GoogleFonts.cairo(fontSize: 16.sp)),
            onTap: () {},
          ),
        ],
      ),
    );
  }

} 