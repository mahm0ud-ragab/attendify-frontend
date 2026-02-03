// QR Scanner Screen - Sky Blue Theme (Student Side)

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../services/localization_service.dart';
import 'dart:ui' as ui; // Import as 'ui' to avoid conflicts

class QrScannerScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const QrScannerScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  // ── Scan state ───────────────────────────────────────────────────────────
  bool _isProcessing = false;
  bool _isSuccess = false;

  // ── Animation controller for the scan-frame pulse ───────────────────────
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Core scan logic (unchanged) ──────────────────────────────────────────
  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;

    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      setState(() {
        _isProcessing = true;
      });
      final String scannedCode = barcodes.first.rawValue!;
      try {
        // 1. Get Location (Anti-Spoofing)
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);

        // 2. Get Device ID (Anti-Buddy Punching)
        // final deviceInfo = DeviceInfoPlugin();
        // final androidInfo = await deviceInfo.androidInfo;
        // String deviceId = androidInfo.id;
        String deviceId = "mock_device_id_123";

        // 3. Send payload to Backend (Mocking it for now)
        debugPrint("PAYLOAD TO SEND:");
        debugPrint("Token: $scannedCode");
        debugPrint("Lat: ${position.latitude}, Long: ${position.longitude}");
        debugPrint("DeviceID: $deviceId");

        if (mounted) {
          // Show success overlay, then pop after a short delay
          setState(() {
            _isSuccess = true;
          });
          await Future.delayed(const Duration(milliseconds: 1800));
          if (mounted) Navigator.pop(context);
        }
      } catch (e) {
        debugPrint("Error: $e");
        if (mounted) {
          setState(() => _isProcessing = false); // Allow retry
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${context.loc?.error ?? 'Error'}: $e"),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // ── Layer 1: Sky Blue gradient (matches student dashboard) ────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade700,
                  Colors.blue.shade600,
                  Colors.lightBlue.shade500,
                ],
              ),
            ),
          ),

          // ── Layer 2: Decorative circle pattern ────────────────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: _CirclePatternPainter(),
            ),
          ),

          // ── Layer 3: Content ──────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Custom header
                _buildCustomHeader(textTheme),

                // Camera viewport + overlays
                Expanded(
                  child: Stack(
                    children: [
                      // Live camera feed
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                        child: MobileScanner(onDetect: _onDetect),
                      ),

                      // Animated scan frame (corner brackets + pulsing glow)
                      Center(
                        child: _buildScanFrame(),
                      ),

                      // Bottom instruction card (glass)
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 32,
                        child: _buildInstructionCard(textTheme),
                      ),

                      // Processing overlay
                      if (_isProcessing && !_isSuccess)
                        _buildProcessingOverlay(textTheme),

                      // Success overlay
                      if (_isSuccess) _buildSuccessOverlay(textTheme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Custom Header ─────────────────────────────────────────────────────────
  Widget _buildCustomHeader(TextTheme textTheme) {
    final loc = context.loc;
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
            loc?.qrScannerTitle ?? 'QR Scanner',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),

          // Spacer to keep title centred
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ── Animated Scan Frame ───────────────────────────────────────────────────
  Widget _buildScanFrame() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        // Opacity pulses between 0.5 and 1.0
        final opacity = 0.5 + (math.sin(_pulseController.value * math.pi) * 0.5);
        // Glow size breathes gently
        final glowSpread = 4.0 + (math.sin(_pulseController.value * math.pi) * 6.0);

        return Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.lightBlue.shade300.withValues(alpha: opacity * 0.5),
                blurRadius: 20,
                spreadRadius: glowSpread,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _ScanFramePainter(opacity: opacity),
            size: const Size(240, 240),
          ),
        );
      },
    );
  }

  // ── Bottom Instruction Card (glass) ──────────────────────────────────────
  Widget _buildInstructionCard(TextTheme textTheme) {
    final loc = context.loc;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
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
          // Icon badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.blue.shade700,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc?.scannerInstruction ?? 'Point your camera at the QR code',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.courseTitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Processing Overlay ────────────────────────────────────────────────────
  Widget _buildProcessingOverlay(TextTheme textTheme) {
    final loc = context.loc;
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
      ),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),   // ✅ fixed: added ui. prefix
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Spinner
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    color: Colors.blue.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  loc?.processing ?? 'Processing...',
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Success Overlay ───────────────────────────────────────────────────────
  Widget _buildSuccessOverlay(TextTheme textTheme) {
    final loc = context.loc;
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
      ),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(44),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.97),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Checkmark circle
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.green.shade300,
                      width: 2.5,
                    ),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.green.shade600,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  loc?.attendanceMarked ?? 'Attendance Marked!',
                  style: textTheme.titleLarge?.copyWith(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.courseTitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Scan Frame Painter ───────────────────────────────────────────────────────
/// Draws four corner-bracket L-shapes at the corners of the scan area.
class _ScanFramePainter extends CustomPainter {
  final double opacity;
  const _ScanFramePainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    const double cornerLen = 28; // length of each bracket arm
    const double radius = 20.0; // corner rounding of the scan box
    final w = size.width;
    final h = size.height;

    // ── Top-Left corner ─────────────────────────────────────────────────
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerLen)
        ..lineTo(0, radius)
        ..quadraticBezierTo(0, 0, radius, 0)       // ✅ fixed
        ..lineTo(cornerLen, 0),
      paint,
    );

    // ── Top-Right corner ────────────────────────────────────────────────
    canvas.drawPath(
      Path()
        ..moveTo(w - cornerLen, 0)
        ..lineTo(w - radius, 0)
        ..quadraticBezierTo(w, 0, w, radius)       // ✅ fixed
        ..lineTo(w, cornerLen),
      paint,
    );

    // ── Bottom-Right corner ─────────────────────────────────────────────
    canvas.drawPath(
      Path()
        ..moveTo(w, h - cornerLen)
        ..lineTo(w, h - radius)
        ..quadraticBezierTo(w, h, w - radius, h)   // ✅ fixed
        ..lineTo(w - cornerLen, h),
      paint,
    );

    // ── Bottom-Left corner ──────────────────────────────────────────────
    canvas.drawPath(
      Path()
        ..moveTo(cornerLen, h)
        ..lineTo(radius, h)
        ..quadraticBezierTo(0, h, 0, h - radius)   // ✅ fixed
        ..lineTo(0, h - cornerLen),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanFramePainter oldDelegate) =>
      oldDelegate.opacity != opacity;
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