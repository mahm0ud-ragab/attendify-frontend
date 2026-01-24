import 'package:flutter/material.dart';

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
        // Status Card with gradient background
        _StatusCard(
          isScanning: isScanning,
          statusMessage: statusMessage,
          colorScheme: colorScheme,
        ),

        const SizedBox(height: 20),

        // Control Buttons
        Row(
          children: [
            Expanded(
              child: _AnimatedButton(
                onPressed: isScanning ? null : onStartScan,
                icon: Icons.play_circle_filled_rounded,
                label: 'Start Scan',
                color: const Color(0xFF00C853),
                isEnabled: !isScanning,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _AnimatedButton(
                onPressed: isScanning ? onStopScan : null,
                icon: Icons.stop_circle_rounded,
                label: 'Stop Scan',
                color: const Color(0xFFFF5252),
                isEnabled: isScanning,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Status card with modern design
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
            colorScheme.primary.withOpacity(0.1),
            colorScheme.secondary.withOpacity(0.05),
          ]
              : [
            colorScheme.surface,
            colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isScanning
              ? colorScheme.primary.withOpacity(0.3)
              : colorScheme.outline.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isScanning
                ? colorScheme.primary.withOpacity(0.1)
                : Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Animated icon
            _PulsingIcon(
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
                      color: isScanning
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.6),
                      letterSpacing: 1.5,
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

// Pulsing icon animation
class _PulsingIcon extends StatefulWidget {
  final bool isScanning;
  final ColorScheme colorScheme;

  const _PulsingIcon({
    required this.isScanning,
    required this.colorScheme,
  });

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isScanning) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_PulsingIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isScanning ? _animation.value : 1.0,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: widget.isScanning
                  ? widget.colorScheme.primary.withOpacity(0.15)
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
        );
      },
    );
  }
}

// Animated button with press effect
class _AnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color color;
  final bool isEnabled;

  const _AnimatedButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
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
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isEnabled
                ? widget.color
                : Theme.of(context).colorScheme.surfaceVariant,
            foregroundColor: widget.isEnabled
                ? Colors.white
                : Theme.of(context).colorScheme.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(vertical: 18),
            elevation: widget.isEnabled ? 2 : 0,
            shadowColor: widget.color.withOpacity(0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 24),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}