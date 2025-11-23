import 'dart:ui';
import 'package:flutter/material.dart';

class BubbleTask extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const BubbleTask({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Stack(
          children: [
            // 🌸 BACKGROUND GLASSY GRADIENT
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.35),
                    Colors.pinkAccent.withOpacity(0.20),
                    Colors.white.withOpacity(0.30),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: Colors.white.withOpacity(0.7),
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.28),
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),

            // 🌈 BLUR LAYER (Glass effect)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: const SizedBox(),
            ),

            // ✨ SHINY BUBBLE HIGHLIGHT
            Positioned(
              top: 8,
              left: 12,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.8),
                      Colors.white.withOpacity(0.0),
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),

            // 💗 CONTENT
            Padding(
              padding: padding,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
