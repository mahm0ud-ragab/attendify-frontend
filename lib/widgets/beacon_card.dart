import 'package:flutter/material.dart';
import '../models/beacon.dart';

/// Modern beacon card with Material You design
class BeaconCard extends StatelessWidget {
  final Beacon beacon;
  final int index;

  const BeaconCard({
    Key? key,
    required this.beacon,
    required this.index,
  }) : super(key: key);

  Color _getSignalColor(int rssi) {
    if (rssi > -60) return const Color(0xFF00C853);
    if (rssi > -70) return const Color(0xFF64DD17);
    if (rssi > -80) return const Color(0xFFFF9800);
    return const Color(0xFFFF5252);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final signalColor = _getSignalColor(beacon.rssi);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: signalColor.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: signalColor.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Signal strength indicator bar
            Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [signalColor, signalColor.withOpacity(0.4)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      // Animated beacon icon
                      _BeaconIcon(color: signalColor),

                      const SizedBox(width: 16),

                      // Beacon info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Beacon #$index',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _SignalBadge(
                              strength: beacon.signalStrength,
                              color: signalColor,
                            ),
                          ],
                        ),
                      ),

                      // RSSI value
                      _RssiDisplay(rssi: beacon.rssi, color: signalColor),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Divider(
                    color: colorScheme.outline.withOpacity(0.2),
                    height: 1,
                  ),
                  const SizedBox(height: 16),

                  // Distance badge
                  _DistanceBadge(
                    distance: beacon.estimatedDistance,
                    colorScheme: colorScheme,
                  ),

                  const SizedBox(height: 16),

                  // Beacon data
                  _DataRow(
                    icon: Icons.fingerprint_rounded,
                    label: 'UUID',
                    value: beacon.uuid,
                    mono: true,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _DataRow(
                          icon: Icons.tag_rounded,
                          label: 'Major',
                          value: beacon.major.toString(),
                          colorScheme: colorScheme,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _DataRow(
                          icon: Icons.label_rounded,
                          label: 'Minor',
                          value: beacon.minor.toString(),
                          colorScheme: colorScheme,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Animated beacon icon with pulse effect
class _BeaconIcon extends StatefulWidget {
  final Color color;

  const _BeaconIcon({required this.color});

  @override
  State<_BeaconIcon> createState() => _BeaconIconState();
}

class _BeaconIconState extends State<_BeaconIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse rings
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
                width: 60 + (20 * _animation.value),
                height: 60 + (20 * _animation.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.color.withOpacity(0.5 * (1 - _animation.value)),
                    width: 2,
                  ),
                ),
              );
            },
          ),

          // Icon container
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bluetooth_connected_rounded,
              color: widget.color,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

// Signal strength badge
class _SignalBadge extends StatelessWidget {
  final String strength;
  final Color color;

  const _SignalBadge({
    required this.strength,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.signal_cellular_alt_rounded,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            strength,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// RSSI display with animation
class _RssiDisplay extends StatelessWidget {
  final int rssi;
  final Color color;

  const _RssiDisplay({
    required this.rssi,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TweenAnimationBuilder<int>(
          duration: const Duration(milliseconds: 800),
          tween: IntTween(begin: -100, end: rssi),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Text(
              '$value',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1,
                letterSpacing: -1,
              ),
            );
          },
        ),
        const SizedBox(height: 2),
        Text(
          'dBm',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// Distance badge
class _DistanceBadge extends StatelessWidget {
  final String distance;
  final ColorScheme colorScheme;

  const _DistanceBadge({
    required this.distance,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.near_me_rounded,
            color: colorScheme.onSecondaryContainer,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            distance,
            style: TextStyle(
              color: colorScheme.onSecondaryContainer,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.25,
            ),
          ),
        ],
      ),
    );
  }
}

// Data row
class _DataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool mono;
  final ColorScheme colorScheme;

  const _DataRow({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.6),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              fontFamily: mono ? 'Courier' : null,
              letterSpacing: mono ? 0 : 0
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}