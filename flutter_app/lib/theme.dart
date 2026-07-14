import 'package:flutter/material.dart';

class C {
  static const brand = Color(0xFFFF6D00);
  static const brand2 = Color(0xFFFF8A2B);
  static const brandDeep = Color(0xFFE85D00);
  static const bg = Color(0xFFF6F7F9);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFEEF0F4);
  static const ink = Color(0xFF1A1D26);
  static const ink2 = Color(0xFF4A5261);
  static const ink3 = Color(0xFF8A92A3);
  static const line = Color(0xFFE2E5EB);
  static const ok = Color(0xFF1F9D55);
  static const like = Color(0xFFFF2C55);
  static const tag = Color(0xFFEFE9FF);
  static const tagInk = Color(0xFF6A4BD8);

  static const brandGrad = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [brand2, brandDeep],
  );
}

ThemeData buildTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: C.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: C.brand,
      secondary: C.brand2,
      surface: C.surface,
    ),
    splashFactory: InkSparkle.splashFactory,
    textTheme: base.textTheme.apply(bodyColor: C.ink, displayColor: C.ink),
    appBarTheme: const AppBarTheme(
      backgroundColor: C.surface, foregroundColor: C.ink, elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(color: C.ink, fontSize: 16, fontWeight: FontWeight.w500),
    ),
  );
}
