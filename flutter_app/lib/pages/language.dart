import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../api/http.dart';
import '../state.dart';
import '../i18n.dart';
import '../theme.dart';

// 语言选择页(果橙):全屏卡片列表,选中即应用并返回
class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  // 每种语言的英文副题 / 旗帜
  static const _subs = {
    'zh': 'Chinese', 'en': 'English', 'vi': 'Vietnamese', 'th': 'Thai', 'id': 'Indonesian',
  };
  static const _flags = {
    'zh': '🇨🇳', 'en': '🇺🇸', 'vi': '🇻🇳', 'th': '🇹🇭', 'id': '🇮🇩',
  };

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<ThemeController>().dark;
    context.watch<AppState>();
    final cur = Http.lang;
    return Scaffold(
      body: Container(
        decoration: pageTopGrad(dark),
        child: SafeArea(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // 顶栏:返回圆钮 + 标题
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
              child: Row(children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque, // 扩大命中:含透明外扩区
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/me'); // 兜底:栈异常时直接回「我的」
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(6), // 外扩 6px 点击区
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(color: C.surface, shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: C.brand.withValues(alpha: .12), blurRadius: 10, offset: const Offset(0, 3))]),
                      child: Icon(Icons.arrow_back_ios_new, size: 15, color: C.ink),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(t('language'), style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: C.ink)),
              ]),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                itemCount: languages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (c, i) {
                  final l = languages[i];
                  final on = cur == l.$1;
                  return GestureDetector(
                    onTap: () {
                      if (!on) context.read<AppState>().setLanguage(l.$1);
                      context.pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: on ? C.tag : C.surface2,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: on ? C.brand : Colors.transparent, width: 1.4),
                      ),
                      child: Row(children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(color: C.surface, shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: C.brand.withValues(alpha: on ? .18 : .08), blurRadius: 8, offset: const Offset(0, 2))]),
                          alignment: Alignment.center,
                          child: Text(_flags[l.$1] ?? '🌐', style: const TextStyle(fontSize: 19)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(l.$2, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: on ? C.brand : C.ink)),
                          const SizedBox(height: 2),
                          Text(_subs[l.$1] ?? '', style: TextStyle(fontSize: 11, color: C.ink3)),
                        ])),
                        Icon(on ? Icons.check_circle : Icons.circle_outlined, color: on ? C.brand : C.quiet, size: 22),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
