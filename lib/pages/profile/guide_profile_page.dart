import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const Color kBg = Color(0xFFF5F8FA);
const Color kPrimary = Color(0xFF79D5FF);

class GuideProfilePage extends StatefulWidget {
  const GuideProfilePage({super.key});

  @override
  State<GuideProfilePage> createState() => _GuideProfilePageState();
}

class _GuideProfilePageState extends State<GuideProfilePage> {
  String _fmtMoney(num v) => NumberFormat.decimalPattern('vi').format(v);

  List<String> _strList(dynamic v) {
    if (v is List) {
      return v.map((e) => (e ?? '').toString()).where((s) => s.trim().isNotEmpty).toList();
    }
    return const [];
  }

  String _fmtTime(dynamic ts) {
    if (ts is Timestamp) {
      return DateFormat('HH:mm dd/MM/yyyy').format(ts.toDate());
    }
    return '-';
  }

  // Hiển thị tên ngôn ngữ tiếng Việt
  String _langName(String code) {
    final c = code.trim().toLowerCase();
    const map = {
      'vi': 'Tiếng Việt',
      'en': 'Tiếng Anh',
      'zh': 'Tiếng Trung',
      'ja': 'Tiếng Nhật',
      'ko': 'Tiếng Hàn',
    };
    return map[c] ?? code;
  }

  int _parseIntLoose(String s) {
    final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  final _langs = const <_LangItem>[
    _LangItem(code: 'vi', name: 'Tiếng Việt'),
    _LangItem(code: 'en', name: 'Tiếng Anh'),
    _LangItem(code: 'zh', name: 'Tiếng Trung'),
    _LangItem(code: 'ja', name: 'Tiếng Nhật'),
    _LangItem(code: 'ko', name: 'Tiếng Hàn'),
  ];

  Future<void> _openEditSheet({
    required BuildContext context,
    required bool hasGuide,
    required Map<String, dynamic> data,
    required DocumentReference<Map<String, dynamic>>? docRef,
    required User authUser,
  }) async {
    final baseName = authUser.displayName ?? '';
    final baseEmail = authUser.email ?? '';

    // initial values
    final fullNameCtrl = TextEditingController(text: (data['fullName'] ?? baseName).toString());
    final phoneCtrl = TextEditingController(text: (data['phone'] ?? '').toString());
    final bioCtrl = TextEditingController(text: (data['bio'] ?? '').toString());

    final expCtrl = TextEditingController(text: (data['experienceYears'] ?? 0).toString());
    final priceCtrl = TextEditingController(text: (data['pricePerHour'] ?? 0).toString());

    bool isActive = (data['isActive'] ?? false) == true;

    final areas = _strList(data['areas']).toList();
    final langSet = _strList(data['languages']).map((e) => e.toLowerCase().trim()).toSet();

    final areaAddCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> save() async {
              if (!formKey.currentState!.validate()) return;

              final fullName = fullNameCtrl.text.trim();
              final phone = phoneCtrl.text.trim();
              final bio = bioCtrl.text.trim();

              final experienceYears = _parseIntLoose(expCtrl.text);
              final pricePerHour = _parseIntLoose(priceCtrl.text);

              final payload = <String, dynamic>{
                'userId': authUser.uid,
                'fullName': fullName,
                'email': baseEmail,
                'phone': phone,
                'bio': bio,
                'experienceYears': experienceYears,
                'pricePerHour': pricePerHour,
                'isActive': isActive,
                'areas': areas,
                'languages': langSet.toList(),
                'updatedAt': FieldValue.serverTimestamp(),
              };

              try {
                // Update nếu đã có doc, còn không thì create doc mới
                if (hasGuide && docRef != null) {
                  await docRef.update(payload);
                } else {
                  payload['createdAt'] = FieldValue.serverTimestamp();
                  await FirebaseFirestore.instance.collection('guides').add(payload);
                }

                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã lưu hồ sơ Guide thành công.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lưu thất bại: $e')),
                  );
                }
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 14,
                  bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                hasGuide ? 'Chỉnh sửa hồ sơ Guide' : 'Tạo hồ sơ Guide',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Full name
                        TextFormField(
                          controller: fullNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Họ và tên',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Nhập họ và tên';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Email (readonly)
                        TextFormField(
                          initialValue: baseEmail,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Email (từ tài khoản)',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Phone
                        TextFormField(
                          controller: phoneCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Số điện thoại',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Active switch
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE6E6E6)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_rounded, color: kPrimary),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text('Trạng thái hoạt động', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                              Switch(
                                value: isActive,
                                onChanged: (v) => setSheetState(() => isActive = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Experience + Price
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: expCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Kinh nghiệm (năm)',
                                  prefixIcon: Icon(Icons.work),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: priceCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Giá/giờ (VNĐ)',
                                  prefixIcon: Icon(Icons.payments),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Bio
                        TextFormField(
                          controller: bioCtrl,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Giới thiệu (bio)',
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.subject),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Areas
                        const Text('Khu vực (Areas)', style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: areaAddCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'Ví dụ: HCM, HN, DN...',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                                onPressed: () {
                                  final v = areaAddCtrl.text.trim();
                                  if (v.isEmpty) return;
                                  if (!areas.contains(v)) {
                                    setSheetState(() => areas.add(v));
                                  }
                                  areaAddCtrl.clear();
                                },
                                child: const Icon(Icons.add),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (areas.isEmpty)
                          const Text('Chưa chọn khu vực.', style: TextStyle(color: Colors.black54))
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: areas
                                .map(
                                  (a) => InputChip(
                                    label: Text(a),
                                    onDeleted: () => setSheetState(() => areas.remove(a)),
                                  ),
                                )
                                .toList(),
                          ),
                        const SizedBox(height: 14),

                        // Languages
                        const Text('Ngôn ngữ (Languages)', style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _langs.map((l) {
                            final selected = langSet.contains(l.code);
                            return FilterChip(
                              label: Text(l.name),
                              selected: selected,
                              onSelected: (v) {
                                setSheetState(() {
                                  if (v) {
                                    langSet.add(l.code);
                                  } else {
                                    langSet.remove(l.code);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                            onPressed: save,
                            icon: const Icon(Icons.save),
                            label: const Text(
                              'Lưu thay đổi',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;

    if (authUser == null) {
      return Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: kPrimary,
          elevation: 0,
          toolbarHeight: 90,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('RoamSG', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 6),
              Text('Guide profile', style: TextStyle(fontSize: 14, color: Colors.white)),
            ],
          ),
        ),
        body: const Center(child: Text('Bạn chưa đăng nhập.')),
      );
    }

    final baseName = authUser.displayName ?? '';
    final baseEmail = authUser.email ?? '';

    final stream = FirebaseFirestore.instance
        .collection('guides')
        .where('userId', isEqualTo: authUser.uid)
        .limit(1)
        .snapshots();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kPrimary,
        elevation: 0,
        toolbarHeight: 90,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('RoamSG', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 6),
            Text('Guide profile', style: TextStyle(fontSize: 14, color: Colors.white)),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Lỗi: ${snap.error}'));
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];
          final hasGuide = docs.isNotEmpty;

          Map<String, dynamic> data = {};
          DocumentReference<Map<String, dynamic>>? docRef;

          if (hasGuide) {
            data = docs.first.data();
            docRef = docs.first.reference;
          }

          final fullName = (data['fullName'] ?? baseName).toString();
          final email = (data['email'] ?? baseEmail).toString();
          final phone = (data['phone'] ?? '').toString();
          final bio = (data['bio'] ?? '').toString();

          final experienceYears = (data['experienceYears'] ?? 0);
          final pricePerHour = (data['pricePerHour'] ?? 0);

          final isActive = (data['isActive'] ?? false) == true;
          final areas = _strList(data['areas']);
          final languagesCode = _strList(data['languages']);
          final languages = languagesCode.map(_langName).toList();

          final createdAt = data['createdAt'];
          final updatedAt = data['updatedAt'];

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              _HeaderCard(
                name: fullName.isEmpty ? 'Chưa có tên' : fullName,
                email: email,
                badge: "Guide",
                onEdit: () => _openEditSheet(
                  context: context,
                  hasGuide: hasGuide,
                  data: data,
                  docRef: docRef,
                  authUser: authUser,
                ),
              ),
              const SizedBox(height: 14),

              if (!hasGuide)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Chưa có hồ sơ Guide", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text(
                          "Bạn chưa tạo hồ sơ hướng dẫn viên. Hãy tạo hồ sơ để khách có thể đặt lịch.",
                          style: TextStyle(color: Colors.black54, height: 1.35),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                            onPressed: () => _openEditSheet(
                              context: context,
                              hasGuide: false,
                              data: const {},
                              docRef: null,
                              authUser: authUser,
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text("Tạo hồ sơ Guide", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (hasGuide) ...[
                _InfoCard(
                  title: "Guide info",
                  children: [
                    _InfoRow(
                      icon: isActive ? Icons.verified_rounded : Icons.info_outline_rounded,
                      label: "Status",
                      value: isActive ? "Đang hoạt động" : "Chưa kích hoạt",
                    ),
                    const Divider(height: 18),
                    _InfoRow(
                      icon: Icons.work_rounded,
                      label: "Experience",
                      value: "$experienceYears năm",
                    ),
                    const Divider(height: 18),
                    _InfoRow(
                      icon: Icons.payments_rounded,
                      label: "Price per hour",
                      value: "${_fmtMoney(pricePerHour)} đ",
                    ),
                    const Divider(height: 18),
                    _InfoRow(
                      icon: Icons.phone_rounded,
                      label: "Phone",
                      value: phone.isEmpty ? "Chưa cập nhật" : phone,
                    ),
                    const Divider(height: 18),
                    _InfoRow(
                      icon: Icons.email_rounded,
                      label: "Email",
                      value: email.isEmpty ? "Chưa cập nhật" : email,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                _InfoCard(
                  title: "About",
                  children: [
                    Text(
                      bio.isEmpty ? "Chưa có mô tả." : bio,
                      style: const TextStyle(height: 1.4, color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                _ChipCard(
                  title: "Areas",
                  icon: Icons.location_on_rounded,
                  chips: areas,
                  emptyText: "Chưa chọn khu vực.",
                ),
                const SizedBox(height: 14),

                _ChipCard(
                  title: "Languages",
                  icon: Icons.translate_rounded,
                  chips: languages,
                  emptyText: "Chưa chọn ngôn ngữ.",
                ),
                const SizedBox(height: 14),

                _InfoCard(
                  title: "System",
                  children: [
                    _InfoRow(
                      icon: Icons.history_rounded,
                      label: "Created at",
                      value: _fmtTime(createdAt),
                    ),
                    const Divider(height: 18),
                    _InfoRow(
                      icon: Icons.update_rounded,
                      label: "Updated at",
                      value: _fmtTime(updatedAt),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _LangItem {
  final String code;
  final String name;
  const _LangItem({required this.code, required this.name});
}

class _HeaderCard extends StatelessWidget {
  final String name;
  final String email;
  final String badge;
  final VoidCallback onEdit;

  const _HeaderCard({
    required this.name,
    required this.email,
    required this.badge,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimary, kPrimary.withOpacity(0.85)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            color: Color(0x16000000),
            offset: Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: kPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: kPrimary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChipCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> chips;
  final String emptyText;

  const _ChipCard({
    required this.title,
    required this.icon,
    required this.chips,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: kPrimary),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            if (chips.isEmpty)
              Text(emptyText, style: const TextStyle(color: Colors.black54))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: chips.map((s) => Chip(label: Text(s))).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
