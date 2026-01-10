import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GuideRegisterPage extends StatefulWidget {
  const GuideRegisterPage({super.key});

  @override
  State<GuideRegisterPage> createState() => _GuideRegisterPageState();
}

class _GuideRegisterPageState extends State<GuideRegisterPage> {
  // ===== Options chuẩn hóa để dễ query/search =====
  static const List<Map<String, String>> kLangOptions = [
    {"code": "vi", "label": "Vietnamese"},
    {"code": "en", "label": "English"},
    {"code": "zh", "label": "Chinese"},
    {"code": "ja", "label": "Japanese"},
    {"code": "ko", "label": "Korean"},
  ];

  static const List<String> kAreaOptions = [
    "HCM",
    "HaNoi",
    "DaNang",
    "VungTau",
    "CanTho",
  ];

  final _formKey = GlobalKey<FormState>();

  final _bioCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _expCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  // lấy từ users/{uid} để hiển thị
  String _fullName = "";
  String _email = "";
  String _phone = "";

  // guide selections
  List<String> _selectedLangs = [];
  List<String> _selectedAreas = [];

  bool _guideDocExists = false;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _priceCtrl.dispose();
    _expCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  int _parseIntSafe(String s) => int.tryParse(s.trim()) ?? 0;

  Future<void> _prefill() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _loading = false);
        _toast("Bạn chưa đăng nhập");
        Navigator.pop(context);
      }
      return;
    }

    try {
      final uid = user.uid;

      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};

      final guideDoc =
          await FirebaseFirestore.instance.collection('guides').doc(uid).get();
      final guideData = guideDoc.data() ?? {};

      setState(() {
        _fullName = (userData['fullName'] ?? user.displayName ?? "").toString();
        _email = (userData['email'] ?? user.email ?? "").toString();
        _phone = (userData['phone'] ?? "").toString();

        _guideDocExists = guideDoc.exists;

        // Nếu đã có hồ sơ guide thì prefill để cập nhật
        if (guideDoc.exists) {
          _bioCtrl.text = (guideData['bio'] ?? "").toString();
          _priceCtrl.text = (guideData['pricePerHour'] ?? "").toString();
          _expCtrl.text = (guideData['experienceYears'] ?? "").toString();

          _selectedLangs = (guideData['languages'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];

          _selectedAreas = (guideData['areas'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
        }
      });
    } catch (e) {
      _toast("Load failed: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_saving) return;

    // validate form + chip fields
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _toast("Bạn chưa đăng nhập");
      return;
    }

    setState(() => _saving = true);

    try {
      final uid = user.uid;

      final languages = _selectedLangs;
      final areas = _selectedAreas;

      final pricePerHour = _parseIntSafe(_priceCtrl.text);
      final expYears = _parseIntSafe(_expCtrl.text);

      // data guide
      final guidePayload = <String, dynamic>{
        "userId": uid,
        "fullName": _fullName,
        "email": _email,
        "phone": _phone,
        "bio": _bioCtrl.text.trim(),
        "languages": languages, // ✅ list -> query arrayContains
        "areas": areas, // ✅ list -> query arrayContains
        "pricePerHour": pricePerHour,
        "experienceYears": expYears,

        // ✅ thành HDV luôn
        "isActive": true,

        "updatedAt": FieldValue.serverTimestamp(),
      };

      // createdAt chỉ set lần đầu (đỡ overwrite)
      if (!_guideDocExists) {
        guidePayload["createdAt"] = FieldValue.serverTimestamp();
      }

      // 1) ghi guides/{uid}
      await FirebaseFirestore.instance
          .collection('guides')
          .doc(uid)
          .set(guidePayload, SetOptions(merge: true));

      // 2) update users/{uid}.isGuide = true
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        "isGuide": true,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      _toast("Đăng ký hướng dẫn viên thành công!");
      Navigator.pop(context, true); // trả về Profile (AuthGate sẽ tự đổi UI)
    } catch (e) {
      if (mounted) _toast("Submit failed: $e");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _guideDocExists ? "Cập nhật hồ sơ HDV" : "Become a guide";

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeaderCard(
                  fullName: _fullName,
                  email: _email,
                  phone: _phone,
                  note: _guideDocExists
                      ? "Bạn đang cập nhật thông tin hướng dẫn viên."
                      : "Điền thông tin để đăng ký làm hướng dẫn viên.",
                ),
                const SizedBox(height: 12),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _bioCtrl,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: "Giới thiệu (bio)",
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final s = (v ?? "").trim();
                          if (s.length < 20) return "Bio tối thiểu 20 ký tự";
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      MultiSelectChipsFormField(
                        labelText: "Ngôn ngữ",
                        options: kLangOptions
                            .map((e) => ChipOption(
                                  value: e["code"]!,
                                  label: e["label"]!,
                                ))
                            .toList(),
                        initialValue: _selectedLangs,
                        onChanged: (v) => setState(() => _selectedLangs = v),
                        validator: (v) => (v == null || v.isEmpty)
                            ? "Chọn ít nhất 1 ngôn ngữ"
                            : null,
                      ),
                      const SizedBox(height: 12),

                      MultiSelectChipsFormField(
                        labelText: "Khu vực hoạt động",
                        options: kAreaOptions
                            .map((e) => ChipOption(value: e, label: e))
                            .toList(),
                        initialValue: _selectedAreas,
                        onChanged: (v) => setState(() => _selectedAreas = v),
                        validator: (v) => (v == null || v.isEmpty)
                            ? "Chọn ít nhất 1 khu vực"
                            : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Giá theo giờ (VND)",
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final n = _parseIntSafe(v ?? "");
                          if (n <= 0) return "Giá phải > 0";
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _expCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Số năm kinh nghiệm",
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final n = _parseIntSafe(v ?? "");
                          if (n < 0) return "Không hợp lệ";
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _submit,
                          child: Text(_saving ? "Đang lưu..." : "Submit"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String fullName;
  final String email;
  final String phone;
  final String note;

  const _HeaderCard({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            color: Color(0x14000000),
            offset: Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fullName.isEmpty ? "User" : fullName,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(email, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 2),
          Text(phone.isEmpty ? "No phone" : phone,
              style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 10),
          Text(note),
        ],
      ),
    );
  }
}

// ===== Multi-select Chips FormField =====

class ChipOption {
  final String value;
  final String label;
  const ChipOption({required this.value, required this.label});
}

class MultiSelectChipsFormField extends FormField<List<String>> {
  MultiSelectChipsFormField({
    super.key,
    required String labelText,
    required List<ChipOption> options,
    required List<String> initialValue,
    FormFieldValidator<List<String>>? validator,
    required ValueChanged<List<String>> onChanged,
  }) : super(
          initialValue: initialValue,
          validator: validator,
          builder: (state) {
            final selected = (state.value ?? []).toSet();

            void toggle(String v) {
              final next = {...selected};
              if (next.contains(v)) {
                next.remove(v);
              } else {
                next.add(v);
              }
              final list = next.toList();
              state.didChange(list);
              onChanged(list);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  labelText,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: state.hasError ? Colors.red : Colors.black26,
                    ),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: options.map((opt) {
                      final isOn = selected.contains(opt.value);
                      return FilterChip(
                        label: Text(opt.label),
                        selected: isOn,
                        onSelected: (_) => toggle(opt.value),
                      );
                    }).toList(),
                  ),
                ),
                if (state.hasError) ...[
                  const SizedBox(height: 6),
                  Text(
                    state.errorText ?? "",
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ],
            );
          },
        );
}
