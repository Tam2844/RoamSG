import 'package:flutter/material.dart';

class TourSearchPage extends StatefulWidget {
  const TourSearchPage({super.key});

  @override
  State<TourSearchPage> createState() => _TourSearchPageState();
}

enum TimeSlot { any, morning, afternoon, evening }

class Tour {
  final String id;
  final String title;
  final String city;
  final String district;
  final String type; // City | Food | Culture | Nature | Night
  final int durationHours;
  final int maxGuests;
  final double rating;
  final int reviews;
  final double priceUsd;

  final bool freeCancel;
  final bool instantConfirm;
  final bool privateTour;

  final DateTime availableFrom;
  final DateTime availableTo;
  final Set<int> weekdays; // DateTime.monday..sunday
  final Set<TimeSlot> slots;
  final List<String> highlights;

  Tour({
    required this.id,
    required this.title,
    required this.city,
    required this.district,
    required this.type,
    required this.durationHours,
    required this.maxGuests,
    required this.rating,
    required this.reviews,
    required this.priceUsd,
    required this.freeCancel,
    required this.instantConfirm,
    required this.privateTour,
    required this.availableFrom,
    required this.availableTo,
    required this.weekdays,
    required this.slots,
    required this.highlights,
  });
}

class _LocResult {
  final String city;
  final String district;
  _LocResult({required this.city, required this.district});
}

class _TourSearchPageState extends State<TourSearchPage> {
  // ===== Filters =====
  String _city = 'Ho Chi Minh City';
  String _district = 'All';
  late DateTimeRange _range;
  TimeSlot _slot = TimeSlot.any;

  String _type = 'All';
  double _maxPrice = 180;
  int _guests = 2;

  bool _needFreeCancel = false;
  bool _needInstantConfirm = false;
  bool _onlyPrivate = false;

  String _sort = 'Popular';
  final TextEditingController _qCtrl = TextEditingController();

  late final List<Tour> _tours;

  final _cities = const ['Ho Chi Minh City', 'Ha Noi', 'Da Nang'];
  final _types = const ['All', 'City', 'Food', 'Culture', 'Nature', 'Night'];
  final Map<String, List<String>> _districtsByCity = const {
    'Ho Chi Minh City': ['All', 'District 1', 'District 2', 'District 3', 'Thu Duc', 'Hoc Mon'],
    'Ha Noi': ['All', 'Hoan Kiem', 'Ba Dinh', 'Cau Giay', 'Tay Ho'],
    'Da Nang': ['All', 'Hai Chau', 'Thanh Khe', 'Son Tra', 'Ngu Hanh Son'],
  };

  @override
  void initState() {
    super.initState();
    final start = DateTime.now().add(const Duration(days: 1));
    _range = DateTimeRange(start: start, end: start.add(const Duration(days: 2)));
    _tours = _buildDemoTours();
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    super.dispose();
  }

  List<Tour> _buildDemoTours() {
    final now = DateTime.now();
    DateTime d(int days) => now.add(Duration(days: days));

    return [
      Tour(
        id: 't1',
        title: 'Saigon Highlights - Half Day City Tour',
        city: 'Ho Chi Minh City',
        district: 'District 1',
        type: 'City',
        durationHours: 4,
        maxGuests: 10,
        rating: 4.8,
        reviews: 2310,
        priceUsd: 39,
        freeCancel: true,
        instantConfirm: true,
        privateTour: false,
        availableFrom: d(0),
        availableTo: d(90),
        weekdays: {1, 2, 3, 4, 5, 6, 7},
        slots: {TimeSlot.morning, TimeSlot.afternoon},
        highlights: const ['Notre Dame', 'Central Post Office', 'Ben Thanh Market'],
      ),
      Tour(
        id: 't2',
        title: 'Street Food Night Safari (Private)',
        city: 'Ho Chi Minh City',
        district: 'District 3',
        type: 'Food',
        durationHours: 3,
        maxGuests: 6,
        rating: 4.9,
        reviews: 1450,
        priceUsd: 55,
        freeCancel: true,
        instantConfirm: true,
        privateTour: true,
        availableFrom: d(0),
        availableTo: d(120),
        weekdays: {4, 5, 6, 7},
        slots: {TimeSlot.evening},
        highlights: const ['Banh mi', 'Oc', 'Che', 'Local alleys'],
      ),
      Tour(
        id: 't3',
        title: 'Cu Chi Tunnels - Full Day Adventure',
        city: 'Ho Chi Minh City',
        district: 'Hoc Mon',
        type: 'Culture',
        durationHours: 8,
        maxGuests: 15,
        rating: 4.7,
        reviews: 980,
        priceUsd: 62,
        freeCancel: false,
        instantConfirm: true,
        privateTour: false,
        availableFrom: d(3),
        availableTo: d(200),
        weekdays: {1, 3, 5, 7},
        slots: {TimeSlot.morning},
        highlights: const ['Tunnels', 'History', 'Optional activities'],
      ),
      Tour(
        id: 't4',
        title: 'Mekong Delta Day Trip - Floating Market',
        city: 'Ho Chi Minh City',
        district: 'District 2',
        type: 'Nature',
        durationHours: 9,
        maxGuests: 12,
        rating: 4.6,
        reviews: 760,
        priceUsd: 79,
        freeCancel: true,
        instantConfirm: false,
        privateTour: false,
        availableFrom: d(5),
        availableTo: d(180),
        weekdays: {2, 4, 6},
        slots: {TimeSlot.morning},
        highlights: const ['Boat ride', 'Local orchards', 'Coconut candy'],
      ),
      Tour(
        id: 't5',
        title: 'Hanoi Old Quarter Walk & Coffee Class',
        city: 'Ha Noi',
        district: 'Hoan Kiem',
        type: 'Culture',
        durationHours: 4,
        maxGuests: 8,
        rating: 4.8,
        reviews: 520,
        priceUsd: 45,
        freeCancel: true,
        instantConfirm: true,
        privateTour: false,
        availableFrom: d(2),
        availableTo: d(160),
        weekdays: {1, 2, 3, 4, 5},
        slots: {TimeSlot.morning, TimeSlot.afternoon},
        highlights: const ['Old Quarter', 'Egg coffee', 'Hidden lanes'],
      ),
      Tour(
        id: 't6',
        title: 'Da Nang Sunset - Bridge & Night Market',
        city: 'Da Nang',
        district: 'Son Tra',
        type: 'Night',
        durationHours: 4,
        maxGuests: 20,
        rating: 4.7,
        reviews: 410,
        priceUsd: 35,
        freeCancel: true,
        instantConfirm: true,
        privateTour: false,
        availableFrom: d(0),
        availableTo: d(365),
        weekdays: {5, 6, 7},
        slots: {TimeSlot.evening},
        highlights: const ['Dragon Bridge', 'Night market', 'Beach view'],
      ),
    ];
  }

  // ===== Filtering =====
  List<Tour> get _filteredTours {
    final q = _qCtrl.text.trim().toLowerCase();
    final rs = _dateOnly(_range.start);
    final re = _dateOnly(_range.end);

    bool matchDateWeekday(Tour t) {
      final aFrom = _dateOnly(t.availableFrom);
      final aTo = _dateOnly(t.availableTo);
      if (re.isBefore(aFrom) || rs.isAfter(aTo)) return false;

      var d = rs;
      for (var i = 0; i < 31 && !d.isAfter(re); i++) {
        final okRange = !d.isBefore(aFrom) && !d.isAfter(aTo);
        if (okRange && t.weekdays.contains(d.weekday)) return true;
        d = d.add(const Duration(days: 1));
      }
      return false;
    }

    bool matchQuery(Tour t) {
      if (q.isEmpty) return true;
      if (t.title.toLowerCase().contains(q)) return true;
      return t.highlights.any((h) => h.toLowerCase().contains(q));
    }

    bool matchLocation(Tour t) {
      if (t.city != _city) return false;
      if (_district == 'All') return true;
      return t.district == _district;
    }

    bool matchOther(Tour t) {
      if (_slot != TimeSlot.any && !t.slots.contains(_slot)) return false;
      if (_type != 'All' && t.type != _type) return false;
      if (t.priceUsd > _maxPrice) return false;
      if (_guests > t.maxGuests) return false;
      if (_needFreeCancel && !t.freeCancel) return false;
      if (_needInstantConfirm && !t.instantConfirm) return false;
      if (_onlyPrivate && !t.privateTour) return false;
      return true;
    }

    final list = _tours.where((t) {
      if (!matchLocation(t)) return false;
      if (!matchDateWeekday(t)) return false;
      if (!matchOther(t)) return false;
      if (!matchQuery(t)) return false;
      return true;
    }).toList();

    switch (_sort) {
      case 'Rating':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Price Low->High':
        list.sort((a, b) => a.priceUsd.compareTo(b.priceUsd));
        break;
      case 'Price High->Low':
        list.sort((a, b) => b.priceUsd.compareTo(a.priceUsd));
        break;
      default:
        list.sort((a, b) => b.reviews.compareTo(a.reviews));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final tours = _filteredTours;

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  _buildSearchCard(),
                  const SizedBox(height: 14),
                  _buildResultsHeader(tours.length),
                  const SizedBox(height: 10),
                  if (tours.isEmpty)
                    _buildEmpty()
                  else
                    ...tours.map(_buildTourCard),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== UI pieces =====
  Widget _buildHeader() {
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
              _iconCircle(Icons.arrow_back_rounded, () => Navigator.pop(context)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.attach_money_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text('USD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE066),
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [BoxShadow(blurRadius: 18, color: Color(0x22000000), offset: Offset(0, 8))],
            ),
            child: const Text('Tours', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.4)),
          ),
          const SizedBox(height: 10),
          Text(
            'Tìm tour theo thời gian • địa điểm • yêu cầu',
            style: TextStyle(color: Colors.white.withOpacity(0.88), fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
    final dateText = '${_fmtDate(_range.start)} - ${_fmtDate(_range.end)}';
    final locText = _district == 'All' ? _city : '$_district, $_city';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(blurRadius: 18, color: Color(0x14000000), offset: Offset(0, 8))],
      ),
      child: Column(
        children: [
          _fieldTile(Icons.place_rounded, locText, 'Địa điểm', _pickLocation),
          const SizedBox(height: 10),
          _fieldTile(Icons.date_range_rounded, dateText, 'Thời gian', _pickDateRange),
          const SizedBox(height: 10),
          _chipRow(
            Icons.schedule_rounded,
            const [
              (TimeSlot.any, 'Any'),
              (TimeSlot.morning, 'Morning'),
              (TimeSlot.afternoon, 'Afternoon'),
              (TimeSlot.evening, 'Evening'),
            ],
            selected: _slot,
            onPick: (v) => setState(() => _slot = v as TimeSlot),
          ),
          const SizedBox(height: 10),
          _chipRow(
            Icons.category_rounded,
            _types.map((e) => (e, e)).toList(),
            selected: _type,
            onPick: (v) => setState(() => _type = v as String),
          ),
          const SizedBox(height: 10),
          _priceRow(),
          const SizedBox(height: 10),
          _guestsRow(),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _togglePill('Free cancel', _needFreeCancel, Icons.free_cancellation_rounded,
                  (v) => setState(() => _needFreeCancel = v)),
              _togglePill('Instant', _needInstantConfirm, Icons.flash_on_rounded,
                  (v) => setState(() => _needInstantConfirm = v)),
              _togglePill('Private', _onlyPrivate, Icons.lock_rounded, (v) => setState(() => _onlyPrivate = v)),
            ],
          ),
          const SizedBox(height: 10),
          _keywordRow(),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(onPressed: _resetFilters, child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.w900))),
              const Spacer(),
              SizedBox(
                width: 180,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF67D4FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _onSearch,
                  child: const Text('SEARCH', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader(int count) {
    return Row(
      children: [
        Text('TOURS ($count)', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.6)),
        const Spacer(),
        InkWell(
          onTap: _pickSort,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [BoxShadow(blurRadius: 14, color: Color(0x14000000), offset: Offset(0, 6))],
            ),
            child: Row(
              children: [
                const Icon(Icons.sort_rounded, size: 18, color: Color(0xFF2B4BFF)),
                const SizedBox(width: 6),
                Text(_sort, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_down_rounded),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(blurRadius: 18, color: Color(0x14000000), offset: Offset(0, 8))],
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 40, color: Color(0xFF4C7DFF)),
          const SizedBox(height: 10),
          const Text('Không tìm thấy tour phù hợp', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('Thử đổi thời gian. địa điểm. hoặc nới điều kiện lọc nhé.',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: _resetFilters,
              child: const Text('Reset filters', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTourCard(Tour t) {
    return InkWell(
      onTap: () => _openTour(t),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(blurRadius: 18, color: Color(0x14000000), offset: Offset(0, 8))],
        ),
        child: Row(
          children: [
            Container(
              width: 86,
              height: 110,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE9F7FF), Color(0xFFB7F0E8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(_typeIcon(t.type), size: 34, color: const Color(0xFF4C7DFF)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.place_rounded, size: 16, color: Colors.black54),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text('${t.district}, ${t.city}',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 6),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _tag(t.type),
                  _tag(_durText(t.durationHours)),
                  _tag('Up to ${t.maxGuests}'),
                  if (t.freeCancel) _tag('Free cancel'),
                  if (t.instantConfirm) _tag('Instant'),
                  if (t.privateTour) _tag('Private'),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFFC107)),
                  const SizedBox(width: 4),
                  Text('${t.rating.toStringAsFixed(1)} (${t.reviews})', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  const Spacer(),
                  Text(_money(t.priceUsd), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      onPressed: () => _openTour(t),
                      child: const Text('Details', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4C7DFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _bookTour(t),
                      child: const Text('Book', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ]),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Pickers & actions =====
  Future<void> _pickLocation() async {
    final res = await showModalBottomSheet<_LocResult>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) {
        String city = _city;
        String district = _district;

        return StatefulBuilder(builder: (ctx, setM) {
          final districts = _districtsByCity[city] ?? const ['All'];
          if (!districts.contains(district)) district = 'All';

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Chọn địa điểm', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _cities.map((c) => _pill(c, c == city, () => setM(() => city = c))).toList(),
                ),
                const SizedBox(height: 14),
                const Text('Khu vực', style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: districts.map((d) => _pill(d, d == district, () => setM(() => district = d))).toList(),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF67D4FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(ctx, _LocResult(city: city, district: district)),
                    child: const Text('APPLY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                  ),
                ),
              ]),
            ),
          );
        });
      },
    );

    if (res == null) return;
    setState(() {
      _city = res.city;
      _district = res.district;
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _range,
    );
    if (picked == null) return;
    setState(() => _range = picked);
  }

  Future<void> _pickSort() async {
    final options = const ['Popular', 'Rating', 'Price Low->High', 'Price High->Low'];
    final v = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Sắp xếp', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 10),
            ...options.map((e) => ListTile(
                  title: Text(e, style: const TextStyle(fontWeight: FontWeight.w800)),
                  trailing: e == _sort ? const Icon(Icons.check_rounded, color: Color(0xFF4C7DFF)) : null,
                  onTap: () => Navigator.pop(ctx, e),
                )),
          ]),
        ),
      ),
    );

    if (v != null) setState(() => _sort = v);
  }

  void _onSearch() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Search: $_city • $_district • ${_fmtDate(_range.start)}-${_fmtDate(_range.end)}')),
    );
    setState(() {});
  }

  void _resetFilters() {
    final start = DateTime.now().add(const Duration(days: 1));
    setState(() {
      _city = 'Ho Chi Minh City';
      _district = 'All';
      _range = DateTimeRange(start: start, end: start.add(const Duration(days: 2)));
      _slot = TimeSlot.any;
      _type = 'All';
      _maxPrice = 180;
      _guests = 2;
      _needFreeCancel = false;
      _needInstantConfirm = false;
      _onlyPrivate = false;
      _sort = 'Popular';
      _qCtrl.clear();
    });
  }

  void _openTour(Tour t) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 6),
            Text('${t.district}, ${t.city}', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            const Text('Highlights', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            ...t.highlights.map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF4C7DFF)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(h, style: const TextStyle(fontWeight: FontWeight.w700))),
                  ]),
                )),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C7DFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _bookTour(t);
                },
                child: Text('BOOK • ${_money(t.priceUsd)}', style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _bookTour(Tour t) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Book: ${t.title} • ${_money(t.priceUsd)} (demo)')),
    );
  }

  // ===== small widgets =====
  Widget _iconCircle(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(999)),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _fieldTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: const Color(0xFFF3FAFF), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(icon, color: const Color(0xFF4C7DFF)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700, fontSize: 12.5)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _pill(String text, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFB7F0E8) : const Color(0xFFF3FAFF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _chipRow(IconData icon, List<(Object, String)> items, {required Object selected, required ValueChanged<Object> onPick}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFFF3FAFF), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Icon(icon, color: const Color(0xFF4C7DFF)),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items.map((e) => _pill(e.$2, e.$1 == selected, () => onPick(e.$1))).toList(),
          ),
        ),
      ]),
    );
  }

  Widget _priceRow() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      decoration: BoxDecoration(color: const Color(0xFFF3FAFF), borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Row(children: [
          const Icon(Icons.payments_rounded, color: Color(0xFF4C7DFF)),
          const SizedBox(width: 10),
          const Expanded(child: Text('Giá tối đa', style: TextStyle(fontWeight: FontWeight.w900))),
          Text(_money(_maxPrice), style: const TextStyle(fontWeight: FontWeight.w900)),
        ]),
        Slider(
          value: _maxPrice.clamp(20, 300),
          min: 20,
          max: 300,
          divisions: 28,
          onChanged: (v) => setState(() => _maxPrice = v),
        ),
      ]),
    );
  }

  Widget _guestsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFF3FAFF), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        const Icon(Icons.group_rounded, color: Color(0xFF4C7DFF)),
        const SizedBox(width: 10),
        Expanded(child: Text('$_guests guests', style: const TextStyle(fontWeight: FontWeight.w900))),
        _stepBtn(Icons.remove_rounded, () => setState(() => _guests = (_guests - 1).clamp(1, 30))),
        const SizedBox(width: 8),
        _stepBtn(Icons.add_rounded, () => setState(() => _guests = (_guests + 1).clamp(1, 30))),
      ]),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
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

  Widget _togglePill(String text, bool on, IconData icon, ValueChanged<bool> setOn) {
    return InkWell(
      onTap: () => setOn(!on),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: on ? const Color(0xFFB7F0E8) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [BoxShadow(blurRadius: 14, color: Color(0x14000000), offset: Offset(0, 6))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: const Color(0xFF2B4BFF)),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }

  Widget _keywordRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFF3FAFF), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        const Icon(Icons.search_rounded, color: Color(0xFF4C7DFF)),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _qCtrl,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Từ khóa (vd: food, market, museum...)',
              hintStyle: TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFF3FAFF), borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }

  // ===== helpers =====
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  String _two(int n) => n.toString().padLeft(2, '0');
  String _fmtDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}';
  String _money(double v) => '${r"$"}${v.toStringAsFixed(0)}';

  String _durText(int hours) {
    if (hours < 8) return '$hours h';
    if (hours == 8) return '1 day';
    final days = (hours / 24).ceil();
    return '$days day';
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Food':
        return Icons.restaurant_rounded;
      case 'Culture':
        return Icons.museum_rounded;
      case 'Nature':
        return Icons.park_rounded;
      case 'Night':
        return Icons.nightlife_rounded;
      default:
        return Icons.location_city_rounded;
    }
  }
}
