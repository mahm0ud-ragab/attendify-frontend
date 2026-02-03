// Main Entry Point of the App - Sky Blue Theme with Localization Support

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:math' as math;
import 'services/storage_service.dart';
import 'services/localization_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/student/student_dashboard.dart';
import 'screens/doctor/lecturer_dashboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Customize status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // Static method to change locale from anywhere in the app
  static void setLocale(BuildContext context, Locale newLocale) {
    final state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  // Static method to get current locale
  static Locale? getLocale(BuildContext context) {
    final state = context.findAncestorStateOfType<_MyAppState>();
    return state?._locale;
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;
  final _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _loadSavedLocale();
  }

  // Load saved locale from storage
  Future<void> _loadSavedLocale() async {
    try {
      final savedLocaleCode = await _storageService.getString('locale');
      if (savedLocaleCode != null && mounted) {
        setState(() {
          _locale = Locale(savedLocaleCode);
        });
      }
    } catch (e) {
      debugPrint('Error loading locale: $e');
    }
  }

  // Change locale and save to storage
  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
    _storageService.setString('locale', locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendify',
      debugShowCheckedModeBanner: false,

      // Localization Configuration
      locale: _locale,
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('ar', ''), // Arabic
        Locale('fr', ''), // French
        Locale('es', ''), // Spanish
        Locale('de', ''), // German
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: ThemeData(
        // Sky Blue Theme
        primarySwatch: Colors.lightBlue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlue,
          brightness: Brightness.light,
        ),
        // Modern typography
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// Splash Screen with modern design and animations
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final _storageService = StorageService();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    // Start animation
    _controller.forward();

    _checkLoginStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    // Wait to show splash screen and animation
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // Check if user is logged in
    final isLoggedIn = await _storageService.isLoggedIn();

    if (isLoggedIn) {
      // Get user role
      final role = await _storageService.getUserRole();

      // Navigate to appropriate dashboard
      if (role == 'student') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const StudentDashboard(),
          ),
        );
      } else if (role == 'lecturer' || role == 'doctor') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LecturerDashboard(),
          ),
        );
      } else {
        // Invalid role, go to login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    } else {
      // Not logged in, go to login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Sky Blue Gradient
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.lightBlue.shade800,
              Colors.lightBlue.shade400,
              Colors.cyan.shade300,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(
              child: CustomPaint(
                painter: _CirclePatternPainter(),
              ),
            ),

            // Content
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Glassmorphism logo container
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/Logo.png',
                        width: 150,
                        height: 150,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback icon if image fails to load
                          return Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 60,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 40),

                    // App Name
                    const Text(
                      'Attendify',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Tagline
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'University Attendance Management',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Loading Indicator
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for Circle Pattern Background
class _CirclePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    // Draw decorative circles
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.2),
      60,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.8),
      45,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 1.05, size.height * 0.85),
      80,
      paint,
    );

    // Draw curved wave-like path
    final wavePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, size.height * 0.4);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        size.height * 0.4 + math.sin((i / size.width) * 2 * math.pi) * 20,
      );
    }

    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
