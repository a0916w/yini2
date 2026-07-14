import 'package:flutter/material.dart';
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
    final list = _list;
    return Scaffold(
      appBar: AppBar(title: Text(t('history')), actions: [
        if (list != null && list.isNotEmpty)
          TextButton(
            onPressed: () async { await WatchHistory.clear(); if (mounted) setState(() => _list = []); },
            child: Text(t('clear'), style: TextStyle(color: C.ink3, fontSize: 13)),
          ),
      ]),
      body: list == null
          ? const Center(child: CircularProgressIndicator(color: C.brand))
          : list.isEmpty
              ? Center(child: Text(t('noHistory'), style: TextStyle(color: C.ink3)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: C.line),
                  itemBuilder: (c, i) => DramaRow(list[i]),
                ),
    );
  }
}
