import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryDark = Color(0xFF2C3E50);
  static const Color primaryBlue = Color(0xFF3498DB);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textTertiary = Color(0xFF95A5A6);
  static const Color borderColor = Color(0xFFBDC3C7);
  static const Color borderLight = Color(0xFFE9ECEF);
  static const Color backgroundGray = Color(0xFFF8F9FA);
  static const Color white = Colors.white;
  
  static const Color googleBlue = Color(0xFF4285F4);
  static const Color linkedinBlue = Color(0xFF0077B5);
  static const Color facebookBlue = Color(0xFF1877F2);

  static const TextStyle headingLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: primaryDark,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: primaryDark,
  );

  static const TextStyle welcomeSubtitle = TextStyle(
    fontSize: 18,
    color: textSecondary,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    color: textSecondary,
  );

  static const TextStyle bodyTextSmall = TextStyle(
    fontSize: 14,
    color: textTertiary,
    height: 1.4,
  );

  static const TextStyle labelText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: primaryDark,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle linkText = TextStyle(
    color: primaryBlue,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle hintText = TextStyle(
    color: borderColor,
  );

  static InputDecoration getInputDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTheme.hintText,
      filled: true,
      fillColor: backgroundGray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue),
      ),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }

  static ButtonStyle getPrimaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryDark,
      foregroundColor: white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
    );
  }

  static ButtonStyle getSecondaryButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: primaryDark,
      side: const BorderSide(
        color: borderColor,
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  static BoxDecoration getSocialButtonDecoration() {
    return BoxDecoration(
      border: Border.all(color: borderLight),
      borderRadius: BorderRadius.circular(12),
    );
  }
}