import 'package:flutter/material.dart';
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
    final list = _list;
    return Scaffold(
      appBar: AppBar(title: Text(t('myFav'))),
      body: list == null
          ? const Center(child: CircularProgressIndicator(color: C.brand))
          : list.isEmpty
              ? Center(child: Text(t('noFav'), style: TextStyle(color: C.ink3)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: C.line),
                  itemBuilder: (c, i) => DramaRow(list[i]),
                ),
    );
  }
}
