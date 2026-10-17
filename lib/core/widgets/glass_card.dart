import 'dart:ui';

import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.accentBorder = false,
    this.frosted = false,
    this.accentColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool accentBorder;
  final bool frosted;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    final surface = Theme.of(context).colorScheme.surface;
    final accent = accentColor ?? Theme.of(context).colorScheme.primary;
    final card = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: frosted ? 12 : 0,
          sigmaY: frosted ? 12 : 0,
        ),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: surface.withValues(alpha: frosted ? 0.64 : 0.92),
            gradient: frosted
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      surface.withValues(alpha: 0.72),
                      surface.withValues(alpha: 0.46),
                    ],
                  )
                : null,
            borderRadius: radius,
            border: Border.all(
              color: accentBorder
                  ? accent.withValues(alpha: 0.48)
                  : Colors.white.withValues(alpha: frosted ? 0.16 : 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: card,
      ),
    );
  }
}
