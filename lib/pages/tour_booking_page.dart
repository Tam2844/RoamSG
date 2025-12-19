import 'package:flutter/material.dart';

class TourBookingPage extends StatefulWidget {
  const TourBookingPage({super.key});

  @override
  State<TourBookingPage> createState() => _TourBookingPageState();
}

class _TourBookingPageState extends State<TourBookingPage> {
  int _mode = 0; // 0 Hour | 1 Day | 2 Immediate

  String _district = "District 2";
  String _language = "English";
  String _level = "Advanced Guide (II)";

  DateTime _start = DateTime.now().add(const Duration(days: 1, hours: 1));
  DateTime _end = DateTime.now().add(const Duration(days: 1, hours: 13));

  int _adults = 3;

  final _levels = const [
    "Newbie Guide (I)",
    "Advanced Guide (II)",
    "Pro Guide (III)",
  ];
  final _langs = const ["English", "Vietnamese", "Japanese", "Korean"];
  final _districts = const ["District 1", "District 2", "District 3", "Hoc Mon"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFF),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header()),
            SliverToBoxAdapter(child: const SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SearchCard(),
              ),
            ),
            SliverToBoxAdapter(child: const SizedBox(height: 14)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _TopGuidesHeader(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: _TopGuidesFilters(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
              sliver: SliverList.separated(
                itemCount: _demoGuides.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _GuideCard(g: _demoGuides[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== UI pieces =====

  Widget _Header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF67D4FF), Color(0xFF4C7DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _IconCircle(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.pop(context),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.attach_money_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text("USD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE066),
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [BoxShadow(blurRadius: 18, color: Color(0x22000000), offset: Offset(0, 8))],
              ),
              child: const Text(
                "Tour Guide",
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ModeTabs(),
        ],
      ),
    );
  }

  Widget _ModeTabs() {
    final items = const ["Hour", "Day", "Immediate"];
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final selected = _mode == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _mode = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  items[i],
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: selected ? const Color(0xFF2B4BFF) : Colors.white,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _SearchCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(blurRadius: 18, color: Color(0x14000000), offset: Offset(0, 8))],
      ),
      child: Column(
        children: [
          _FieldTile(
            icon: Icons.search_rounded,
            title: _district,
            trailing: IconButton(
              onPressed: _pickDistrict,
              icon: const Icon(Icons.gps_fixed_rounded, color: Color(0xFF4C7DFF)),
              tooltip: "Chọn khu vực",
            ),
            onTap: _pickDistrict,
          ),
          const SizedBox(height: 10),
          _FieldTile(
            icon: Icons.translate_rounded,
            title: _language,
            onTap: _pickLanguage,
          ),
          const SizedBox(height: 10),
          _FieldTile(
            icon: Icons.verified_rounded,
            title: _level,
            onTap: _pickLevel,
          ),
          const SizedBox(height: 10),
          _ModeSpecificFields(),
          const SizedBox(height: 10),
          _AdultsTile(),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF67D4FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _onSearch,
              child: const Text("SEARCH", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ModeSpecificFields() {
    if (_mode == 2) {
      // Immediate
      return Row(
        children: [
          Expanded(
            child: _MiniInfo(
              icon: Icons.flash_on_rounded,
              title: "Now",
              subtitle: "Immediate",
              onTap: () {
                setState(() {
                  _start = DateTime.now();
                  _end = DateTime.now().add(const Duration(hours: 2));
                });
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MiniInfo(
              icon: Icons.timer_rounded,
              title: "2 hours",
              subtitle: "Default",
              onTap: () async {
                // tuỳ chủ nhân sau này làm duration picker
              },
            ),
          ),
        ],
      );
    }

    // Hour / Day: dùng start/end
    return Row(
      children: [
        Expanded(
          child: _MiniInfo(
            icon: Icons.calendar_month_rounded,
            title: _fmtTime(_start),
            subtitle: _fmtDate(_start),
            onTap: () => _pickDateTime(isStart: true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniInfo(
            icon: Icons.calendar_month_rounded,
            title: _fmtTime(_end),
            subtitle: _fmtDate(_end),
            onTap: () => _pickDateTime(isStart: false),
          ),
        ),
      ],
    );
  }

  Widget _AdultsTile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3FAFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.group_rounded, color: Color(0xFF4C7DFF)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "$_adults adults",
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          _StepBtn(icon: Icons.remove_rounded, onTap: () => setState(() => _adults = (_adults - 1).clamp(1, 20))),
          const SizedBox(width: 8),
          _StepBtn(icon: Icons.add_rounded, onTap: () => setState(() => _adults = (_adults + 1).clamp(1, 20))),
        ],
      ),
    );
  }

  Widget _TopGuidesHeader() {
    return const Text(
      "TOP GUIDES",
      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.6),
    );
  }

  Widget _TopGuidesFilters() {
    return Row(
      children: [
        _Pill(
          text: "Level",
          icon: Icons.keyboard_arrow_down_rounded,
          onTap: _pickLevel,
        ),
        const SizedBox(width: 10),
        _Pill(
          text: "All",
          onTap: () {},
          active: true,
        ),
        const SizedBox(width: 10),
        _Pill(
          text: _district,
          onTap: _pickDistrict,
        ),
      ],
    );
  }

  // ===== actions =====

  Future<void> _pickDistrict() async {
    final v = await _showPicker(title: "Chọn khu vực", options: _districts, current: _district);
    if (v != null) setState(() => _district = v);
  }

  Future<void> _pickLanguage() async {
    final v = await _showPicker(title: "Chọn ngôn ngữ", options: _langs, current: _language);
    if (v != null) setState(() => _language = v);
  }

  Future<void> _pickLevel() async {
    final v = await _showPicker(title: "Chọn level guide", options: _levels, current: _level);
    if (v != null) setState(() => _level = v);
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final base = isStart ? _start : _end;

    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null) return;

    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    setState(() {
      if (isStart) {
        _start = dt;
        if (_end.isBefore(_start)) _end = _start.add(const Duration(hours: 2));
      } else {
        _end = dt;
        if (_end.isBefore(_start)) _end = _start.add(const Duration(hours: 2));
      }
    });
  }

  void _onSearch() {
    // chỗ này sau này nối Firestore / API
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Search: $_district · $_language · $_level · ${_adults}p · ${_fmtDate(_start)} ${_fmtTime(_start)}",
        ),
      ),
    );
  }

  Future<String?> _showPicker({
    required String title,
    required List<String> options,
    required String current,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 10),
              ...options.map((e) {
                final selected = e == current;
                return ListTile(
                  title: Text(e, style: const TextStyle(fontWeight: FontWeight.w800)),
                  trailing: selected ? const Icon(Icons.check_rounded, color: Color(0xFF4C7DFF)) : null,
                  onTap: () => Navigator.pop(ctx, e),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ===== format utils =====

  String _two(int n) => n.toString().padLeft(2, "0");
  String _fmtTime(DateTime d) => "${_two(d.hour)}:${_two(d.minute)}";
  String _fmtDate(DateTime d) => "${_two(d.day)}/${_two(d.month)}";

  // ===== small widgets =====

  Widget _Pill({required String text, IconData? icon, VoidCallback? onTap, bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFB7F0E8) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [BoxShadow(blurRadius: 14, color: Color(0x14000000), offset: Offset(0, 6))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
            if (icon != null) ...[
              const SizedBox(width: 6),
              Icon(icon, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconCircle({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.22),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _FieldTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  const _FieldTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3FAFF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF4C7DFF)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MiniInfo({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3FAFF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF4C7DFF)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(blurRadius: 14, color: Color(0x14000000), offset: Offset(0, 6))],
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF2B4BFF)),
      ),
    );
  }
}

// ===== Demo data + Guide card =====

class Guide {
  final String name;
  final String langs;
  final String metaLeft;
  final double rating;
  final int reviews;
  final String tag1;
  final String tag2;

  const Guide({
    required this.name,
    required this.langs,
    required this.metaLeft,
    required this.rating,
    required this.reviews,
    required this.tag1,
    required this.tag2,
  });
}

const _demoGuides = <Guide>[
  Guide(
    name: "VU KIM YEN",
    langs: "Languages: VN, EN, CN",
    metaLeft: "Experience: 10 yrs\nDistrict: 1, 2, 3, ...",
    rating: 4.8,
    reviews: 2599,
    tag1: "Friendly",
    tag2: "Humorous",
  ),
  Guide(
    name: "TRAN THI VAN",
    langs: "Languages: VN, EN",
    metaLeft: "Experience: 6 yrs\nDistrict: 2, 7, ...",
    rating: 4.7,
    reviews: 1200,
    tag1: "Careful",
    tag2: "On-time",
  ),
  Guide(
    name: "NGUYEN MINH TRI",
    langs: "Languages: VN, EN, JP",
    metaLeft: "Experience: 8 yrs\nDistrict: 1, 5, ...",
    rating: 4.9,
    reviews: 840,
    tag1: "Pro",
    tag2: "Storyteller",
  ),
];

class _GuideCard extends StatelessWidget {
  final Guide g;
  const _GuideCard({required this.g});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(blurRadius: 18, color: Color(0x14000000), offset: Offset(0, 8))],
      ),
      child: Row(
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFE9F7FF),
                child: const Icon(Icons.person_rounded, color: Color(0xFF4C7DFF), size: 30),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFB7F0E8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text("MORE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(g.langs, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700, fontSize: 12.5)),
                const SizedBox(height: 6),
                Text(g.metaLeft, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700, fontSize: 12.5)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StarRow(rating: g.rating),
                    const SizedBox(width: 8),
                    Text("${g.rating.toStringAsFixed(1)} (${g.reviews})",
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Tag(text: g.tag1),
                    _Tag(text: g.tag2),
                    const _Tag(text: "Level"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3FAFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }
}

class _StarRow extends StatelessWidget {
  final double rating;
  const _StarRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    final full = rating.floor().clamp(0, 5);
    final half = (rating - full) >= 0.5 ? 1 : 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < full) return const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFC107));
        if (i == full && half == 1) return const Icon(Icons.star_half_rounded, size: 16, color: Color(0xFFFFC107));
        return const Icon(Icons.star_border_rounded, size: 16, color: Color(0xFFFFC107));
      }),
    );
  }
}
