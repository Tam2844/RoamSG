import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserBookingHistoryPage extends StatelessWidget {
  const UserBookingHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF0F172A),
        title: const Text("Booking history", style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: user == null
          ? const _CenterMessage("Bạn chưa đăng nhập.")
          : _TourBookingsList(userId: user.uid),
    );
  }
}

class _TourBookingsList extends StatelessWidget {
  final String userId;
  const _TourBookingsList({required this.userId});

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('tour_bookings')
        .where('userId', isEqualTo: userId)
        .snapshots(includeMetadataChanges: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) return _CenterMessage("Lỗi tour_bookings: ${snap.error}");
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());

        final qs = snap.data!;
        final docs = qs.docs.toList();

        docs.sort((a, b) {
          final at = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bt = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bt.compareTo(at);
        });

        if (docs.isEmpty) return const _CenterMessage("Chưa có booking tour nào.");

        final fromCache = qs.metadata.isFromCache;

        return Column(
          children: [
            if (fromCache)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 18, color: Color(0xFF9A3412)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Đang hiển thị dữ liệu từ cache (offline). Status có thể chưa cập nhật theo Firestore Console.",
                        style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF9A3412)),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final d = doc.data();

                  final tourId = (d['tourId'] ?? '').toString();
                  final start = (d['startDate'] as Timestamp?)?.toDate();
                  final end = (d['endDate'] as Timestamp?)?.toDate();
                  final participants = _asInt(d['participants']);
                  final pickup = (d['pickupPoint'] ?? '').toString();
                  final total = _asInt(d['totalPrice']);
                  final createdAt = (d['createdAt'] as Timestamp?)?.toDate();

                  final status = _readStatus(d);

                  return _BookingCard(
                    tourId: tourId,
                    start: start,
                    end: end,
                    participants: participants,
                    pickupPoint: pickup,
                    totalPrice: total,
                    createdAt: createdAt,
                    status: status,
                    onTap: () => _openDetail(context, doc.id, d),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _openDetail(BuildContext context, String docId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _BookingDetailSheet(docId: docId, data: data),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final String tourId;
  final DateTime? start;
  final DateTime? end;
  final int participants;
  final String pickupPoint;
  final int totalPrice;
  final DateTime? createdAt;
  final String status; // accepted|waiting|rejected
  final VoidCallback onTap;

  const _BookingCard({
    required this.tourId,
    required this.start,
    required this.end,
    required this.participants,
    required this.pickupPoint,
    required this.totalPrice,
    required this.createdAt,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusUI = _statusUI(status);
    final created = createdAt != null ? _fmtDateTime(createdAt!) : "—";

    final dateLine = (start != null && end != null)
        ? "${_fmtDate(start!)} → ${_fmtDate(end!)}"
        : (start != null ? "Start: ${_fmtDate(start!)}" : "Start: —");

    final line2 = "${participants > 0 ? participants : "—"} participant(s) · "
        "${pickupPoint.isEmpty ? "Pickup: —" : "Pickup: $pickupPoint"}";

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(blurRadius: 18, color: Color(0x14000000), offset: Offset(0, 8))],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF5FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.map_rounded, color: Color(0xFF4C7DFF)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Tour booking",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      if (totalPrice > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(_money(totalPrice), style: const TextStyle(fontWeight: FontWeight.w900)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusUI.bg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          statusUI.label,
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: statusUI.fg),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tourId.isEmpty ? "Tour: —" : "Tour: $tourId",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(dateLine, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(line2, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text("Created: $created", style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

/// ===== BottomSheet (đã bỏ Meta + Guide hiển thị tên) =====
class _BookingDetailSheet extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const _BookingDetailSheet({required this.docId, required this.data});

  @override
  Widget build(BuildContext context) {
    final status = _readStatus(data);
    final statusUI = _statusUI(status);

    final tourId = (data['tourId'] ?? '').toString();
    final guideId = (data['guideId'] ?? '').toString(); // uid của guide (match guides.userId)
    final pickup = (data['pickupPoint'] ?? '').toString();
    final participants = _asInt(data['participants']);
    final total = _asInt(data['totalPrice']);

    final start = (data['startDate'] as Timestamp?)?.toDate();
    final end = (data['endDate'] as Timestamp?)?.toDate();
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text("Booking detail", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              _DetailCard(
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF5FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.map_rounded, color: Color(0xFF4C7DFF)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text("Tour booking", style: TextStyle(fontWeight: FontWeight.w900)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusUI.bg,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  statusUI.label,
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: statusUI.fg),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tourId.isEmpty ? "Tour: —" : "Tour: $tourId",
                            style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            total > 0 ? _money(total) : "—",
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              _DetailCard(
                title: "Thông tin",
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.calendar_month_rounded,
                      label: "Thời gian",
                      value: (start != null && end != null)
                          ? "${_fmtDate(start)} → ${_fmtDate(end)}"
                          : (start != null ? "Start: ${_fmtDate(start)}" : "—"),
                    ),
                    const Divider(height: 18),
                    _DetailRow(
                      icon: Icons.groups_rounded,
                      label: "Số người",
                      value: participants > 0 ? "$participants" : "—",
                    ),
                    const Divider(height: 18),
                    _DetailRow(
                      icon: Icons.place_rounded,
                      label: "Điểm đón",
                      value: pickup.isNotEmpty ? pickup : "—",
                    ),
                    const Divider(height: 18),

                    /// ✅ Guide hiển thị tên (không hiện uid nữa)
                    _GuideNameRow(guideUserId: guideId),

                    const Divider(height: 18),

                    /// ✅ vẫn cho user thấy thời điểm tạo đơn (nhưng không tách Meta nữa)
                    _DetailRow(
                      icon: Icons.access_time_rounded,
                      label: "Tạo lúc",
                      value: createdAt != null ? _fmtDateTime(createdAt) : "—",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                height: 46,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C7DFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Đóng", style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Row riêng cho Guide: load tên từ guides (userId == guideUserId)
class _GuideNameRow extends StatelessWidget {
  final String guideUserId;
  const _GuideNameRow({required this.guideUserId});

  @override
  Widget build(BuildContext context) {
    if (guideUserId.trim().isEmpty) {
      return const _DetailRow(
        icon: Icons.person_rounded,
        label: "Guide",
        value: "—",
      );
    }

    final q = FirebaseFirestore.instance
        .collection('guides')
        .where('userId', isEqualTo: guideUserId)
        .limit(1)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q,
      builder: (context, snap) {
        if (snap.hasError) {
          return const _DetailRow(icon: Icons.person_rounded, label: "Guide", value: "—");
        }

        if (!snap.hasData) {
          return const _DetailRow(icon: Icons.person_rounded, label: "Guide", value: "Đang tải...");
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          // không tìm thấy guide trong collection guides
          return const _DetailRow(icon: Icons.person_rounded, label: "Guide", value: "—");
        }

        final g = docs.first.data();
        final name = (g['fullName'] ?? g['name'] ?? '—').toString().trim();
        return _DetailRow(icon: Icons.person_rounded, label: "Guide", value: name.isEmpty ? "—" : name);
      },
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String? title;
  final Widget child;
  const _DetailCard({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(blurRadius: 18, color: Color(0x14000000), offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF4C7DFF)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ],
    );
  }
}

class _CenterMessage extends StatelessWidget {
  final String text;
  const _CenterMessage(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// ===== Status helpers =====
String _readStatus(Map<String, dynamic> d) {
  final raw = (d['status'] ?? d['Status'] ?? '').toString().trim().toLowerCase();

  if (raw == 'accepted' || raw == 'accept' || raw == 'approved' || raw == 'approve' || raw == 'ok' || raw == 'done') {
    return 'accepted';
  }
  if (raw == 'aceppted' || raw == 'accecpted' || raw == 'accpeted') return 'accepted';

  if (raw == 'rejected' || raw == 'reject' || raw == 'denied' || raw == 'cancel' || raw == 'canceled') {
    return 'rejected';
  }
  if (raw == 'waiting' || raw == 'pending' || raw == 'wait') return 'waiting';

  if (d.containsKey('isAccept')) {
    final v = d['isAccept'];
    if (v == true) return 'accepted';
    return 'waiting';
  }
  return 'waiting';
}

_StatusUI _statusUI(String status) {
  final s = status.trim().toLowerCase();
  switch (s) {
    case 'accepted':
      return const _StatusUI(label: "ACCEPTED", bg: Color(0xFFDCFCE7), fg: Color(0xFF166534));
    case 'rejected':
      return const _StatusUI(label: "REJECTED", bg: Color(0xFFFEE2E2), fg: Color(0xFF991B1B));
    default:
      return const _StatusUI(label: "WAITING", bg: Color(0xFFFFF3C4), fg: Color(0xFF92400E));
  }
}

class _StatusUI {
  final String label;
  final Color bg;
  final Color fg;
  const _StatusUI({required this.label, required this.bg, required this.fg});
}

/// ===== helpers =====
int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is num) return v.toInt();
  return int.tryParse((v ?? '0').toString()) ?? 0;
}

String _money(int vnd) {
  if (vnd <= 0) return "—";
  final s = vnd.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final left = s.length - i;
    buf.write(s[i]);
    if (left > 1 && left % 3 == 1) buf.write('.');
  }
  return "${buf.toString()}đ";
}

String _fmtDate(DateTime dt) {
  final d = dt.day.toString().padLeft(2, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final y = dt.year.toString();
  return "$d/$m/$y";
}

String _fmtDateTime(DateTime dt) {
  final d = dt.day.toString().padLeft(2, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final y = dt.year.toString();
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return "$d/$m/$y $hh:$mm";
}
