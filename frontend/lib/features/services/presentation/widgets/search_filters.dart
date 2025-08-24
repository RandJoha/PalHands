import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';

class SearchFilters extends StatelessWidget {
  final String selectedCategory;
  final String selectedLocation;
  final Function(String) onCategoryChanged;
  final Function(String) onLocationChanged;
  final VoidCallback onClearFilters;

  const SearchFilters({
    super.key,
    required this.selectedCategory,
    required this.selectedLocation,
    required this.onCategoryChanged,
    required this.onLocationChanged,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filters Header
        Row(
          children: [
            Text(
              'Filters',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const Spacer(),
            if (selectedCategory.isNotEmpty || selectedLocation.isNotEmpty)
              TextButton(
                onPressed: onClearFilters,
                child: Text(
                  'Clear all',
                  style: GoogleFonts.cairo(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Category Filter
        _buildFilterSection(
          title: 'Category',
          selectedValue: selectedCategory,
          options: _getCategoryOptions(),
          onChanged: onCategoryChanged,
        ),
        
        const SizedBox(height: 16),
        
        // Location Filter
        _buildFilterSection(
          title: 'Location',
          selectedValue: selectedLocation,
          options: _getLocationOptions(),
          onChanged: onLocationChanged,
        ),
      ],
    );
  }

  Widget _buildFilterSection({
    required String title,
    required String selectedValue,
    required List<Map<String, String>> options,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValue == option['value'];
            return FilterChip(
              label: Text(
                option['label']!,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppColors.white : AppColors.textDark,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onChanged(option['value']!);
                } else {
                  onChanged('');
                }
              },
              backgroundColor: AppColors.white,
              selectedColor: AppColors.primary,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<Map<String, String>> _getCategoryOptions() {
    return [
      {'value': '', 'label': 'All Categories'},
      {'value': 'cleaning', 'label': 'Cleaning'},
      {'value': 'laundry', 'label': 'Laundry'},
      {'value': 'caregiving', 'label': 'Caregiving'},
      {'value': 'furniture_moving', 'label': 'Furniture Moving'},
      {'value': 'elderly_support', 'label': 'Elderly Support'},
      {'value': 'aluminum_work', 'label': 'Aluminum Work'},
      {'value': 'carpentry', 'label': 'Carpentry'},
      {'value': 'home_nursing', 'label': 'Home Nursing'},
      {'value': 'maintenance', 'label': 'Maintenance'},
      {'value': 'other', 'label': 'Other'},
    ];
  }

  List<Map<String, String>> _getLocationOptions() {
    return [
      {'value': '', 'label': 'All Locations'},
      {'value': 'jerusalem', 'label': 'Jerusalem'},
      {'value': 'ramallah', 'label': 'Ramallah'},
      {'value': 'nablus', 'label': 'Nablus'},
      {'value': 'hebron', 'label': 'Hebron'},
      {'value': 'bethlehem', 'label': 'Bethlehem'},
      {'value': 'gaza', 'label': 'Gaza'},
      {'value': 'jenin', 'label': 'Jenin'},
      {'value': 'tulkarm', 'label': 'Tulkarm'},
      {'value': 'qalqilya', 'label': 'Qalqilya'},
      {'value': 'salfit', 'label': 'Salfit'},
      {'value': 'tubas', 'label': 'Tubas'},
      {'value': 'jericho', 'label': 'Jericho'},
    ];
  }
}
