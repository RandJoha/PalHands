import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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
      onTap: () {
                // Allow all report types for both authenticated and anonymous users
        // Authentication is handled at submission time
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