import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
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
import 'pages/theater.dart';
import 'pages/topics.dart';
import 'pages/detail.dart';
import 'pages/player.dart';
import 'pages/vip.dart';
import 'pages/login.dart';
import 'pages/me.dart';
import 'pages/favorites.dart';
import 'pages/history.dart';
import 'pages/topic_list.dart';
import 'i18n.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 安卓:申请最高刷新率(ColorOS 等默认把第三方 App 锁 60Hz)
  if (defaultTargetPlatform == TargetPlatform.android) {
    try { await FlutterDisplayMode.setHighRefreshRate(); } catch (_) {}
  }
  await Http.init();
  final theme = ThemeController();
  await theme.load(); // 默认浅色(果橙·活力)
  final state = AppState();
  await state.boot();
  // 启动即预热:核心数据 + 站点配置(封面/HLS 签名要用),后台进行不阻塞首帧
  Api.prewarm();
  Media.settings();
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider.value(value: state),
    ChangeNotifierProvider.value(value: theme),
  ], child: const YiniApp()));
}

final _rootKey = GlobalKey<NavigatorState>();

final _router = GoRouter(
  navigatorKey: _rootKey,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (c, s, shell) => MainShell(shell: shell),
      branches: [
        // 首页=竖滑视频流(抖音式开屏即刷),剧场=分类浏览页
        StatefulShellBranch(routes: [GoRoute(path: '/', builder: (c, s) => const TheaterPage())]),
        StatefulShellBranch(routes: [GoRoute(path: '/theater', builder: (c, s) => const HomePage())]),
        StatefulShellBranch(routes: [GoRoute(path: '/trends', builder: (c, s) => const TrendsPage())]),
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
    GoRoute(path: '/history', builder: (c, s) => const HistoryPage()),
    GoRoute(path: '/topic/:id', builder: (c, s) => TopicListPage(int.parse(s.pathParameters['id']!), s.uri.queryParameters['name'] ?? '')),
  ],
);

class YiniApp extends StatelessWidget {
  const YiniApp({super.key});
  @override
  Widget build(BuildContext context) {
    final dark = context.watch<ThemeController>().dark;
    return MaterialApp.router(
      title: '橙子短剧',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(dark),
      routerConfig: _router,
    );
  }
}

class MainShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const MainShell({super.key, required this.shell});

  static List<(String, IconData)> get _tabs => [
    (t('home'), Icons.home_outlined),
    (t('cinema'), Icons.smart_display_outlined),
    (t('rank'), Icons.emoji_events_outlined),
    (t('topics'), Icons.grid_view_outlined),
    (t('me'), Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>(); // 主题切换时重建外壳/底栏,刷新 C.* 颜色
    context.watch<AppState>(); // 语言切换时重建底栏文案
    activeTab.value = shell.currentIndex; // 剧场据此在切走时暂停播放
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

  // 首页 feed 为深色态,其余浅色态(规范:blur + 半透明)
  bool get _feedDark => current == 0;
  Color get _bg => _feedDark ? const Color(0xE10C0C0E) : C.surface.withValues(alpha: .94);
  Color get _border => _feedDark ? Colors.white.withValues(alpha: .08) : C.line;
  Color get _idle => _feedDark ? Colors.white.withValues(alpha: .55) : C.quiet;

  @override
  Widget build(BuildContext context) {
    // 低端机优化:不用 BackdropFilter(blur 在入门 GPU 上开销大),半透明底近似
    return Container(
      decoration: BoxDecoration(color: _bg, border: Border(top: BorderSide(color: _border))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(children: [for (var i = 0; i < MainShell._tabs.length; i++) Expanded(child: _item(i))]),
        ),
      ),
    );
  }

  Widget _item(int i) {
    final t = MainShell._tabs[i];
    final active = i == current;
    final c = active ? C.brand : _idle;
    return InkWell(onTap: () => onTap(i), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(t.$2, size: 22, color: c),
      const SizedBox(height: 3),
      Text(t.$1, style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.w700)),
    ]));
  }
}
