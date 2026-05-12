// lib/main.dart (Final Update with Auth & Theme Persistence)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/theme_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/dashboard/presentation/pages/dashboard_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase Init
  await Supabase.initialize(
    url: 'https://yromirxnpjknpkohsnes.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlyb21pcnhucGprbnBrb2hzbmVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0NTE2ODQsImV4cCI6MjA5MzAyNzY4NH0.B06CD5Lj4FBeAm3ua5qXRvokYD5UKEDJd1Bw0ntIexA',
  );

  // 🚀 NAYA: Login aur Theme dono ko fetch karna
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final int? savedColor = prefs.getInt('app_theme_color'); // Saved color code

  runApp(ProviderScope(
    overrides: [
      // 🚀 NAYA: App start hote hi provider mein purana color inject karna
      if (savedColor != null)
        themeProvider.overrideWith((ref) => ThemeNotifier()..loadSavedTheme(Color(savedColor))),
    ],
    child: AzamKiryanaApp(isLoggedIn: isLoggedIn),
  ));
}

class AzamKiryanaApp extends ConsumerWidget {
  final bool isLoggedIn;
  const AzamKiryanaApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Azam Kiryana Store POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeState.primaryColor,
          primary: themeState.primaryColor,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: themeState.primaryColor,
          centerTitle: true,
          elevation: 0,
          titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: themeState.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: isLoggedIn ? const DashboardScreen() : const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}