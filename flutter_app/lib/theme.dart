import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 品牌色/语义色:两套主题下不变,保持 const
class C {
  static const brand = Color(0xFFFF6D00);
  static const brand2 = Color(0xFFFF8A2B);
  static const brandDeep = Color(0xFFE85D00);
  static const ok = Color(0xFF1F9D55);
  static const like = Color(0xFFFF2C55);
  static const brandGrad = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [brand2, brandDeep],
  );

  // 主题相关色(可变,随深浅切换)。默认深色。
  static Color bg = _darkBg;
  static Color surface = _darkSurface;
  static Color surface2 = _darkSurface2;
  static Color ink = _darkInk;
  static Color ink2 = _darkInk2;
  static Color ink3 = _darkInk3;
  static Color line = _darkLine;
  static Color tag = _darkTag;
  static Color tagInk = _darkTagInk;

  static const _darkBg = Color(0xFF0D0F13);
  static const _darkSurface = Color(0xFF15181E);
  static const _darkSurface2 = Color(0xFF1B2027);
  static const _darkInk = Color(0xFFEEF1F5);
  static const _darkInk2 = Color(0xFFAEB6C6);
  static const _darkInk3 = Color(0xFF6F7892);
  static const _darkLine = Color(0xFF262C3A);
  static const _darkTag = Color(0xFF352C4E);
  static const _darkTagInk = Color(0xFFB9A6FF);
  static const _lightBg = Color(0xFFF6F7F9);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightSurface2 = Color(0xFFEEF0F4);
  static const _lightInk = Color(0xFF1A1D26);
  static const _lightInk2 = Color(0xFF4A5261);
  static const _lightInk3 = Color(0xFF8A92A3);
  static const _lightLine = Color(0xFFE2E5EB);
  static const _lightTag = Color(0xFFEFE9FF);
  static const _lightTagInk = Color(0xFF6A4BD8);

  static void apply(bool dark) {
    bg = dark ? _darkBg : _lightBg;
    surface = dark ? _darkSurface : _lightSurface;
    surface2 = dark ? _darkSurface2 : _lightSurface2;
    ink = dark ? _darkInk : _lightInk;
    ink2 = dark ? _darkInk2 : _lightInk2;
    ink3 = dark ? _darkInk3 : _lightInk3;
    line = dark ? _darkLine : _lightLine;
    tag = dark ? _darkTag : _lightTag;
    tagInk = dark ? _darkTagInk : _lightTagInk;
  }
}

class ThemeController extends ChangeNotifier {
  bool dark = true;
  SharedPreferences? _sp;

  Future<void> load() async {
    _sp = await SharedPreferences.getInstance();
    dark = _sp?.getBool('dark') ?? true; // 默认深色
    C.apply(dark);
  }

  void toggle(bool v) {
    dark = v;
    C.apply(dark);
    _sp?.setBool('dark', dark);
    notifyListeners();
  }
}

ThemeData buildTheme(bool dark) {
  final base = dark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: C.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: C.brand, secondary: C.brand2, surface: C.surface,
      brightness: dark ? Brightness.dark : Brightness.light,
    ),
    splashFactory: InkSparkle.splashFactory,
    textTheme: base.textTheme.apply(bodyColor: C.ink, displayColor: C.ink),
    appBarTheme: AppBarTheme(
      backgroundColor: C.surface, foregroundColor: C.ink, elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(color: C.ink, fontSize: 16, fontWeight: FontWeight.w500),
    ),
    canvasColor: C.surface,
  );
}
