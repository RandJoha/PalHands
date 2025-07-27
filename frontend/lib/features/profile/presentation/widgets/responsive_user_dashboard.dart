import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/auth_service.dart';

// User models
import '../../domain/models/user_menu_item.dart';

class ResponsiveUserDashboard extends StatefulWidget {
  const ResponsiveUserDashboard({super.key});

  @override
  State<ResponsiveUserDashboard> createState() => _ResponsiveUserDashboardState();
}

class _ResponsiveUserDashboardState extends State<ResponsiveUserDashboard> 
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;
  late AnimationController _sidebarAnimationController;
  late Animation<double> _sidebarAnimation;
  late AnimationController _contentAnimationController;
  late Animation<double> _contentAnimation;

  // Menu items - will be localized
  List<UserMenuItem> get _menuItems {
    return [
      UserMenuItem(title: _getLocalizedString('dashboard_home'), icon: Icons.home, index: 0),
      UserMenuItem(title: _getLocalizedString('my_bookings'), icon: Icons.calendar_today, index: 1),
      UserMenuItem(title: _getLocalizedString('chat_messages'), icon: Icons.chat, index: 2),
      UserMenuItem(title: _getLocalizedString('payments'), icon: Icons.payment, index: 3),
      UserMenuItem(title: _getLocalizedString('my_reviews'), icon: Icons.star, index: 4),
      UserMenuItem(title: _getLocalizedString('profile_settings'), icon: Icons.person, index: 5),
      UserMenuItem(title: _getLocalizedString('saved_providers'), icon: Icons.favorite, index: 6),
      UserMenuItem(title: _getLocalizedString('support_help'), icon: Icons.help, index: 7),
      UserMenuItem(title: _getLocalizedString('security'), icon: Icons.security, index: 8),
    ];
  }

  String _getLocalizedString(String key) {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final isArabic = languageService.currentLanguage == 'ar';
    
    switch (key) {
      case 'dashboard_home':
        return isArabic ? 'الرئيسية' : 'Dashboard Home';
      case 'my_bookings':
        return isArabic ? 'حجوزاتي' : 'My Bookings';
      case 'chat_messages':
        return isArabic ? 'المحادثات' : 'Chat / Messages';
      case 'payments':
        return isArabic ? 'المدفوعات' : 'Payments';
      case 'my_reviews':
        return isArabic ? 'تقييماتي' : 'My Reviews';
      case 'profile_settings':
        return isArabic ? 'إعدادات الملف الشخصي' : 'Profile Settings';
      case 'saved_providers':
        return isArabic ? 'المزودين المحفوظين' : 'Saved Providers';
      case 'support_help':
        return isArabic ? 'الدعم والمساعدة' : 'Support / Help';
      case 'security':
        return isArabic ? 'الأمان' : 'Security';
      case 'welcome_back':
        return isArabic ? 'مرحباً بعودتك' : 'Welcome Back';
      case 'upcoming_bookings':
        return isArabic ? 'الحجوزات القادمة' : 'Upcoming Bookings';
      case 'completed':
        return isArabic ? 'مكتمل' : 'Completed';
      case 'reviews':
        return isArabic ? 'التقييمات' : 'Reviews';
      case 'favorites':
        return isArabic ? 'المفضلة' : 'Favorites';
      case 'alerts_notifications':
        return isArabic ? 'التنبيهات والإشعارات' : 'Alerts & Notifications';
      case 'payment_pending':
        return isArabic ? 'دفعة معلقة' : 'Payment Pending';
      case 'booking_reminder':
        return isArabic ? 'تذكير بالحجز' : 'Booking Reminder';
      case 'unread_messages':
        return isArabic ? 'رسائل غير مقروءة' : 'Unread Messages';
      case 'view_all':
        return isArabic ? 'عرض الكل' : 'View All';
      case 'confirmed':
        return isArabic ? 'مؤكد' : 'Confirmed';
      case 'pending':
        return isArabic ? 'معلق' : 'Pending';
      case 'quick_actions':
        return isArabic ? 'إجراءات سريعة' : 'Quick Actions';
      case 'book_again':
        return isArabic ? 'احجز مرة أخرى' : 'Book Again';
      case 'view_calendar':
        return isArabic ? 'عرض التقويم' : 'View Calendar';
      case 'rate_provider':
        return isArabic ? 'قيّم المزود' : 'Rate Provider';
      case 'schedule_new_service':
        return isArabic ? 'جدولة خدمة جديدة' : 'Schedule new service';
      case 'check_availability':
        return isArabic ? 'تحقق من التوفر' : 'Check availability';
      case 'share_experience':
        return isArabic ? 'شارك تجربتك' : 'Share your experience';
      case 'all':
        return isArabic ? 'الكل' : 'All';
      case 'cancelled':
        return isArabic ? 'ملغي' : 'Cancelled';
      case 'provider':
        return isArabic ? 'المزود' : 'Provider';
      case 'date_time':
        return isArabic ? 'التاريخ والوقت' : 'Date & Time';
      case 'address':
        return isArabic ? 'العنوان' : 'Address';
      case 'price':
        return isArabic ? 'السعر' : 'Price';
      case 'cancel':
        return isArabic ? 'إلغاء' : 'Cancel';
      case 'reschedule':
        return isArabic ? 'إعادة جدولة' : 'Reschedule';
      case 'contact':
        return isArabic ? 'تواصل' : 'Contact';
      case 'track':
        return isArabic ? 'تتبع' : 'Track';
      case 'messages':
        return isArabic ? 'الرسائل' : 'Messages';
      case 'type_message':
        return isArabic ? 'اكتب رسالة...' : 'Type a message...';
      case 'total_spent':
        return isArabic ? 'إجمالي الإنفاق' : 'Total Spent';
      case 'this_month':
        return isArabic ? 'هذا الشهر' : 'This Month';
      case 'payment_methods':
        return isArabic ? 'طرق الدفع' : 'Payment Methods';
      case 'add_new':
        return isArabic ? 'إضافة جديد' : 'Add New';
      case 'default':
        return isArabic ? 'افتراضي' : 'Default';
      case 'connected':
        return isArabic ? 'متصل' : 'Connected';
      case 'payment_history':
        return isArabic ? 'سجل المدفوعات' : 'Payment History';
      case 'total_reviews':
        return isArabic ? 'إجمالي التقييمات' : 'Total Reviews';
      case 'average_rating':
        return isArabic ? 'متوسط التقييم' : 'Average Rating';
      case 'edit':
        return isArabic ? 'تعديل' : 'Edit';
      case 'personal_information':
        return isArabic ? 'المعلومات الشخصية' : 'Personal Information';
      case 'full_name':
        return isArabic ? 'الاسم الكامل' : 'Full Name';
      case 'email':
        return isArabic ? 'البريد الإلكتروني' : 'Email';
      case 'phone':
        return isArabic ? 'الهاتف' : 'Phone';
      case 'date_of_birth':
        return isArabic ? 'تاريخ الميلاد' : 'Date of Birth';
      case 'saved_addresses':
        return isArabic ? 'العناوين المحفوظة' : 'Saved Addresses';
      case 'home':
        return isArabic ? 'المنزل' : 'Home';
      case 'work':
        return isArabic ? 'العمل' : 'Work';
      case 'notification_preferences':
        return isArabic ? 'تفضيلات الإشعارات' : 'Notification Preferences';
      case 'email_notifications':
        return isArabic ? 'إشعارات البريد الإلكتروني' : 'Email Notifications';
      case 'push_notifications':
        return isArabic ? 'الإشعارات الفورية' : 'Push Notifications';
      case 'sms_notifications':
        return isArabic ? 'إشعارات الرسائل النصية' : 'SMS Notifications';
      case 'available_now':
        return isArabic ? 'متاح الآن' : 'Available Now';
      case 'recently_booked':
        return isArabic ? 'محجوز مؤخراً' : 'Recently Booked';
      case 'last_booked':
        return isArabic ? 'آخر حجز' : 'Last booked';
      case 'available':
        return isArabic ? 'متاح' : 'Available';
      case 'busy':
        return isArabic ? 'مشغول' : 'Busy';
      case 'need_help':
        return isArabic ? 'تحتاج مساعدة؟' : 'Need Help?';
      case 'we_are_here':
        return isArabic ? 'نحن هنا لمساعدتك على مدار الساعة' : 'We\'re here to help you 24/7';
      case 'quick_help':
        return isArabic ? 'مساعدة سريعة' : 'Quick Help';
      case 'live_chat':
        return isArabic ? 'الدردشة المباشرة' : 'Live Chat';
      case 'submit_ticket':
        return isArabic ? 'إرسال تذكرة' : 'Submit Ticket';
      case 'call_us':
        return isArabic ? 'اتصل بنا' : 'Call Us';
      case 'support_options':
        return isArabic ? 'خيارات الدعم' : 'Support Options';
      case 'browse_faqs':
        return isArabic ? 'تصفح الأسئلة الشائعة' : 'Browse FAQs';
      case 'find_answers':
        return isArabic ? 'ابحث عن إجابات للأسئلة الشائعة' : 'Find answers to common questions';
      case 'submit_support_ticket':
        return isArabic ? 'إرسال تذكرة دعم' : 'Submit Support Ticket';
      case 'create_new_request':
        return isArabic ? 'إنشاء طلب دعم جديد' : 'Create a new support request';
      case 'view_previous_requests':
        return isArabic ? 'عرض الطلبات السابقة' : 'View Previous Requests';
      case 'check_ticket_status':
        return isArabic ? 'تحقق من حالة تذاكرك' : 'Check status of your tickets';
      case 'live_chat_support':
        return isArabic ? 'الدردشة المباشرة مع الدعم' : 'Live Chat Support';
      case 'chat_with_support':
        return isArabic ? 'دردشة مع فريق الدعم' : 'Chat with our support team';
      case 'recent_support_tickets':
        return isArabic ? 'تذاكر الدعم الأخيرة' : 'Recent Support Tickets';
      case 'payment_issue':
        return isArabic ? 'مشكلة في الدفع' : 'Payment Issue';
      case 'booking_cancellation':
        return isArabic ? 'إلغاء الحجز' : 'Booking Cancellation';
      case 'resolved':
        return isArabic ? 'تم الحل' : 'Resolved';
      case 'in_progress':
        return isArabic ? 'قيد التنفيذ' : 'In Progress';
      case 'account_security':
        return isArabic ? 'أمان الحساب' : 'Account Security';
      case 'keep_account_safe':
        return isArabic ? 'حافظ على أمان حسابك' : 'Keep your account safe and secure';
      case 'security_settings':
        return isArabic ? 'إعدادات الأمان' : 'Security Settings';
      case 'change_password':
        return isArabic ? 'تغيير كلمة المرور' : 'Change Password';
      case 'update_password':
        return isArabic ? 'تحديث كلمة مرور حسابك' : 'Update your account password';
      case 'two_factor_auth':
        return isArabic ? 'المصادقة الثنائية' : 'Two-Factor Authentication';
      case 'add_extra_security':
        return isArabic ? 'أضف طبقة أمان إضافية' : 'Add an extra layer of security';
      case 'login_alerts':
        return isArabic ? 'تنبيهات تسجيل الدخول' : 'Login Alerts';
      case 'get_notified':
        return isArabic ? 'احصل على إشعارات بتسجيلات الدخول الجديدة' : 'Get notified of new logins';
      case 'trusted_devices':
        return isArabic ? 'الأجهزة الموثوقة' : 'Trusted Devices';
      case 'manage_devices':
        return isArabic ? 'إدارة أجهزتك الموثوقة' : 'Manage your trusted devices';
      case 'delete_account':
        return isArabic ? 'حذف الحساب' : 'Delete Account';
      case 'permanently_delete':
        return isArabic ? 'حذف حسابك نهائياً' : 'Permanently delete your account';
      case 'login_history':
        return isArabic ? 'سجل تسجيل الدخول' : 'Login History';
      case 'current':
        return isArabic ? 'الحالي' : 'Current';
      case 'active':
        return isArabic ? 'نشط' : 'Active';
      case 'inactive':
        return isArabic ? 'غير نشط' : 'Inactive';
      case 'member_since':
        return isArabic ? 'عضو منذ' : 'Member since';
      case 'upcoming_bookings_this_week':
        return isArabic ? 'لديك 3 حجوزات قادمة هذا الأسبوع' : 'You have 3 upcoming bookings this week';
      case 'view_all_alerts':
        return isArabic ? 'عرض جميع التنبيهات' : 'View All Alerts';
      case 'payment_pending_desc':
        return isArabic ? 'لديك دفعة معلقة للحجز رقم 1234' : 'You have a pending payment for booking #1234';
      case 'booking_reminder_desc':
        return isArabic ? 'خدمة التنظيف مجدولة غداً الساعة 10:00 صباحاً' : 'Your cleaning service is scheduled for tomorrow at 10:00 AM';
      case 'unread_messages_desc':
        return isArabic ? 'لديك رسالتان غير مقروءتين من مزود الخدمة' : 'You have 2 unread messages from your service provider';
      case 'schedule_new_service':
        return isArabic ? 'جدولة خدمة جديدة' : 'Schedule new service';
      case 'check_availability':
        return isArabic ? 'تحقق من التوفر' : 'Check availability';
      case 'share_experience':
        return isArabic ? 'شارك تجربتك' : 'Share your experience';
      case 'book_again':
        return isArabic ? 'احجز مرة أخرى' : 'Book Again';
      case 'view_calendar':
        return isArabic ? 'عرض التقويم' : 'View Calendar';
      case 'rate_provider':
        return isArabic ? 'قيّم المزود' : 'Rate Provider';
      case 'home_cleaning':
        return isArabic ? 'تنظيف المنزل' : 'Home Cleaning';
      case 'elderly_care':
        return isArabic ? 'رعاية المسنين' : 'Elderly Care';
      case 'fatima_al_zahra':
        return isArabic ? 'فاطمة الزهراء' : 'Fatima Al-Zahra';
      case 'mariam_hassan':
        return isArabic ? 'مريم حسن' : 'Mariam Hassan';
      case 'tomorrow_10am':
        return isArabic ? 'غداً، 10:00 صباحاً' : 'Tomorrow, 10:00 AM';
      case 'friday_2pm':
        return isArabic ? 'الجمعة، 2:00 مساءً' : 'Friday, 2:00 PM';
      case 'confirmed':
        return isArabic ? 'مؤكد' : 'Confirmed';
      case 'pending':
        return isArabic ? 'معلق' : 'Pending';
      case 'service':
        return isArabic ? 'الخدمة' : 'Service';
      case 'provider':
        return isArabic ? 'المزود' : 'Provider';
      case 'date_time':
        return isArabic ? 'التاريخ والوقت' : 'Date & Time';
      case 'status':
        return isArabic ? 'الحالة' : 'Status';
      default:
        return key;
    }
  }

  @override
  void initState() {
    super.initState();
    _sidebarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _sidebarAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sidebarAnimationController,
      curve: Curves.easeInOut,
    ));

    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _contentAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeInOut,
    ));

    _contentAnimationController.forward();
  }

  @override
  void dispose() {
    _sidebarAnimationController.dispose();
    _contentAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        
        // Responsive breakpoints
        final isDesktop = screenWidth > 1200;
        final isTablet = screenWidth > 768 && screenWidth <= 1200;
        final isMobile = screenWidth <= 768;

        return Scaffold(
          body: Row(
            children: [
              // Responsive Sidebar
              if (isDesktop || isTablet) _buildResponsiveSidebar(isDesktop, isTablet),
              
              // Main Content Area
              Expanded(
                child: Column(
                  children: [
                    // Responsive App Bar
                    _buildResponsiveAppBar(isMobile, isTablet),
                    
                    // Main Content
                    Expanded(
                      child: _buildResponsiveContent(isMobile, isTablet, isDesktop),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Mobile Bottom Navigation
          bottomNavigationBar: isMobile ? _buildMobileBottomNavigation() : null,
        );
      },
    );
  }

  Widget _buildResponsiveSidebar(bool isDesktop, bool isTablet) {
    final sidebarWidth = isDesktop ? 280.0 : 240.0;
    final collapsedWidth = 70.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isSidebarCollapsed ? collapsedWidth : sidebarWidth,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(
            right: BorderSide(
              color: AppColors.border,
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            // Sidebar Header
            _buildSidebarHeader(isDesktop, isTablet),
            
            // Menu Items
            Expanded(
              child: _buildSidebarMenu(isDesktop, isTablet),
            ),
            
            // Language Toggle
            _buildLanguageToggle(isDesktop, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader(bool isDesktop, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (!_isSidebarCollapsed) ...[
            Icon(
              Icons.handshake,
              color: AppColors.primary,
              size: isDesktop ? 32.0 : 28.0,
            ),
            SizedBox(width: isDesktop ? 16.0 : 12.0),
            Expanded(
              child: Text(
                'PalHands',
                style: GoogleFonts.cairo(
                  fontSize: isDesktop ? 20.0 : 18.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ] else ...[
            Icon(
              Icons.handshake,
              color: AppColors.primary,
              size: 28.0,
            ),
          ],
          if (isDesktop) ...[
            IconButton(
              onPressed: () {
                setState(() {
                  _isSidebarCollapsed = !_isSidebarCollapsed;
                });
              },
              icon: Icon(
                _isSidebarCollapsed ? Icons.chevron_right : Icons.chevron_left,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebarMenu(bool isDesktop, bool isTablet) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return ListView.builder(
          padding: EdgeInsets.symmetric(
            vertical: isDesktop ? 16.0 : 12.0,
            horizontal: isDesktop ? 12.0 : 8.0,
          ),
          itemCount: _menuItems.length,
          itemBuilder: (context, index) {
            final item = _menuItems[index];
            final isSelected = _selectedIndex == index;
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(bottom: isDesktop ? 8.0 : 6.0),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(isDesktop ? 12.0 : 10.0),
                border: isSelected ? Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ) : null,
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 16.0 : 12.0,
                  vertical: isDesktop ? 8.0 : 6.0,
                ),
                leading: Icon(
                  item.icon,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: isDesktop ? 24.0 : 22.0,
                ),
                title: _isSidebarCollapsed ? null : Text(
                  item.title,
                  style: GoogleFonts.cairo(
                    fontSize: isDesktop ? 16.0 : 14.0,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                onTap: () {
                  if (mounted) {
                    setState(() {
                      _selectedIndex = index;
                    });
                    _contentAnimationController.reset();
                    _contentAnimationController.forward();
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildResponsiveAppBar(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16.0 : 24.0,
        vertical: isMobile ? 12.0 : 16.0,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (isMobile) ...[
            IconButton(
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              icon: Icon(
                Icons.menu,
                color: AppColors.textPrimary,
                size: 24.0,
              ),
            ),
            SizedBox(width: 12.0),
          ],
          Expanded(
            child: Consumer<LanguageService>(
              builder: (context, languageService, child) {
                return Text(
                  _menuItems[_selectedIndex].title,
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 20.0 : 24.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                );
              },
            ),
          ),
          // User profile section
          _buildUserProfile(isMobile, isTablet),
        ],
      ),
    );
  }

  Widget _buildUserProfile(bool isMobile, bool isTablet) {
    return Row(
      children: [
        if (!isMobile) ...[
          Icon(
            Icons.notifications_outlined,
            color: AppColors.textSecondary,
            size: isTablet ? 22.0 : 24.0,
          ),
          SizedBox(width: isTablet ? 16.0 : 20.0),
        ],
        Container(
          padding: EdgeInsets.all(isMobile ? 8.0 : 12.0),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(isMobile ? 20.0 : 24.0),
          ),
          child: Icon(
            Icons.person,
            color: AppColors.primary,
            size: isMobile ? 20.0 : 24.0,
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveContent(bool isMobile, bool isTablet, bool isDesktop) {
    return AnimatedBuilder(
      animation: _contentAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.95 + (_contentAnimation.value * 0.05),
          child: Opacity(
            opacity: _contentAnimation.value,
            child: _buildContent(),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardHome();
      case 1:
        return _buildMyBookings();
      case 2:
        return _buildChatMessages();
      case 3:
        return _buildPayments();
      case 4:
        return _buildMyReviews();
      case 5:
        return _buildProfileSettings();
      case 6:
        return _buildSavedProviders();
      case 7:
        return _buildSupportHelp();
      case 8:
        return _buildSecurity();
      default:
        return _buildDashboardHome();
    }
  }

  Widget _buildLanguageToggle(bool isDesktop, bool isTablet) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        final isArabic = languageService.isArabic;
        
        if (_isSidebarCollapsed) {
          return _buildCollapsedLanguageToggle(context, languageService, isArabic, isDesktop, isTablet);
        } else {
          return _buildExpandedLanguageToggle(context, languageService, isArabic, isDesktop, isTablet);
        }
      },
    );
  }

  Widget _buildCollapsedLanguageToggle(BuildContext context, LanguageService languageService, bool isArabic, bool isDesktop, bool isTablet) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => languageService.toggleLanguage(),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Language flag/icon
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isArabic ? AppColors.primary : AppColors.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      isArabic ? 'ع' : 'EN',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedLanguageToggle(BuildContext context, LanguageService languageService, bool isArabic, bool isDesktop, bool isTablet) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => languageService.toggleLanguage(),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Language flag/icon
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isArabic ? AppColors.primary : AppColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      isArabic ? 'ع' : 'EN',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(width: 10),
                
                // Language text
                Expanded(
                  child: Text(
                    isArabic ? 'العربية' : 'English',
                    style: GoogleFonts.cairo(
                      fontSize: isDesktop ? 14 : 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                
                // Toggle icon
                Icon(
                  Icons.language,
                  color: AppColors.primary,
                  size: isDesktop ? 18 : 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileBottomNavigation() {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          onTap: (index) {
            if (mounted) {
              setState(() {
                _selectedIndex = index;
              });
              _contentAnimationController.reset();
              _contentAnimationController.forward();
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 24),
              label: _getLocalizedString('home'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today, size: 24),
              label: _getLocalizedString('my_bookings'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat, size: 24),
              label: _getLocalizedString('messages'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person, size: 24),
              label: _getLocalizedString('profile_settings'),
            ),
          ],
        );
      },
    );
  }

  // Content sections with responsive layouts
  Widget _buildDashboardHome() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= 768;
        final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _buildWelcomeSection(isMobile, isTablet),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              
              // Stats Cards
              _buildStatsCards(isMobile, isTablet, constraints.maxWidth),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              
              // Alerts Section
              _buildAlertsSection(isMobile, isTablet),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              
              // Upcoming Bookings
              _buildUpcomingBookings(isMobile, isTablet),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              
              // Quick Actions
              _buildQuickActions(isMobile, isTablet, constraints.maxWidth),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection(bool isMobile, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 16.0 : 20.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getLocalizedString('welcome_back'),
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 18.0 : 24.0,
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  'Ahmed Hassan',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 24.0 : 32.0,
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8.0),
                Text(
                  _getLocalizedString('upcoming_bookings_this_week'),
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14.0 : 16.0,
                    color: AppColors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.person,
            color: AppColors.white,
            size: isMobile ? 48.0 : 64.0,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(bool isMobile, bool isTablet, double screenWidth) {
    final stats = [
      {'icon': Icons.calendar_today, 'value': '3', 'label': _getLocalizedString('upcoming_bookings'), 'color': AppColors.primary},
      {'icon': Icons.check_circle, 'value': '12', 'label': _getLocalizedString('completed'), 'color': AppColors.success},
      {'icon': Icons.star, 'value': '8', 'label': _getLocalizedString('reviews'), 'color': AppColors.warning},
      {'icon': Icons.favorite, 'value': '5', 'label': _getLocalizedString('favorites'), 'color': AppColors.error},
    ];

    return Wrap(
      spacing: isMobile ? 12.0 : 16.0,
      runSpacing: isMobile ? 12.0 : 16.0,
      children: stats.map((stat) {
        final cardWidth = isMobile 
            ? (screenWidth - 48) / 2 
            : isTablet 
                ? (screenWidth - 96) / 4 
                : (screenWidth - 144) / 4;
        
        return Container(
          width: cardWidth,
          padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                stat['icon'] as IconData,
                color: stat['color'] as Color,
                size: isMobile ? 32.0 : 40.0,
              ),
              SizedBox(height: isMobile ? 8.0 : 12.0),
              Text(
                stat['value'] as String,
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 24.0 : 32.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4.0),
              Text(
                stat['label'] as String,
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 14.0 : 16.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAlertsSection(bool isMobile, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getLocalizedString('alerts_notifications'),
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 18.0 : 20.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isMobile ? 12.0 : 16.0),
          _buildAlertItem(
            Icons.payment,
            _getLocalizedString('payment_pending'),
            _getLocalizedString('payment_pending_desc'),
            AppColors.warning,
            isMobile,
          ),
          SizedBox(height: 8.0),
          _buildAlertItem(
            Icons.access_time,
            _getLocalizedString('booking_reminder'),
            _getLocalizedString('booking_reminder_desc'),
            AppColors.info,
            isMobile,
          ),
          SizedBox(height: 8.0),
          _buildAlertItem(
            Icons.message,
            _getLocalizedString('unread_messages'),
            _getLocalizedString('unread_messages_desc'),
            AppColors.primary,
            isMobile,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(IconData icon, String title, String message, Color color, bool isMobile) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: isMobile ? 20.0 : 24.0,
        ),
        SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 14.0 : 16.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                message,
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 12.0 : 14.0,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingBookings(bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getLocalizedString('upcoming_bookings'),
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 18.0 : 20.0,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                _getLocalizedString('view_all'),
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 14.0 : 16.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 12.0 : 16.0),
        _buildBookingCard(
          _getLocalizedString('home_cleaning'),
          _getLocalizedString('fatima_al_zahra'),
          _getLocalizedString('tomorrow_10am'),
          _getLocalizedString('confirmed'),
          AppColors.success,
          isMobile,
        ),
        SizedBox(height: 12.0),
        _buildBookingCard(
          _getLocalizedString('elderly_care'),
          _getLocalizedString('mariam_hassan'),
          _getLocalizedString('friday_2pm'),
          _getLocalizedString('pending'),
          AppColors.warning,
          isMobile,
        ),
      ],
    );
  }

  Widget _buildBookingCard(String service, String provider, String time, String status, Color statusColor, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 48.0 : 56.0,
            height: isMobile ? 48.0 : 56.0,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isMobile ? 24.0 : 28.0),
            ),
            child: Icon(
              Icons.person,
              color: AppColors.primary,
              size: isMobile ? 24.0 : 28.0,
            ),
          ),
          SizedBox(width: isMobile ? 12.0 : 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service,
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 16.0 : 18.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  provider,
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14.0 : 16.0,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  time,
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 12.0 : 14.0,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8.0 : 12.0,
              vertical: isMobile ? 4.0 : 6.0,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isMobile ? 8.0 : 12.0),
            ),
            child: Text(
              status,
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 12.0 : 14.0,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isMobile, bool isTablet, double screenWidth) {
    final actions = [
      {'icon': Icons.calendar_today, 'title': _getLocalizedString('book_again'), 'subtitle': _getLocalizedString('schedule_new_service'), 'color': AppColors.primary},
      {'icon': Icons.calendar_month, 'title': _getLocalizedString('view_calendar'), 'subtitle': _getLocalizedString('check_availability'), 'color': AppColors.info},
      {'icon': Icons.star, 'title': _getLocalizedString('rate_provider'), 'subtitle': _getLocalizedString('share_experience'), 'color': AppColors.warning},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getLocalizedString('quick_actions'),
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 18.0 : 20.0,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: isMobile ? 12.0 : 16.0),
        Wrap(
          spacing: isMobile ? 12.0 : 16.0,
          runSpacing: isMobile ? 12.0 : 16.0,
          children: actions.map((action) {
            final cardWidth = isMobile 
                ? (screenWidth - 48) / 2 
                : (screenWidth - 96) / 3;
            
            return Container(
              width: cardWidth,
              padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    action['icon'] as IconData,
                    color: action['color'] as Color,
                    size: isMobile ? 32.0 : 40.0,
                  ),
                  SizedBox(height: isMobile ? 8.0 : 12.0),
                  Text(
                    action['title'] as String,
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 16.0 : 18.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    action['subtitle'] as String,
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 12.0 : 14.0,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Content sections with responsive layouts
  Widget _buildMyBookings() => _buildMyBookingsContent();
  Widget _buildChatMessages() => _buildChatMessagesContent();
  Widget _buildPayments() => _buildPaymentsContent();
  Widget _buildMyReviews() => _buildMyReviewsContent();
  Widget _buildProfileSettings() => _buildProfileSettingsContent();
  Widget _buildSavedProviders() => _buildSavedProvidersContent();
  Widget _buildSupportHelp() => _buildSupportHelpContent();
  Widget _buildSecurity() => _buildSecurityContent();

  // My Bookings Section
  Widget _buildMyBookingsContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= 768;
        final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Tabs
              _buildBookingFilters(isMobile, isTablet),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              
              // Bookings List
              _buildBookingsList(isMobile, isTablet, constraints.maxWidth),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookingFilters(bool isMobile, bool isTablet) {
    final filters = ['All', 'Upcoming', 'Completed', 'Cancelled'];
    int selectedFilter = 0; // This would be state in a real app
    
    return Wrap(
      spacing: isMobile ? 8.0 : 12.0,
      children: filters.asMap().entries.map((entry) {
        final index = entry.key;
        final filter = entry.value;
        final isSelected = selectedFilter == index;
        
        return FilterChip(
          label: Text(
            filter,
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 14.0 : 16.0,
              fontWeight: FontWeight.w500,
              color: isSelected ? AppColors.white : AppColors.textPrimary,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            // Handle filter selection
          },
          backgroundColor: AppColors.white,
          selectedColor: AppColors.primary,
          checkmarkColor: AppColors.white,
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBookingsList(bool isMobile, bool isTablet, double screenWidth) {
    final bookings = [
      {
        'service': 'Home Cleaning',
        'provider': 'Fatima Al-Zahra',
        'date': 'Tomorrow, 10:00 AM',
        'status': 'Confirmed',
        'statusColor': AppColors.success,
        'price': '₪150',
        'address': '123 Main St, Jerusalem',
      },
      {
        'service': 'Elderly Care',
        'provider': 'Mariam Hassan',
        'date': 'Friday, 2:00 PM',
        'status': 'Pending',
        'statusColor': AppColors.warning,
        'price': '₪200',
        'address': '456 Oak Ave, Tel Aviv',
      },
      {
        'service': 'Babysitting',
        'provider': 'Aisha Mohammed',
        'date': 'Yesterday, 3:00 PM',
        'status': 'Completed',
        'statusColor': AppColors.info,
        'price': '₪120',
        'address': '789 Pine Rd, Haifa',
      },
    ];

    return Column(
      children: bookings.map((booking) {
        return Container(
          margin: EdgeInsets.only(bottom: isMobile ? 16.0 : 20.0),
          child: _buildDetailedBookingCard(booking, isMobile, isTablet, screenWidth),
        );
      }).toList(),
    );
  }

  Widget _buildDetailedBookingCard(Map<String, dynamic> booking, bool isMobile, bool isTablet, double screenWidth) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with service and status
          Row(
            children: [
              Expanded(
                child: Text(
                  booking['service'],
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 18.0 : 20.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8.0 : 12.0,
                  vertical: isMobile ? 4.0 : 6.0,
                ),
                decoration: BoxDecoration(
                  color: booking['statusColor'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isMobile ? 8.0 : 12.0),
                ),
                child: Text(
                  booking['status'],
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 12.0 : 14.0,
                    fontWeight: FontWeight.w600,
                    color: booking['statusColor'],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12.0 : 16.0),
          
          // Booking details
          _buildBookingDetailRow(
            Icons.person,
            'Provider',
            booking['provider'],
            isMobile,
          ),
          SizedBox(height: 8.0),
          _buildBookingDetailRow(
            Icons.calendar_today,
            'Date & Time',
            booking['date'],
            isMobile,
          ),
          SizedBox(height: 8.0),
          _buildBookingDetailRow(
            Icons.location_on,
            'Address',
            booking['address'],
            isMobile,
          ),
          SizedBox(height: 8.0),
          _buildBookingDetailRow(
            Icons.attach_money,
            'Price',
            booking['price'],
            isMobile,
          ),
          SizedBox(height: isMobile ? 16.0 : 20.0),
          
          // Action buttons
          _buildBookingActions(isMobile, isTablet, screenWidth),
        ],
      ),
    );
  }

  Widget _buildBookingDetailRow(IconData icon, String label, String value, bool isMobile) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.textSecondary,
          size: isMobile ? 16.0 : 18.0,
        ),
        SizedBox(width: 8.0),
        Text(
          '$label: ',
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 14.0 : 16.0,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 14.0 : 16.0,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingActions(bool isMobile, bool isTablet, double screenWidth) {
    final actions = [
      {'icon': Icons.cancel, 'label': 'Cancel', 'color': AppColors.error},
      {'icon': Icons.schedule, 'label': 'Reschedule', 'color': AppColors.warning},
      {'icon': Icons.chat, 'label': 'Contact', 'color': AppColors.primary},
      {'icon': Icons.location_on, 'label': 'Track', 'color': AppColors.info},
    ];

    return Wrap(
      spacing: isMobile ? 8.0 : 12.0,
      runSpacing: isMobile ? 8.0 : 12.0,
      children: actions.map((action) {
        return OutlinedButton.icon(
          onPressed: () {
            // Handle action
          },
          icon: Icon(
            action['icon'] as IconData,
            size: isMobile ? 16.0 : 18.0,
            color: action['color'] as Color,
          ),
          label: Text(
            action['label'] as String,
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 12.0 : 14.0,
              fontWeight: FontWeight.w500,
              color: action['color'] as Color,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: action['color'] as Color, width: 1),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12.0 : 16.0,
              vertical: isMobile ? 8.0 : 10.0,
            ),
          ),
        );
      }).toList(),
    );
  }

  // Chat Messages Section
  Widget _buildChatMessagesContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= 768;
        final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
        
        return Row(
          children: [
            // Chat List (hidden on mobile)
            if (!isMobile) ...[
              Container(
                width: isTablet ? 300.0 : 350.0,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border(
                    right: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: _buildChatList(isMobile, isTablet),
              ),
            ],
            
            // Chat Messages Area
            Expanded(
              child: _buildChatMessagesArea(isMobile, isTablet),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChatList(bool isMobile, bool isTablet) {
    final chats = [
      {
        'name': 'Fatima Al-Zahra',
        'service': 'Home Cleaning',
        'lastMessage': 'I will arrive in 10 minutes',
        'time': '2 min ago',
        'unread': 2,
        'isOnline': true,
      },
      {
        'name': 'Mariam Hassan',
        'service': 'Elderly Care',
        'lastMessage': 'Thank you for the booking',
        'time': '1 hour ago',
        'unread': 0,
        'isOnline': false,
      },
      {
        'name': 'Aisha Mohammed',
        'service': 'Babysitting',
        'lastMessage': 'The children are doing great',
        'time': '3 hours ago',
        'unread': 1,
        'isOnline': true,
      },
    ];

    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(isTablet ? 16.0 : 20.0),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.chat,
                color: AppColors.primary,
                size: isTablet ? 24.0 : 28.0,
              ),
              SizedBox(width: 12.0),
              Text(
                'Messages',
                style: GoogleFonts.cairo(
                  fontSize: isTablet ? 18.0 : 20.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        
        // Chat list
        Expanded(
          child: ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return _buildChatListItem(chat, isMobile, isTablet);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatListItem(Map<String, dynamic> chat, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 12.0 : 16.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border.withOpacity(0.5), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: isTablet ? 48.0 : 56.0,
                height: isTablet ? 48.0 : 56.0,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isTablet ? 24.0 : 28.0),
                ),
                child: Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: isTablet ? 24.0 : 28.0,
                ),
              ),
              if (chat['isOnline'])
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: isTablet ? 12.0 : 14.0,
                    height: isTablet ? 12.0 : 14.0,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(isTablet ? 6.0 : 7.0),
                      border: Border.all(color: AppColors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 12.0),
          
          // Chat info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        chat['name'],
                        style: GoogleFonts.cairo(
                          fontSize: isTablet ? 16.0 : 18.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      chat['time'],
                      style: GoogleFonts.cairo(
                        fontSize: isTablet ? 12.0 : 14.0,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.0),
                Text(
                  chat['service'],
                  style: GoogleFonts.cairo(
                    fontSize: isTablet ? 12.0 : 14.0,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 4.0),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        chat['lastMessage'],
                        style: GoogleFonts.cairo(
                          fontSize: isTablet ? 14.0 : 16.0,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (chat['unread'] > 0)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          chat['unread'].toString(),
                          style: GoogleFonts.cairo(
                            fontSize: isTablet ? 10.0 : 12.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessagesArea(bool isMobile, bool isTablet) {
    return Column(
      children: [
        // Chat header
        Container(
          padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              if (isMobile) ...[
                IconButton(
                  onPressed: () {
                    // Show chat list on mobile
                  },
                  icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                ),
                SizedBox(width: 12.0),
              ],
              Container(
                width: isMobile ? 40.0 : 48.0,
                height: isMobile ? 40.0 : 48.0,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isMobile ? 20.0 : 24.0),
                ),
                child: Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: isMobile ? 20.0 : 24.0,
                ),
              ),
              SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fatima Al-Zahra',
                      style: GoogleFonts.cairo(
                        fontSize: isMobile ? 16.0 : 18.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Home Cleaning',
                      style: GoogleFonts.cairo(
                        fontSize: isMobile ? 12.0 : 14.0,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.circle,
                color: AppColors.success,
                size: isMobile ? 12.0 : 14.0,
              ),
            ],
          ),
        ),
        
        // Messages area
        Expanded(
          child: Container(
            color: AppColors.background,
            child: _buildMessagesList(isMobile, isTablet),
          ),
        ),
        
        // Message input
        _buildMessageInput(isMobile, isTablet),
      ],
    );
  }

  Widget _buildMessagesList(bool isMobile, bool isTablet) {
    final messages = [
      {
        'text': 'Hello! I will arrive in 10 minutes',
        'isMe': false,
        'time': '10:30 AM',
      },
      {
        'text': 'Perfect, thank you!',
        'isMe': true,
        'time': '10:31 AM',
      },
      {
        'text': 'I\'m here now',
        'isMe': false,
        'time': '10:40 AM',
      },
    ];

    return ListView.builder(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(message, isMobile, isTablet);
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMobile, bool isTablet) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: message['isMe'] ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message['isMe']) ...[
            Container(
              width: isMobile ? 32.0 : 36.0,
              height: isMobile ? 32.0 : 36.0,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isMobile ? 16.0 : 18.0),
              ),
              child: Icon(
                Icons.person,
                color: AppColors.primary,
                size: isMobile ? 16.0 : 18.0,
              ),
            ),
            SizedBox(width: 8.0),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
              decoration: BoxDecoration(
                color: message['isMe'] ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(isMobile ? 16.0 : 20.0),
                border: message['isMe'] ? null : Border.all(color: AppColors.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['text'],
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 14.0 : 16.0,
                      fontWeight: FontWeight.w400,
                      color: message['isMe'] ? AppColors.white : AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    message['time'],
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 10.0 : 12.0,
                      fontWeight: FontWeight.w400,
                      color: message['isMe'] ? AppColors.white.withOpacity(0.7) : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              // Attach file
            },
            icon: Icon(Icons.attach_file, color: AppColors.textSecondary),
          ),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: GoogleFonts.cairo(
                  fontSize: isMobile ? 14.0 : 16.0,
                  color: AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 20.0 : 24.0),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16.0 : 20.0,
                  vertical: isMobile ? 12.0 : 16.0,
                ),
              ),
            ),
          ),
          SizedBox(width: 8.0),
          IconButton(
            onPressed: () {
              // Send message
            },
            icon: Icon(Icons.send, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  // Payments Section
  Widget _buildPaymentsContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= 768;
        final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Summary
              _buildPaymentSummary(isMobile, isTablet, constraints.maxWidth),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              
              // Payment Methods
              _buildPaymentMethods(isMobile, isTablet),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              
              // Payment History
              _buildPaymentHistory(isMobile, isTablet),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentSummary(bool isMobile, bool isTablet, double screenWidth) {
    final summaryCards = [
      {'title': 'Total Spent', 'amount': '₪2,450', 'icon': Icons.account_balance_wallet, 'color': AppColors.primary},
      {'title': 'This Month', 'amount': '₪580', 'icon': Icons.calendar_today, 'color': AppColors.success},
      {'title': 'Pending', 'amount': '₪150', 'icon': Icons.pending, 'color': AppColors.warning},
    ];

    return Wrap(
      spacing: isMobile ? 12.0 : 16.0,
      runSpacing: isMobile ? 12.0 : 16.0,
      children: summaryCards.map((card) {
        final cardWidth = isMobile 
            ? (screenWidth - 48) / 2 
            : (screenWidth - 96) / 3;
        
        return Container(
          width: cardWidth,
          padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                card['icon'] as IconData,
                color: card['color'] as Color,
                size: isMobile ? 32.0 : 40.0,
              ),
              SizedBox(height: isMobile ? 8.0 : 12.0),
              Text(
                card['amount'] as String,
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 24.0 : 32.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4.0),
              Text(
                card['title'] as String,
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 14.0 : 16.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentMethods(bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Payment Methods',
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 18.0 : 20.0,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.add, size: isMobile ? 16.0 : 18.0),
              label: Text(
                'Add New',
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 14.0 : 16.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12.0 : 16.0,
                  vertical: isMobile ? 8.0 : 10.0,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 12.0 : 16.0),
        
        // Payment methods list
        _buildPaymentMethodCard(
          'Visa ending in 1234',
          'Default',
          Icons.credit_card,
          AppColors.primary,
          true,
          isMobile,
        ),
        SizedBox(height: 12.0),
        _buildPaymentMethodCard(
          'PayPal',
          'Connected',
          Icons.payment,
          AppColors.info,
          false,
          isMobile,
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(String title, String status, IconData icon, Color color, bool isDefault, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
        border: Border.all(
          color: isDefault ? AppColors.primary : AppColors.border,
          width: isDefault ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: isMobile ? 24.0 : 28.0,
          ),
          SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 16.0 : 18.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  status,
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14.0 : 16.0,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isDefault)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Default',
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 12.0 : 14.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory(bool isMobile, bool isTablet) {
    final payments = [
      {
        'service': 'Home Cleaning',
        'provider': 'Fatima Al-Zahra',
        'amount': '₪150',
        'date': 'Today, 10:00 AM',
        'status': 'Completed',
        'statusColor': AppColors.success,
      },
      {
        'service': 'Elderly Care',
        'provider': 'Mariam Hassan',
        'amount': '₪200',
        'date': 'Yesterday, 2:00 PM',
        'status': 'Pending',
        'statusColor': AppColors.warning,
      },
      {
        'service': 'Babysitting',
        'provider': 'Aisha Mohammed',
        'amount': '₪120',
        'date': '2 days ago',
        'status': 'Completed',
        'statusColor': AppColors.success,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment History',
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 18.0 : 20.0,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: isMobile ? 12.0 : 16.0),
        
        ...payments.map((payment) {
          return Container(
            margin: EdgeInsets.only(bottom: 12.0),
            child: _buildPaymentHistoryCard(payment, isMobile, isTablet),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPaymentHistoryCard(Map<String, dynamic> payment, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment['service'],
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 16.0 : 18.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  payment['provider'],
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14.0 : 16.0,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  payment['date'],
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 12.0 : 14.0,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                payment['amount'],
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 18.0 : 20.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4.0),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: payment['statusColor'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  payment['status'],
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 12.0 : 14.0,
                    fontWeight: FontWeight.w600,
                    color: payment['statusColor'],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // My Reviews Section
  Widget _buildMyReviewsContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= 768;
        final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reviews Summary
              _buildReviewsSummary(isMobile, isTablet, constraints.maxWidth),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              
              // My Reviews List
              _buildMyReviewsList(isMobile, isTablet),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewsSummary(bool isMobile, bool isTablet, double screenWidth) {
    final summaryCards = [
      {'title': 'Total Reviews', 'count': '8', 'icon': Icons.rate_review, 'color': AppColors.primary},
      {'title': 'Average Rating', 'count': '4.8', 'icon': Icons.star, 'color': AppColors.warning},
      {'title': 'This Month', 'count': '3', 'icon': Icons.calendar_today, 'color': AppColors.success},
    ];

    return Wrap(
      spacing: isMobile ? 12.0 : 16.0,
      runSpacing: isMobile ? 12.0 : 16.0,
      children: summaryCards.map((card) {
        final cardWidth = isMobile 
            ? (screenWidth - 48) / 2 
            : (screenWidth - 96) / 3;
        
        return Container(
          width: cardWidth,
          padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                card['icon'] as IconData,
                color: card['color'] as Color,
                size: isMobile ? 32.0 : 40.0,
              ),
              SizedBox(height: isMobile ? 8.0 : 12.0),
              Text(
                card['count'] as String,
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 24.0 : 32.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4.0),
              Text(
                card['title'] as String,
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 14.0 : 16.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMyReviewsList(bool isMobile, bool isTablet) {
    final reviews = [
      {
        'provider': 'Fatima Al-Zahra',
        'service': 'Home Cleaning',
        'rating': 5.0,
        'comment': 'Excellent service! Very professional and thorough cleaning.',
        'date': '2 days ago',
        'canEdit': true,
      },
      {
        'provider': 'Mariam Hassan',
        'service': 'Elderly Care',
        'rating': 4.5,
        'comment': 'Very caring and attentive. Highly recommended.',
        'date': '1 week ago',
        'canEdit': false,
      },
      {
        'provider': 'Aisha Mohammed',
        'service': 'Babysitting',
        'rating': 5.0,
        'comment': 'Great with kids! Very reliable and trustworthy.',
        'date': '2 weeks ago',
        'canEdit': false,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Reviews',
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 18.0 : 20.0,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: isMobile ? 12.0 : 16.0),
        
        ...reviews.map((review) {
          return Container(
            margin: EdgeInsets.only(bottom: 16.0),
            child: _buildReviewCard(review, isMobile, isTablet),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['provider'],
                      style: GoogleFonts.cairo(
                        fontSize: isMobile ? 16.0 : 18.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      review['service'],
                      style: GoogleFonts.cairo(
                        fontSize: isMobile ? 14.0 : 16.0,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (review['canEdit'])
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Edit',
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 14.0 : 16.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.0),
          
          // Rating stars
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < review['rating'] ? Icons.star : Icons.star_border,
                color: AppColors.ratingFilled,
                size: isMobile ? 20.0 : 24.0,
              );
            }),
          ),
          SizedBox(height: 8.0),
          
          Text(
            review['comment'],
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 14.0 : 16.0,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.0),
          
          Text(
            review['date'],
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 12.0 : 14.0,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // Profile Settings Section
  Widget _buildProfileSettingsContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= 768;
        final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              _buildProfileHeader(isMobile, isTablet),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              
              // Profile Form
              _buildProfileForm(isMobile, isTablet),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              
              // Addresses
              _buildAddressesSection(isMobile, isTablet),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              
              // Notifications
              _buildNotificationsSection(isMobile, isTablet),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 16.0 : 20.0),
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 80.0 : 100.0,
            height: isMobile ? 80.0 : 100.0,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(isMobile ? 40.0 : 50.0),
            ),
            child: Icon(
              Icons.person,
              color: AppColors.white,
              size: isMobile ? 40.0 : 50.0,
            ),
          ),
          SizedBox(width: isMobile ? 16.0 : 20.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ahmed Hassan',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 24.0 : 28.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  'Member since January 2024',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14.0 : 16.0,
                    fontWeight: FontWeight.w400,
                    color: AppColors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.edit,
              color: AppColors.white,
              size: isMobile ? 24.0 : 28.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 18.0 : 20.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isMobile ? 16.0 : 20.0),
          
          _buildFormField('Full Name', 'Ahmed Hassan', Icons.person, isMobile),
          SizedBox(height: 12.0),
          _buildFormField('Email', 'ahmed@example.com', Icons.email, isMobile),
          SizedBox(height: 12.0),
          _buildFormField('Phone', '+972 50 123 4567', Icons.phone, isMobile),
          SizedBox(height: 12.0),
          _buildFormField('Date of Birth', '15 March 1985', Icons.calendar_today, isMobile),
        ],
      ),
    );
  }

  Widget _buildFormField(String label, String value, IconData icon, bool isMobile) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.textSecondary,
          size: isMobile ? 20.0 : 24.0,
        ),
        SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 14.0 : 16.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 16.0 : 18.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.edit,
            color: AppColors.primary,
            size: isMobile ? 20.0 : 24.0,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressesSection(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saved Addresses',
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 18.0 : 20.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.add, size: isMobile ? 16.0 : 18.0),
                label: Text(
                  'Add New',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14.0 : 16.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12.0 : 16.0,
                    vertical: isMobile ? 8.0 : 10.0,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12.0 : 16.0),
          
          _buildAddressCard('Home', '123 Main Street, Jerusalem', true, isMobile),
          SizedBox(height: 12.0),
          _buildAddressCard('Work', '456 Business Ave, Tel Aviv', false, isMobile),
        ],
      ),
    );
  }

  Widget _buildAddressCard(String label, String address, bool isDefault, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(isMobile ? 8.0 : 12.0),
        border: Border.all(
          color: isDefault ? AppColors.primary : AppColors.border,
          width: isDefault ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: AppColors.primary,
            size: isMobile ? 20.0 : 24.0,
          ),
          SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 16.0 : 18.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  address,
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14.0 : 16.0,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isDefault)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Default',
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 12.0 : 14.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notification Preferences',
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 18.0 : 20.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isMobile ? 12.0 : 16.0),
          
          _buildNotificationToggle('Email Notifications', true, isMobile),
          SizedBox(height: 8.0),
          _buildNotificationToggle('Push Notifications', true, isMobile),
          SizedBox(height: 8.0),
          _buildNotificationToggle('SMS Notifications', false, isMobile),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle(String label, bool isEnabled, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 16.0 : 18.0,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        Switch(
          value: isEnabled,
          onChanged: (value) {
            // Handle toggle
          },
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  // Saved Providers Section
  Widget _buildSavedProvidersContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= 768;
        final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Providers Summary
              _buildProvidersSummary(isMobile, isTablet, constraints.maxWidth),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              
              // Saved Providers List
              _buildSavedProvidersList(isMobile, isTablet),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProvidersSummary(bool isMobile, bool isTablet, double screenWidth) {
    final summaryCards = [
      {'title': 'Total Saved', 'count': '5', 'icon': Icons.favorite, 'color': AppColors.error},
      {'title': 'Available Now', 'count': '3', 'icon': Icons.check_circle, 'color': AppColors.success},
      {'title': 'Recently Booked', 'count': '2', 'icon': Icons.calendar_today, 'color': AppColors.primary},
    ];

    return Wrap(
      spacing: isMobile ? 12.0 : 16.0,
      runSpacing: isMobile ? 12.0 : 16.0,
      children: summaryCards.map((card) {
        final cardWidth = isMobile 
            ? (screenWidth - 48) / 2 
            : (screenWidth - 96) / 3;
        
        return Container(
          width: cardWidth,
          padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                card['icon'] as IconData,
                color: card['color'] as Color,
                size: isMobile ? 32.0 : 40.0,
              ),
              SizedBox(height: isMobile ? 8.0 : 12.0),
              Text(
                card['count'] as String,
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 24.0 : 32.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4.0),
              Text(
                card['title'] as String,
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 14.0 : 16.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSavedProvidersList(bool isMobile, bool isTablet) {
    final providers = [
      {
        'name': 'Fatima Al-Zahra',
        'service': 'Home Cleaning',
        'rating': 4.8,
        'price': '₪150',
        'isAvailable': true,
        'lastBooked': '2 days ago',
      },
      {
        'name': 'Mariam Hassan',
        'service': 'Elderly Care',
        'rating': 4.9,
        'price': '₪200',
        'isAvailable': true,
        'lastBooked': '1 week ago',
      },
      {
        'name': 'Aisha Mohammed',
        'service': 'Babysitting',
        'rating': 4.7,
        'price': '₪120',
        'isAvailable': false,
        'lastBooked': '3 weeks ago',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved Providers',
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 18.0 : 20.0,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: isMobile ? 12.0 : 16.0),
        
        ...providers.map((provider) {
          return Container(
            margin: EdgeInsets.only(bottom: 16.0),
            child: _buildSavedProviderCard(provider, isMobile, isTablet),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSavedProviderCard(Map<String, dynamic> provider, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 60.0 : 70.0,
            height: isMobile ? 60.0 : 70.0,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isMobile ? 30.0 : 35.0),
            ),
            child: Icon(
              Icons.person,
              color: AppColors.primary,
              size: isMobile ? 30.0 : 35.0,
            ),
          ),
          SizedBox(width: isMobile ? 12.0 : 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider['name'],
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 16.0 : 18.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  provider['service'],
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14.0 : 16.0,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8.0),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: AppColors.ratingFilled,
                      size: isMobile ? 16.0 : 18.0,
                    ),
                    SizedBox(width: 4.0),
                    Text(
                      provider['rating'].toString(),
                      style: GoogleFonts.cairo(
                        fontSize: isMobile ? 14.0 : 16.0,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(width: 16.0),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: provider['isAvailable'] ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        provider['isAvailable'] ? 'Available' : 'Busy',
                        style: GoogleFonts.cairo(
                          fontSize: isMobile ? 12.0 : 14.0,
                          fontWeight: FontWeight.w600,
                          color: provider['isAvailable'] ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.0),
                Text(
                  'Last booked: ${provider['lastBooked']}',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 12.0 : 14.0,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                provider['price'],
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 18.0 : 20.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 8.0),
              ElevatedButton(
                onPressed: provider['isAvailable'] ? () {
                  // Handle book again
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12.0 : 16.0,
                    vertical: isMobile ? 8.0 : 10.0,
                  ),
                ),
                child: Text(
                  'Book Again',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 12.0 : 14.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Support Help Section
  Widget _buildSupportHelpContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= 768;
        final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Support Header
              _buildSupportHeader(isMobile, isTablet),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              
              // Quick Help
              _buildQuickHelp(isMobile, isTablet, constraints.maxWidth),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              
              // Support Options
              _buildSupportOptions(isMobile, isTablet),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              
              // Recent Tickets
              _buildRecentTickets(isMobile, isTablet),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSupportHeader(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.info, AppColors.info.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 16.0 : 20.0),
      ),
      child: Row(
        children: [
          Icon(
            Icons.support_agent,
            color: AppColors.white,
            size: isMobile ? 48.0 : 64.0,
          ),
          SizedBox(width: isMobile ? 16.0 : 20.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need Help?',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 24.0 : 28.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  'We\'re here to help you 24/7',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14.0 : 16.0,
                    fontWeight: FontWeight.w400,
                    color: AppColors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickHelp(bool isMobile, bool isTablet, double screenWidth) {
    final helpItems = [
      {'title': 'FAQs', 'icon': Icons.help_outline, 'color': AppColors.primary},
      {'title': 'Live Chat', 'icon': Icons.chat, 'color': AppColors.success},
      {'title': 'Submit Ticket', 'icon': Icons.support_agent, 'color': AppColors.warning},
      {'title': 'Call Us', 'icon': Icons.phone, 'color': AppColors.info},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Help',
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 18.0 : 20.0,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: isMobile ? 12.0 : 16.0),
        
        Wrap(
          spacing: isMobile ? 12.0 : 16.0,
          runSpacing: isMobile ? 12.0 : 16.0,
          children: helpItems.map((item) {
            final cardWidth = isMobile 
                ? (screenWidth - 48) / 2 
                : (screenWidth - 96) / 4;
            
            return Container(
              width: cardWidth,
              padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
                    size: isMobile ? 32.0 : 40.0,
                  ),
                  SizedBox(height: isMobile ? 8.0 : 12.0),
                  Text(
                    item['title'] as String,
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 16.0 : 18.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSupportOptions(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Support Options',
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 18.0 : 20.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isMobile ? 12.0 : 16.0),
          
          _buildSupportOption(
            'Browse FAQs',
            'Find answers to common questions',
            Icons.help_outline,
            isMobile,
          ),
          SizedBox(height: 12.0),
          _buildSupportOption(
            'Submit Support Ticket',
            'Create a new support request',
            Icons.support_agent,
            isMobile,
          ),
          SizedBox(height: 12.0),
          _buildSupportOption(
            'View Previous Requests',
            'Check status of your tickets',
            Icons.history,
            isMobile,
          ),
          SizedBox(height: 12.0),
          _buildSupportOption(
            'Live Chat Support',
            'Chat with our support team',
            Icons.chat,
            isMobile,
          ),
        ],
      ),
    );
  }

  Widget _buildSupportOption(String title, String subtitle, IconData icon, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(isMobile ? 8.0 : 12.0),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: isMobile ? 24.0 : 28.0,
          ),
          SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 16.0 : 18.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14.0 : 16.0,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: AppColors.textSecondary,
            size: isMobile ? 16.0 : 18.0,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTickets(bool isMobile, bool isTablet) {
    final tickets = [
      {
        'title': 'Payment Issue',
        'status': 'Resolved',
        'date': '2 days ago',
        'statusColor': AppColors.success,
      },
      {
        'title': 'Booking Cancellation',
        'status': 'In Progress',
        'date': '1 week ago',
        'statusColor': AppColors.warning,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Support Tickets',
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 18.0 : 20.0,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: isMobile ? 12.0 : 16.0),
        
        ...tickets.map((ticket) {
          return Container(
            margin: EdgeInsets.only(bottom: 12.0),
            child: _buildTicketCard(ticket, isMobile, isTablet),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket['title'],
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 16.0 : 18.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  ticket['date'],
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14.0 : 16.0,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ticket['statusColor'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              ticket['status'],
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 12.0 : 14.0,
                fontWeight: FontWeight.w600,
                color: ticket['statusColor'],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Security Section
  Widget _buildSecurityContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= 768;
        final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Security Header
              _buildSecurityHeader(isMobile, isTablet),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              
              // Security Status
              _buildSecurityStatus(isMobile, isTablet, constraints.maxWidth),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              
              // Security Options
              _buildSecurityOptions(isMobile, isTablet),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              
              // Login History
              _buildLoginHistory(isMobile, isTablet),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSecurityHeader(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.error, AppColors.error.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 16.0 : 20.0),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security,
            color: AppColors.white,
            size: isMobile ? 48.0 : 64.0,
          ),
          SizedBox(width: isMobile ? 16.0 : 20.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Security',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 24.0 : 28.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  'Keep your account safe and secure',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14.0 : 16.0,
                    fontWeight: FontWeight.w400,
                    color: AppColors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityStatus(bool isMobile, bool isTablet, double screenWidth) {
    final securityItems = [
      {'title': 'Password', 'status': 'Strong', 'icon': Icons.lock, 'color': AppColors.success},
      {'title': '2FA', 'status': 'Enabled', 'icon': Icons.verified_user, 'color': AppColors.success},
      {'title': 'Login Alerts', 'status': 'Active', 'icon': Icons.notifications, 'color': AppColors.success},
      {'title': 'Device Trust', 'status': '3 Devices', 'icon': Icons.devices, 'color': AppColors.warning},
    ];

    return Wrap(
      spacing: isMobile ? 12.0 : 16.0,
      runSpacing: isMobile ? 12.0 : 16.0,
      children: securityItems.map((item) {
        final cardWidth = isMobile 
            ? (screenWidth - 48) / 2 
            : (screenWidth - 96) / 4;
        
        return Container(
          width: cardWidth,
          padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                item['icon'] as IconData,
                color: item['color'] as Color,
                size: isMobile ? 32.0 : 40.0,
              ),
              SizedBox(height: isMobile ? 8.0 : 12.0),
              Text(
                item['status'] as String,
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 18.0 : 20.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4.0),
              Text(
                item['title'] as String,
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 14.0 : 16.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSecurityOptions(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security Settings',
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 18.0 : 20.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isMobile ? 12.0 : 16.0),
          
          _buildSecurityOption(
            'Change Password',
            'Update your account password',
            Icons.lock,
            isMobile,
          ),
          SizedBox(height: 12.0),
          _buildSecurityOption(
            'Two-Factor Authentication',
            'Add an extra layer of security',
            Icons.verified_user,
            isMobile,
          ),
          SizedBox(height: 12.0),
          _buildSecurityOption(
            'Login Alerts',
            'Get notified of new logins',
            Icons.notifications,
            isMobile,
          ),
          SizedBox(height: 12.0),
          _buildSecurityOption(
            'Trusted Devices',
            'Manage your trusted devices',
            Icons.devices,
            isMobile,
          ),
          SizedBox(height: 12.0),
          _buildSecurityOption(
            'Delete Account',
            'Permanently delete your account',
            Icons.delete_forever,
            isMobile,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityOption(String title, String subtitle, IconData icon, bool isMobile, {bool isDestructive = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(isMobile ? 8.0 : 12.0),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDestructive ? AppColors.error : AppColors.primary,
            size: isMobile ? 24.0 : 28.0,
          ),
          SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 16.0 : 18.0,
                    fontWeight: FontWeight.w600,
                    color: isDestructive ? AppColors.error : AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14.0 : 16.0,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: AppColors.textSecondary,
            size: isMobile ? 16.0 : 18.0,
          ),
        ],
      ),
    );
  }

  Widget _buildLoginHistory(bool isMobile, bool isTablet) {
    final logins = [
      {
        'device': 'iPhone 12',
        'location': 'Jerusalem, Israel',
        'time': 'Today, 10:30 AM',
        'status': 'Current',
        'statusColor': AppColors.success,
      },
      {
        'device': 'MacBook Pro',
        'location': 'Tel Aviv, Israel',
        'time': 'Yesterday, 2:15 PM',
        'status': 'Active',
        'statusColor': AppColors.info,
      },
      {
        'device': 'Samsung Galaxy',
        'location': 'Haifa, Israel',
        'time': '3 days ago',
        'status': 'Inactive',
        'statusColor': AppColors.textSecondary,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Login History',
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 18.0 : 20.0,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: isMobile ? 12.0 : 16.0),
        
        ...logins.map((login) {
          return Container(
            margin: EdgeInsets.only(bottom: 12.0),
            child: _buildLoginCard(login, isMobile, isTablet),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildLoginCard(Map<String, dynamic> login, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.devices,
            color: AppColors.primary,
            size: isMobile ? 24.0 : 28.0,
          ),
          SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  login['device'],
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 16.0 : 18.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  login['location'],
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14.0 : 16.0,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  login['time'],
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 12.0 : 14.0,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: login['statusColor'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              login['status'],
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 12.0 : 14.0,
                fontWeight: FontWeight.w600,
                color: login['statusColor'],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderContent(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            '$title - Coming Soon',
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
} 