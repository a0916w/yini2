import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yini_app/api/http.dart';
import 'package:yini_app/pages/language.dart';
import 'package:yini_app/state.dart';
import 'package:yini_app/theme.dart';

void main() {
  testWidgets('language page back button pops', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Http.init();
    final theme = ThemeController();
    await theme.load();
    final state = AppState();

    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (c, s) => Scaffold(
        body: Center(child: Builder(builder: (c) => TextButton(
          onPressed: () => c.push('/language'),
          child: const Text('open'),
        ))),
      )),
      GoRoute(path: '/language', builder: (c, s) => const LanguagePage()),
    ]);

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: state),
        ChangeNotifierProvider.value(value: theme),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // 语言页已打开
    expect(find.text('中文'), findsOneWidget);

    // 点返回圆钮
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    // 应回到首页
    expect(find.text('open'), findsOneWidget);
    expect(find.text('中文'), findsNothing);
  });
}
