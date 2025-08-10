import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/services/language_service.dart';
import '../../../../shared/widgets/shared_navigation.dart';
import '../../../../shared/widgets/shared_hero_section.dart';
import '../../data/faq_data.dart';
import 'faq_item_widget.dart';
import 'faq_search_widget.dart';
import '../../../../shared/services/responsive_service.dart';


class MobileFAQsWidget extends StatefulWidget {
  const MobileFAQsWidget({super.key});

  @override
  State<MobileFAQsWidget> createState() => _MobileFAQsWidgetState();
}

class _MobileFAQsWidgetState extends State<MobileFAQsWidget> {
  String _searchQuery = '';
  Set<int> _expandedItems = {};
  List<FAQItem> _filteredItems = [];
  String? _selectedCategory;
  int _selectedIndex = 2; // FAQ tab is selected by default
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _selectedCategory = null; // This represents "All Questions"
    _filteredItems = FAQData.getAllFAQItems();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _selectedCategory = null; // Clear category filter when searching
      if (query.isEmpty) {
        _filteredItems = _selectedCategory != null
            ? FAQData.getAllFAQItems().where((item) => item.categoryKey == _selectedCategory).toList()
            : FAQData.getAllFAQItems();
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
      // Close all expanded items when searching to avoid index mismatches
      _expandedItems.clear();
    });
  }

  void _toggleItem(int index) {
    // Only toggle if the index is valid for the current filtered items
    if (index >= 0 && index < _filteredItems.length) {
      setState(() {
        if (_expandedItems.contains(index)) {
          _expandedItems.remove(index);
        } else {
          _expandedItems.add(index);
        }
      });
    }
  }

  void _selectCategory(String? categoryKey) {
    setState(() {
      _selectedCategory = categoryKey;
      _searchQuery = ''; // Clear search when selecting category
      if (categoryKey == null) {
        _filteredItems = FAQData.getAllFAQItems();
      } else {
        _filteredItems = FAQData.getAllFAQItems().where((item) => item.categoryKey == categoryKey).toList();
      }
      _expandedItems.clear(); // Clear expanded items when category changes
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageService, ResponsiveService>(
      builder: (context, languageService, responsiveService, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final shouldUseMobileLayout = responsiveService.shouldUseMobileLayout(screenWidth);
        
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFFDF5EC),
          drawer: shouldUseMobileLayout ? SharedMobileDrawer(currentPage: 'faqs') : null,
          body: Stack(
            children: [
              // Main content
              Column(
                children: [
                  // Shared Navigation
                  SharedNavigation(
                    currentPage: 'faqs',
                    showAuthButtons: false,
                    onMenuTap: shouldUseMobileLayout ? () {
                      _scaffoldKey.currentState?.openDrawer();
                    } : null,
                    isMobile: shouldUseMobileLayout,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Shared Hero Section
                          SharedHeroSections.faqsHero(
                            languageService: languageService,
                            isMobile: shouldUseMobileLayout,
                          ),
                          FAQSearchWidget(
                            searchQuery: _searchQuery,
                            onSearchChanged: _onSearchChanged,
                          ),
                          _buildCategoryNavigation(languageService),
                          _buildFAQContent(languageService),
                          _buildContactSection(languageService),
                          _buildFooter(languageService),
                          const SizedBox(height: 80), // Space for bottom nav
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          bottomNavigationBar: shouldUseMobileLayout ? _buildBottomNavigationBar(languageService) : null,
        );
      },
    );
  }

  Widget _buildCategoryNavigation(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.getString('faqs', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          // Two-row grid layout for category chips
          Column(
            children: [
              // First row
              Row(
                children: [
                  Expanded(
                    child: _buildCategoryChip(
                      title: AppStrings.getString('allQuestions', languageService.currentLanguage),
                      isSelected: _selectedCategory == null,
                      onTap: () => _selectCategory(null),
                      languageService: languageService,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCategoryChip(
                      title: AppStrings.getString('faqGeneralQuestions', languageService.currentLanguage),
                      isSelected: _selectedCategory == 'faqGeneralQuestions',
                      onTap: () => _selectCategory('faqGeneralQuestions'),
                      languageService: languageService,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Second row
              Row(
                children: [
                  Expanded(
                    child: _buildCategoryChip(
                      title: AppStrings.getString('faqBookingApp', languageService.currentLanguage),
                      isSelected: _selectedCategory == 'faqBookingApp',
                      onTap: () => _selectCategory('faqBookingApp'),
                      languageService: languageService,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCategoryChip(
                      title: AppStrings.getString('faqPayments', languageService.currentLanguage),
                      isSelected: _selectedCategory == 'faqPayments',
                      onTap: () => _selectCategory('faqPayments'),
                      languageService: languageService,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Third row for remaining categories
              Row(
                children: [
                  Expanded(
                    child: _buildCategoryChip(
                      title: AppStrings.getString('faqTrustSafety', languageService.currentLanguage),
                      isSelected: _selectedCategory == 'faqTrustSafety',
                      onTap: () => _selectCategory('faqTrustSafety'),
                      languageService: languageService,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCategoryChip(
                      title: AppStrings.getString('faqServiceProviders', languageService.currentLanguage),
                      isSelected: _selectedCategory == 'faqServiceProviders',
                      onTap: () => _selectCategory('faqServiceProviders'),
                      languageService: languageService,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Fourth row for the last category
              Row(
                children: [
                  Expanded(
                    child: _buildCategoryChip(
                      title: AppStrings.getString('faqLocalization', languageService.currentLanguage),
                      isSelected: _selectedCategory == 'faqLocalization',
                      onTap: () => _selectCategory('faqLocalization'),
                      languageService: languageService,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Empty space to maintain layout
                  const Expanded(child: SizedBox()),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required LanguageService languageService,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
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
              : null,
        ),
        child: Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildFAQContent(LanguageService languageService) {
    if (_filteredItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.getString('faqNoResults', languageService.currentLanguage),
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          // FAQ Items
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            AppStrings.getString('stillNeedHelp', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              _buildContactButton(
                Icons.email,
                AppStrings.getString('contactUs', languageService.currentLanguage),
                () {
                  // TODO: Open email
                },
              ),
              const SizedBox(height: 12),
              _buildContactButton(
                Icons.chat,
                AppStrings.getString('chatNow', languageService.currentLanguage),
                () {
                  // TODO: Open chat
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(IconData icon, String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
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
      ),
    );
  }

  Widget _buildFooter(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Text(
            AppStrings.getString('copyright', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(LanguageService languageService) {
    final items = [
      {'icon': Icons.home, 'label': 'home'},
      {'icon': Icons.info, 'label': 'aboutUs'},
      {'icon': Icons.contact_support, 'label': 'faqs'},
      {'icon': Icons.settings, 'label': 'settings'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == _selectedIndex;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                  
                  // Navigate to respective screens
                  switch (index) {
                    case 0: // Home
                      Navigator.pushReplacementNamed(context, '/home');
                      break;
                    case 1: // About Us
                      Navigator.pushNamed(context, '/about');
                      break;
                    case 2: // FAQs (current page)
                      // Already on FAQs page
                      break;
                    case 3: // Settings
                      // TODO: Navigate to settings page
                      break;
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      color: isSelected ? AppColors.primary : Colors.grey[600],
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.getString(item['label'] as String, languageService.currentLanguage),
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? AppColors.primary : Colors.grey[600],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }


} 