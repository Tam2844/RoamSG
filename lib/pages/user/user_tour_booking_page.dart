import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UserTourBookingPage extends StatefulWidget {
  final String tourId;
  const UserTourBookingPage({super.key, required this.tourId});

  @override
  State<UserTourBookingPage> createState() => _UserTourBookingPageState();
}

class _UserTourBookingPageState extends State<UserTourBookingPage> {
  final _formKey = GlobalKey<FormState>();

  final _participantsCtrl = TextEditingController(text: "1");
  final _pickupCtrl = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  bool _saving = false;

  @override
  void dispose() {
    _participantsCtrl.dispose();
    _pickupCtrl.dispose();
    super.dispose();
  }

  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is num) return v.toInt();
    return int.tryParse((v ?? '0').toString()) ?? 0;
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

  String _fmtDate(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

  DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _pickStartDate(DateTime initial) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? initial,
      firstDate: _startOfToday(),
      lastDate: DateTime(_startOfToday().year + 2),
    );

    if (picked == null) return;

    setState(() {
      _startDate = picked;
      if (_endDate != null && _endDate!.isBefore(picked)) {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickEndDate(DateTime initial) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final base = _startDate ?? initial;
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? base,
      firstDate: base,
      lastDate: DateTime(_startOfToday().year + 2),
    );

    if (picked == null) return;

    setState(() => _endDate = picked);
  }

  Future<void> _submitBooking({
    required Map<String, dynamic> tour,
    required String tourId,
  }) async {
    if (_saving) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bạn chưa đăng nhập.")),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final participants = int.tryParse(_participantsCtrl.text.trim()) ?? 0;
    final pickupPoint = _pickupCtrl.text.trim();

    final price = _asInt(tour['price']);
    final guideId = (tour['guideId'] ?? '').toString();

    // Nếu tour có startDate/endDate cố định, dùng làm default
    final tourStart = (tour['startDate'] as Timestamp?)?.toDate();
    final tourEnd = (tour['endDate'] as Timestamp?)?.toDate();

    final start = _startDate ?? tourStart ?? _startOfToday();
    final end = _endDate ?? tourEnd ?? start;

    if (end.isBefore(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("End date phải >= Start date.")),
      );
      return;
    }

    final totalPrice = price * participants;

    setState(() => _saving = true);

    try {
      final ref = FirebaseFirestore.instance.collection('tour_bookings').doc(); // auto id

      await ref.set({
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
        "tourId": tourId,
        "userId": user.uid,
        "guideId": guideId,
        "participants": participants,
        "pickupPoint": pickupPoint,
        "startDate": Timestamp.fromDate(start),
        "endDate": Timestamp.fromDate(end),
        "totalPrice": totalPrice,
        "status": "waiting", // ✅ mặc định
        "seedTag": "app_booking_v1", // optional (có thể xoá nếu không cần)
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã gửi yêu cầu đặt tour (waiting).")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi đặt tour: $e")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tourRef = FirebaseFirestore.instance.collection('tours').doc(widget.tourId);

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF0F172A),
        title: const Text("Book tour", style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: tourRef.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text("Lỗi tải tour: ${snap.error}"));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data!.data();
          if (data == null) {
            return const Center(child: Text("Tour không tồn tại."));
          }

          final title = (data['title'] ?? 'Tour').toString();
          final city = (data['city'] ?? '').toString();
          final price = _asInt(data['price']);
          final maxPeople = _asInt(data['maxPeople']);

          final tourStart = (data['startDate'] as Timestamp?)?.toDate();
          final tourEnd = (data['endDate'] as Timestamp?)?.toDate();
          final initialDate = tourStart ?? _startOfToday();

          final participants = int.tryParse(_participantsCtrl.text.trim()) ?? 1;
          final totalPrice = price * (participants <= 0 ? 1 : participants);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              // Info card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [BoxShadow(blurRadius: 18, color: Color(0x14000000), offset: Offset(0, 8))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 18, color: Color(0xFF4C7DFF)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            city.isEmpty ? "—" : city,
                            style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Pill(text: "Price: ${_money(price)}"),
                        if (maxPeople > 0) _Pill(text: "Max: $maxPeople"),
                        _Pill(text: "Total: ${_money(totalPrice)}"),
                        const _Pill(text: "Status: waiting"),
                      ],
                    ),
                    if (tourStart != null || tourEnd != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        "Tour dates: "
                        "${tourStart != null ? _fmtDate(tourStart) : "—"}"
                        " → "
                        "${tourEnd != null ? _fmtDate(tourEnd) : "—"}",
                        style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Form card
              Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [BoxShadow(blurRadius: 18, color: Color(0x14000000), offset: Offset(0, 8))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Your info", style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _participantsCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: "Participants",
                          isDense: true,
                        ),
                        validator: (v) {
                          final n = int.tryParse((v ?? '').trim()) ?? 0;
                          if (n <= 0) return "Participants phải >= 1";
                          if (maxPeople > 0 && n > maxPeople) return "Tối đa $maxPeople người";
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _pickupCtrl,
                        decoration: const InputDecoration(
                          labelText: "Pickup point",
                          hintText: "e.g. Hotel Lobby",
                          isDense: true,
                        ),
                        validator: (v) {
                          if ((v ?? '').trim().isEmpty) return "Vui lòng nhập pickup point";
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: _DateField(
                              label: "Start date",
                              value: _startDate,
                              fallback: tourStart,
                              onTap: () => _pickStartDate(initialDate),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DateField(
                              label: "End date",
                              value: _endDate,
                              fallback: tourEnd,
                              onTap: () => _pickEndDate(initialDate),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4C7DFF),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _saving
                              ? null
                              : () => _submitBooking(tour: data, tourId: widget.tourId),
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text("Submit booking", style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ===== Small UI widgets =====

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateTime? fallback;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.fallback,
    required this.onTap,
  });

  String _fmt(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

  @override
  Widget build(BuildContext context) {
    final display = value ?? fallback;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF6FAFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDAE6FF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF4C7DFF)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    display == null ? "—" : _fmt(display),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
