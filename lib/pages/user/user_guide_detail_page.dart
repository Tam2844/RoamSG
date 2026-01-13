import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserGuideDetailPage extends StatelessWidget {
  /// guideKey có thể là:
  /// - docId của guides/{docId}
  /// - hoặc userId (field guides.userId)
  final String guideKey;

  const UserGuideDetailPage({super.key, required this.guideKey});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF0F172A),
        title: const Text("Guide detail", style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: _GuideResolver(guideKey: guideKey),
    );
  }
}

/// Resolve guide theo:
/// 1) docId = guideKey
/// 2) nếu doc rỗng -> query guides where userId == guideKey
class _GuideResolver extends StatelessWidget {
  final String guideKey;
  const _GuideResolver({required this.guideKey});

  @override
  Widget build(BuildContext context) {
    if (guideKey.isEmpty) {
      return const _CenterMessage("Thiếu guide id.");
    }

    final docRef = FirebaseFirestore.instance.collection('guides').doc(guideKey);

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: docRef.get(),
      builder: (context, docSnap) {
        if (docSnap.hasError) {
          return _CenterMessage("Lỗi tải guide: ${docSnap.error}");
        }
        if (!docSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final doc = docSnap.data!;
        final data = doc.data();
        if (data != null) {
          return _GuideDetailBody(guideDocId: doc.id, data: data);
        }
        final q = FirebaseFirestore.instance
            .collection('guides')
            .where('userId', isEqualTo: guideKey)
            .limit(1);

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: q.snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return _CenterMessage("Lỗi query guide: ${snap.error}");
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return const _CenterMessage("Không tìm thấy guide.");
            }

            return _GuideDetailBody(guideDocId: docs.first.id, data: docs.first.data());
          },
        );
      },
    );
  }
}

class _GuideDetailBody extends StatelessWidget {
  final String guideDocId;
  final Map<String, dynamic> data;

  const _GuideDetailBody({
    required this.guideDocId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final fullName = (data['fullName'] ?? 'Guide').toString();
    final bio = (data['bio'] ?? '').toString();
    final phone = (data['phone'] ?? '').toString();
    final email = (data['email'] ?? '').toString();
    final isActive = (data['isActive'] ?? true) == true;
    final exp = _asInt(data['experienceYears']);
    final pricePerHour = _asInt(data['pricePerHour']);

    final areas = (data['areas'] is List)
        ? (data['areas'] as List).map((e) => e.toString()).toList()
        : <String>[];

    final languages = (data['languages'] is List)
        ? (data['languages'] as List).map((e) => e.toString()).toList()
        : <String>[];

    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        _GuideHeader(
          name: fullName,
          email: email,
          isActive: isActive,
          expYears: exp,
        ),
        const SizedBox(height: 14),

        _InfoCard(
          title: "About",
          children: [
            Text(
              bio.isEmpty ? "Chưa có giới thiệu." : bio,
              style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35),
            ),
          ],
        ),
        const SizedBox(height: 14),

        _InfoCard(
          title: "Details",
          children: [
            _InfoRow(
              icon: Icons.payments_rounded,
              label: "Price per hour",
              value: pricePerHour > 0 ? "${_money(pricePerHour)}/h" : "—",
            ),
            const Divider(height: 18),
            _InfoRow(
              icon: Icons.work_history_rounded,
              label: "Experience",
              value: exp > 0 ? "$exp year(s)" : "—",
            ),
            const Divider(height: 18),
            _InfoRow(
              icon: Icons.place_rounded,
              label: "Areas",
              value: areas.isEmpty ? "—" : areas.join(", "),
            ),
            const Divider(height: 18),
            _InfoRow(
              icon: Icons.language_rounded,
              label: "Languages",
              value: languages.isEmpty ? "—" : languages.map((e) => e.toUpperCase()).join(", "),
            ),
          ],
        ),

        const SizedBox(height: 14),

        _InfoCard(
          title: "Contact",
          children: [
            _InfoRow(
              icon: Icons.phone_rounded,
              label: "Phone",
              value: phone.isEmpty ? "—" : phone,
            ),
            const Divider(height: 18),
            _InfoRow(
              icon: Icons.email_rounded,
              label: "Email",
              value: email.isEmpty ? "—" : email,
            ),
          ],
        ),

        const SizedBox(height: 14),

        if (createdAt != null || updatedAt != null)
          _InfoCard(
            title: "Meta",
            children: [
              if (createdAt != null)
                _InfoRow(
                  icon: Icons.event_available_rounded,
                  label: "Created",
                  value: _fmtDate(createdAt),
                ),
              if (createdAt != null && updatedAt != null) const Divider(height: 18),
              if (updatedAt != null)
                _InfoRow(
                  icon: Icons.update_rounded,
                  label: "Updated",
                  value: _fmtDate(updatedAt),
                ),
            ],
          ),
      ],
    );
  }
}

// ===== UI =====

class _GuideHeader extends StatelessWidget {
  final String name;
  final String email;
  final bool isActive;
  final int expYears;

  const _GuideHeader({
    required this.name,
    required this.email,
    required this.isActive,
    required this.expYears,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF9FE6FF), Color(0xFF6BBEFF)], // ✅ nhạt hơn
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(blurRadius: 18, color: Color(0x16000000), offset: Offset(0, 10)),
      ],
    ),

      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 34),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Badge(
                      text: isActive ? "Active" : "Inactive",
                      bg: isActive ? const Color(0xFFB7F0E8) : const Color(0xFFFEE2E2),
                    ),
                    if (expYears > 0)
                      const _Badge(text: "Experience"),
                    if (expYears > 0)
                      _Badge(text: "$expYears yrs", bg: const Color(0xFFFFE066)),
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

class _Badge extends StatelessWidget {
  final String text;
  final Color bg;

  const _Badge({required this.text, this.bg = const Color(0xFFFFE066)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(blurRadius: 18, color: Color(0x14000000), offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

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

String _fmtDate(DateTime dt) {
  final d = dt.day.toString().padLeft(2, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final y = dt.year.toString();
  return "$d/$m/$y";
}
