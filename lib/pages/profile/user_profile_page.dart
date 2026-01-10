import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
  
}

class _ProfilePageState extends State<ProfilePage> {
  String fullName = "";
  String email = "";
  String phone = "";
  String cccd = "";
  String address = "";
  bool isGuide = false;

  bool _loading = true;
  bool _saving = false;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  @override
  void initState() {
    super.initState();
    _bindUser();
  }

  void _bindUser() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Nếu chưa login thì để trống (hoặc điều hướng về login tùy flow app)
      setState(() {
        _loading = false;
        fullName = "Guest";
        email = "";
        phone = "";
        cccd = "";
        address = "";
        isGuide = false;
      });
      return;
    }

    // lấy từ FirebaseAuth
    setState(() {
      email = user.email ?? "";
      fullName = user.displayName ?? "";
    });

    // lắng nghe Firestore users/{uid}
    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) {
      final data = doc.data() ?? {};

      setState(() {
        fullName = (data['fullName'] ?? fullName).toString();
        phone = (data['phone'] ?? '').toString();
        cccd = (data['cccd'] ?? '').toString();
        address = (data['address'] ?? '').toString();
        isGuide = (data['isGuide'] ?? false) == true;
        _loading = false;
      });
    }, onError: (_) {
      setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF0F172A),
        title: const Text("Profile", style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: false,
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          _HeaderCard(
            name: fullName,
            email: email,
            badge: isGuide ? "Guide" : "Customer",
            onEdit: _saving ? () {} : _openEditProfile,
          ),
          const SizedBox(height: 14),

          _InfoCard(
            title: "Personal info",
            children: [
              _InfoRow(
                icon: Icons.phone_rounded,
                label: "Phone",
                value: phone.isEmpty ? "Chưa cập nhật" : phone,
              ),
              const Divider(height: 18),
              _InfoRow(
                icon: Icons.badge_rounded,
                label: "CCCD",
                value: cccd.isEmpty ? "Chưa cập nhật" : cccd,
              ),
              const Divider(height: 18),
              _InfoRow(
                icon: Icons.location_on_rounded,
                label: "Address",
                value: address.isEmpty ? "Chưa cập nhật" : address,
              ),
            ],
          ),


          const SizedBox(height: 14),

          _MenuCard(
            title: "Your stuff",
            items: [
              _MenuItemData(
                icon: Icons.receipt_long_rounded,
                title: "My bookings",
                subtitle: "View your tour history",
                onTap: () {
                  // TODO: Navigator.push(...)
                  _toast("Chưa làm My bookings");
                },
              ),
              _MenuItemData(
                icon: Icons.favorite_rounded,
                title: "Saved guides",
                subtitle: "Your favorite guides",
                onTap: () => _toast("Chưa làm Saved guides"),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _MenuCard(
            title: "Account",
            items: [
              _MenuItemData(
                icon: Icons.workspace_premium_rounded,
                title: isGuide ? "Guide profile" : "Become a guide",
                subtitle: isGuide ? "Manage your guide settings" : "Apply to be a guide",
                onTap: () {
                  setState(() => isGuide = !isGuide);
                  _toast(isGuide ? "Đã bật chế độ Guide (demo)" : "Đã về Customer (demo)");
                },
              ),
              _MenuItemData(
                icon: Icons.settings_rounded,
                title: "Settings",
                subtitle: "Language, currency, privacy",
                onTap: () => _toast("Chưa làm Settings"),
              ),
              _MenuItemData(
                icon: Icons.logout_rounded,
                title: "Log out",
                subtitle: "Sign out of this account",
                danger: true,
                onTap: _confirmLogout,
              ),
            ],
          ),
        ],
      ),
    );
  }

bool saving = false;

Future<void> _saveProfileToFirestore(_EditResult result) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  setState(() => _saving = true);

  try {
    final uid = user.uid;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      "fullName": result.fullName,
      "phone": result.phone,
      "cccd": result.cccd,
      "address": result.address,
      "email": user.email ?? "",
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // cập nhật displayName để header đổi luôn (optional nhưng nên có)
    if ((user.displayName ?? "") != result.fullName) {
      await user.updateDisplayName(result.fullName);
      await user.reload();
    }

    if (!mounted) return;
    _toast("Saved to Firestore!");
  } catch (e) {
    if (!mounted) return;
    _toast("Save failed: $e");
  } finally {
    if (mounted) setState(() => _saving = false);
  }
}


  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openEditProfile() async {
    final result = await showModalBottomSheet<_EditResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _EditProfileSheet(
        fullName: fullName,
        phone: phone,
        cccd: cccd,
        address: address,
      ),
    );

    if (result == null) return;

    setState(() {
    fullName = result.fullName;
    phone = result.phone;
    cccd = result.cccd;
    address = result.address;
  });

  // ✅ lưu lên Firestore
  await _saveProfileToFirestore(result);

  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Log out?"),
        content: const Text("You will need to sign in again."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text("Log out"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    // TODO: FirebaseAuth.instance.signOut();
    _toast("Logged out (demo)");
  }
  
}

// ===== UI Components =====

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
        gradient: const LinearGradient(
          colors: [Color(0xFF67D4FF), Color(0xFF4C7DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(blurRadius: 18, color: Color(0x16000000), offset: Offset(0, 10))],
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
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE066),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(badge, style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            tooltip: "Edit profile",
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

class _MenuItemData {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  _MenuItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });
}

class _MenuCard extends StatelessWidget {
  final String title;
  final List<_MenuItemData> items;

  const _MenuCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(blurRadius: 18, color: Color(0x14000000), offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 6),
          ...items.map((it) => ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: it.onTap,
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: it.danger ? const Color(0xFFFEE2E2) : const Color(0xFFEAF5FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(it.icon, color: it.danger ? const Color(0xFFEF4444) : const Color(0xFF4C7DFF)),
                ),
                title: Text(it.title, style: TextStyle(fontWeight: FontWeight.w900, color: it.danger ? const Color(0xFFEF4444) : null)),
                subtitle: Text(it.subtitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                trailing: const Icon(Icons.chevron_right_rounded),
              )),
        ],
      ),
    );
  }
}

// ===== Bottom sheet: edit =====

class _EditResult {
  final String fullName;
  final String phone;
  final String cccd;
  final String address;

  _EditResult({
    required this.fullName,
    required this.phone,
    required this.cccd,
    required this.address,
  });
}

class _EditProfileSheet extends StatefulWidget {
  final String fullName;
  final String phone;
  final String cccd;
  final String address;

  const _EditProfileSheet({
    required this.fullName,
    required this.phone,
    required this.cccd,
    required this.address,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}


class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _cccd;
  late final TextEditingController _address;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.fullName);
    _phone = TextEditingController(text: widget.phone);
    _cccd = TextEditingController(text: widget.cccd);
    _address = TextEditingController(text: widget.address);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _cccd.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Edit profile", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 12),
          _Field(label: "Full name", controller: _name, icon: Icons.person_rounded),
          const SizedBox(height: 10),
          _Field(label: "Phone", controller: _phone, icon: Icons.phone_rounded, keyboardType: TextInputType.phone),
          const SizedBox(height: 10),
          _Field(label: "CCCD", controller: _cccd, icon: Icons.badge_rounded, keyboardType: TextInputType.number),
          const SizedBox(height: 10),
          _Field(label: "Address", controller: _address, icon: Icons.location_on_rounded),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(  
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4C7DFF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pop(
                  context,
                  _EditResult(
                    fullName: _name.text.trim(),
                    phone: _phone.text.trim(),
                    cccd: _cccd.text.trim(),
                    address: _address.text.trim(),
                  ),
                );
              },
              child: const Text("Save", style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;

  const _Field({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
