import 'dart:ui';
import 'package:flutter/material.dart';

/// Fast GlassContainer - uses blur only when explicitly needed (modals)
/// Avoids BackdropFilter on list items to prevent 120Hz jank
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double opacity;
  final double blur;
  final Color? tint;
  final bool applyBlur; // Set false for list tiles for performance

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 20,
    this.opacity = 0.10,
    this.blur = 12,
    this.tint,
    this.applyBlur = false, // Off by default for perf
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      color: (tint ?? Colors.white).withValues(alpha: opacity),
      // Glass Edge Highlights
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.18),
        width: 1.0,
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          (tint ?? Colors.white).withValues(alpha: opacity + 0.06),
          (tint ?? Colors.white).withValues(alpha: opacity - 0.02),
        ],
        stops: const [0.0, 1.0],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 20,
          offset: const Offset(0, 10),
          spreadRadius: -5,
        ),
      ],
    );

    final clipped = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: applyBlur
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Container(decoration: decoration, child: Padding(padding: padding, child: child)),
            )
          : Container(decoration: decoration, child: Padding(padding: padding, child: child)),
    );

    return Container(margin: margin, child: clipped);
  }
}
