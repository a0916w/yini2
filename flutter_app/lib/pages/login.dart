import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state.dart';
import '../theme.dart';

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
    if (_acc.text.trim().isEmpty) { setState(() => _err = '请输入账号'); return; }
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
    return Scaffold(
      appBar: AppBar(title: const Text('登录')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 68, height: 68, decoration: BoxDecoration(gradient: C.brandGrad, borderRadius: BorderRadius.circular(20)), alignment: Alignment.center, child: const Text('橙', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900))),
            const SizedBox(height: 12),
            const Text('橙子短剧', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 26),
            TextField(controller: _acc, decoration: const InputDecoration(labelText: '账号 / 邮箱', border: OutlineInputBorder())),
            const SizedBox(height: 14),
            TextField(controller: _pwd, obscureText: true, decoration: const InputDecoration(labelText: '密码', border: OutlineInputBorder())),
            if (_err != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_err!, style: const TextStyle(color: C.like))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: _busy ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: C.brand, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
                child: Text(_busy ? '登录中…' : '登录', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
