import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/services/language_service.dart';
import '../../../../shared/widgets/animated_handshake.dart';
import '../../../../shared/widgets/tatreez_pattern.dart';
import '../../data/faq_data.dart';
import 'faq_item_widget.dart';
import 'faq_search_widget.dart';

class MobileFAQsWidget extends StatefulWidget {
  const MobileFAQsWidget({super.key});

  @override
  State<MobileFAQsWidget> createState() => _MobileFAQsWidgetState();
}

class _MobileFAQsWidgetState extends State<MobileFAQsWidget> {
  String _searchQuery = '';
  Set<int> _expandedItems = {};
  List<FAQItem> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = FAQData.getAllFAQItems();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
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
      // Close all expanded items when searching
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
          drawer: _buildDrawer(languageService),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(languageService),
                _buildHeroSection(languageService),
                FAQSearchWidget(
                  searchQuery: _searchQuery,
                  onSearchChanged: _onSearchChanged,
                ),
                _buildFAQContent(languageService),
                _buildContactSection(languageService),
                _buildFooter(languageService),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo and app name
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const AnimatedHandshake(
                  size: 20,
                  color: Colors.white,
                  animationDuration: Duration(milliseconds: 2000),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppStrings.getString('appName', languageService.currentLanguage),
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Language toggle
          _buildLanguageToggle(languageService),
        ],
      ),
    );
  }

  Widget _buildLanguageToggle(LanguageService languageService) {
    return GestureDetector(
      onTap: () {
        languageService.toggleLanguage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          languageService.currentLanguage == 'ar' ? 'EN' : 'العربية',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(LanguageService languageService) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const AnimatedHandshake(
                    size: 30,
                    color: AppColors.primary,
                    animationDuration: Duration(milliseconds: 2000),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.getString('appName', languageService.currentLanguage),
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.home,
            title: AppStrings.getString('home', languageService.currentLanguage),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
            },
            languageService: languageService,
          ),
          _buildDrawerItem(
            icon: Icons.info,
            title: AppStrings.getString('aboutUs', languageService.currentLanguage),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/about');
            },
            languageService: languageService,
          ),
          _buildDrawerItem(
            icon: Icons.cleaning_services,
            title: AppStrings.getString('ourServices', languageService.currentLanguage),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/categories');
            },
            languageService: languageService,
          ),
          _buildDrawerItem(
            icon: Icons.question_answer,
            title: AppStrings.getString('faqs', languageService.currentLanguage),
            onTap: () {
              Navigator.pop(context);
            },
            isSelected: true,
            languageService: languageService,
          ),
          _buildDrawerItem(
            icon: Icons.contact_support,
            title: AppStrings.getString('contactUs', languageService.currentLanguage),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to contact
            },
            languageService: languageService,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
    required LanguageService languageService,
  }) {
    return Directionality(
      textDirection: languageService.textDirection,
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : Colors.black87,
        ),
        title: Text(
          title,
          textAlign: languageService.currentLanguage == 'ar' ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        selected: isSelected,
      ),
    );
  }

  Widget _buildHeroSection(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background Tatreez pattern
          Positioned(
            top: 20,
            right: 20,
            child: Opacity(
              opacity: 0.1,
              child: const TatreezPattern(
                size: 80,
                opacity: 0.3,
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: Opacity(
              opacity: 0.1,
              child: const TatreezPattern(
                size: 60,
                opacity: 0.3,
              ),
            ),
          ),
          // Content
          Column(
            children: [
              const SizedBox(height: 24),
              Text(
                AppStrings.getString('faqPageTitle', languageService.currentLanguage),
                style: GoogleFonts.cairo(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.getString('faqPageDescription', languageService.currentLanguage),
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
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
} 