import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GuideCreateTourPage extends StatefulWidget {
  const GuideCreateTourPage({super.key});

  @override
  State<GuideCreateTourPage> createState() => _GuideCreateTourPageState();
}

class _GuideCreateTourPageState extends State<GuideCreateTourPage> {
  static const Color kBg = Color(0xFFF5F8FA);
  static const Color kPrimary = Color(0xFF79D5FF);

  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _maxPeopleCtrl = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  bool _isActive = true;
  bool _saving = false;

  // lưu đúng dạng array string như Firestore của cậu
  final Set<String> _languages = {'vi'};
  final Set<String> _tags = {'city'};

  String _fmtDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  int _calcDays(DateTime? s, DateTime? e) {
    if (s == null || e == null) return 1;
    final diff = e.difference(DateTime(s.year, s.month, s.day)).inDays;
    // start 01/02 00:00 -> end 02/02 00:00 => 1 ngày
    return diff <= 0 ? 1 : diff;
  }

  int _toInt(String s) => int.tryParse(s.trim().replaceAll('.', '').replaceAll(',', '')) ?? 0;

  // tạo docId kiểu: tour_city_highlights (giống dữ liệu cậu đang seed)
  String _slugify(String input) {
    final lower = input.trim().toLowerCase();
    final replaced = lower
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final cleaned = replaced.replaceAll(RegExp(r'^_+|_+$'), '');
    return cleaned.isEmpty ? 'tour' : cleaned;
  }

  Future<DateTime?> _pickDate(BuildContext context, DateTime? initial) {
    final now = DateTime.now();
    final init = initial ?? DateTime(now.year, now.month, now.day);
    return showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
  }

  Future<void> _selectStartDate() async {
    final picked = await _pickDate(context, _startDate);
    if (picked == null) return;

    setState(() {
      _startDate = DateTime(picked.year, picked.month, picked.day);

      // nếu endDate đang nhỏ hơn startDate thì tự đẩy endDate = startDate + 1 ngày
      if (_endDate != null && _endDate!.isBefore(_startDate!)) {
        _endDate = _startDate!.add(const Duration(days: 1));
      }
      _endDate ??= _startDate!.add(const Duration(days: 1));
    });
  }

  Future<void> _selectEndDate() async {
    final picked = await _pickDate(context, _endDate);
    if (picked == null) return;

    final end = DateTime(picked.year, picked.month, picked.day);
    if (_startDate != null && end.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date phải >= Start date')),
      );
      return;
    }

    setState(() => _endDate = end);
  }

  Future<void> _createTour() async {
    if (_saving) return;

    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa đăng nhập')),
      );
      return;
    }

    // bảo đảm có ngày
    final start = _startDate ?? DateTime.now();
    final end = _endDate ?? start.add(const Duration(days: 1));

    final title = _titleCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final imageUrl = _imageUrlCtrl.text.trim();

    final price = _toInt(_priceCtrl.text);
    final maxPeople = _toInt(_maxPeopleCtrl.text);

    final days = _calcDays(start, end);

    setState(() => _saving = true);
    try {
      final toursCol = FirebaseFirestore.instance.collection('tours');

      // docId theo pattern giống data mẫu (tour_ + slug)
      final baseId = 'tour_${_slugify(title)}';
      String docId = baseId;

      // nếu trùng id thì thêm suffix timestamp cho chắc
      final exists = await toursCol.doc(docId).get();
      if (exists.exists) {
        docId = '${baseId}_${DateTime.now().millisecondsSinceEpoch}';
      }

      await toursCol.doc(docId).set({
        'title': title,
        'city': city,
        'description': desc,
        'imageUrl': imageUrl,
        'price': price,
        'maxPeople': maxPeople,
        'languages': _languages.toList(),
        'tags': _tags.toList(),
        'isActive': _isActive,

        'startDate': Timestamp.fromDate(DateTime(start.year, start.month, start.day)),
        'endDate': Timestamp.fromDate(DateTime(end.year, end.month, end.day)),
        'days': days,

        'guideId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo tour thành công')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tạo tour thất bại: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _cityCtrl.dispose();
    _descCtrl.dispose();
    _imageUrlCtrl.dispose();
    _priceCtrl.dispose();
    _maxPeopleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _calcDays(_startDate, _endDate);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Tạo tour'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionTitle('Thông tin tour'),
              const SizedBox(height: 10),

              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập title' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _cityCtrl,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập city' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descCtrl,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập description' : null,
              ),
              const SizedBox(height: 18),

              _sectionTitle('Thời gian'),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _dateBox(
                      label: 'Start date',
                      value: _startDate == null ? 'Chọn ngày' : _fmtDate(_startDate!),
                      onTap: _selectStartDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dateBox(
                      label: 'End date',
                      value: _endDate == null ? 'Chọn ngày' : _fmtDate(_endDate!),
                      onTap: _selectEndDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('Days: $days', style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 18),

              _sectionTitle('Giá & Số người'),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        hintText: '650000',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final val = _toInt(v ?? '');
                        if (val <= 0) return 'Price phải > 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _maxPeopleCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max people',
                        hintText: '10',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final val = _toInt(v ?? '');
                        if (val <= 0) return 'Max people phải > 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              _sectionTitle('Ảnh'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _imageUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập imageUrl' : null,
              ),

              const SizedBox(height: 18),
              _sectionTitle('Languages'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chipLang('vi', 'Tiếng Việt'),
                  _chipLang('en', 'Tiếng Anh'),
                  _chipLang('zh', 'Tiếng Trung'),
                  _chipLang('ja', 'Tiếng Nhật'),
                  _chipLang('ko', 'Tiếng Hàn'),
                ],
              ),
              const SizedBox(height: 18),

              _sectionTitle('Tags'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chipTag('city'),
                  _chipTag('photo'),
                  _chipTag('iconic'),
                  _chipTag('food'),
                  _chipTag('museum'),
                  _chipTag('nature'),
                  _chipTag('night'),
                  _chipTag('family'),
                ],
              ),

              const SizedBox(height: 18),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('isActive'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),

              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _createTour,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add),
                  label: Text(_saving ? 'Đang tạo...' : 'Tạo tour'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    );
  }

  Widget _dateBox({required String label, required String value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE6E6E6)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, size: 18, color: Colors.black54),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipLang(String code, String label) {
    final selected = _languages.contains(code);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) {
        setState(() {
          if (v) {
            _languages.add(code);
          } else {
            // luôn giữ ít nhất 1 ngôn ngữ
            if (_languages.length > 1) _languages.remove(code);
          }
        });
      },
    );
  }

  Widget _chipTag(String tag) {
    final selected = _tags.contains(tag);
    return FilterChip(
      label: Text(tag),
      selected: selected,
      onSelected: (v) {
        setState(() {
          if (v) {
            _tags.add(tag);
          } else {
            if (_tags.length > 1) _tags.remove(tag);
          }
        });
      },
    );
  }
}
