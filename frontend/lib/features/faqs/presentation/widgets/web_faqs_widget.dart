import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/services/language_service.dart';
import '../../../../shared/widgets/animated_handshake.dart';
import '../../../../shared/widgets/tatreez_pattern.dart';
import '../../../../shared/widgets/shared_navigation.dart';
import '../../../../shared/widgets/shared_hero_section.dart';
import '../../data/faq_data.dart';
import 'faq_item_widget.dart';
import 'faq_search_widget.dart';

class WebFAQsWidget extends StatefulWidget {
  const WebFAQsWidget({super.key});

  @override
  State<WebFAQsWidget> createState() => _WebFAQsWidgetState();
}

class _WebFAQsWidgetState extends State<WebFAQsWidget> {
  String _searchQuery = '';
  Set<int> _expandedItems = {};
  List<FAQItem> _filteredItems = [];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _filteredItems = FAQData.getAllFAQItems();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _selectedCategory = null; // Clear category filter when searching
      if (query.isEmpty) {
        _filteredItems = FAQData.getAllFAQItems();
      } else {
        _filteredItems = FAQData.getAllFAQItems().where((item) {
          final question = AppStrings.getString(
            item.questionKey,
            context.read<LanguageService>().currentLanguage,
          ).toLowerCase();
          final answer = AppStrings.getString(
            item.answerKey,
            context.read<LanguageService>().currentLanguage,
          ).toLowerCase();
          final searchLower = query.toLowerCase();
          return question.contains(searchLower) || answer.contains(searchLower);
        }).toList();
      }
      _expandedItems.clear();
    });
  }

  void _toggleItem(int index) {
    setState(() {
      if (_expandedItems.contains(index)) {
        _expandedItems.remove(index);
      } else {
        _expandedItems.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFFDF5EC),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Shared Navigation
                SharedNavigation(
                  currentPage: 'faqs',
                  showAuthButtons: true,
                  isMobile: false,
                ),
                // Shared Hero Section
                SharedHeroSections.faqsHero(
                  languageService: languageService,
                  isMobile: false,
                ),
                _buildSearchSection(languageService),
                _buildContentSection(languageService),
                _buildContactSection(languageService),
                _buildFooter(languageService),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchSection(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: FAQSearchWidget(
        searchQuery: _searchQuery,
        onSearchChanged: _onSearchChanged,
      ),
    );
  }



  Widget _buildContentSection(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categories sidebar
          Expanded(
            flex: 1,
            child: _buildCategoriesSidebar(languageService),
          ),
          const SizedBox(width: 40),
          // FAQ content
          Expanded(
            flex: 2,
            child: _buildFAQContent(languageService),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSidebar(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categories',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          ...FAQData.categories.map((category) {
            final isSelected = _selectedCategory == category.titleKey;
            return _buildCategoryItem(category, isSelected, languageService);
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(FAQCategory category, bool isSelected, LanguageService languageService) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          // Filter by category
          setState(() {
            if (isSelected) {
              _selectedCategory = null;
              _filteredItems = FAQData.getAllFAQItems();
            } else {
              _selectedCategory = category.titleKey;
              _filteredItems = FAQData.getAllFAQItems()
                  .where((item) => item.categoryKey == category.titleKey)
                  .toList();
            }
            _expandedItems.clear();
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                category.icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppStrings.getString(
                    category.titleKey,
                    languageService.currentLanguage,
                  ),
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQContent(LanguageService languageService) {
    if (_filteredItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(60),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: AppColors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.getString('faqNoResults', languageService.currentLanguage),
              style: GoogleFonts.cairo(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedCategory != null
                ? AppStrings.getString(_selectedCategory!, languageService.currentLanguage)
                : 'All Questions',
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(_filteredItems.length, (index) {
            final item = _filteredItems[index];
            return FAQItemWidget(
              key: ValueKey('${item.questionKey}_$index'),
              faqItem: item,
              isExpanded: _expandedItems.contains(index),
              onTap: () => _toggleItem(index),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContactSection(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            AppStrings.getString('stillNeedHelp', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'Get in touch with our support team for personalized assistance.',
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 200,
                child: _buildContactButton(
                  Icons.email,
                  AppStrings.getString('contactUs', languageService.currentLanguage),
                  () {
                    Navigator.pushNamed(context, '/contact');
                  },
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 200,
                child: _buildContactButton(
                  Icons.chat,
                  AppStrings.getString('chatNow', languageService.currentLanguage),
                  () {
                    // TODO: Open chat
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildFooter(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppStrings.getString('copyright', languageService.currentLanguage),
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ),
          Row(
            children: [
              _buildFooterLink('Privacy Policy'),
              const SizedBox(width: 24),
              _buildFooterLink('Terms of Service'),
              const SizedBox(width: 24),
              _buildFooterLink('Contact'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return TextButton(
      onPressed: () {},
      child: Text(
        text,
        style: GoogleFonts.cairo(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
} 