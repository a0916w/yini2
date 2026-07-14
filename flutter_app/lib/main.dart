import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'api/http.dart';
import 'state.dart';
import 'theme.dart';
import 'pages/home.dart';
import 'pages/search.dart';
import 'pages/trends.dart';
import 'pages/topics.dart';
import 'pages/wishes.dart';
import 'pages/detail.dart';
import 'pages/player.dart';
import 'pages/vip.dart';
import 'pages/login.dart';
import 'pages/me.dart';
import 'pages/favorites.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Http.init();
  final state = AppState();
  await state.boot();
  runApp(ChangeNotifierProvider.value(value: state, child: const YiniApp()));
}

final _router = GoRouter(
  routes: [
    ShellRoute(
      builder: (c, s, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (c, s) => const HomePage()),
        GoRoute(path: '/trends', builder: (c, s) => const TrendsPage()),
        GoRoute(path: '/wishes', builder: (c, s) => const WishesPage()),
        GoRoute(path: '/topics', builder: (c, s) => const TopicsPage()),
        GoRoute(path: '/me', builder: (c, s) => const MePage()),
      ],
    ),
    GoRoute(path: '/search', builder: (c, s) => const SearchPage()),
    GoRoute(path: '/drama/:id', builder: (c, s) => DetailPage(int.parse(s.pathParameters['id']!))),
    GoRoute(path: '/watch/:id', builder: (c, s) => PlayerPage(int.parse(s.pathParameters['id']!))),
    GoRoute(path: '/vip', builder: (c, s) => const VipPage()),
    GoRoute(path: '/login', builder: (c, s) => const LoginPage()),
    GoRoute(path: '/favorites', builder: (c, s) => const FavoritesPage()),
  ],
);

class YiniApp extends StatelessWidget {
  const YiniApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '橙子短剧',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: _router,
    );
  }
}

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    ('/', '首页', Icons.home_filled),
    ('/trends', '魔改', Icons.local_movies_outlined),
    ('/wishes', '心愿榜', Icons.favorite),
    ('/topics', '专题', Icons.grid_view_rounded),
    ('/me', '我的', Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    int cur = _tabs.indexWhere((t) => t.$1 == loc);
    if (cur < 0) cur = 0;
    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomBar(current: cur, onTap: (i) => context.go(_tabs[i].$1)),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _BottomBar({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: C.surface,
        border: Border(top: BorderSide(color: C.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(children: [
            for (var i = 0; i < MainShell._tabs.length; i++)
              Expanded(child: _item(i)),
          ]),
        ),
      ),
    );
  }

  Widget _item(int i) {
    final t = MainShell._tabs[i];
    final active = i == current;
    // 中间「心愿榜」= 凸起粉色爱心
    if (i == 2) {
      return InkWell(
        onTap: () => onTap(i),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Transform.translate(
            offset: const Offset(0, -2),
            child: Container(
              width: 42, height: 42,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Icon(Icons.favorite, color: C.like, size: 30),
            ),
          ),
          Text(t.$2, style: const TextStyle(fontSize: 11, color: C.ink3, fontWeight: FontWeight.w600)),
        ]),
      );
    }
    return InkWell(
      onTap: () => onTap(i),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(t.$3, size: 23, color: active ? C.brand : C.ink3),
        const SizedBox(height: 3),
        Text(t.$2, style: TextStyle(fontSize: 11, color: active ? C.brand : C.ink3, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
