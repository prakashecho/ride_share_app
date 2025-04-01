import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:provider/provider.dart';
import 'package:ride_share_app/auth/app_auth_state.dart';
import 'package:ride_share_app/screens/home_screen.dart';
import 'package:ride_share_app/screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Make sure this path is correct for your project structure
import 'package:ride_share_app/services/api_service.dart';

// --- IMPORTANT: Replace with your actual Supabase credentials ---
const String supabaseUrl = 'https://uvunkxnnfffydpuquzry.supabase.co'; // Replace!
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV2dW5reG5uZmZmeWRwdXF1enJ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI4MDg3MDIsImV4cCI6MjA1ODM4NDcwMn0.WUxFLCi089TPWIoaiELSUas8jZxlkX454viM7yzZ63U'; // Replace!
// --- IMPORTANT ---

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // Optional: Initialize Google Fonts license if bundling fonts
  // GoogleFonts.config.allowRuntimeFetching = false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppAuthState()),
        Provider<ApiService>(
          create: (_) => ApiService(),
          // dispose: (_, service) => service.dispose(), // Optional cleanup
        ),
      ],
      child: const MyApp(),
    ),
  );
}

// Global Supabase client instance (consider accessing via ApiService provider)
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- Enhanced Theming using Material 3 & Google Fonts ---

    const Color seedColor = Colors.teal; // Main brand color

    // Generate Light ColorScheme from seed
    final ColorScheme lightColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    // Generate Dark ColorScheme from seed
    final ColorScheme darkColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      surface: const Color(0xFF212121), // Slightly lighter dark surface
    );

    // Define base TextTheme using Google Fonts (CORRECTED)
    final TextTheme baseTextTheme = GoogleFonts.latoTextTheme(); // Create theme directly

    // Apply color scheme colors to the text theme
    final TextTheme lightTextTheme = baseTextTheme.apply(
      bodyColor: lightColorScheme.onBackground,
      displayColor: lightColorScheme.onBackground,
    );

    final TextTheme darkTextTheme = baseTextTheme.apply(
      bodyColor: darkColorScheme.onBackground,
      displayColor: darkColorScheme.onBackground,
    );

    // --- End Enhanced Theming ---

    return MaterialApp(
      title: 'Ride Share App',
      debugShowCheckedModeBanner: false,

      // --- THEME DEFINITION ---
      theme: ThemeData( // Light Theme
        colorScheme: lightColorScheme,
        textTheme: lightTextTheme,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          backgroundColor: lightColorScheme.primaryContainer,
          foregroundColor: lightColorScheme.onPrimaryContainer,
          elevation: 1,
          titleTextStyle: lightTextTheme.titleLarge,
        ),
        inputDecorationTheme: _buildInputDecorationTheme(lightColorScheme),
        elevatedButtonTheme: _buildElevatedButtonTheme(lightColorScheme, lightTextTheme),
        textButtonTheme: _buildTextButtonTheme(lightColorScheme, lightTextTheme),
        cardTheme: _buildCardTheme(lightColorScheme),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
           backgroundColor: lightColorScheme.primary,
           foregroundColor: lightColorScheme.onPrimary,
        ),
      ),

      darkTheme: ThemeData( // Dark Theme
        colorScheme: darkColorScheme,
        textTheme: darkTextTheme,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: darkColorScheme.background,
        appBarTheme: AppBarTheme(
          backgroundColor: darkColorScheme.surface,
          foregroundColor: darkColorScheme.onSurface,
          elevation: 1,
          titleTextStyle: darkTextTheme.titleLarge,
        ),
        inputDecorationTheme: _buildInputDecorationTheme(darkColorScheme),
        elevatedButtonTheme: _buildElevatedButtonTheme(darkColorScheme, darkTextTheme),
        textButtonTheme: _buildTextButtonTheme(darkColorScheme, darkTextTheme),
        cardTheme: _buildCardTheme(darkColorScheme),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
           backgroundColor: darkColorScheme.primary,
           foregroundColor: darkColorScheme.onPrimary,
        ),
      ),
      // --- END THEME DEFINITION ---

      themeMode: ThemeMode.system, // Respect user's system preference

      home: Consumer<AppAuthState>(
        builder: (context, authState, child) {
          if (authState.isLoading) {
            return const SplashScreen(); // Show themed splash screen
          }
          if (authState.currentUser != null) {
            return const HomeScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }

  // Helper method for consistent InputDecorationTheme
  InputDecorationTheme _buildInputDecorationTheme(ColorScheme colorScheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
      ),
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
      prefixIconColor: colorScheme.onSurfaceVariant,
    );
  }

  // Helper method for consistent ElevatedButtonThemeData
  ElevatedButtonThemeData _buildElevatedButtonTheme(ColorScheme colorScheme, TextTheme textTheme) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)
      ),
    );
  }

  // Helper method for consistent TextButtonThemeData
  TextButtonThemeData _buildTextButtonTheme(ColorScheme colorScheme, TextTheme textTheme) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      )
    );
  }

   // Helper method for consistent CardTheme
  CardTheme _buildCardTheme(ColorScheme colorScheme) {
    return CardTheme(
      elevation: 1,
      color: colorScheme.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        // side: BorderSide(color: colorScheme.outline.withOpacity(0.5), width: 1), // Optional border
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}

// Simple Splash Screen Widget
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading Ride Share...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}


// --- Placeholder/Example ApiService class ---
// Ensure this exists in lib/services/api_service.dart
/*
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getTrips() async {
    try {
      final response = await _supabase.from('trips').select();
      return response;
    } catch (e) {
      print('Error fetching trips: $e');
      throw Exception('Failed to load trips: $e');
    }
  }

  // ... other methods ...

  // void dispose() { ... }
}
*/