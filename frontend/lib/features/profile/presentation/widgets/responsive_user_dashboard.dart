import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/auth_service.dart';

// Widget imports
import 'my_bookings_widget.dart';
import 'chat_messages_widget.dart';
import 'payments_widget.dart';
import 'my_reviews_widget.dart';
import 'profile_settings_widget.dart';
import 'saved_providers_widget.dart';
import 'support_help_widget.dart';
import 'security_widget.dart';
import '../../../admin/presentation/widgets/language_toggle_widget.dart';

// User models
class UserMenuItem {
  final String title;
  final IconData icon;
  final int index;
  final String? badge;

  UserMenuItem({
    required this.title,
    required this.icon,
    required this.index,
    this.badge,
  });
}

class ResponsiveUserDashboard extends StatefulWidget {
  const ResponsiveUserDashboard({super.key});

  @override
  State<ResponsiveUserDashboard> createState() => _ResponsiveUserDashboardState();
}

class _ResponsiveUserDashboardState extends State<ResponsiveUserDashboard> 
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _sidebarAnimationController;
  late Animation<double> _sidebarAnimation;
  late AnimationController _contentAnimationController;
  late Animation<double> _contentAnimation;

  // Menu items - will be localized
  List<UserMenuItem> _getMenuItems() {
    return [
      UserMenuItem(title: _getLocalizedString('my_bookings'), icon: Icons.calendar_today, index: 0, badge: '3'),
      UserMenuItem(title: _getLocalizedString('chat_messages'), icon: Icons.chat, index: 1, badge: '2'),
      UserMenuItem(title: _getLocalizedString('payments'), icon: Icons.payment, index: 2),
      UserMenuItem(title: _getLocalizedString('my_reviews'), icon: Icons.star, index: 3),
      UserMenuItem(title: _getLocalizedString('profile_settings'), icon: Icons.person, index: 4),
      UserMenuItem(title: _getLocalizedString('saved_providers'), icon: Icons.favorite, index: 5),
      UserMenuItem(title: _getLocalizedString('support_help'), icon: Icons.help, index: 6),
      UserMenuItem(title: _getLocalizedString('security'), icon: Icons.security, index: 7),
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
      case 'upcoming':
        return isArabic ? 'قادم' : 'Upcoming';
      case 'home_cleaning':
        return isArabic ? 'تنظيف المنزل' : 'Home Cleaning';
      case 'elderly_care':
        return isArabic ? 'رعاية المسنين' : 'Elderly Care';
      case 'babysitting':
        return isArabic ? 'رعاية الأطفال' : 'Babysitting';
      case 'fatima_al_zahra':
        return isArabic ? 'فاطمة الزهراء' : 'Fatima Al-Zahra';
      case 'mariam_hassan':
        return isArabic ? 'مريم حسن' : 'Mariam Hassan';
      case 'aisha_mohammed':
        return isArabic ? 'عائشة محمد' : 'Aisha Mohammed';
      case 'tomorrow_10am':
        return isArabic ? 'غداً، 10:00 صباحاً' : 'Tomorrow, 10:00 AM';
      case 'friday_2pm':
        return isArabic ? 'الجمعة، 2:00 مساءً' : 'Friday, 2:00 PM';
      case 'yesterday_3pm':
        return isArabic ? 'أمس، 3:00 مساءً' : 'Yesterday, 3:00 PM';
      case 'messages':
        return isArabic ? 'الرسائل' : 'Messages';
      case 'chat':
        return isArabic ? 'الدردشة' : 'Chat';
      case 'online':
        return isArabic ? 'متصل' : 'Online';
      case 'offline':
        return isArabic ? 'غير متصل' : 'Offline';
      case 'lastSeen':
        return isArabic ? 'آخر ظهور' : 'Last seen';
      case 'typing':
        return isArabic ? 'يكتب...' : 'Typing...';
      case 'send':
        return isArabic ? 'إرسال' : 'Send';
      case 'attach':
        return isArabic ? 'إرفاق' : 'Attach';
      case 'voiceMessage':
        return isArabic ? 'رسالة صوتية' : 'Voice Message';
      case 'emoji':
        return isArabic ? 'الرموز التعبيرية' : 'Emoji';
      case 'noMessages':
        return isArabic ? 'لا توجد رسائل بعد' : 'No messages yet';
      case 'startConversation':
        return isArabic ? 'ابدأ محادثة' : 'Start a conversation';
      case 'minutesAgo':
        return isArabic ? 'دقيقة مضت' : 'min ago';
      case 'hoursAgo':
        return isArabic ? 'ساعة مضت' : 'hour ago';
      case 'daysAgo':
        return isArabic ? 'أيام مضت' : 'days ago';
      case 'willArriveIn':
        return isArabic ? 'سأصل خلال 10 دقائق' : 'I will arrive in 10 minutes';
      case 'thankYouForBooking':
        return isArabic ? 'شكراً لك على الحجز' : 'Thank you for the booking';
      case 'childrenDoingGreat':
        return isArabic ? 'الأطفال بخير' : 'The children are doing great';
      case 'type_message':
        return isArabic ? 'اكتب رسالة...' : 'Type a message...';
      // Payment strings
      case 'totalSpent':
        return isArabic ? 'إجمالي الإنفاق' : 'Total Spent';
      case 'thisMonth':
        return isArabic ? 'هذا الشهر' : 'This Month';
      case 'pending':
        return isArabic ? 'معلق' : 'Pending';
      case 'paymentMethods':
        return isArabic ? 'طرق الدفع' : 'Payment Methods';
      case 'addNew':
        return isArabic ? 'إضافة جديد' : 'Add New';
      case 'defaultText':
        return isArabic ? 'افتراضي' : 'Default';
      case 'connected':
        return isArabic ? 'متصل' : 'Connected';
      case 'paymentHistory':
        return isArabic ? 'سجل المدفوعات' : 'Payment History';
      case 'visaEndingIn':
        return isArabic ? 'فيزا تنتهي بـ 1234' : 'Visa ending in 1234';
      case 'paypal':
        return isArabic ? 'باي بال' : 'PayPal';
      case 'completed':
        return isArabic ? 'مكتمل' : 'Completed';
      case 'today':
        return isArabic ? 'اليوم' : 'Today';
      case 'yesterday':
        return isArabic ? 'أمس' : 'Yesterday';
      case 'daysAgo':
        return isArabic ? 'أيام مضت' : 'days ago';
      case 'at':
        return isArabic ? 'في' : 'at';
      case 'totalReviews':
        return isArabic ? 'إجمالي التقييمات' : 'Total Reviews';
      case 'averageRating':
        return isArabic ? 'متوسط التقييم' : 'Average Rating';
      case 'myReviews':
        return isArabic ? 'تقييماتي' : 'My Reviews';
      case 'edit':
        return isArabic ? 'تعديل' : 'Edit';
      case 'weekAgo':
        return isArabic ? 'أسبوع مضى' : 'week ago';
      case 'weeksAgo':
        return isArabic ? 'أسابيع مضت' : 'weeks ago';
      // Profile Settings strings
      case 'profileSettings':
        return isArabic ? 'إعدادات الملف الشخصي' : 'Profile Settings';
      case 'personalInformation':
        return isArabic ? 'المعلومات الشخصية' : 'Personal Information';
      case 'firstName':
        return isArabic ? 'الاسم الأول' : 'First Name';
      case 'lastName':
        return isArabic ? 'اسم العائلة' : 'Last Name';
      case 'phoneNumber':
        return isArabic ? 'رقم الهاتف' : 'Phone Number';
      case 'saveChanges':
        return isArabic ? 'حفظ التغييرات' : 'Save Changes';
      case 'savedAddresses':
        return isArabic ? 'العناوين المحفوظة' : 'Saved Addresses';
      case 'addNewAddress':
        return isArabic ? 'إضافة عنوان جديد' : 'Add New Address';
      case 'notificationPreferences':
        return isArabic ? 'تفضيلات الإشعارات' : 'Notification Preferences';
      case 'emailNotifications':
        return isArabic ? 'إشعارات البريد الإلكتروني' : 'Email Notifications';
      case 'pushNotifications':
        return isArabic ? 'الإشعارات الفورية' : 'Push Notifications';
      case 'smsNotifications':
        return isArabic ? 'إشعارات الرسائل النصية' : 'SMS Notifications';
      // Saved Providers strings
      case 'savedProviders':
        return isArabic ? 'مقدمي الخدمات المحفوظون' : 'Saved Providers';
      case 'totalProviders':
        return isArabic ? 'إجمالي مقدمي الخدمات' : 'Total Providers';
      case 'available':
        return isArabic ? 'متاح' : 'Available';
      case 'unavailable':
        return isArabic ? 'غير متاح' : 'Unavailable';
      case 'bookNow':
        return isArabic ? 'احجز الآن' : 'Book Now';
      case 'remove':
        return isArabic ? 'إزالة' : 'Remove';
      // Support Help strings
      case 'supportHelp':
        return isArabic ? 'الدعم والمساعدة' : 'Support & Help';
      case 'quickHelp':
        return isArabic ? 'مساعدة سريعة' : 'Quick Help';
      case 'contactSupport':
        return isArabic ? 'تواصل مع الدعم' : 'Contact Support';
      case 'faq':
        return isArabic ? 'الأسئلة الشائعة' : 'FAQ';
      case 'liveChat':
        return isArabic ? 'الدردشة المباشرة' : 'Live Chat';
      case 'reportIssue':
        return isArabic ? 'الإبلاغ عن مشكلة' : 'Report Issue';
      case 'recentTickets':
        return isArabic ? 'التذاكر الحديثة' : 'Recent Tickets';
      case 'open':
        return isArabic ? 'مفتوح' : 'Open';
      case 'closed':
        return isArabic ? 'مغلق' : 'Closed';
      // Security strings
      case 'security':
        return isArabic ? 'الأمان' : 'Security';
      case 'securityStatus':
        return isArabic ? 'حالة الأمان' : 'Security Status';
      case 'strong':
        return isArabic ? 'قوي' : 'Strong';
      case 'changePassword':
        return isArabic ? 'تغيير كلمة المرور' : 'Change Password';
      case 'twoFactorAuth':
        return isArabic ? 'المصادقة الثنائية' : 'Two-Factor Authentication';
      case 'enabled':
        return isArabic ? 'مفعل' : 'Enabled';
      case 'disabled':
        return isArabic ? 'معطل' : 'Disabled';
      case 'loginHistory':
        return isArabic ? 'سجل تسجيل الدخول' : 'Login History';
      case 'lastLogin':
        return isArabic ? 'آخر تسجيل دخول' : 'Last Login';
      case 'device':
        return isArabic ? 'الجهاز' : 'Device';
      case 'location':
        return isArabic ? 'الموقع' : 'Location';
      case 'accountSettings':
        return isArabic ? 'إعدادات الحساب' : 'Account Settings';
      case 'deactivateAccount':
        return isArabic ? 'إلغاء تفعيل الحساب' : 'Deactivate Account';
      case 'deleteAccount':
        return isArabic ? 'حذف الحساب' : 'Delete Account';
      // Additional strings for complete translation
      case 'dateOfBirth':
        return isArabic ? 'تاريخ الميلاد' : 'Date of Birth';
      case 'recentlyBooked':
        return isArabic ? 'حجوزات حديثة' : 'Recently Booked';
      case 'findAnswers':
        return isArabic ? 'اعثر على إجابات للأسئلة الشائعة' : 'Find answers to common questions';
      case 'createSupportRequest':
        return isArabic ? 'إنشاء طلب دعم جديد' : 'Create a new support request';
      case 'viewPreviousRequests':
        return isArabic ? 'عرض الطلبات السابقة' : 'View Previous Requests';
      case 'checkTicketStatus':
        return isArabic ? 'تحقق من حالة تذاكرك' : 'Check status of your tickets';
      case 'chatWithSupport':
        return isArabic ? 'دردشة مع فريق الدعم' : 'Chat with our support team';
      case 'password':
        return isArabic ? 'كلمة المرور' : 'Password';
      case 'loginAlerts':
        return isArabic ? 'تنبيهات تسجيل الدخول' : 'Login Alerts';
      case 'active':
        return isArabic ? 'نشط' : 'Active';
      case 'deviceTrust':
        return isArabic ? 'ثقة الجهاز' : 'Device Trust';
      case 'devices':
        return isArabic ? 'الأجهزة' : 'Devices';
      case 'updatePassword':
        return isArabic ? 'تحديث كلمة مرور حسابك' : 'Update your account password';
      case 'addExtraSecurity':
        return isArabic ? 'إضافة طبقة أمان إضافية' : 'Add an extra layer of security';
      case 'getLoginNotifications':
        return isArabic ? 'احصل على إشعارات بتسجيلات الدخول الجديدة' : 'Get notified of new logins';
      case 'trustedDevices':
        return isArabic ? 'الأجهزة الموثوقة' : 'Trusted Devices';
      case 'manageTrustedDevices':
        return isArabic ? 'إدارة أجهزتك الموثوقة' : 'Manage your trusted devices';
      case 'permanentlyDeleteAccount':
        return isArabic ? 'حذف حسابك نهائياً' : 'Permanently delete your account';
      case 'membersSince':
        return isArabic ? 'عضو منذ' : 'Members since';
      case 'fullName':
        return isArabic ? 'الاسم الكامل' : 'Full Name';
      case 'march15':
        return isArabic ? '15 اذار 1998' : 'March 15, 1998';
      case 'home':
        return isArabic ? 'المنزل' : 'Home';
      case 'businessF':
        return isArabic ? 'الأعمال ف' : 'Business F';
      case 'dellaBia':
        return isArabic ? 'ديلا بيا' : 'Della Bia';
      case 'f456':
        return isArabic ? 'ف456' : 'F456';
      case 'homeCleaning':
        return isArabic ? 'تنظيف المنزل' : 'Home Cleaning';
      case 'elderlyCare':
        return isArabic ? 'رعاية المسنين' : 'Elderly Care';
      case 'babysitting':
        return isArabic ? 'رعاية الأطفال' : 'Babysitting';
      case 'lastBook':
        return isArabic ? 'آخر حجز' : 'Last Book';
      case 'twoDaysAgo':
        return isArabic ? 'قبل يومين' : 'Two days ago';
      case 'oneWeekAgo':
        return isArabic ? 'قبل أسبوع' : 'One week ago';
      case 'threeWeeksAgo':
        return isArabic ? 'قبل ثلاثة أسابيع' : 'Three weeks ago';
      case 'threeDaysAgo':
        return isArabic ? 'قبل ثلاثة أيام' : 'Three days ago';
      case 'oneDayAgo':
        return isArabic ? 'قبل يوم واحد' : 'One day ago';
      case 'oneWeekAgo':
        return isArabic ? 'قبل أسبوع' : 'One week ago';
      case 'twoWeeksAgo':
        return isArabic ? 'قبل أسبوعين' : 'Two weeks ago';
      case 'oneMonthAgo':
        return isArabic ? 'قبل شهر' : 'One month ago';
      case 'twoMonthsAgo':
        return isArabic ? 'قبل شهرين' : 'Two months ago';
      case 'threeMonthsAgo':
        return isArabic ? 'قبل ثلاثة أشهر' : 'Three months ago';
      case 'oneYearAgo':
        return isArabic ? 'قبل سنة' : 'One year ago';
      case 'twoYearsAgo':
        return isArabic ? 'قبل سنتين' : 'Two years ago';
      case 'justNow':
        return isArabic ? 'الآن' : 'Just now';
      case 'minutesAgo':
        return isArabic ? 'دقائق مضت' : 'minutes ago';
      case 'hoursAgo':
        return isArabic ? 'ساعات مضت' : 'hours ago';
      case 'daysAgo':
        return isArabic ? 'أيام مضت' : 'days ago';
      case 'weeksAgo':
        return isArabic ? 'أسابيع مضت' : 'weeks ago';
      case 'monthsAgo':
        return isArabic ? 'أشهر مضت' : 'months ago';
      case 'yearsAgo':
        return isArabic ? 'سنوات مضت' : 'years ago';
      case 'keepAccountSafe':
        return isArabic ? 'حافظ على أمان حسابك' : 'Keep Your Account Safe and Secure';
      case 'accountSecurity':
        return isArabic ? 'أمان الحساب' : 'Account Security';
      case 'january2024':
        return isArabic ? 'كانون الثاني 2024' : 'January 2024';
      case 'needHelp':
        return isArabic ? 'تحتاج مساعدة؟' : 'Need help?';
      case 'weAreHereToHelp':
        return isArabic ? 'نحن هنا لمساعدتك على مدار الساعة' : 'We are here to help you 24/7';
      case 'paymentIssueResolved':
        return isArabic ? 'تم حل مشكلة الدفع' : 'Payment issue resolved';
      case 'bookingCancellations':
        return isArabic ? 'إلغاءات الحجز' : 'Booking cancellations';
      case 'inProgress':
        return isArabic ? 'قيد التنفيذ' : 'In progress';
      case 'jerusalem':
        return isArabic ? 'القدس' : 'Jerusalem';
      case 'telAviv':
        return isArabic ? 'نابلس' : 'Nablus';
      case 'haifa':
        return isArabic ? 'حيفا' : 'Haifa';
      case 'today830AM':
        return isArabic ? 'اليوم 8:30 صباحاً' : 'Today 8:30 AM';
      case 'current':
        return isArabic ? 'الحالي' : 'Current';
      case 'inActive':
        return isArabic ? 'نشط' : 'In Active';
      case 'palestine':
        return isArabic ? 'فلسطين' : 'Palestine';
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
      case 'lastBooked':
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
          key: _scaffoldKey,
          drawer: isMobile ? _buildMobileDrawer() : null,
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
        final menuItems = _getMenuItems();
        return ListView.builder(
          padding: EdgeInsets.symmetric(
            vertical: isDesktop ? 16.0 : 12.0,
            horizontal: isDesktop ? 12.0 : 8.0,
          ),
          itemCount: menuItems.length,
          itemBuilder: (context, index) {
            final item = menuItems[index];
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
                _scaffoldKey.currentState?.openDrawer();
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
                final menuItems = _getMenuItems();
                return Text(
                  menuItems[_selectedIndex].title,
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 20.0 : 24.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                );
              },
            ),
          ),
          // Header Actions - Updated to match Admin Dashboard order
          _buildHeaderActions(isMobile, isTablet),
        ],
      ),
    );
  }

  Widget _buildHeaderActions(bool isMobile, bool isTablet) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
    return Row(
      children: [
            // Notifications
            IconButton(
              onPressed: () {
                // TODO: Show notifications
              },
              icon: Stack(
                children: [
          Icon(
            Icons.notifications_outlined,
            color: AppColors.textSecondary,
            size: isTablet ? 22.0 : 24.0,
          ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
          SizedBox(width: isTablet ? 16.0 : 20.0),

            // User profile
            Consumer<AuthService>(
              builder: (context, authService, child) {
                return Row(
                  children: [
                    CircleAvatar(
                      radius: isTablet ? 20.0 : 24.0,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        authService.currentUser?['firstName']?.substring(0, 1).toUpperCase() ?? 'U',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 16.0 : 18.0,
                        ),
                      ),
                    ),
                    if (!isMobile) ...[
                      SizedBox(width: isTablet ? 10.0 : 12.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${authService.currentUser?['firstName'] ?? 'User'} ${authService.currentUser?['lastName'] ?? ''}',
                            style: GoogleFonts.cairo(
                              fontSize: isTablet ? 14.0 : 16.0,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            AppStrings.getString('client', languageService.currentLanguage),
                            style: GoogleFonts.cairo(
                              fontSize: isTablet ? 10.0 : 12.0,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),

            SizedBox(width: isTablet ? 16.0 : 20.0),

            // Logout button
            IconButton(
              onPressed: () async {
                try {
                  final authService = Provider.of<AuthService>(context, listen: false);
                  await authService.logout();
                  if (mounted) {
                    // Navigate to home screen and clear all routes
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/home',
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Logout failed: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: Icon(
                Icons.logout,
                color: AppColors.textSecondary,
                size: isTablet ? 22.0 : 24.0,
              ),
              tooltip: AppStrings.getString('logout', languageService.currentLanguage),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResponsiveContent(bool isMobile, bool isTablet, bool isDesktop) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
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
      },
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildMyBookings();
      case 1:
        return _buildChatMessages();
      case 2:
        return _buildPayments();
      case 3:
        return _buildMyReviews();
      case 4:
        return _buildProfileSettings();
      case 5:
        return _buildSavedProviders();
      case 6:
        return _buildSupportHelp();
      case 7:
        return _buildSecurity();
      default:
        return _buildMyBookings();
    }
  }

  Widget _buildLanguageToggle(bool isDesktop, bool isTablet) {
    return LanguageToggleWidget(
      isCollapsed: _isSidebarCollapsed,
      screenWidth: MediaQuery.of(context).size.width,
    );
  }

  Widget _buildMobileBottomNavigation() {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        // Only show bottom navigation for main sections (0-4)
        // For other sections (5-8), hide the bottom navigation
        if (_selectedIndex > 4) {
          return const SizedBox.shrink();
        }
        
        return BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex.clamp(0, 4),
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
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
              icon: Stack(
                children: [
                  Icon(Icons.calendar_today, size: 20),
                  if (_selectedIndex != 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                ],
              ),
              label: _getLocalizedString('my_bookings'),
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  Icon(Icons.chat, size: 20),
                  if (_selectedIndex != 1)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                ],
              ),
              label: _getLocalizedString('chat_messages'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.payment, size: 20),
              label: _getLocalizedString('payments'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.star, size: 20),
              label: _getLocalizedString('my_reviews'),
            ),
          ],
        );
      },
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
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final filters = [
      AppStrings.getString('all', languageService.currentLanguage),
      AppStrings.getString('upcoming', languageService.currentLanguage),
      AppStrings.getString('completed', languageService.currentLanguage),
      AppStrings.getString('cancelled', languageService.currentLanguage),
    ];
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
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final bookings = [
      {
        'service': AppStrings.getString('homeCleaning', languageService.currentLanguage),
        'provider': 'Fatima Al-Zahra',
        'date': AppStrings.getString('tomorrow10AM', languageService.currentLanguage),
        'status': AppStrings.getString('confirmed', languageService.currentLanguage),
        'statusColor': AppColors.success,
        'price': '₪150',
        'address': '${AppStrings.getString('mainStreet', languageService.currentLanguage)}, ${AppStrings.getString('jerusalem', languageService.currentLanguage)}',
      },
      {
        'service': AppStrings.getString('elderlyCare', languageService.currentLanguage),
        'provider': 'Mariam Hassan',
        'date': AppStrings.getString('friday2PM', languageService.currentLanguage),
        'status': AppStrings.getString('pending', languageService.currentLanguage),
        'statusColor': AppColors.warning,
        'price': '₪200',
        'address': '${AppStrings.getString('oakAvenue', languageService.currentLanguage)}, ${AppStrings.getString('telAviv', languageService.currentLanguage)}',
      },
      {
        'service': AppStrings.getString('babysitting', languageService.currentLanguage),
        'provider': 'Aisha Mohammed',
        'date': AppStrings.getString('yesterday3PM', languageService.currentLanguage),
        'status': AppStrings.getString('completed', languageService.currentLanguage),
        'statusColor': AppColors.info,
        'price': '₪120',
        'address': '${AppStrings.getString('pineRoad', languageService.currentLanguage)}, ${AppStrings.getString('haifa', languageService.currentLanguage)}',
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
    final languageService = Provider.of<LanguageService>(context, listen: false);
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
            AppStrings.getString('provider', languageService.currentLanguage),
            booking['provider'],
            isMobile,
          ),
          SizedBox(height: 8.0),
          _buildBookingDetailRow(
            Icons.calendar_today,
            AppStrings.getString('dateTime', languageService.currentLanguage),
            booking['date'],
            isMobile,
          ),
          SizedBox(height: 8.0),
          _buildBookingDetailRow(
            Icons.location_on,
            AppStrings.getString('address', languageService.currentLanguage),
            booking['address'],
            isMobile,
          ),
          SizedBox(height: 8.0),
          _buildBookingDetailRow(
            Icons.attach_money,
            AppStrings.getString('price', languageService.currentLanguage),
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
    final languageService = Provider.of<LanguageService>(context, listen: false);
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
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final actions = [
      {'icon': Icons.cancel, 'label': AppStrings.getString('cancel', languageService.currentLanguage), 'color': AppColors.error},
      {'icon': Icons.schedule, 'label': AppStrings.getString('reschedule', languageService.currentLanguage), 'color': AppColors.warning},
      {'icon': Icons.chat, 'label': AppStrings.getString('contact', languageService.currentLanguage), 'color': AppColors.primary},
      {'icon': Icons.location_on, 'label': AppStrings.getString('track', languageService.currentLanguage), 'color': AppColors.info},
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
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final chats = [
      {
        'name': 'Fatima Al-Zahra',
        'service': AppStrings.getString('homeCleaning', languageService.currentLanguage),
        'lastMessage': 'I will arrive in 10 minutes',
        'time': '2 ${AppStrings.getString('minutesAgo', languageService.currentLanguage)}',
        'unread': 2,
        'isOnline': true,
      },
      {
        'name': 'Mariam Hassan',
        'service': AppStrings.getString('elderlyCare', languageService.currentLanguage),
        'lastMessage': 'Thank you for the booking',
        'time': '1 ${AppStrings.getString('hoursAgo', languageService.currentLanguage)}',
        'unread': 0,
        'isOnline': false,
      },
      {
        'name': 'Aisha Mohammed',
        'service': AppStrings.getString('babysitting', languageService.currentLanguage),
        'lastMessage': 'The children are doing great',
        'time': '3 ${AppStrings.getString('hoursAgo', languageService.currentLanguage)}',
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
                _getLocalizedString('messages'),
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
                      _getLocalizedString('homeCleaning'),
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
                hintText: _getLocalizedString('type_message'),
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
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final summaryCards = [
      {'title': AppStrings.getString('totalSpent', languageService.currentLanguage), 'amount': '₪2,450', 'icon': Icons.account_balance_wallet, 'color': AppColors.primary},
      {'title': AppStrings.getString('thisMonth', languageService.currentLanguage), 'amount': '₪580', 'icon': Icons.calendar_today, 'color': AppColors.success},
      {'title': AppStrings.getString('pending', languageService.currentLanguage), 'amount': '₪150', 'icon': Icons.pending, 'color': AppColors.warning},
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
              _getLocalizedString('paymentMethods'),
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
                _getLocalizedString('addNew'),
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
          _getLocalizedString('visaEndingIn'),
          _getLocalizedString('defaultText'),
          Icons.credit_card,
          AppColors.primary,
          true,
          isMobile,
        ),
        SizedBox(height: 12.0),
        _buildPaymentMethodCard(
          _getLocalizedString('paypal'),
          _getLocalizedString('connected'),
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
                _getLocalizedString('defaultText'),
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
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final payments = [
      {
        'service': AppStrings.getString('homeCleaning', languageService.currentLanguage),
        'provider': 'Fatima Al-Zahra',
        'amount': '₪150',
        'date': '${AppStrings.getString('today', languageService.currentLanguage)}, 10:00 AM',
        'status': AppStrings.getString('completed', languageService.currentLanguage),
        'statusColor': AppColors.success,
      },
      {
        'service': AppStrings.getString('elderlyCare', languageService.currentLanguage),
        'provider': 'Mariam Hassan',
        'amount': '₪200',
        'date': '${AppStrings.getString('yesterday', languageService.currentLanguage)}, 2:00 PM',
        'status': AppStrings.getString('pending', languageService.currentLanguage),
        'statusColor': AppColors.warning,
      },
      {
        'service': AppStrings.getString('babysitting', languageService.currentLanguage),
        'provider': 'Aisha Mohammed',
        'amount': '₪120',
        'date': '2 ${AppStrings.getString('daysAgo', languageService.currentLanguage)}',
        'status': AppStrings.getString('completed', languageService.currentLanguage),
        'statusColor': AppColors.success,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getLocalizedString('paymentHistory'),
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
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final summaryCards = [
      {'title': AppStrings.getString('totalReviews', languageService.currentLanguage), 'count': '8', 'icon': Icons.rate_review, 'color': AppColors.primary},
      {'title': AppStrings.getString('averageRating', languageService.currentLanguage), 'count': '4.8', 'icon': Icons.star, 'color': AppColors.warning},
      {'title': AppStrings.getString('thisMonth', languageService.currentLanguage), 'count': '3', 'icon': Icons.calendar_today, 'color': AppColors.success},
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
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final reviews = [
      {
        'provider': 'Fatima Al-Zahra',
        'service': AppStrings.getString('homeCleaning', languageService.currentLanguage),
        'rating': 5.0,
        'comment': 'Excellent service! Very professional and thorough cleaning.',
        'date': '2 ${AppStrings.getString('daysAgo', languageService.currentLanguage)}',
        'canEdit': true,
      },
      {
        'provider': 'Mariam Hassan',
        'service': AppStrings.getString('elderlyCare', languageService.currentLanguage),
        'rating': 4.5,
        'comment': 'Very caring and attentive. Highly recommended.',
        'date': '1 ${AppStrings.getString('weekAgo', languageService.currentLanguage)}',
        'canEdit': false,
      },
      {
        'provider': 'Aisha Mohammed',
        'service': AppStrings.getString('babysitting', languageService.currentLanguage),
        'rating': 5.0,
        'comment': 'Great with kids! Very reliable and trustworthy.',
        'date': '2 ${AppStrings.getString('weeksAgo', languageService.currentLanguage)}',
        'canEdit': false,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getLocalizedString('myReviews'),
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
                    _getLocalizedString('edit'),
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
                  '${_getLocalizedString('membersSince')} ${_getLocalizedString('january2024')}',
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
            _getLocalizedString('personalInformation'),
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 18.0 : 20.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isMobile ? 16.0 : 20.0),
          
          _buildFormField(_getLocalizedString('fullName'), 'Ahmed Hassan', Icons.person, isMobile),
          SizedBox(height: 12.0),
          _buildFormField(_getLocalizedString('email'), 'ahmed@example.com', Icons.email, isMobile),
          SizedBox(height: 12.0),
          _buildFormField(_getLocalizedString('phoneNumber'), '+972 50 123 4567', Icons.phone, isMobile),
          SizedBox(height: 12.0),
          _buildFormField(_getLocalizedString('dateOfBirth'), _getLocalizedString('march15'), Icons.calendar_today, isMobile),
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
                _getLocalizedString('savedAddresses'),
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
                  _getLocalizedString('addNewAddress'),
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
          
          _buildAddressCard(_getLocalizedString('home'), '123 ${_getLocalizedString('mainStreet')}, ${_getLocalizedString('jerusalem')}', true, isMobile),
          SizedBox(height: 12.0),
          _buildAddressCard(_getLocalizedString('work'), '456 ${_getLocalizedString('businessF')}, ${_getLocalizedString('telAviv')}', false, isMobile),
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
                _getLocalizedString('defaultText'),
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
            _getLocalizedString('notificationPreferences'),
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 18.0 : 20.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isMobile ? 12.0 : 16.0),
          
          _buildNotificationToggle(_getLocalizedString('emailNotifications'), true, isMobile),
          SizedBox(height: 8.0),
          _buildNotificationToggle(_getLocalizedString('pushNotifications'), true, isMobile),
          SizedBox(height: 8.0),
          _buildNotificationToggle(_getLocalizedString('smsNotifications'), false, isMobile),
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
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final summaryCards = [
      {'title': _getLocalizedString('totalProviders'), 'count': '5', 'icon': Icons.favorite, 'color': AppColors.error},
      {'title': _getLocalizedString('available'), 'count': '3', 'icon': Icons.check_circle, 'color': AppColors.success},
      {'title': _getLocalizedString('recentlyBooked'), 'count': '2', 'icon': Icons.calendar_today, 'color': AppColors.primary},
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
        'service': _getLocalizedString('homeCleaning'),
        'rating': 4.8,
        'price': '₪150',
        'isAvailable': true,
        'lastBooked': _getLocalizedString('twoDaysAgo'),
      },
      {
        'name': 'Mariam Hassan',
        'service': _getLocalizedString('elderlyCare'),
        'rating': 4.9,
        'price': '₪200',
        'isAvailable': true,
        'lastBooked': _getLocalizedString('oneWeekAgo'),
      },
      {
        'name': 'Aisha Mohammed',
        'service': _getLocalizedString('babysitting'),
        'rating': 4.7,
        'price': '₪120',
        'isAvailable': false,
        'lastBooked': _getLocalizedString('threeWeeksAgo'),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getLocalizedString('savedProviders'),
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
                        provider['isAvailable'] ? _getLocalizedString('available') : _getLocalizedString('unavailable'),
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
                  '${_getLocalizedString('lastBooked')}: ${provider['lastBooked']}',
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
                  _getLocalizedString('bookNow'),
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
                  _getLocalizedString('needHelp'),
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 24.0 : 28.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  _getLocalizedString('weAreHereToHelp'),
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
      {'title': _getLocalizedString('faq'), 'icon': Icons.help_outline, 'color': AppColors.primary},
      {'title': _getLocalizedString('liveChat'), 'icon': Icons.chat, 'color': AppColors.success},
      {'title': _getLocalizedString('reportIssue'), 'icon': Icons.support_agent, 'color': AppColors.warning},
      {'title': _getLocalizedString('contactSupport'), 'icon': Icons.phone, 'color': AppColors.info},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getLocalizedString('quickHelp'),
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
            _getLocalizedString('supportHelp'),
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 18.0 : 20.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isMobile ? 12.0 : 16.0),
          
          _buildSupportOption(
            _getLocalizedString('faq'),
            _getLocalizedString('findAnswers'),
            Icons.help_outline,
            isMobile,
          ),
          SizedBox(height: 12.0),
          _buildSupportOption(
            _getLocalizedString('reportIssue'),
            _getLocalizedString('createSupportRequest'),
            Icons.support_agent,
            isMobile,
          ),
          SizedBox(height: 12.0),
          _buildSupportOption(
            _getLocalizedString('viewPreviousRequests'),
            _getLocalizedString('checkTicketStatus'),
            Icons.history,
            isMobile,
          ),
          SizedBox(height: 12.0),
          _buildSupportOption(
            _getLocalizedString('liveChat'),
            _getLocalizedString('chatWithSupport'),
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
        'title': _getLocalizedString('paymentIssueResolved'),
        'status': _getLocalizedString('resolved'),
        'date': _getLocalizedString('twoDaysAgo'),
        'statusColor': AppColors.success,
      },
      {
        'title': _getLocalizedString('bookingCancellations'),
        'status': _getLocalizedString('inProgress'),
        'date': _getLocalizedString('oneWeekAgo'),
        'statusColor': AppColors.warning,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getLocalizedString('recentTickets'),
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
                  _getLocalizedString('accountSecurity'),
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 24.0 : 28.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  _getLocalizedString('keepAccountSafe'),
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
      {'title': _getLocalizedString('password'), 'status': _getLocalizedString('strong'), 'icon': Icons.lock, 'color': AppColors.success},
      {'title': _getLocalizedString('twoFactorAuth'), 'status': _getLocalizedString('enabled'), 'icon': Icons.verified_user, 'color': AppColors.success},
      {'title': _getLocalizedString('loginAlerts'), 'status': _getLocalizedString('active'), 'icon': Icons.notifications, 'color': AppColors.success},
      {'title': _getLocalizedString('deviceTrust'), 'status': '3 ${_getLocalizedString('devices')}', 'icon': Icons.devices, 'color': AppColors.warning},
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
            _getLocalizedString('security'),
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 18.0 : 20.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isMobile ? 12.0 : 16.0),
          
          _buildSecurityOption(
            _getLocalizedString('changePassword'),
            _getLocalizedString('updatePassword'),
            Icons.lock,
            isMobile,
          ),
          SizedBox(height: 12.0),
          _buildSecurityOption(
            _getLocalizedString('twoFactorAuth'),
            _getLocalizedString('addExtraSecurity'),
            Icons.verified_user,
            isMobile,
          ),
          SizedBox(height: 12.0),
          _buildSecurityOption(
            _getLocalizedString('loginAlerts'),
            _getLocalizedString('getLoginNotifications'),
            Icons.notifications,
            isMobile,
          ),
          SizedBox(height: 12.0),
          _buildSecurityOption(
            _getLocalizedString('trustedDevices'),
            _getLocalizedString('manageTrustedDevices'),
            Icons.devices,
            isMobile,
          ),
          SizedBox(height: 12.0),
          _buildSecurityOption(
            _getLocalizedString('deleteAccount'),
            _getLocalizedString('permanentlyDeleteAccount'),
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
        'location': '${_getLocalizedString('jerusalem')}, ${_getLocalizedString('palestine')}',
        'time': _getLocalizedString('today830AM'),
        'status': _getLocalizedString('current'),
        'statusColor': AppColors.success,
      },
      {
        'device': 'MacBook Pro',
        'location': '${_getLocalizedString('telAviv')}, ${_getLocalizedString('palestine')}',
                  'time': '${_getLocalizedString('yesterday')}, 2:15 PM',
        'status': _getLocalizedString('inActive'),
        'statusColor': AppColors.info,
      },
      {
        'device': 'Samsung Galaxy',
        'location': '${_getLocalizedString('haifa')}, ${_getLocalizedString('palestine')}',
        'time': '3 days ago',
        'status': _getLocalizedString('inactive'),
        'statusColor': AppColors.textSecondary,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getLocalizedString('loginHistory'),
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



  Widget _buildMobileDrawer() {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        final menuItems = _getMenuItems();
        
        return Drawer(
          child: Container(
            color: AppColors.white,
            child: Column(
              children: [
                // Drawer header
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Icon(
                              Icons.person,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Ahmed Hassan',
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Premium User',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: AppColors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Menu items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: menuItems.length,
                    itemBuilder: (context, index) {
                      final item = menuItems[index];
                      return _buildDrawerMenuItem(item);
                    },
                  ),
                ),
                
                // Language toggle in drawer
                Container(
                  padding: const EdgeInsets.all(16),
                  child: ListTile(
                    leading: Icon(
                      Icons.language,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    title: Text(
                      languageService.isEnglish ? 'العربية' : 'English',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      languageService.toggleLanguage();
                      Navigator.pop(context);
                    },
                  ),
                ),
                
                // Drawer footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.logout,
                      color: AppColors.error,
                      size: 20,
                    ),
                    title: Text(
                      AppStrings.getString('logout', languageService.currentLanguage),
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      // Handle logout
                      Navigator.pop(context); // Close drawer
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerMenuItem(UserMenuItem item) {
    final isSelected = _selectedIndex == item.index;
    
    return ListTile(
      leading: Stack(
        children: [
          Icon(
            item.icon,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            size: 20,
          ),
          if (item.badge != null)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.badge!,
                  style: GoogleFonts.cairo(
                    fontSize: 8,
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        item.title,
        style: GoogleFonts.cairo(
          fontSize: 14,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withOpacity(0.1),
      onTap: () {
        if (mounted) {
          setState(() {
            _selectedIndex = item.index;
          });
        }
        Navigator.pop(context); // Close drawer
      },
    );
  }
} 