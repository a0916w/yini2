import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── 「果橙·活力」设计 tokens(design_handoff_yinitv)───
// 品牌色/语义色:两套主题下不变,保持 const
class C {
  static const brand = Color(0xFFFF6000);      // Primary
  static const brand2 = Color(0xFFFF8A3C);     // 渐变亮端
  static const brandDeep = Color(0xFFE55500);
  static const ok = Color(0xFF1F9D55);
  static const like = Color(0xFFFF2C55);
  static const gold = Color(0xFFFFD27A);       // 评分金
  static const crown = Color(0xFFFFB020);      // 皇冠
  static const vipBg = Color(0xFF2B2018);      // VIP 深底
  static const vipGold = Color(0xFFF5CE86);    // VIP 金
  static const vipInk = Color(0xFF3A2A18);     // VIP 金底上的字
  // 主按钮渐变 150deg
  static const brandGrad = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [brand2, brand],
  );

  // 主题相关色(可变,随深浅切换)。默认浅色(果橙)。
  static Color bg = _lightBg;
  static Color surface = _lightSurface;
  static Color surface2 = _lightSurface2; // 暖底卡 #FFF6EE
  static Color ink = _lightInk;
  static Color ink2 = _lightInk2;   // 暖灰次要 #7A6B5C
  static Color ink3 = _lightInk3;   // 暖灰辅助 #A08D7A
  static Color quiet = _lightQuiet; // 浅灰 #B8AFA6
  static Color line = _lightLine;   // #F6EDE4
  static Color tag = _lightTag;     // 主色浅底 #FFE9D9
  static Color tagInk = _lightTagInk;

  static const _lightBg = Color(0xFFFFFFFF);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightSurface2 = Color(0xFFFFF6EE);
  static const _lightInk = Color(0xFF1A1A1E);
  static const _lightInk2 = Color(0xFF7A6B5C);
  static const _lightInk3 = Color(0xFFA08D7A);
  static const _lightQuiet = Color(0xFFB8AFA6);
  static const _lightLine = Color(0xFFF6EDE4);
  static const _lightTag = Color(0xFFFFE9D9);
  static const _lightTagInk = Color(0xFFFF6000);
  static const _darkBg = Color(0xFF121014);
  static const _darkSurface = Color(0xFF1B181D);
  static const _darkSurface2 = Color(0xFF242026);
  static const _darkInk = Color(0xFFF2EEEA);
  static const _darkInk2 = Color(0xFFC4B5A8);
  static const _darkInk3 = Color(0xFF95887C);
  static const _darkQuiet = Color(0xFF6F675F);
  static const _darkLine = Color(0xFF2E2930);
  static const _darkTag = Color(0xFF3A2416);
  static const _darkTagInk = Color(0xFFFFA95C);

  static void apply(bool dark) {
    bg = dark ? _darkBg : _lightBg;
    surface = dark ? _darkSurface : _lightSurface;
    surface2 = dark ? _darkSurface2 : _lightSurface2;
    ink = dark ? _darkInk : _lightInk;
    ink2 = dark ? _darkInk2 : _lightInk2;
    ink3 = dark ? _darkInk3 : _lightInk3;
    quiet = dark ? _darkQuiet : _lightQuiet;
    line = dark ? _darkLine : _lightLine;
    tag = dark ? _darkTag : _lightTag;
    tagInk = dark ? _darkTagInk : _lightTagInk;
  }
}

// 页面顶部浅橙渐变(#FFE3CC → #FFF6EE 46% → 透明);深色主题给一层微弱品牌洇染
BoxDecoration pageTopGrad(bool dark) => BoxDecoration(
      gradient: dark
          ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [C.brand.withValues(alpha: .12), Colors.transparent], stops: const [0, .5])
          : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFFFFE3CC), Color(0xFFFFF6EE), Color(0x00FFFFFF)], stops: [0, .46, 1]),
    );

class ThemeController extends ChangeNotifier {
  bool dark = false;
  SharedPreferences? _sp;

  Future<void> load() async {
    _sp = await SharedPreferences.getInstance();
    // 果橙改版:一次性迁移到浅色默认(旧深色偏好重置一次)
    if (_sp?.getBool('theme_v2') != true) {
      await _sp?.setBool('theme_v2', true);
      await _sp?.setBool('dark', false);
    }
    dark = _sp?.getBool('dark') ?? false; // 默认浅色(果橙·活力)
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
    textTheme: base.textTheme.apply(
      bodyColor: C.ink, displayColor: C.ink,
      fontFamilyFallback: const ['PingFang SC', 'Hiragino Sans GB', 'Microsoft YaHei'],
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: C.surface, foregroundColor: C.ink, elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(color: C.ink, fontSize: 16, fontWeight: FontWeight.w700),
    ),
    canvasColor: C.surface,
  );
}
