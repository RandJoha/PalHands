import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Core imports
import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';

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
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            // Bloc providers will be added here
            // BlocProvider<AuthBloc>(
            //   create: (context) => AuthBloc(),
            // ),
            // BlocProvider<ServicesBloc>(
            //   create: (context) => ServicesBloc(),
            // ),
            // BlocProvider<BookingsBloc>(
            //   create: (context) => BookingsBloc(),
            // ),
          ],
          child: MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
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
            // Navigation will be implemented with GoRouter
            // initialLocation: '/splash',
            // routerConfig: AppRouter.router,
          ),
        );
      },
    );
  }
}

// Temporary splash screen
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo will be added here
            Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                Icons.handshake,
                size: 60.sp,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              AppStrings.appName,
              style: GoogleFonts.cairo(
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              AppStrings.appTagline,
              style: GoogleFonts.cairo(
                fontSize: 16.sp,
                color: AppColors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40.h),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
} 