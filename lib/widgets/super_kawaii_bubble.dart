import 'dart:ui';
import 'package:flutter/material.dart';

class SuperKawaiiBubble extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;

  const SuperKawaiiBubble({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),

    // ⬇️⬇️ FIXED: vertical spacing reduced from 12 → 6
    this.margin = const EdgeInsets.symmetric(horizontal: 14, vertical: 1),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50), // bubble shape
        child: Stack(
          children: [
            // 🌈 BACKGROUND GRADIENT (soft glassy pink)
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFEAF7),
                    Color(0xFFFFC8EC),
                    Color(0xFFFFF7FC),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // 🌫️ GLASS BLUR
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(color: Colors.white.withOpacity(0.05)),
            ),

            // ✨ TOP-LEFT HIGHLIGHT SPOT
            Positioned(
              top: -6,
              left: -6,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.85),
                      Colors.white.withOpacity(0.0),
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),

            // 🌟 BOTTOM-RIGHT INNER GLOW
            Positioned(
              bottom: -18,
              right: -18,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.18),
                ),
              ),
            ),

            // 💫 HOLOGRAPHIC EDGE SHIMMER
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    width: 2.5,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pinkAccent.withOpacity(0.28),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),

            // 🎀 CONTENT
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}
