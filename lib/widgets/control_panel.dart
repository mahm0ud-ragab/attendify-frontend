import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Modern control panel with gradient status card and animated buttons
class ControlPanel extends StatelessWidget {
  final bool isScanning;
  final String statusMessage;
  final VoidCallback onStartScan;
  final VoidCallback onStopScan;

  const ControlPanel({
    Key? key,
    required this.isScanning,
    required this.statusMessage,
    required this.onStartScan,
    required this.onStopScan,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Status Card with frosted glass effect
        _StatusCard(
          isScanning: isScanning,
          statusMessage: statusMessage,
          colorScheme: colorScheme,
        ),

        const SizedBox(height: 28), // Increased breathing room

        // Control Buttons
        Row(
          children: [
            Expanded(
              child: _AnimatedButton(
                onPressed: isScanning ? null : onStartScan,
                icon: Icons.play_circle_filled_rounded,
                label: 'Start Scan',
                gradientColors: const [
                  Color(0xFF00C853), // Emerald green
                  Color(0xFF00897B), // Teal
                ],
                isEnabled: !isScanning,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _AnimatedButton(
                onPressed: isScanning ? onStopScan : null,
                icon: Icons.stop_circle_rounded,
                label: 'Stop Scan',
                gradientColors: const [
                  Color(0xFFFF5252), // Red
                  Color(0xFFFF6E40), // Deep orange
                ],
                isEnabled: isScanning,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Status card with frosted glass effect and colored shadows
class _StatusCard extends StatelessWidget {
  final bool isScanning;
  final String statusMessage;
  final ColorScheme colorScheme;

  const _StatusCard({
    required this.isScanning,
    required this.statusMessage,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isScanning
              ? [
            colorScheme.primary.withValues(alpha: 0.12),
            colorScheme.secondary.withValues(alpha: 0.08),
          ]
              : [
            colorScheme.surface,
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isScanning
              ? colorScheme.primary.withValues(alpha: 0.4)
              : colorScheme.outline.withValues(alpha: 0.15),
          width: isScanning ? 2.0 : 1.5, // Thicker border when active
        ),
        boxShadow: [
          BoxShadow(
            color: isScanning
                ? colorScheme.primary.withValues(alpha: 0.15) // Colored glow
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isScanning ? 16 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Animated radar ripple icon
            _RadarRippleIcon(
              isScanning: isScanning,
              colorScheme: colorScheme,
            ),

            const SizedBox(width: 16),

            // Status text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isScanning ? 'SCANNING' : 'IDLE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Courier', // Monospaced for technical feel
                      color: isScanning
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.6),
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    statusMessage,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            // Progress indicator
            if (isScanning)
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Radar ripple icon animation (like radio waves)
class _RadarRippleIcon extends StatefulWidget {
  final bool isScanning;
  final ColorScheme colorScheme;

  const _RadarRippleIcon({
    required this.isScanning,
    required this.colorScheme,
  });

  @override
  State<_RadarRippleIcon> createState() => _RadarRippleIconState();
}

class _RadarRippleIconState extends State<_RadarRippleIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.isScanning) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(_RadarRippleIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isScanning && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple effect (radio waves)
          if (widget.isScanning)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  width: 56 * _scaleAnimation.value,
                  height: 56 * _scaleAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.colorScheme.primary
                          .withValues(alpha: _fadeAnimation.value),
                      width: 2,
                    ),
                  ),
                );
              },
            ),

          // Main icon container
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: widget.isScanning
                  ? widget.colorScheme.primary.withValues(alpha: 0.15)
                  : widget.colorScheme.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.isScanning
                  ? Icons.radar_rounded
                  : Icons.bluetooth_rounded,
              size: 30,
              color: widget.isScanning
                  ? widget.colorScheme.primary
                  : widget.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// Animated button with gradient, haptic feedback, and press effect
class _AnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final List<Color> gradientColors;
  final bool isEnabled;

  const _AnimatedButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.gradientColors,
    required this.isEnabled,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.isEnabled) {
      _controller.forward();
      // Haptic feedback for physical click sensation
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.isEnabled) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.isEnabled) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Opacity(
          opacity: widget.isEnabled ? 1.0 : 0.5, // Consistent disabled state
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: widget.isEnabled
                  ? LinearGradient(
                colors: widget.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
                  : LinearGradient(
                colors: [
                  theme.colorScheme.surfaceVariant,
                  theme.colorScheme.surfaceVariant,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: widget.isEnabled
                  ? [
                BoxShadow(
                  color: widget.gradientColors[0].withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.icon,
                        size: 24,
                        color: widget.isEnabled
                            ? Colors.white
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: widget.isEnabled
                              ? Colors.white
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
