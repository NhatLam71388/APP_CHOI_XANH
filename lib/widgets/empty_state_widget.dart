import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? color;
  final double? iconSize;
  final double? containerSize;
  final Duration? animationDuration;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.color,
    this.iconSize,
    this.containerSize,
    this.animationDuration,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColor = color ?? const Color(0xFF198754);
    
    return Center(
      child: FadeInUp(
        duration: animationDuration ?? const Duration(milliseconds: 800),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: padding ?? const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: defaultColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(borderRadius ?? 30),
              ),
              child: Icon(
                icon,
                size: iconSize ?? 80,
                color: defaultColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: defaultColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: defaultColor.withOpacity(0.7),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
