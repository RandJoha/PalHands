import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'shared/services/language_service.dart';
import 'shared/services/auth_service.dart';
import 'core/constants/app_strings.dart';
import 'core/constants/app_colors.dart';
import 'shared/widgets/auth_wrapper.dart';
import 'shared/services/responsive_service.dart';
// Top-level routed screens
import 'features/home/presentation/pages/home_screen.dart';
import 'features/categories/presentation/pages/category_screen.dart';
import 'features/about/presentation/pages/about_screen.dart';
import 'features/contact/presentation/pages/contact_screen.dart';
import 'features/faqs/presentation/pages/faqs_screen.dart';
import 'features/admin/presentation/pages/admin_dashboard_screen.dart';
import 'features/provider/presentation/pages/provider_dashboard_screen.dart';
import 'features/profile/presentation/pages/user_dashboard_screen.dart';
import 'shared/widgets/login_screen.dart';
import 'shared/widgets/signup_screen.dart';
import 'shared/widgets/reset_password_screen.dart';

// Minimal app entrypoint for Flutter Web + Mobile
// Wires core services and routes through AuthWrapper to ensure authentication.
Future<void> main() async {
	WidgetsFlutterBinding.ensureInitialized();

	final language = LanguageService();
	await language.initializeLanguage();

	final auth = AuthService();
	await auth.initialize();

	runApp(MyApp(language: language, auth: auth));
}

class MyApp extends StatelessWidget {
	final LanguageService language;
	final AuthService auth;
	const MyApp({super.key, required this.language, required this.auth});

	@override
	Widget build(BuildContext context) {
		return MultiProvider(
			providers: [
				ChangeNotifierProvider<LanguageService>.value(value: language),
				ChangeNotifierProvider<AuthService>.value(value: auth),
				ChangeNotifierProvider<ResponsiveService>(create: (_) => ResponsiveService()),
			],
			child: Builder(
				builder: (context) {
					final lang = context.watch<LanguageService>().currentLanguage;
					return MaterialApp(
						debugShowCheckedModeBanner: false,
						title: AppStrings.appName[lang] ?? 'PalHands',
						theme: ThemeData(
							colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
							textTheme: GoogleFonts.cairoTextTheme(),
							useMaterial3: true,
						),
						home: const AuthWrapper(),
						routes: {
							'/home': (context) => const HomeScreen(),
							'/about': (context) => const AboutScreen(),
							'/contact': (context) => const ContactScreen(),
							'/faqs': (context) => const FAQsScreen(),
							'/categories': (context) => const CategoryScreen(),
							'/admin': (context) => const AdminDashboardScreen(),
							'/provider': (context) => const ProviderDashboardScreen(),
							'/user': (context) => const UserDashboardScreen(),
							'/login': (context) => const LoginScreen(),
							'/signup': (context) => const SignupScreen(),
						},
						onGenerateRoute: (settings) {
							final name = settings.name ?? '';
							final uri = Uri.tryParse(name);
							if (uri != null) {
								// Normalize routes that include query parameters
								switch (uri.path) {
									case '/':
										return MaterialPageRoute(builder: (_) => const AuthWrapper());
									case '/user':
										// Optional: parse ?tab= but default to dashboard
										return MaterialPageRoute(builder: (_) => const UserDashboardScreen());
									case '/reset-password':
										final token = uri.queryParameters['token'];
										return MaterialPageRoute(builder: (_) => ResetPasswordScreen(token: token));
									default:
										break;
								}
							}
							// Fallback to home for unknown routes
							return MaterialPageRoute(builder: (_) => const HomeScreen());
						},
					);
				},
			),
		);
	}
}

