import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

// Core imports
import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';

// Widget imports
import 'shared/widgets/auth_wrapper.dart';
import 'shared/widgets/login_screen.dart';
import 'shared/widgets/signup_screen.dart';
import 'shared/widgets/reset_password_screen.dart';
import 'shared/widgets/verify_email_screen.dart';
import 'features/home/presentation/pages/home_screen.dart';
import 'features/categories/presentation/pages/category_screen.dart';
import 'features/about/presentation/pages/about_screen.dart';
import 'features/faqs/presentation/pages/faqs_screen.dart';
import 'features/contact/presentation/pages/contact_screen.dart';
import 'features/admin/presentation/pages/admin_dashboard_screen.dart';
import 'features/profile/presentation/pages/user_dashboard_screen.dart';
import 'features/provider/presentation/pages/provider_dashboard_screen.dart';

// Services
import 'shared/services/language_service.dart';
import 'shared/services/health_service.dart';
import 'shared/services/auth_service.dart';
import 'shared/services/responsive_service.dart';
import 'shared/services/provider_service.dart';

// Feature imports (to be implemented)
// import 'features/auth/presentation/bloc/auth_bloc.dart';
// import 'features/services/presentation/bloc/services_bloc.dart';
// import 'features/bookings/presentation/bloc/bookings_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Initialize screen utilities
  await ScreenUtil.ensureScreenSize();
  // Force frontend-only mocks for Providers/Our Services (decouple from backend)
  ProviderService.useFrontendMocks(true);
  
  runApp(const PalHandsApp());
}

class PalHandsApp extends StatelessWidget {
  const PalHandsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1920, 1080), // Web-first design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (context) => LanguageService()..initializeLanguage()),
            ChangeNotifierProvider(create: (context) => HealthService()),
            ChangeNotifierProvider(
              create: (context) => AuthService()..initialize(),
            ),
            ChangeNotifierProvider(create: (context) => ResponsiveService()),
          ],
          child: Consumer<LanguageService>(
            builder: (context, languageService, child) {
              return MaterialApp(
                title: AppStrings.getString('appName', languageService.currentLanguage),
                debugShowCheckedModeBanner: false,
                locale: Locale(languageService.currentLanguage),
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('en'),
                  Locale('ar'),
                ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.light,
            ),
            textTheme: GoogleFonts.cairoTextTheme(
              Theme.of(context).textTheme,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.background,
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: GoogleFonts.cairo(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 12.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ),
                // Do not set `home` or `initialRoute` so the browser URL is respected on web.
                routes: {
                  '/home': (context) => const HomeScreen(),
                  '/categories': (context) => const CategoryScreen(),
                  '/about': (context) => const AboutScreen(),
                  '/faqs': (context) => const FAQsScreen(),
                  '/contact': (context) => const ContactScreen(),
                  '/admin': (context) => const AdminDashboardScreen(),
                  '/user': (context) => const UserDashboardScreen(),
                  '/login': (context) => const LoginScreen(),
                  '/signup': (context) => const SignupScreen(),
                  '/provider': (context) => const ProviderDashboardScreen(),
                },
                // Handle deep links with query parameters (e.g., /reset-password?token=...)
                onGenerateRoute: (settings) {
                  final uri = Uri.tryParse(settings.name ?? '/') ?? Uri(path: '/');
                  // If backend redirected with evt=email-updated, refresh profile once
                  if (uri.queryParameters['evt'] == 'email-updated' && uri.path == '/user') {
                    return MaterialPageRoute(
                      builder: (_) => const _ProfileRefresh(child: UserDashboardScreen()),
                      settings: const RouteSettings(name: '/user'),
                    );
                  }
                  if (uri.path == '/reset-password') {
                    final token = uri.queryParameters['token'];
                    return MaterialPageRoute(
                      builder: (_) => ResetPasswordScreen(token: token),
                      settings: settings,
                    );
                  }
                  if (uri.path == '/verify-email') {
                    final token = uri.queryParameters['token'];
                    final ret = uri.queryParameters['r'];
                    return MaterialPageRoute(
                      builder: (_) => VerifyEmailScreen(token: token, returnPath: ret),
                      settings: settings,
                    );
                  }
                  // Default and fallbacks
                  switch (uri.path) {
                    case '/':
                      return MaterialPageRoute(builder: (_) => const AuthWrapper(), settings: settings);
                    case '/home':
                      return MaterialPageRoute(builder: (_) => const HomeScreen(), settings: settings);
                    case '/categories':
                      return MaterialPageRoute(builder: (_) => const CategoryScreen(), settings: settings);
                    case '/about':
                      return MaterialPageRoute(builder: (_) => const AboutScreen(), settings: settings);
                    case '/faqs':
                      return MaterialPageRoute(builder: (_) => const FAQsScreen(), settings: settings);
                    case '/contact':
                      return MaterialPageRoute(builder: (_) => const ContactScreen(), settings: settings);
                    case '/admin':
                      return MaterialPageRoute(builder: (_) => const AdminDashboardScreen(), settings: settings);
                    case '/user':
                      return MaterialPageRoute(builder: (_) => const UserDashboardScreen(), settings: settings);
                    case '/login':
                      return MaterialPageRoute(builder: (_) => const LoginScreen(), settings: settings);
                    case '/signup':
                      return MaterialPageRoute(builder: (_) => const SignupScreen(), settings: settings);
                    case '/provider':
                      return MaterialPageRoute(builder: (_) => const ProviderDashboardScreen(), settings: settings);
                  }
                  // Unknown route -> home
                  return MaterialPageRoute(builder: (_) => const AuthWrapper(), settings: settings);
                },
                onGenerateInitialRoutes: (initialRoute) {
                  final uri = Uri.tryParse(Uri.base.toString()) ?? Uri(path: '/');
                  if (uri.queryParameters['evt'] == 'email-updated' && uri.path == '/user') {
                    return [
                      MaterialPageRoute(
                        builder: (_) => const _ProfileRefresh(child: UserDashboardScreen()),
                        settings: const RouteSettings(name: '/user'),
                      )
                    ];
                  }
                  if (uri.path == '/reset-password') {
                    final token = uri.queryParameters['token'];
                    return [
                      MaterialPageRoute(
                        builder: (_) => ResetPasswordScreen(token: token),
                        settings: const RouteSettings(name: '/reset-password'),
                      )
                    ];
                  }
                  if (uri.path == '/verify-email') {
                    final token = uri.queryParameters['token'];
                    final ret = uri.queryParameters['r'];
                    return [
                      MaterialPageRoute(
                        builder: (_) => VerifyEmailScreen(token: token, returnPath: ret),
                        settings: const RouteSettings(name: '/verify-email'),
                      )
                    ];
                  }
                  // Default initial page
                  return [
                    MaterialPageRoute(
                      builder: (_) => const AuthWrapper(),
                      settings: const RouteSettings(name: '/'),
                    )
                  ];
                },
              );
            },
          ),
        );
      },
    );
  }
} 

// Internal helper: refresh the current profile once, then show the provided child.
class _ProfileRefresh extends StatefulWidget {
  final Widget child;
  const _ProfileRefresh({required this.child});
  @override
  State<_ProfileRefresh> createState() => _ProfileRefreshState();
}

class _ProfileRefreshState extends State<_ProfileRefresh> {
  bool _refreshed = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_refreshed) {
      _refreshed = true;
      final auth = Provider.of<AuthService>(context, listen: false);
      Future.microtask(() async { try { await auth.getProfile(); } catch (_) {} });
    }
  }
  @override
  Widget build(BuildContext context) => widget.child;
}