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
import 'shared/widgets/splash_screen.dart';
import 'features/home/presentation/pages/home_screen.dart';
import 'features/categories/presentation/pages/category_screen.dart';
import 'features/about/presentation/pages/about_screen.dart';
import 'features/faqs/presentation/pages/faqs_screen.dart';
import 'features/contact/presentation/pages/contact_screen.dart';

// Services
import 'shared/services/language_service.dart';
import 'shared/services/health_service.dart';

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
                home: const SplashScreen(),
                routes: {
                  '/home': (context) => const HomeScreen(),
                  '/categories': (context) => const CategoryScreen(),
                  '/about': (context) => const AboutScreen(),
                  '/faqs': (context) => const FAQsScreen(),
                  '/contact': (context) => const ContactScreen(),
                },
              );
            },
          ),
        );
      },
    );
  }
} 