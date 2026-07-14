import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'api/http.dart';
import 'api/api.dart';
import 'api/media.dart';
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
  // 启动即预热:核心数据 + 站点配置(封面/HLS 签名要用),后台进行不阻塞首帧
  Api.prewarm();
  Media.settings();
  runApp(ChangeNotifierProvider.value(value: state, child: const YiniApp()));
}

final _rootKey = GlobalKey<NavigatorState>();

final _router = GoRouter(
  navigatorKey: _rootKey,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (c, s, shell) => MainShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/', builder: (c, s) => const HomePage())]),
        StatefulShellBranch(routes: [GoRoute(path: '/trends', builder: (c, s) => const TrendsPage())]),
        StatefulShellBranch(routes: [GoRoute(path: '/wishes', builder: (c, s) => const WishesPage())]),
        StatefulShellBranch(routes: [GoRoute(path: '/topics', builder: (c, s) => const TopicsPage())]),
        StatefulShellBranch(routes: [GoRoute(path: '/me', builder: (c, s) => const MePage())]),
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
  final StatefulNavigationShell shell;
  const MainShell({super.key, required this.shell});

  static const _tabs = [
    ('首页', Icons.home_filled),
    ('魔改', Icons.local_movies_outlined),
    ('心愿榜', Icons.favorite),
    ('专题', Icons.grid_view_rounded),
    ('我的', Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: _BottomBar(
        current: shell.currentIndex,
        onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
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
      decoration: const BoxDecoration(color: C.surface, border: Border(top: BorderSide(color: C.line))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(children: [for (var i = 0; i < MainShell._tabs.length; i++) Expanded(child: _item(i))]),
        ),
      ),
    );
  }

  Widget _item(int i) {
    final t = MainShell._tabs[i];
    final active = i == current;
    if (i == 2) {
      return InkWell(onTap: () => onTap(i), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Transform.translate(offset: const Offset(0, -2), child: const Icon(Icons.favorite, color: C.like, size: 30)),
        Text(t.$1, style: const TextStyle(fontSize: 11, color: C.ink3, fontWeight: FontWeight.w500)),
      ]));
    }
    return InkWell(onTap: () => onTap(i), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(t.$2, size: 23, color: active ? C.brand : C.ink3),
      const SizedBox(height: 3),
      Text(t.$1, style: TextStyle(fontSize: 11, color: active ? C.brand : C.ink3, fontWeight: FontWeight.w500)),
    ]));
  }
}
