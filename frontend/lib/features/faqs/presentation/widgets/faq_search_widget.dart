import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/services/language_service.dart';

class FAQSearchWidget extends StatefulWidget {
  final Function(String) onSearchChanged;
  final String searchQuery;

  const FAQSearchWidget({
    super.key,
    required this.onSearchChanged,
    required this.searchQuery,
  });

  @override
  State<FAQSearchWidget> createState() => _FAQSearchWidgetState();
}

class _FAQSearchWidgetState extends State<FAQSearchWidget> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _searchFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(FAQSearchWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update if the query actually changed and is different from current text
    if (widget.searchQuery != oldWidget.searchQuery && 
        widget.searchQuery != _searchController.text) {
      _searchController.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    widget.onSearchChanged('');
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: widget.onSearchChanged,
            textDirection: languageService.textDirection,
            textAlign: languageService.currentLanguage == 'ar' 
              ? TextAlign.right 
              : TextAlign.left,
            decoration: InputDecoration(
              hintText: AppStrings.getString(
                'faqSearchPlaceholder',
                languageService.currentLanguage,
              ),
              hintStyle: GoogleFonts.cairo(
                fontSize: 14,
                color: AppColors.placeholderText,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: AppColors.primary,
                size: 20,
              ),
              suffixIcon: widget.searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: AppColors.grey,
                      size: 20,
                    ),
                    onPressed: _clearSearch,
                  )
                : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        );
      },
    );
  }
} 