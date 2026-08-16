import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:onam_pass/utils/constants.dart';
import 'package:onam_pass/screens/home_screen.dart';
import 'package:onam_pass/screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation for a consistent event-day experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const OnamPassApp());
}

class OnamPassApp extends StatelessWidget {
  const OnamPassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Onam Pass',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = snapshot.data?.session;
          if (session != null) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: OnamColors.green,
        primary: OnamColors.green,
        secondary: OnamColors.gold,
        surface: OnamColors.surface,
        error: OnamColors.error,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme),
      scaffoldBackgroundColor: OnamColors.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
