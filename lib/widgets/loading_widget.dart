import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final Color? color;
  final double? size;
  final double? strokeWidth;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? backgroundColor;

  const LoadingWidget({
    super.key,
    this.color,
    this.size,
    this.strokeWidth,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: (backgroundColor ?? const Color(0xFF198754)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(borderRadius ?? 20),
            ),
            child: CircularProgressIndicator(
              color: color ?? const Color(0xFF198754),
              strokeWidth: strokeWidth ?? 3,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget loading đơn giản (chỉ có CircularProgressIndicator)
class SimpleLoadingWidget extends StatelessWidget {
  final Color? color;
  final double? size;
  final double? strokeWidth;

  const SimpleLoadingWidget({
    super.key,
    this.color,
    this.size,
    this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: color ?? const Color(0xFF198754),
        strokeWidth: strokeWidth ?? 3,
      ),
    );
  }
}

// Widget loading với text
class LoadingWithTextWidget extends StatelessWidget {
  final String text;
  final Color? color;
  final double? size;
  final double? strokeWidth;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? backgroundColor;
  final TextStyle? textStyle;

  const LoadingWithTextWidget({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.strokeWidth,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: (backgroundColor ?? const Color(0xFF198754)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(borderRadius ?? 20),
            ),
            child: Column(
              children: [
                CircularProgressIndicator(
                  color: color ?? const Color(0xFF198754),
                  strokeWidth: strokeWidth ?? 3,
                ),
                const SizedBox(height: 16),
                Text(
                  text,
                  style: textStyle ?? 
                    TextStyle(
                      color: color ?? const Color(0xFF198754),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
