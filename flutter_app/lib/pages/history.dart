import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../api/models.dart';
import '../history.dart';
import '../i18n.dart';
import '../theme.dart';
import '../widgets.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Drama>? _list;

  @override
  void initState() {
    super.initState();
    WatchHistory.list().then((r) { if (mounted) setState(() => _list = r); });
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
                Text(t('history'), style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: C.ink)),
                const Spacer(),
                if (list != null && list.isNotEmpty)
                  GestureDetector(
                    onTap: () async { await WatchHistory.clear(); if (mounted) setState(() => _list = []); },
                    child: Text(t('clear'), style: TextStyle(color: C.quiet, fontSize: 13)),
                  ),
              ]),
            ),
            Expanded(
              child: list == null
                  ? const Center(child: CircularProgressIndicator(color: C.brand))
                  : list.isEmpty
                      ? Center(child: Text(t('noHistory'), style: TextStyle(color: C.ink3)))
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
