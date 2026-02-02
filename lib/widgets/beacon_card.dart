import 'package:flutter/material.dart';
import '../../models/beacon.dart';

/// Modern beacon card with Material You design + Expandable details
///
/// Features:
/// - Clean default view (Icon, Name, Distance, Button only)
/// - Tap to expand and reveal technical details with smooth animation
/// - Hero card treatment for university beacons (green tint + stronger shadow)
/// - Material 3 aesthetic with softer corners and borders
class BeaconCard extends StatefulWidget {
  final Beacon beacon;
  final int index;
  final bool isUniversityBeacon;
  final bool isMarking;
  final VoidCallback? onMarkAttendance;

  const BeaconCard({
    Key? key,
    required this.beacon,
    required this.index,
    this.isUniversityBeacon = false,
    this.isMarking = false,
    this.onMarkAttendance,
  }) : super(key: key);

  @override
  State<BeaconCard> createState() => _BeaconCardState();
}

class _BeaconCardState extends State<BeaconCard> {
  bool _isExpanded = false;

  Color _getSignalColor(int rssi) {
    if (rssi > -60) return const Color(0xFF00C853);
    if (rssi > -70) return const Color(0xFF64DD17);
    if (rssi > -80) return const Color(0xFFFF9800);
    return const Color(0xFFFF5252);
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final signalColor = widget.isUniversityBeacon
        ? Colors.green
        : _getSignalColor(widget.beacon.rssi);
    final signalStrength = widget.beacon.signalStrength;

    // Hero card gets green background tint
    final backgroundColor = widget.isUniversityBeacon
        ? Colors.green.withValues(alpha: 0.08)
        : colorScheme.surface;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (widget.index * 50)),
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
      child: GestureDetector(
        onTap: _toggleExpanded,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24), // Softer corners
            border: Border.all(
              color: signalColor.withValues(
                alpha: widget.isUniversityBeacon ? 0.4 : 0.2, // Lighter border
              ),
              width: widget.isUniversityBeacon ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isUniversityBeacon
                    ? Colors.green.withValues(alpha: 0.25) // Stronger shadow for hero
                    : signalColor.withValues(alpha: 0.12),
                blurRadius: widget.isUniversityBeacon ? 16 : 10,
                offset: Offset(0, widget.isUniversityBeacon ? 6 : 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // Signal strength indicator bar
              Container(
                height: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [signalColor, signalColor.withValues(alpha: 0.3)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(23),
                    topRight: Radius.circular(23),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Clean default view: Icon + Name + Distance
                    Row(
                      children: [
                        // Animated beacon icon
                        _BeaconIcon(
                          color: signalColor,
                          isUniversityBeacon: widget.isUniversityBeacon,
                        ),

                        const SizedBox(width: 16),

                        // Beacon name and distance
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.isUniversityBeacon
                                          ? 'University Beacon'
                                          : 'Beacon #${widget.index}',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (widget.isUniversityBeacon) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.verified,
                                      color: Colors.green,
                                      size: 22,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Distance badge (always visible)
                              _DistanceBadge(
                                distance: widget.beacon.estimatedDistance,
                                colorScheme: colorScheme,
                                isHero: widget.isUniversityBeacon,
                              ),
                            ],
                          ),
                        ),

                        // Expand/collapse indicator
                        Icon(
                          _isExpanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                          size: 28,
                        ),
                      ],
                    ),

                    // Expandable technical details section
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _isExpanded
                          ? Column(
                        children: [
                          const SizedBox(height: 20),
                          Divider(
                            color: colorScheme.outline.withValues(alpha: 0.15),
                            height: 1,
                          ),
                          const SizedBox(height: 20),

                          // Signal strength badge
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _SignalBadge(
                              strength: signalStrength,
                              color: signalColor,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // RSSI value
                          _RssiDisplay(
                            rssi: widget.beacon.rssi,
                            color: signalColor,
                          ),

                          const SizedBox(height: 20),

                          // Technical data
                          _DataRow(
                            icon: Icons.fingerprint_rounded,
                            label: 'UUID',
                            value: widget.beacon.uuid.length > 20
                                ? '${widget.beacon.uuid.substring(0, 20)}...'
                                : widget.beacon.uuid,
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
                                  value: widget.beacon.major.toString(),
                                  colorScheme: colorScheme,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _DataRow(
                                  icon: Icons.label_rounded,
                                  label: 'Minor',
                                  value: widget.beacon.minor.toString(),
                                  colorScheme: colorScheme,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                          : const SizedBox.shrink(),
                    ),

                    // Mark Attendance Button (only for university beacons)
                    if (widget.isUniversityBeacon && widget.onMarkAttendance != null) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: widget.isMarking ? null : widget.onMarkAttendance,
                          icon: widget.isMarking
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                              : const Icon(
                            Icons.check_circle_rounded,
                            size: 24,
                          ),
                          label: Text(
                            widget.isMarking
                                ? 'Marking Attendance...'
                                : 'Mark Attendance',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: Colors.green.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Animated beacon icon with pulse effect
class _BeaconIcon extends StatefulWidget {
  final Color color;
  final bool isUniversityBeacon;

  const _BeaconIcon({
    required this.color,
    this.isUniversityBeacon = false,
  });

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
                    color: widget.color.withValues(
                      alpha: 0.5 * (1 - _animation.value),
                    ),
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
              color: widget.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.isUniversityBeacon
                  ? Icons.school_rounded
                  : Icons.bluetooth_connected_rounded,
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
            color: color.withValues(alpha: 0.3),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.router_rounded,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Signal Strength',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          Row(
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
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1,
                      letterSpacing: -0.5,
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  'dBm',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Distance badge
class _DistanceBadge extends StatelessWidget {
  final String distance;
  final ColorScheme colorScheme;
  final bool isHero;

  const _DistanceBadge({
    required this.distance,
    required this.colorScheme,
    this.isHero = false,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = isHero
        ? Colors.green.withValues(alpha: 0.15)
        : colorScheme.secondaryContainer;
    final textColor = isHero
        ? Colors.green.shade700
        : colorScheme.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.near_me_rounded,
            color: textColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            distance,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
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
                color: colorScheme.onSurface.withValues(alpha: 0.6),
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
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
