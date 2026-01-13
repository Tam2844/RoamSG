import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'user_tour_detail_page.dart';

class UserTourSearchPage extends StatefulWidget {
  final VoidCallback? onBackToHomeTab;
  const UserTourSearchPage({super.key, this.onBackToHomeTab});

  @override
  State<UserTourSearchPage> createState() => _UserTourSearchPageState();
}

class _UserTourSearchPageState extends State<UserTourSearchPage> {
  final _qCtrl = TextEditingController();
  bool _filtersOpen = true;

  String _keyword = '';
  String _city = 'All';
  int _days = 0; // 0 = all
  int _maxPrice = 0; // 0 = all
  String _lang = 'All';

  _Sort _sort = _Sort.newest;

  @override
  void initState() {
    super.initState();
    _qCtrl.addListener(() {
      setState(() => _keyword = _qCtrl.text.trim());
    });
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    super.dispose();
  }

Widget _Header() {
  final topPad = MediaQuery.of(context).padding.top;

  return Container(
    padding: EdgeInsets.fromLTRB(16, topPad + 16, 16, 14),
    decoration: const BoxDecoration(
      color: Color(0xFF86D9FF),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "RoamSG",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 4),
        Text(
          "Search tours",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}



  Query<Map<String, dynamic>> _baseQuery() {
    return FirebaseFirestore.instance
        .collection('tours')
        .orderBy('createdAt', descending: true)
        .limit(200);
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF6FAFF),

    // ✅ Đưa StreamBuilder ra ngoài để build thành 1 trang cuộn
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _baseQuery().snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text("Lỗi load tours: ${snap.error}"));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;

        final items = docs
            .map((d) => _TourVM.fromDoc(d))
            .where(_matchFilters)
            .toList();

        _applySort(items);

        final bottomPad =
            MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 12;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header()),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: _SearchBox(
                  controller: _qCtrl,
                  onClear: () => _qCtrl.clear(),
                  onFocus: () => setState(() => _filtersOpen = false),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _CollapsibleFilterPanel(
                  isOpen: _filtersOpen,
                  onToggle: () => setState(() => _filtersOpen = !_filtersOpen),
                  child: _FilterBar(
                    city: _city,
                    days: _days,
                    maxPrice: _maxPrice,
                    lang: _lang,
                    sort: _sort,
                    onChanged: (v) => setState(() {
                      _city = v.city;
                      _days = v.days;
                      _maxPrice = v.maxPrice;
                      _lang = v.lang;
                      _sort = v.sort;
                    }),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 10)),

            if (items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    "Không có tour phù hợp bộ lọc hiện tại.",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.black54,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomPad),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final t = items[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TourTile(
                          tour: t,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserTourDetailPage(tourId: t.id),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

  bool _matchFilters(_TourVM t) {
    if (_keyword.isNotEmpty) {
      final k = _normalize(_keyword);
      final hay = _normalize("${t.title} ${t.city} ${t.description} ${t.tags.join(' ')}");
      if (!hay.contains(k)) return false;
    }

    if (_city != 'All' && _normalize(t.city) != _normalize(_city)) return false;
    if (_days > 0 && t.days != _days) return false;
    if (_maxPrice > 0 && t.price > _maxPrice) return false;

    if (_lang != 'All') {
      final has = t.languages.map(_normalize).contains(_normalize(_lang));
      if (!has) return false;
    }

    return true;
  }

  void _applySort(List<_TourVM> items) {
    switch (_sort) {
      case _Sort.newest:
        items.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
        break;
      case _Sort.priceAsc:
        items.sort((a, b) => a.price.compareTo(b.price));
        break;
      case _Sort.priceDesc:
        items.sort((a, b) => b.price.compareTo(a.price));
        break;
    }
  }

  String _normalize(String s) => s.trim().toLowerCase();
}

enum _Sort { newest, priceAsc, priceDesc }

class _FilterValue {
  final String city;
  final int days;
  final int maxPrice;
  final String lang;
  final _Sort sort;

  const _FilterValue({
    required this.city,
    required this.days,
    required this.maxPrice,
    required this.lang,
    required this.sort,
  });
}

class _FilterBar extends StatelessWidget {
  final String city;
  final int days;
  final int maxPrice;
  final String lang;
  final _Sort sort;

  final ValueChanged<_FilterValue> onChanged;

  const _FilterBar({
    required this.city,
    required this.days,
    required this.maxPrice,
    required this.lang,
    required this.sort,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const cities = ['All', 'Singapore', 'HCM', 'VungTau', 'CanTho'];
    const dayOpts = [0, 1, 2, 3, 4, 5, 7];
    const priceOpts = [0, 300000, 500000, 800000, 1000000, 1500000, 2000000];
    const langs = ['All', 'vi', 'en', 'zh', 'ja', 'ko'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(blurRadius: 14, color: Color(0x14000000), offset: Offset(0, 6))],
      ),
      child: Wrap(
        runSpacing: 10,
        spacing: 10,
        children: [
          _dd<String>(
            label: "City",
            value: city,
            items: cities,
            onChanged: (v) => onChanged(_FilterValue(
              city: v,
              days: days,
              maxPrice: maxPrice,
              lang: lang,
              sort: sort,
            )),
          ),
          _dd<int>(
            label: "Days",
            value: days,
            items: dayOpts,
            format: (v) => v == 0 ? "All" : "$v day(s)",
            onChanged: (v) => onChanged(_FilterValue(
              city: city,
              days: v,
              maxPrice: maxPrice,
              lang: lang,
              sort: sort,
            )),
          ),
          _dd<int>(
            label: "Max price",
            value: maxPrice,
            items: priceOpts,
            format: (v) => v == 0 ? "All" : _money(v),
            onChanged: (v) => onChanged(_FilterValue(
              city: city,
              days: days,
              maxPrice: v,
              lang: lang,
              sort: sort,
            )),
          ),
          _dd<String>(
            label: "Lang",
            value: lang,
            items: langs,
            onChanged: (v) => onChanged(_FilterValue(
              city: city,
              days: days,
              maxPrice: maxPrice,
              lang: v,
              sort: sort,
            )),
          ),
          _dd<_Sort>(
            label: "Sort",
            value: sort,
            items: const [_Sort.newest, _Sort.priceAsc, _Sort.priceDesc],
            format: (v) {
              switch (v) {
                case _Sort.newest:
                  return "Newest";
                case _Sort.priceAsc:
                  return "Price ↑";
                case _Sort.priceDesc:
                  return "Price ↓";
              }
            },
            onChanged: (v) => onChanged(_FilterValue(
              city: city,
              days: days,
              maxPrice: maxPrice,
              lang: lang,
              sort: v,
            )),
          ),
        ],
      ),
    );
  }

  Widget _dd<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T> onChanged,
    String Function(T v)? format,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150),
      child: DropdownButtonFormField<T>(
        value: value,
        isDense: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: items
            .map((it) => DropdownMenuItem<T>(
                  value: it,
                  child: Text(format?.call(it) ?? it.toString()),
                ))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;
  final VoidCallback? onFocus;

  const _SearchBox({
    required this.controller,
    required this.onClear,
    this.onFocus,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onTap: onFocus,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: "Search title, city, tags...",
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty ? null : IconButton(onPressed: onClear, icon: const Icon(Icons.clear)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _TourTile extends StatelessWidget {
  final _TourVM tour;
  final VoidCallback onTap;

  const _TourTile({required this.tour, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(blurRadius: 14, color: Color(0x14000000), offset: Offset(0, 6))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
              child: SizedBox(
                width: 120,
                height: 110,
                child: tour.imageUrl.isEmpty
                    ? Container(
                        color: const Color(0xFFE9F7FF),
                        child: const Icon(Icons.image, color: Color(0xFF4C7DFF)),
                      )
                    : Image.network(
                        tour.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFE9F7FF),
                          child: const Icon(Icons.broken_image, color: Color(0xFF4C7DFF)),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tour.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${tour.city} · ${tour.days} day(s) · max ${tour.maxPeople}",
                      style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _pill(_money(tour.price)),
                        if (tour.languages.isNotEmpty) _pill("Lang: ${tour.languages.take(2).join(', ')}"),
                        if (tour.tags.isNotEmpty) _pill("#${tour.tags.first}"),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F7FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF4C7DFF)),
      ),
    );
  }
}

class _TourVM {
  final String id;
  final String title;
  final String city;
  final String description;
  final String imageUrl;
  final int price;
  final int days;
  final int maxPeople;
  final List<String> tags;
  final List<String> languages;
  final int createdAtMs;

  _TourVM({
    required this.id,
    required this.title,
    required this.city,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.days,
    required this.maxPeople,
    required this.tags,
    required this.languages,
    required this.createdAtMs,
  });

  factory _TourVM.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();

    int tsMs(dynamic v) {
      if (v is Timestamp) return v.millisecondsSinceEpoch;
      if (v is int) return v;
      return 0;
    }

    List<String> toStrList(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      return const [];
    }

    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is num) return v.toInt();
      return int.tryParse((v ?? '0').toString()) ?? 0;
    }

    return _TourVM(
      id: doc.id,
      title: (d['title'] ?? 'Tour').toString(),
      city: (d['city'] ?? '').toString(),
      description: (d['description'] ?? '').toString(),
      imageUrl: (d['imageUrl'] ?? '').toString(),
      price: asInt(d['price']),
      days: asInt(d['days']),
      maxPeople: asInt(d['maxPeople']),
      tags: toStrList(d['tags']),
      languages: toStrList(d['languages']),
      createdAtMs: tsMs(d['createdAt']),
    );
  }
}

String _money(int vnd) {
  final s = vnd.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final left = s.length - i;
    buf.write(s[i]);
    if (left > 1 && left % 3 == 1) buf.write('.');
  }
  return "${buf.toString()}đ";
}

class _CollapsibleFilterPanel extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onToggle;
  final Widget child;

  const _CollapsibleFilterPanel({
    required this.isOpen,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            color: Color(0x14000000),
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded, color: Color(0xFF4C7DFF)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Filters",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.expand_more_rounded, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: child,
            ),
            crossFadeState: isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

// ✅ widget còn thiếu: _IconCircle
class _IconCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconCircle({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 42,
        height: 42,
        child: Center(
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}