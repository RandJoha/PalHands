# User Dashboard Documentation

## 📋 **Overview**

The **User Dashboard** is a comprehensive client management interface for PalHands service consumers. It provides a complete user experience with responsive design, multi-language support, and intuitive navigation across all device types.

## 🎯 **Key Features**

### **Core Functionality**
- **9 Comprehensive Dashboard Sections**: Complete user management across all service needs
- **Responsive Multi-Layout Design**: Single widget tree that adapts to all screen sizes
- **Real-time Language Switching**: Full Arabic/English support with instant updates
- **Smart Navigation System**: Adaptive navigation based on screen size
- **Advanced State Management**: BLoC pattern with proper state handling

### **Dashboard Sections**
1. **My Bookings** - Booking management with filtering and actions (Default Tab)
2. **Chat Messages** - Real-time messaging interface
3. **Payments** - Payment history and management
4. **My Reviews** - Review system with rating management
5. **Profile Settings** - Personal information and preferences
   - Address Book UI updated to match provider/admin style: text button actions (Edit/Delete) and right-aligned "Make Default"; default badge and highlighted border retained
   - Notification Preferences: SMS option removed; Email and Push only
6. **Saved Providers** - Favorite service providers
7. **Support Help** - Help center and support tickets
8. **Security** - Account security and login history

## 📊 **Navigation Structure**

### **Current Navigation (Updated)**
1. **My Bookings** - Default landing tab after login
2. **Chat Messages** - Real-time messaging interface
3. **Payments** - Payment history and management
4. **My Reviews** - Review system with rating management
5. **Profile Settings** - Personal information and preferences
6. **Saved Providers** - Favorite service providers
7. **Support Help** - Help center and support tickets
8. **Security** - Account security and login history

### **Removed Features**
- **Dashboard Home**: Removed to streamline navigation and reduce redundancy
  - Content was largely duplicated in other sections
  - Improved user experience by focusing on actionable features
  - Reduced cognitive load for users
  - My Bookings now serves as the default landing tab

## 🏗️ **Architecture**

### **File Structure**
```
frontend/lib/features/profile/
├── domain/
│   └── models/
│       └── user_menu_item.dart          # Menu item data model
├── presentation/
│   ├── pages/
│   │   └── user_dashboard_screen.dart   # Main dashboard screen
│   └── widgets/
│       ├── responsive_user_dashboard.dart    # Main responsive widget
│       ├── web_user_dashboard.dart           # Web-specific layout
│       ├── mobile_user_dashboard.dart        # Mobile-specific layout
│       ├── user_sidebar.dart                 # Sidebar navigation
│       ├── dashboard_home_widget.dart        # Dashboard home section
│       ├── my_bookings_widget.dart           # Bookings management
│       ├── chat_messages_widget.dart         # Chat interface
│       ├── payments_widget.dart              # Payment management
│       ├── my_reviews_widget.dart            # Review system
│       ├── profile_settings_widget.dart      # Profile settings
│       ├── saved_providers_widget.dart       # Saved providers
│       ├── support_help_widget.dart          # Support system
│       ├── security_widget.dart              # Security settings
│       └── mobile_*.dart                     # Mobile-specific widgets
```

### **Technology Stack**
- **Framework**: Flutter 3.0+
- **State Management**: Provider pattern with ChangeNotifier
- **Navigation**: Custom responsive navigation system
- **Localization**: Custom string management with Arabic/English support
- **UI**: Material 3 with custom theming
- **Responsive**: LayoutBuilder with adaptive breakpoints

## 📱 **Responsive Design Implementation**

### **Multi-Layout Responsive Approach**

#### **Core Philosophy**
The User Dashboard implements a **single responsive widget tree** that adapts its structure, layout, and content presentation based on screen dimensions. This ensures:

- **Consistent User Experience**: Same functionality across all devices
- **Maintainable Code**: Single source of truth for each feature
- **Smooth Transitions**: No jarring layout switches during resizing
- **Performance**: No widget recreation during screen size changes

#### **Responsive Breakpoints**
```dart
// Responsive breakpoints
final isDesktop = screenWidth > 1200;
final isTablet = screenWidth > 768 && screenWidth <= 1200;
final isMobile = screenWidth <= 768;
```

#### **Layout Adaptation**
- **Desktop (>1200px)**: Full sidebar with collapsible menu and language toggle
- **Tablet (768-1200px)**: Compact sidebar with essential navigation
- **Mobile (≤768px)**: Bottom navigation bar with hamburger menu drawer

### **Navigation System**

#### **Desktop/Tablet Navigation**
```dart
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
          _buildSidebarHeader(isDesktop, isTablet),
          Expanded(child: _buildSidebarMenu(isDesktop, isTablet)),
          _buildLanguageToggle(isDesktop, isTablet),
        ],
      ),
    ),
  );
}
```

#### **Mobile Navigation**
```dart
Widget _buildMobileBottomNavigation() {
  // Only show bottom navigation for main sections (0-4)
  if (_selectedIndex > 4) {
    return const SizedBox.shrink();
  }
  
  return BottomNavigationBar(
    type: BottomNavigationBarType.fixed,
    currentIndex: _selectedIndex.clamp(0, 4),
    // ... navigation items
  );
}
```

#### **Hamburger Menu Drawer**
```dart
Widget _buildMobileDrawer() {
  return Consumer<LanguageService>(
    builder: (context, languageService, child) {
      return Drawer(
        child: Container(
          color: AppColors.white,
          child: Column(
            children: [
              _buildDrawerHeader(),
              Expanded(child: _buildDrawerMenuItems()),
              _buildLanguageToggle(),
              _buildDrawerFooter(),
            ],
          ),
        ),
      );
    },
  );
}
```

## 🌍 **Localization System**

### **Advanced String Management**

#### **Centralized String Constants**
```dart
// Location: frontend/lib/core/constants/app_strings.dart
static const Map<String, String> dashboard_home = {
  'en': 'Dashboard Home',
  'ar': 'الرئيسية'
};

static const Map<String, String> my_bookings = {
  'en': 'My Bookings',
  'ar': 'حجوزاتي'
};
```

#### **Dynamic String Resolution**
```dart
String _getLocalizedString(String key) {
  final languageService = Provider.of<LanguageService>(context, listen: false);
  final isArabic = languageService.currentLanguage == 'ar';
  
  switch (key) {
    case 'dashboard_home':
      return isArabic ? 'الرئيسية' : 'Dashboard Home';
    case 'my_bookings':
      return isArabic ? 'حجوزاتي' : 'My Bookings';
    // ... comprehensive translation mapping
  }
}
```

#### **Time Translation System**
```dart
static String getTimeAgo(int value, String unit, String languageCode) {
  if (value == 0) return getString('justNow', languageCode);
  
  String numberStr = value.toString();
  String unitStr = (value == 1) ? getString(unit, languageCode) : getString('${unit}s', languageCode);
  
  if (languageCode == 'ar') {
    if (value == 1 || value == 2) return 'قبل $unitStr';
    return 'قبل $numberStr $unitStr';
  } else {
    return '$value $unitStr ago';
  }
}
```

#### **Month Name Translation**
```dart
static String getMonthName(int month, String languageCode) {
  final months = ['january', 'february', 'march', 'april', 'may', 'june',
                  'july', 'august', 'september', 'october', 'november', 'december'];
  
  if (month >= 1 && month <= 12) {
    return getString(months[month - 1], languageCode);
  }
  return '';
}
```

### **Language Toggle Implementation**

#### **Desktop/Tablet Language Toggle**
```dart
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
```

#### **Mobile Language Toggle**
```dart
Widget _buildMobileLanguageToggle() {
  return Consumer<LanguageService>(
    builder: (context, languageService, child) {
      final isArabic = languageService.isArabic;
      
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => languageService.toggleLanguage(),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              isArabic ? 'ع' : 'EN',
              style: GoogleFonts.cairo(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    },
  );
}
```

## 🎨 **UI/UX Design System**

### **Color Palette**
```dart
// App Colors
static const Color primary = Color(0xFFC43F20);      // Palestinian Red
static const Color secondary = Color(0xFFD4AC0D);    // Golden
static const Color background = Color(0xFFFDF5EC);   // Warm Beige
static const Color white = Color(0xFFFFFFFF);
static const Color textPrimary = Color(0xFF111827);  // Dark Gray
static const Color textSecondary = Color(0xFF6B7280);
static const Color border = Color(0xFFE5E7EB);
static const Color greyLight = Color(0xFFF3F4F6);
static const Color error = Color(0xFFEF4444);
```

### **Typography**
```dart
// Font Family: Cairo (Arabic-friendly)
Text(
  'Dashboard Title',
  style: GoogleFonts.cairo(
    fontSize: isMobile ? 20.0 : 24.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  ),
)
```

### **Responsive Spacing**
```dart
// Adaptive spacing based on screen size
padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
SizedBox(height: isMobile ? 20.0 : 32.0),
```

## 📊 **Dashboard Sections Implementation**

### **1. Dashboard Home**

#### **Features**
- Welcome message with user name
- Statistics cards (upcoming bookings, completed, reviews, favorites)
- Alerts and notifications section
- Upcoming bookings preview
- Quick actions grid

#### **Implementation**
```dart
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
            _buildWelcomeSection(isMobile, isTablet),
            SizedBox(height: isMobile ? 20.0 : 32.0),
            _buildStatsCards(isMobile, isTablet, constraints.maxWidth),
            SizedBox(height: isMobile ? 20.0 : 32.0),
            _buildAlertsSection(isMobile, isTablet),
            SizedBox(height: isMobile ? 20.0 : 32.0),
            _buildUpcomingBookings(isMobile, isTablet),
            SizedBox(height: isMobile ? 20.0 : 32.0),
            _buildQuickActions(isMobile, isTablet, constraints.maxWidth),
          ],
        ),
      );
    },
  );
}
```

### **2. My Bookings**

#### **Features**
- Filter tabs (All, Upcoming, Completed, Cancelled)
- Booking cards with service details
- Action buttons (Cancel, Reschedule, Contact, Track)
- Status indicators with color coding

#### **Implementation**
```dart
Widget _buildMyBookings() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isMobile = constraints.maxWidth <= 768;
      final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
      
      return Column(
        children: [
          _buildBookingFilters(isMobile, isTablet),
          SizedBox(height: isMobile ? 16.0 : 24.0),
          Expanded(
            child: _buildBookingsList(isMobile, isTablet, constraints.maxWidth),
          ),
        ],
      );
    },
  );
}
```

### **3. Chat Messages**

#### **Features**
- Two-panel layout (chat list + message area)
- Real-time message indicators
- Service context for each chat
- Time stamps with localization

#### **Implementation**
```dart
Widget _buildChatMessages() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isMobile = constraints.maxWidth <= 768;
      final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
      
      if (isMobile) {
        return _buildMobileChatLayout();
      } else {
        return _buildDesktopChatLayout(isTablet, constraints.maxWidth);
      }
    },
  );
}
```

### **4. Payments**

#### **Features**
- Payment summary with totals
- Payment methods management
- Transaction history with detailed breakdown
- Status indicators (Pending, Completed, Failed)

#### **Implementation**
```dart
Widget _buildPayments() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isMobile = constraints.maxWidth <= 768;
      final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
      
      return SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          children: [
            _buildPaymentSummary(isMobile, isTablet),
            SizedBox(height: isMobile ? 20.0 : 32.0),
            _buildPaymentMethods(isMobile, isTablet),
            SizedBox(height: isMobile ? 20.0 : 32.0),
            _buildTransactionHistory(isMobile, isTablet),
          ],
        ),
      );
    },
  );
}
```

### **5. My Reviews**

#### **Features**
- Review summary with average rating
- Rating cards with edit functionality
- Service context for each review
- Date and time localization

#### **Implementation**
```dart
Widget _buildMyReviews() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isMobile = constraints.maxWidth <= 768;
      final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
      
      return SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          children: [
            _buildReviewSummary(isMobile, isTablet),
            SizedBox(height: isMobile ? 20.0 : 32.0),
            _buildReviewsList(isMobile, isTablet, constraints.maxWidth),
          ],
        ),
      );
    },
  );
}
```

### **6. Profile Settings**

#### **Features**
- Personal information management
- Address book with saved locations
- Notification preferences
- Account settings

#### **Implementation**
```dart
Widget _buildProfileSettings() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isMobile = constraints.maxWidth <= 768;
      final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
      
      return SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          children: [
            _buildPersonalInfo(isMobile, isTablet),
            SizedBox(height: isMobile ? 20.0 : 32.0),
            _buildAddressBook(isMobile, isTablet),
            SizedBox(height: isMobile ? 20.0 : 32.0),
            _buildNotificationPreferences(isMobile, isTablet),
            SizedBox(height: isMobile ? 20.0 : 32.0),
            _buildAccountSettings(isMobile, isTablet),
          ],
        ),
      );
    },
  );
}
```

### **7. Saved Providers**

#### **Features**
- Provider cards with service details
- Availability status indicators
- Quick booking functionality
- Provider ratings and reviews

#### **Implementation**
```dart
Widget _buildSavedProviders() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isMobile = constraints.maxWidth <= 768;
      final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
      
      return SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          children: [
            _buildSavedProvidersHeader(isMobile, isTablet),
            SizedBox(height: isMobile ? 20.0 : 32.0),
            _buildProvidersGrid(isMobile, isTablet, constraints.maxWidth),
          ],
        ),
      );
    },
  );
}
```

### **8. Support Help**

#### **Features**
- Quick help cards for common issues
- Support ticket system
- FAQ integration
- Contact options

#### **Implementation**
```dart
Widget _buildSupportHelp() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isMobile = constraints.maxWidth <= 768;
      final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
      
      return SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          children: [
            _buildQuickHelpCards(isMobile, isTablet, constraints.maxWidth),
            SizedBox(height: isMobile ? 20.0 : 32.0),
            _buildSupportTickets(isMobile, isTablet),
            SizedBox(height: isMobile ? 20.0 : 32.0),
            _buildContactOptions(isMobile, isTablet),
          ],
        ),
      );
    },
  );
}
```

### **9. Security**

#### **Features**
- Security status overview
- Login history with device information
- Two-factor authentication settings
- Account recovery options

#### **Implementation**
```dart
Widget _buildSecurity() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isMobile = constraints.maxWidth <= 768;
      final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
      
      return SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          children: [
            _buildSecurityStatus(isMobile, isTablet),
            SizedBox(height: isMobile ? 20.0 : 32.0),
            _buildLoginHistory(isMobile, isTablet),
            SizedBox(height: isMobile ? 20.0 : 32.0),
            _buildSecuritySettings(isMobile, isTablet),
            SizedBox(height: isMobile ? 20.0 : 32.0),
            _buildAccountRecovery(isMobile, isTablet),
          ],
        ),
      );
    },
  );
}
```

## 🔧 **State Management**

### **Provider Pattern Implementation**
```dart
class ResponsiveUserDashboard extends StatefulWidget {
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
}
```

### **Language Service Integration**
```dart
Consumer<LanguageService>(
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
)
```

## 🚀 **Performance Optimization**

### **Efficient Rendering**
- **LayoutBuilder**: Responsive layouts without widget recreation
- **AnimatedContainer**: Smooth transitions for sidebar collapse
- **SingleChildScrollView**: Efficient scrolling for long content
- **const Constructors**: Performance optimization for static widgets

### **Memory Management**
- **Proper Disposal**: Animation controllers disposed in dispose method
- **Efficient Lists**: ListView.builder for large lists
- **Image Optimization**: Cached network images with placeholders

### **State Optimization**
- **Selective Rebuilds**: Only necessary widgets rebuild on state changes
- **Efficient Updates**: Minimal state updates to prevent unnecessary rebuilds
- **Proper Context Usage**: Avoid context usage across async gaps

## 🧪 **Testing Strategy**

### **Unit Tests**
```dart
// Test language switching
test('should switch language correctly', () {
  final languageService = LanguageService();
  expect(languageService.currentLanguage, 'en');
  
  languageService.toggleLanguage();
  expect(languageService.currentLanguage, 'ar');
});
```

### **Widget Tests**
```dart
// Test responsive behavior
testWidgets('should show mobile layout on small screen', (WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(375, 812)); // iPhone X size
  
  await tester.pumpWidget(
    MaterialApp(
      home: ResponsiveUserDashboard(),
    ),
  );
  
  expect(find.byType(BottomNavigationBar), findsOneWidget);
  expect(find.byType(Drawer), findsOneWidget);
});
```

### **Integration Tests**
```dart
// Test navigation flow
testWidgets('should navigate between dashboard sections', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ResponsiveUserDashboard(),
    ),
  );
  
  // Tap on My Bookings
  await tester.tap(find.text('My Bookings'));
  await tester.pumpAndSettle();
  
  expect(find.text('My Bookings'), findsOneWidget);
  expect(find.byType(MyBookingsWidget), findsOneWidget);
});
```

## 📱 **Platform Support**

### **Mobile Platforms**
- **Android**: API level 21+ (Android 5.0+)
- **iOS**: iOS 11.0+
- **Responsive Design**: Adaptive layouts for all screen sizes

### **Web Platform**
- **Progressive Web App**: PWA capabilities
- **Responsive Web**: Desktop and tablet support
- **Cross-Browser**: Modern browser compatibility

### **Responsive Breakpoints**
```dart
// Mobile: ≤768px
// Tablet: 768-1200px  
// Desktop: >1200px
```

## 🔒 **Security Features**

### **Authentication**
- **JWT Token Management**: Secure token handling
- **Session Management**: Proper session lifecycle
- **Role-Based Access**: User-specific permissions

### **Data Protection**
- **Input Validation**: All user inputs validated
- **XSS Prevention**: Proper data sanitization
- **CSRF Protection**: Cross-site request forgery prevention

## 📈 **Analytics & Monitoring**

### **User Behavior Tracking**
- **Navigation Patterns**: Track user navigation flow
- **Feature Usage**: Monitor dashboard section usage
- **Performance Metrics**: Track loading times and responsiveness

### **Error Monitoring**
- **Crash Reporting**: Automatic error reporting
- **Performance Monitoring**: Track app performance
- **User Feedback**: Collect user feedback and issues

## 🔄 **Future Enhancements**

### **Planned Features**
- **Real-time Notifications**: Push notifications for updates
- **Advanced Search**: Global search across all sections
- **Data Export**: Export user data and reports
- **Customization**: User-customizable dashboard layout

### **Technical Improvements**
- **Offline Support**: Offline functionality for core features
- **Performance Optimization**: Further performance improvements
- **Accessibility**: Enhanced accessibility features
- **Internationalization**: Support for additional languages

## 📚 **API Integration**

### **Backend Endpoints**
```dart
// User Dashboard API endpoints
class UserDashboardAPI {
  static const String baseUrl = '/api/user';
  
  // Dashboard data
  static const String dashboard = '$baseUrl/dashboard';
  
  // Bookings
  static const String bookings = '$baseUrl/bookings';
  static const String bookingDetails = '$baseUrl/bookings/{id}';
  
  // Messages
  static const String messages = '$baseUrl/messages';
  static const String sendMessage = '$baseUrl/messages/send';
  
  // Payments
  static const String payments = '$baseUrl/payments';
  static const String paymentMethods = '$baseUrl/payments/methods';
  
  // Reviews
  static const String reviews = '$baseUrl/reviews';
  static const String submitReview = '$baseUrl/reviews/submit';
  
  // Profile
  static const String profile = '$baseUrl/profile';
  static const String updateProfile = '$baseUrl/profile/update';
  
  // Security
  static const String security = '$baseUrl/security';
  static const String loginHistory = '$baseUrl/security/login-history';
}
```

### **Data Models**
```dart
// User Dashboard data models
class DashboardData {
  final UserInfo user;
  final DashboardStats stats;
  final List<Booking> upcomingBookings;
  final List<Alert> alerts;
  final List<QuickAction> quickActions;
}

class DashboardStats {
  final int upcomingBookings;
  final int completedBookings;
  final int totalReviews;
  final int savedProviders;
}

class Booking {
  final String id;
  final String serviceName;
  final String providerName;
  final DateTime scheduledDate;
  final String status;
  final double amount;
  final String address;
}
```

## 🎯 **Best Practices**

### **Code Organization**
- **Feature-Based Structure**: Each dashboard section is self-contained
- **Clean Architecture**: Separation of concerns
- **Single Responsibility**: Each widget has one purpose
- **Dependency Injection**: Loose coupling between components

### **Performance Guidelines**
- **Efficient Rendering**: Use appropriate widgets for performance
- **Memory Management**: Proper disposal of resources
- **State Optimization**: Minimize unnecessary rebuilds
- **Image Optimization**: Use appropriate image formats and sizes

### **Accessibility**
- **Semantic Labels**: Proper semantic labels for screen readers
- **Color Contrast**: Sufficient color contrast for readability
- **Touch Targets**: Adequate touch target sizes
- **Keyboard Navigation**: Full keyboard navigation support

### **Security**
- **Input Validation**: Validate all user inputs
- **Data Encryption**: Encrypt sensitive data
- **Secure Communication**: Use HTTPS for all API calls
- **Session Management**: Proper session handling

## 📝 **Documentation Standards**

### **Code Documentation**
- **Inline Comments**: Complex logic explanation
- **Widget Documentation**: Purpose and usage of each widget
- **API Documentation**: Clear API endpoint documentation
- **Architecture Documentation**: System design and patterns

### **User Documentation**
- **Feature Guides**: How to use each dashboard section
- **FAQ System**: Common questions and answers
- **Video Tutorials**: Visual learning resources
- **Help Center**: Comprehensive help documentation

---

## 📋 **Implementation Checklist**

### **Core Features** ✅
- [x] Responsive multi-layout design
- [x] 9 comprehensive dashboard sections
- [x] Real-time language switching
- [x] Smart navigation system
- [x] Mobile hamburger menu with drawer
- [x] Bottom navigation for main sections
- [x] Language toggle in app bar and drawer
- [x] Complete Arabic/English localization
- [x] Advanced string management system
- [x] Time and date translation system
- [x] Cultural sensitivity (Palestine-first)
- [x] Performance optimization
- [x] Error handling and validation

### **UI/UX Features** ✅
- [x] Material 3 design system
- [x] Palestinian color palette
- [x] Cairo font family
- [x] Responsive typography
- [x] Adaptive spacing
- [x] Smooth animations
- [x] Touch-friendly interactions
- [x] Accessibility support

### **Technical Features** ✅
- [x] Provider state management
- [x] Animation controllers
- [x] LayoutBuilder implementation
- [x] Scaffold key management
- [x] Proper widget disposal
- [x] Memory optimization
- [x] Performance monitoring

### **Testing** ✅
- [x] Unit tests for core functionality
- [x] Widget tests for UI components
- [x] Integration tests for navigation
- [x] Responsive design testing
- [x] Language switching testing
- [x] Error handling testing

---

**Last Updated**: December 2024  
**Version**: 1.0.0  
**Maintained By**: PalHands Development Team 