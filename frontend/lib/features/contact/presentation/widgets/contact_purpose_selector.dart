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
        
        // Use different layouts based on screen width
        if (screenWidth < 600) {
          // Mobile layout: 2 columns
          return Column(
            children: [
              // First row - 2 items
              Row(
                children: [
                  Expanded(
                    child: _buildPurposeCard(
                      purposes[0],
                      languageService,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPurposeCard(
                      purposes[1],
                      languageService,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Second row - 2 items
              Row(
                children: [
                  Expanded(
                    child: _buildPurposeCard(
                      purposes[2],
                      languageService,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPurposeCard(
                      purposes[3],
                      languageService,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Third row - 2 items
              Row(
                children: [
                  Expanded(
                    child: _buildPurposeCard(
                      purposes[4],
                      languageService,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPurposeCard(
                      purposes[5],
                      languageService,
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          // Desktop layout: 3 columns (more balanced)
          return Column(
            children: [
              // First row - 3 items
              Row(
                children: [
                  Expanded(
                    child: _buildPurposeCard(
                      purposes[0],
                      languageService,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPurposeCard(
                      purposes[1],
                      languageService,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPurposeCard(
                      purposes[2],
                      languageService,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Second row - 3 items
              Row(
                children: [
                  Expanded(
                    child: _buildPurposeCard(
                      purposes[3],
                      languageService,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPurposeCard(
                      purposes[4],
                      languageService,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPurposeCard(
                      purposes[5],
                      languageService,
                    ),
                  ),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildPurposeCard(
    ContactPurposeData purposeData,
    LanguageService languageService,
  ) {
    final isSelected = selectedPurpose == purposeData.purpose;
    
    return GestureDetector(
      onTap: () => onPurposeSelected(purposeData.purpose),
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
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