import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/auth_service.dart';

class MobileSecurityWidget extends StatefulWidget {
  const MobileSecurityWidget({super.key});

  @override
  State<MobileSecurityWidget> createState() => _MobileSecurityWidgetState();
}

class _MobileSecurityWidgetState extends State<MobileSecurityWidget> {
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security',
            style: GoogleFonts.cairo(
              fontSize: 24,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.lock, color: AppColors.primary),
            title: Text('Change Password', style: GoogleFonts.cairo(fontSize: 16)),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.error),
            title: Text('Delete Account', style: GoogleFonts.cairo(fontSize: 16)),
            onTap: () => _showDeleteAccountDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.history, color: AppColors.primary),
            title: Text('Login History', style: GoogleFonts.cairo(fontSize: 16)),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteAccount(context);
              },
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
            const SnackBar(
              content: Text('Account deleted successfully'),
              backgroundColor: Colors.green,
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
              content: Text(response['message'] ?? 'Failed to delete account'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 