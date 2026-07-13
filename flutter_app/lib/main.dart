import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'api/http.dart';
import 'state.dart';
import 'theme.dart';
import 'i18n.dart';
import 'pages/home.dart';
import 'pages/search.dart';
import 'pages/trends.dart';
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
      builder: (c, s, child) => HomeShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (c, s) => const HomePage()),
        GoRoute(path: '/trends', builder: (c, s) => const TrendsPage()),
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

class HomeShell extends StatelessWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  int _index(String loc) {
    if (loc.startsWith('/trends')) return 1;
    if (loc.startsWith('/me')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    final idx = _index(loc);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        backgroundColor: C.surface,
        indicatorColor: C.brand.withValues(alpha: .12),
        onDestinationSelected: (i) => context.go(['/', '/trends', '/me'][i]),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_filled), label: t('home')),
          NavigationDestination(icon: const Icon(Icons.local_fire_department), label: t('rank')),
          NavigationDestination(icon: const Icon(Icons.person), label: t('me')),
        ],
      ),
    );
  }
}
