import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roamsg/pages/profile/guide_profile_page.dart';
import 'package:flutter/material.dart';



const Color kBg = Color(0xFFF5F8FA);
const Color kPrimary = Color(0xFF79D5FF);

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

    setState(() {
      email = user.email ?? "";
      fullName = user.displayName ?? "";
    });

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
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kPrimary,
        elevation: 0,
        toolbarHeight: 90,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'RoamSG',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Your profile',
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                      onTap: () => _toast("Chưa làm My bookings"),
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
                      subtitle: isGuide
                          ? "Manage your guide settings"
                          : "Apply to be a guide",
                    onTap: () async {
                      final changed = await Navigator.push<bool>(
                      context,
                        MaterialPageRoute(
                          builder: (_) => const GuideProfilePage(),
                        ),
                      );
                      if (changed == true) {
                      _toast("Đã cập nhật hồ sơ HDV");
                      }
                    },
                    ),
                    // _MenuItemData(
                    //   icon: Icons.settings_rounded,
                    //   title: "Settings",
                    //   subtitle: "Language, currency, privacy",
                    //   onTap: () => _toast("Chưa làm Settings"),
                    // ),
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

  Future<void> _saveProfileToFirestore(_EditResult result) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        "fullName": result.fullName,
        "phone": result.phone,
        "cccd": result.cccd,
        "address": result.address,
        "email": user.email ?? "",
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if ((user.displayName ?? "") != result.fullName) {
        await user.updateDisplayName(result.fullName);
        await user.reload();
      }

      if (mounted) _toast("Saved!");
    } catch (e) {
      if (mounted) _toast("Save failed: $e");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
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

    await _saveProfileToFirestore(result);
  }

  Future<void> _confirmLogout() async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Log out?"),
      content: const Text("You will need to sign in again."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text("Log out"),
        ),
      ],
    ),
  );

  if (ok != true) return;

  try {
    await _userSub?.cancel();
    _userSub = null;

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    // ✅ Quay về root (AuthGate) và xóa các trang trên stack
    Navigator.of(context).popUntil((route) => route.isFirst);

    // (tuỳ chọn) thông báo
    _toast("Logged out");
  } catch (e) {
    if (!mounted) return;
    _toast("Log out failed: $e");
  }
}

}

// ================= UI COMPONENTS =================

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
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
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black54)),
              Text(value,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ...items.map(
              (it) => ListTile(
                onTap: it.onTap,
                leading: Icon(
                  it.icon,
                  color: it.danger ? Colors.red : kPrimary,
                ),
                title: Text(
                  it.title,
                  style: TextStyle(
                    color: it.danger ? Colors.red : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(it.subtitle),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= EDIT SHEET =================

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
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Edit profile",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _Field(label: "Full name", controller: _name, icon: Icons.person),
          const SizedBox(height: 10),
          _Field(label: "Phone", controller: _phone, icon: Icons.phone),
          const SizedBox(height: 10),
          _Field(label: "CCCD", controller: _cccd, icon: Icons.badge),
          const SizedBox(height: 10),
          _Field(label: "Address", controller: _address, icon: Icons.location_on),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
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
              child: const Text(
                "Save",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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

  const _Field({
    required this.label,
    required this.controller,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
