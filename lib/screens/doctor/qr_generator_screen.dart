// QR Generator Screen - Royal Purple Theme (Lecturer Side)

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrGeneratorScreen extends StatefulWidget {
  final String courseTitle;
  final String courseId;

  const QrGeneratorScreen({
    super.key,
    required this.courseTitle,
    required this.courseId,
  });

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen>
    with SingleTickerProviderStateMixin {
  // ── Token & countdown state ──────────────────────────────────────────────
  static const int _totalSeconds = 5;

  String _qrData = '';
  int _timeLeft = _totalSeconds;
  Timer? _timer;

  // ── Animation controller for the countdown ring ─────────────────────────
  late final AnimationController _ringController;

  @override
  void initState() {
    super.initState();

    // Ring animates from 1.0 → 0.0 over _totalSeconds
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _totalSeconds),
    );

    // Generate the very first token immediately so the QR is never empty
    _generateToken();
    _startRotation();
  }

  // ── Token helpers ────────────────────────────────────────────────────────
  void _generateToken() {
    _qrData = '${widget.courseId}_${DateTime.now().millisecondsSinceEpoch}';
  }

  void _startRotation() {
    _ringController.forward(from: 0.0);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft <= 1) {
          // Token expired → rotate
          _generateToken();
          _timeLeft = _totalSeconds;
          _ringController.forward(from: 0.0); // restart ring animation
        } else {
          _timeLeft--;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ringController.dispose();
    super.dispose();
  }

  // ── Color helpers ────────────────────────────────────────────────────────
  /// Border & glow colour: transitions green → amber → red as time runs out
  Color get _borderColor {
    if (_timeLeft >= 4) return Colors.deepPurple.shade400;
    if (_timeLeft >= 2) return Colors.amber.shade600;
    return Colors.red.shade500;
  }

  Color get _glowColor {
    if (_timeLeft >= 4) return Colors.deepPurple.shade400;
    if (_timeLeft >= 2) return Colors.amber.shade600;
    return Colors.red.shade500;
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // Layer 1: Royal Purple gradient (identical to lecturer dashboard)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.deepPurple.shade900,
                  Colors.deepPurple.shade800,
                  Colors.purple.shade700,
                ],
              ),
            ),
          ),

          // Layer 2: Decorative circle pattern overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _CirclePatternPainter(),
            ),
          ),

          // Layer 3: Content
          SafeArea(
            child: Column(
              children: [
                // ── Custom Header ───────────────────────────────────────────
                _buildCustomHeader(textTheme),

                // ── Scrollable body ─────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Course info glass card
                        _buildCourseInfoCard(textTheme),
                        const SizedBox(height: 24),

                        // QR code glass card (main focus)
                        _buildQrCard(textTheme),
                        const SizedBox(height: 24),

                        // Projector mode button
                        _buildProjectorButton(textTheme),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Custom Header (matches dashboard pattern exactly) ───────────────────
  Widget _buildCustomHeader(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: Colors.white,
              onPressed: () => Navigator.pop(context),
              tooltip: 'Back',
            ),
          ),

          // Title
          Text(
            'QR Generator',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),

          // Placeholder to keep title centred
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ── Course info card ─────────────────────────────────────────────────────
  Widget _buildCourseInfoCard(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Course icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.class_rounded,
              color: Colors.deepPurple.shade700,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),

          // Course title + label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.courseTitle,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade900,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Attendance Session',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Live badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border.all(
                color: Colors.green.shade300,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pulsing dot
                _PulsingDot(color: Colors.green.shade500),
                const SizedBox(width: 6),
                Text(
                  'Live',
                  style: textTheme.labelMedium?.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Main QR card ─────────────────────────────────────────────────────────
  Widget _buildQrCard(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Section title
          Text(
            'Scan to Mark Attendance',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple.shade900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Students scan the QR code below',
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // ── Countdown ring + QR ──────────────────────────────────────────
          Stack(
            alignment: Alignment.center,
            children: [
              // Animated countdown ring
              AnimatedBuilder(
                animation: _ringController,
                builder: (context, child) {
                  return SizedBox(
                    width: 310,
                    height: 310,
                    child: CustomPaint(
                      painter: _CountdownRingPainter(
                        progress: 1.0 - _ringController.value,
                        color: _borderColor,
                      ),
                    ),
                  );
                },
              ),

              // QR code with animated border colour
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _borderColor,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _glowColor.withValues(alpha: 0.25),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: _qrData,
                  version: QrVersions.auto,
                  size: 220.0,

                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.deepPurple.shade800,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.deepPurple.shade800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Countdown label + refresh badge ──────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.refresh_rounded,
                size: 18,
                color: _borderColor,
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Text(
                  'Refreshing in $_timeLeft s',
                  key: ValueKey(_timeLeft),
                  style: textTheme.bodyLarge?.copyWith(
                    color: _borderColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Projector mode button ────────────────────────────────────────────────
  Widget _buildProjectorButton(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Copy link to clipboard / open projector mode
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.cast_rounded,
                    color: Colors.deepPurple.shade700,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Projector Mode',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade900,
                      ),
                    ),
                    Text(
                      'Open full-screen QR for projection',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Countdown Ring Painter ───────────────────────────────────────────────────
/// Draws an arc that shrinks as [progress] goes from 1.0 → 0.0.
class _CountdownRingPainter extends CustomPainter {
  final double progress; // 1.0 = full ring, 0.0 = empty
  final Color color;

  const _CountdownRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 6;

    // Track (background arc)
    final trackPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc — starts at top (−π/2) and sweeps clockwise
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,                   // start angle (12 o'clock)
      2 * math.pi * progress,         // sweep angle
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

// ── Pulsing Dot (for the "Live" badge) ──────────────────────────────────────
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({super.key, required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        // Pulse opacity between 0.4 and 1.0
        final opacity = 0.4 + (math.sin(_ctrl.value * math.pi) * 0.6);
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

// ── Circle Pattern Painter (identical to dashboards) ────────────────────────
class _CirclePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

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

    // Subtle wave stroke
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