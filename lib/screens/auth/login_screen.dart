// Login Screen - Sky Blue Theme

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'register_screen.dart';
import '../student/student_dashboard.dart';
import '../doctor/lecturer_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  final _storageService = StorageService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _apiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      if (result['success']) {
        // Get role from storage service (safer than trusting JSON directly)
        final role = await _storageService.getUserRole();

        // Navigate based on role
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
          // Unknown role
          _showErrorSnackBar('Invalid user role');
        }
      } else {
        // Show error message from API
        _showErrorSnackBar(result['message'] ?? 'Login failed');
      }
    } catch (e) {
      // Connection error or other exception
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      _showErrorSnackBar(
        'Connection error. Please check your internet and try again.',
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Layer 1: Gradient background - CHANGED TO SKY BLUE
          Container(
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
          ),

          // Layer 2: Circle pattern overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _CirclePatternPainter(),
            ),
          ),

          // Layer 3: Form content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo/icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Glassmorphic card
                    Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              'Welcome Back!',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sign in to continue',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Email Field
                            CustomTextField(
                              controller: _emailController,
                              label: 'Email',
                              hint: 'Enter your email',
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.email_rounded,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Password Field
                            CustomTextField(
                              controller: _passwordController,
                              label: 'Password',
                              hint: 'Enter your password',
                              isPassword: true,
                              prefixIcon: Icons.lock_rounded,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 8) {
                                  return 'Password must be at least 8 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),

                            // Login Button with gradient - CHANGED TO SKY BLUE
                            CustomButton(
                              text: 'Login',
                              icon: Icons.login_rounded,
                              onPressed: _handleLogin,
                              isLoading: _isLoading,
                              gradientColors: [
                                Colors.lightBlue.shade600,
                                Colors.cyan.shade500,
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Register Link - CHANGED TO SKY BLUE
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[700],
                                  ),
                                ),
                                TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                        const RegisterScreen(),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                  ),
                                  child: Text(
                                    'Register',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.lightBlue.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Footer text
                    Text(
                      'Attendify © 2025',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Circle Pattern Background (reused from main.dart)
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
