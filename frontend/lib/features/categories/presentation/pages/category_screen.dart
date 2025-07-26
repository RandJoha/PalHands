import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/services/language_service.dart';
import '../../../../shared/widgets/tatreez_pattern.dart';
import 'widgets/mobile_category_widget.dart';
import 'widgets/web_category_widget.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5EC), // Warm beige background
      body: Stack(
        children: [
          // Background Tatreez patterns
          Positioned(
            top: 50,
            left: 20,
            child: TatreezPattern(
              size: 80,
              color: const Color(0xFFC43F20).withOpacity(0.3),
            ),
          ),
          Positioned(
            top: 150,
            right: 30,
            child: TatreezPattern(
              size: 60,
              color: const Color(0xFFC43F20).withOpacity(0.25),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 50,
            child: TatreezPattern(
              size: 70,
              color: const Color(0xFFC43F20).withOpacity(0.2),
            ),
          ),
          Positioned(
            bottom: 200,
            right: 80,
            child: TatreezPattern(
              size: 50,
              color: const Color(0xFFC43F20).withOpacity(0.3),
            ),
          ),
          
          // Main content
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 768) {
                return const WebCategoryWidget();
              } else {
                return const MobileCategoryWidget();
              }
            },
          ),
        ],
      ),
    );
  }
} 