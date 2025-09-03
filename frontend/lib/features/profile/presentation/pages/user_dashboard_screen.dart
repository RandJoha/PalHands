import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Core imports

// Shared imports

// User models

// Responsive dashboard widget
import '../widgets/responsive_user_dashboard.dart';

class UserDashboardScreen extends StatefulWidget {
  final int? initialTabIndex;
  const UserDashboardScreen({super.key, this.initialTabIndex});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
    
    if (kDebugMode && widget.initialTabIndex != null) {
      print('🎯 UserDashboardScreen - Initial tab index: ${widget.initialTabIndex}');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ResponsiveUserDashboard(initialIndex: widget.initialTabIndex),
      ),
    );
  }
} 