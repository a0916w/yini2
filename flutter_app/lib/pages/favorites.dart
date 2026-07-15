import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../api/api.dart';
import '../api/models.dart';
import '../state.dart';
import '../i18n.dart';
import '../theme.dart';
import '../widgets.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Drama>? _list;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final app = context.read<AppState>();
    if (app.authed) {
      try {
        final r = await Api.favorites();
        if (mounted) setState(() => _list = r);
        return;
      } catch (_) {}
    }
    // 未登录:按本地收藏 id 拉详情
    final ids = app.favorites.toList();
    final out = <Drama>[];
    for (final id in ids) {
      try { out.add(await Api.videoDetail(id)); } catch (_) {}
    }
    if (mounted) setState(() => _list = out);
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<ThemeController>().dark;
    final list = _list;
    return Scaffold(
      body: Container(
        decoration: pageTopGrad(dark),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
              child: Row(children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(color: C.surface, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: C.brand.withValues(alpha: .12), blurRadius: 10, offset: const Offset(0, 3))]),
                    child: Icon(Icons.arrow_back_ios_new, size: 15, color: C.ink),
                  ),
                ),
                const SizedBox(width: 12),
                Text(t('myFav'), style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: C.ink)),
                const Spacer(),
                const SizedBox(),
              ]),
            ),
            Expanded(
              child: list == null
                  ? const Center(child: CircularProgressIndicator(color: C.brand))
                  : list.isEmpty
                      ? Center(child: Text(t('noFav'), style: TextStyle(color: C.ink3)))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (c, i) => DramaRow(list[i]),
                        ),
            ),
          ]),
        ),
      ),
    );
  }
}
