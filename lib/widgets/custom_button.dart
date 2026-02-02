// Reliable Modern Button (Uses InkWell for safety)

import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;
  final List<Color>? gradientColors;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.primaryColor;

    // Use provided gradient OR generate a default one based on primary color
    final colors = gradientColors ??
        [
          baseColor,
          baseColor.withOpacity(0.8),
        ];

    return Container(
      width: double.infinity,
      height: 56, // Standard accessible height
      decoration: BoxDecoration(
        // The Gradient Background
        gradient: LinearGradient(
          colors: isLoading
              ? [Colors.grey.shade300, Colors.grey.shade400]
              : colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16), // Modern Rounded Corners
        // The Glow Effect
        boxShadow: isLoading
            ? null
            : [
          BoxShadow(
            color: colors[0].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // STANDARD FLUTTER CLICK LOGIC (100% RELIABLE)
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withOpacity(0.2), // The ripple effect
          highlightColor: Colors.white.withOpacity(0.1),
          child: Center(
            child: isLoading
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                ],
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
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
