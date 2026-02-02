import 'package:flutter/material.dart';

/// Modern empty state with animated icon and proper physics
class EmptyState extends StatefulWidget {
  final bool isScanning;

  const EmptyState({
    Key? key,
    required this.isScanning,
  }) : super(key: key);

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _textController;

  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _textOpacityAnimation;

  @override
  void initState() {
    super.initState();

    // Rotation animation for icon only
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    // Pulse animation for container
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Text pulsing animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _textOpacityAnimation = Tween<double>(begin: 1.0, end: 0.6).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );

    if (widget.isScanning) {
      _rotationController.repeat();
      _pulseController.repeat(reverse: true);
      _textController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(EmptyState oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !_rotationController.isAnimating) {
      _rotationController.repeat();
      _pulseController.repeat(reverse: true);
      _textController.repeat(reverse: true);
    } else if (!widget.isScanning && _rotationController.isAnimating) {
      _rotationController.stop();
      _rotationController.reset();
      _pulseController.stop();
      _pulseController.reset();
      _textController.stop();
      _textController.reset();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon with concentric rings
            SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring (faintest)
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.isScanning
                            ? colorScheme.primary.withValues(alpha: 0.08)
                            : Colors.grey.withValues(alpha: 0.1),
                        width: 2,
                      ),
                    ),
                  ),

                  // Middle ring
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.isScanning
                            ? colorScheme.primary.withValues(alpha: 0.12)
                            : Colors.grey.withValues(alpha: 0.15),
                        width: 2,
                      ),
                    ),
                  ),

                  // Main animated container (pulsing, NOT rotating)
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: widget.isScanning ? _scaleAnimation.value : 1.0,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            // Static gradient (doesn't rotate)
                            gradient: LinearGradient(
                              colors: widget.isScanning
                                  ? [
                                colorScheme.primary.withValues(alpha: 0.2),
                                colorScheme.secondary.withValues(alpha: 0.1),
                              ]
                                  : [
                                colorScheme.surfaceVariant.withValues(alpha: 0.5),
                                colorScheme.surfaceVariant.withValues(alpha: 0.3),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          // Icon rotates inside (proper physics)
                          child: AnimatedBuilder(
                            animation: _rotationController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: widget.isScanning
                                    ? _rotationAnimation.value * 2 * 3.14159
                                    : 0,
                                child: Icon(
                                  widget.isScanning
                                      ? Icons.radar_rounded
                                      : Icons.bluetooth_disabled_rounded,
                                  size: 60,
                                  color: widget.isScanning
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Title with pulsing animation when scanning
            AnimatedBuilder(
              animation: _textController,
              builder: (context, child) {
                return Opacity(
                  opacity: widget.isScanning ? _textOpacityAnimation.value : 1.0,
                  child: Text(
                    widget.isScanning
                        ? 'Searching for beacons...'
                        : 'No beacons detected',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Subtitle
            Text(
              widget.isScanning
                  ? 'Make sure beacons are nearby and broadcasting'
                  : 'Tap "Start Scan" to begin searching',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            if (!widget.isScanning) ...[
              const SizedBox(height: 36),

              // Info card with pill shape and shadow
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30), // Full pill shape
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lightbulb_outline_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Use "Beacon Simulator" app\non another phone to test!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
