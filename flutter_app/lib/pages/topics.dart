import 'package:flutter/material.dart';
import '../api/api.dart';
import '../api/models.dart';
import '../theme.dart';
import '../widgets.dart';

class TopicsPage extends StatefulWidget {
  const TopicsPage({super.key});
  @override
  State<TopicsPage> createState() => _TopicsPageState();
}

class _TopicsPageState extends State<TopicsPage> {
  List<Map>? _topics; // {name, count, covers:[Drama]}

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final cats = await Api.categories();
      final out = <Map>[];
      for (final c in cats.cast<Map>()) {
        List<Drama> covers = [];
        try {
          final (rows, _, _) = await Api.videos(categoryId: c['id'] as int, perPage: 3);
          covers = rows;
        } catch (_) {}
        out.add({'name': cleanName(c['name'] as String?), 'count': c['videos_count'] ?? '', 'covers': covers});
      }
      if (mounted) setState(() => _topics = out);
    } catch (_) {
      if (mounted) setState(() => _topics = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topics = _topics;
    return Scaffold(
      appBar: AppBar(title: const Text('专题合集'), centerTitle: false),
      body: topics == null
          ? const Center(child: CircularProgressIndicator(color: C.brand))
          : ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: topics.length,
              itemBuilder: (c, i) {
                final tp = topics[i];
                final covers = (tp['covers'] as List).cast<Drama>();
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.line)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${tp['name']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text('${tp['count']}部精选', style: const TextStyle(color: C.ink3, fontSize: 12)),
                      ])),
                      const Icon(Icons.chevron_right, color: C.ink3),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      for (var k = 0; k < covers.length; k++) ...[
                        Expanded(child: AspectRatio(aspectRatio: 3 / 4, child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Cover(covers[k])))),
                        if (k < covers.length - 1) const SizedBox(width: 8),
                      ],
                    ]),
                  ]),
                );
              },
            ),
    );
  }
}
