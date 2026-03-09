import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final List<Color> gradientColors;
  final Color textColor;
  final IconData? icon;
  final double? height;
  final double? fontSize;
  final bool isOutlined;
  final Color? borderColor;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.gradientColors = const [
      Color(0xFF198754),
      Color(0xFF20C997),
    ],
    this.textColor = Colors.white,
    this.icon,
    this.height = 48,
    this.fontSize = 16,
    this.isOutlined = false,
    this.borderColor,
  });

  // Constructor helper cho outlined button
  const CustomButton.outlined({
    super.key,
    required this.text,
    required this.onPressed,
    this.borderColor = const Color(0xFF198754),
    this.textColor = const Color(0xFF198754),
    this.icon,
    this.height = 48,
    this.fontSize = 16,
  }) : gradientColors = const [Color(0xFF198754), Color(0xFF20C997)],
       isOutlined = true;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ?? gradientColors.first;
    final effectiveTextColor = isOutlined 
        ? (borderColor ?? gradientColors.first) 
        : textColor;

    return Container(
      height: height,
      width: 250,
      decoration: isOutlined
          ? BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: effectiveBorderColor,
                width: 2,
              ),
              borderRadius: BorderRadius.circular((height ?? 48) / 2),
              boxShadow: [
                BoxShadow(
                  color: effectiveBorderColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
            )
          : BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular((height ?? 48) / 2),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: effectiveTextColor,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular((height ?? 48) / 2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: fontSize,
                color: effectiveTextColor,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: effectiveTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildSocialIconButton(
    String imagePath, String text, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(24),
    child: Container(
      height: 48,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF198754).withOpacity(0.3), 
          width: 2
        ),
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF198754).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            imagePath,
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF198754),
            ),
          ),
        ],
      ),
    ),
  );
}

