import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/services/language_service.dart';
import '../../data/contact_data.dart';

class ContactPurposeSelector extends StatelessWidget {
  final ContactPurpose? selectedPurpose;
  final Function(ContactPurpose) onPurposeSelected;

  const ContactPurposeSelector({
    super.key,
    required this.selectedPurpose,
    required this.onPurposeSelected,
  });

  // Store the selected purpose for restoration after login
  static Future<void> _storeSelectedPurpose(ContactPurpose purpose) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_contact_purpose', purpose.toString());
    } catch (e) {
      // Handle error silently
    }
  }

  // Retrieve and clear the stored purpose
  static Future<ContactPurpose?> getAndClearStoredPurpose() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final purposeString = prefs.getString('pending_contact_purpose');
      if (purposeString != null) {
        await prefs.remove('pending_contact_purpose');
        return ContactPurpose.values.firstWhere(
          (purpose) => purpose.toString() == purposeString,
          orElse: () => ContactPurpose.other,
        );
      }
    } catch (e) {
      // Handle error silently
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        final purposes = ContactData.getAllContactPurposes();
        final screenWidth = MediaQuery.of(context).size.width;
        
        // Use different layouts based on screen width with dynamic item counts
        final isMobile = screenWidth < 600;
        final crossAxisCount = isMobile ? 2 : 3;
        final spacing = isMobile ? 12.0 : 16.0;

        List<Widget> rows = [];
        for (int i = 0; i < purposes.length; i += crossAxisCount) {
          final rowItems = purposes.sublist(
            i,
            i + crossAxisCount > purposes.length ? purposes.length : i + crossAxisCount,
          );
          rows.add(
            Row(
              children: [
                ...rowItems.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final data = entry.value;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: idx == rowItems.length - 1 ? 0 : spacing),
                      child: _buildPurposeCard(
                        data,
                        languageService,
                        context,
                      ),
                    ),
                  );
                }),
                // If last row has fewer items, fill the space to keep alignment
                if (rowItems.length < crossAxisCount)
                  const Expanded(
                    child: SizedBox.shrink(),
                  ),
                if (!isMobile && rowItems.length == 1)
                  const Expanded(
                    child: SizedBox.shrink(),
                  ),
              ],
            ),
          );
          if (i + crossAxisCount < purposes.length) {
            rows.add(SizedBox(height: spacing));
          }
        }

        return Column(children: rows);
      },
    );
  }

  Widget _buildPurposeCard(
    ContactPurposeData purposeData,
    LanguageService languageService,
    BuildContext context,
  ) {
    final isSelected = selectedPurpose == purposeData.purpose;
    
    return GestureDetector(
      onTap: () async {
        // Check if user is authenticated before allowing selection
        final authService = Provider.of<AuthService>(context, listen: false);
        if (!authService.isAuthenticated) {
          // Show login dialog
          final shouldLogin = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text(
                AppStrings.getString('loginRequired', languageService.currentLanguage),
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              content: Text(
                AppStrings.getString('loginRequiredMessage', languageService.currentLanguage),
                style: GoogleFonts.cairo(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Login',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );

          if (shouldLogin == true) {
            // Store the selected purpose for restoration after login
            ContactPurposeSelector._storeSelectedPurpose(purposeData.purpose);
            // Navigate to login page
            Navigator.of(context).pushNamed('/login');
          }
          return;
        }
        
        // User is authenticated, proceed with selection
        onPurposeSelected(purposeData.purpose);
      },
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              purposeData.icon,
              size: 28,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.getString(purposeData.titleKey, languageService.currentLanguage),
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.primary,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
} 