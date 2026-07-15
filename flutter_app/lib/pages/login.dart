import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state.dart';
import '../i18n.dart';
import '../theme.dart';

// 登录(果橙):浅橙渐变底 + YiniTV logo + 暖底输入 + 主色渐变按钮
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _acc = TextEditingController();
  final _pwd = TextEditingController();
  bool _busy = false;
  String? _err;

  Future<void> _submit() async {
    if (_acc.text.trim().isEmpty) { setState(() => _err = t('enterAccount')); return; }
    setState(() { _busy = true; _err = null; });
    try {
      await context.read<AppState>().login(_acc.text, _pwd.text);
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _err = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<ThemeController>().dark;
    return Scaffold(
      body: Container(
        decoration: pageTopGrad(dark),
        child: SafeArea(
          child: Column(children: [
            // 返回圆钮
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(color: C.surface, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: C.brand.withValues(alpha: .12), blurRadius: 10, offset: const Offset(0, 3))]),
                    child: Icon(Icons.arrow_back_ios_new, size: 15, color: C.ink),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    // YiniTV logo
                    Text.rich(TextSpan(children: [
                      TextSpan(text: 'Yini', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -.5, color: C.ink)),
                      const TextSpan(text: 'TV', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -.5, color: C.brand)),
                    ])),
                    const SizedBox(height: 6),
                    Text(t('vipPitch'), style: TextStyle(fontSize: 12, color: C.ink3)),
                    const SizedBox(height: 30),
                    _field(_acc, t('account'), Icons.person_outline, false),
                    const SizedBox(height: 12),
                    _field(_pwd, t('password'), Icons.lock_outline, true),
                    if (_err != null)
                      Padding(padding: const EdgeInsets.only(top: 12), child: Text(_err!, style: const TextStyle(color: C.like, fontSize: 12.5))),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _busy ? null : _submit,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: C.brandGrad,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [BoxShadow(color: C.brand.withValues(alpha: .32), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: Text(_busy ? t('loggingIn') : t('login'),
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // 暖底输入胶囊
  Widget _field(TextEditingController c, String hint, IconData icon, bool obscure) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Icon(icon, size: 17, color: C.ink3),
          const SizedBox(width: 10),
          Expanded(child: TextField(
            controller: c,
            obscureText: obscure,
            style: TextStyle(fontSize: 14, color: C.ink),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 13.5, color: C.quiet),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          )),
        ]),
      );
}
