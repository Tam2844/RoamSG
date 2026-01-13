import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'user_tour_booking_page.dart';

// Nếu chủ nhân muốn bấm "Book" nhảy qua trang nào đó thì import ở đây.
// import 'user_guide_booking_page.dart';

class UserTourDetailPage extends StatelessWidget {
  final String tourId;
  const UserTourDetailPage({super.key, required this.tourId});
  
  @override
  Widget build(BuildContext context) {
    final tourRef = FirebaseFirestore.instance.collection('tours').doc(tourId);

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF0F172A),
        title: const Text(
          "Tour detail",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: tourRef.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return _CenterMessage("Lỗi tải tour: ${snap.error}");
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final doc = snap.data!;
          final data = doc.data();
          if (data == null) {
            return const _CenterMessage("Tour không tồn tại hoặc đã bị xoá.");
          }

          final title = (data['title'] ?? 'Tour').toString();
          final city = (data['city'] ?? '').toString();
          final description = (data['description'] ?? '').toString();
          final imageUrl = (data['imageUrl'] ?? '').toString();

          final days = _asInt(data['days']);
          final price = _asInt(data['price']);
          final maxPeople = _asInt(data['maxPeople']);

          final startDate = (data['startDate'] as Timestamp?)?.toDate();
          final endDate = (data['endDate'] as Timestamp?)?.toDate();

          final guideId = (data['guideId'] ?? '').toString();

          final tags = (data['tags'] is List)
              ? (data['tags'] as List).map((e) => e.toString()).toList()
              : <String>[];

          final languages = (data['languages'] is List)
              ? (data['languages'] as List).map((e) => e.toString()).toList()
              : <String>[];

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              _HeroImage(imageUrl: imageUrl),
              const SizedBox(height: 12),

              Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),

              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 18, color: Color(0xFF4C7DFF)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      city.isEmpty ? "—" : city,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black54),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _InfoGrid(
                days: days,
                price: price,
                maxPeople: maxPeople,
                startDate: startDate,
                endDate: endDate,
              ),

              const SizedBox(height: 12),

              if (tags.isNotEmpty) ...[
                const _BlockTitle("Tags"),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((t) => _Chip(text: t)).toList(),
                ),
                const SizedBox(height: 12),
              ],

              if (languages.isNotEmpty) ...[
                const _BlockTitle("Languages"),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: languages.map((l) => _Chip(text: l.toUpperCase())).toList(),
                ),
                const SizedBox(height: 12),
              ],

              const _BlockTitle("Description"),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(blurRadius: 18, color: Color(0x14000000), offset: Offset(0, 8)),
                  ],
                ),
                child: Text(
                  description.isEmpty ? "Chưa có mô tả." : description,
                  style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35),
                ),
              ),

              const SizedBox(height: 14),

              // ===== Guide info =====
              const _BlockTitle("Your guide"),
              const SizedBox(height: 8),
              _GuideCardByGuideId(guideId: guideId),

              const SizedBox(height: 14),

              // ===== CTA =====
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C7DFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    final ok = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => UserTourBookingPage(tourId: doc.id)),
                    );

                    if (ok == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Đã gửi yêu cầu đặt tour.")),
                      );
                    }
                  },

                  child: Text(
                    "Book this tour • ${_money(price)}",
                    style: const TextStyle(fontWeight: FontWeight.w900),
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

// ===== Guide section: load theo guideId trong tour =====
class _GuideCardByGuideId extends StatelessWidget {
  final String guideId;
  const _GuideCardByGuideId({required this.guideId});

  @override
  Widget build(BuildContext context) {
    if (guideId.isEmpty) {
      return const _CenterMessage("Tour chưa có guideId.");
    }

    // guideId trong tour đang là userId => trong guides schema của chủ nhân có field userId
    final q = FirebaseFirestore.instance
        .collection('guides')
        .where('userId', isEqualTo: guideId)
        .limit(1);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return _SmallCard(text: "Lỗi tải guide: ${snap.error}");
        }
        if (!snap.hasData) {
          return const _SmallCard(loading: true);
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const _SmallCard(text: "Không tìm thấy guide tương ứng (guides.userId).");
        }

        final data = docs.first.data();

        final fullName = (data['fullName'] ?? 'Guide').toString();
        final bio = (data['bio'] ?? '').toString();
        final phone = (data['phone'] ?? '').toString();
        final email = (data['email'] ?? '').toString();
        final exp = _asInt(data['experienceYears']);
        final pricePerHour = _asInt(data['pricePerHour']);

        final areas = (data['areas'] is List)
            ? (data['areas'] as List).map((e) => e.toString()).toList()
            : <String>[];

        final languages = (data['languages'] is List)
            ? (data['languages'] as List).map((e) => e.toString()).toList()
            : <String>[];

        final isActive = (data['isActive'] ?? true) == true;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(blurRadius: 18, color: Color(0x14000000), offset: Offset(0, 8)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F7FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.person, color: Color(0xFF4C7DFF), size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFFB7F0E8) : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            isActive ? "Active" : "Inactive",
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bio.isEmpty ? "Local guide" : bio,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (exp > 0) _MiniPill(text: "$exp years exp"),
                        if (pricePerHour > 0) _MiniPill(text: "${_money(pricePerHour)}/h"),
                        if (areas.isNotEmpty) _MiniPill(text: "Areas: ${areas.take(2).join(", ")}"),
                        if (languages.isNotEmpty) _MiniPill(text: "Lang: ${languages.take(3).join(", ")}"),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (phone.isNotEmpty || email.isNotEmpty)
                      Row(
                        children: [
                          if (phone.isNotEmpty) ...[
                            const Icon(Icons.phone, size: 16, color: Colors.black54),
                            const SizedBox(width: 6),
                            Text(phone, style: const TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(width: 12),
                          ],
                          if (email.isNotEmpty) ...[
                            const Icon(Icons.email, size: 16, color: Colors.black54),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(email, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black54)),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ===== UI helpers =====

class _HeroImage extends StatelessWidget {
  final String imageUrl;
  const _HeroImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: imageUrl.isEmpty
            ? Container(
                color: const Color(0xFFE9F7FF),
                child: const Center(
                  child: Icon(Icons.image, size: 46, color: Color(0xFF4C7DFF)),
                ),
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFE9F7FF),
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 46, color: Color(0xFF4C7DFF)),
                  ),
                ),
              ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final int days;
  final int price;
  final int maxPeople;
  final DateTime? startDate;
  final DateTime? endDate;

  const _InfoGrid({
    required this.days,
    required this.price,
    required this.maxPeople,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _InfoTile(label: "Days", value: days > 0 ? "$days" : "—", icon: Icons.calendar_month_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _InfoTile(label: "Max people", value: maxPeople > 0 ? "$maxPeople" : "—", icon: Icons.groups_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _InfoTile(label: "Price", value: _money(price), icon: Icons.payments_rounded)),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(blurRadius: 18, color: Color(0x14000000), offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF4C7DFF)),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _BlockTitle extends StatelessWidget {
  final String text;
  const _BlockTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14));
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F7FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF4C7DFF))),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String text;
  const _MiniPill({required this.text});

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

class _SmallCard extends StatelessWidget {
  final String? text;
  final bool loading;

  const _SmallCard({this.text, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(blurRadius: 18, color: Color(0x14000000), offset: Offset(0, 8))],
      ),
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : Text(text ?? "", style: const TextStyle(fontWeight: FontWeight.w700)),
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

// ===== Helpers =====

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
