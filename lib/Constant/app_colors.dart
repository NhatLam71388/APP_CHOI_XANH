import 'package:flutter/material.dart';

class AppColors {
  static Color backgroundColor = const Color(0xFFF8FFF8);

  // Màu chính của app
  static const Color primary = Color(0xFF198754);
  static const Color primaryLight = Color(0xFF20C997);
  static const Color primaryDark = Color(0xFF146C43);
  
  // Màu phụ
  static const Color secondary = Color(0xFF0066FF);
  static const Color secondaryLight = Color(0xFF4D94FF);
  static const Color secondaryDark = Color(0xFF0047B3);
  
  // Màu trạng thái
  static const Color success = Color(0xFF198754);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFDC3545);
  static const Color info = Color(0xFF0DCAF0);
  
  // Màu trung tính
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF6C757D);
  static const Color lightGrey = Color(0xFFF8F9FA);
  static const Color darkGrey = Color(0xFF343A40);
  
  // Màu nền
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  // Màu text
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textLight = Color(0xFFADB5BD);
  
  // Màu border
  static const Color border = Color(0xFFDEE2E6);
  static const Color borderLight = Color(0xFFE9ECEF);
  
  // Màu shadow
  static const Color shadow = Color(0xFF000000);
  
  // Màu gradient
  static const Color gradientStart = Color(0xFF198754);
  static const Color gradientEnd = Color(0xFF20C997);
  
  // Màu opacity
  static Color primaryWithOpacity(double opacity) => primary.withOpacity(opacity);
  static Color secondaryWithOpacity(double opacity) => secondary.withOpacity(opacity);
  static Color successWithOpacity(double opacity) => success.withOpacity(opacity);
  static Color errorWithOpacity(double opacity) => error.withOpacity(opacity);
}
