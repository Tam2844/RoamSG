import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cccdCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cccdCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case "invalid-email":
        return "Email không hợp lệ.";
      case "email-already-in-use":
        return "Email đã được sử dụng.";
      case "weak-password":
        return "Mật khẩu yếu. Hãy dùng ít nhất 6 ký tự.";
      case "operation-not-allowed":
        return "Chưa bật Email/Password trong Firebase Authentication.";
      case "network-request-failed":
        return "Lỗi mạng. Kiểm tra internet rồi thử lại.";
      default:
        return e.message ?? "Đăng ký thất bại.";
    }
  }

  Future<void> _register() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _loading = true);
  try {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    // 1) Tạo tài khoản Auth -> lấy uid
    final cred = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    final uid = cred.user!.uid;

    // (tuỳ chọn) cập nhật displayName trên Auth
    await cred.user!.updateDisplayName(_nameCtrl.text.trim());

    // 2) Lưu thông tin mở rộng vào Firestore users/{uid}
    await FirebaseFirestore.instance.collection("users").doc(uid).set({
      "fullName": _nameCtrl.text.trim(),
      "phone": _phoneCtrl.text.trim(),
      "cccd": _cccdCtrl.text.trim(),
      "address": "", // chưa có thì để rỗng
      "isGuide": false,
      "email": email,
      "createdAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đăng ký thành công!")),
      );
      Navigator.pop(context); // quay về Login
    }
  } on FirebaseAuthException catch (e) {
    // handle lỗi
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng ký")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final s = (v ?? "").trim();
                        if (s.isEmpty) return "Nhập email.";
                        if (!s.contains("@")) return "Email không hợp lệ.";
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: "Họ và tên",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final s = (v ?? "").trim();
                        if (s.isEmpty) return "Nhập họ và tên.";
                        if (s.length < 2) return "Tên quá ngắn.";
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Số điện thoại",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final s = (v ?? "").trim();
                        if (s.isEmpty) return "Nhập số điện thoại.";
                        final onlyDigits = RegExp(r'^\d+$');
                        if (!onlyDigits.hasMatch(s)) return "SĐT chỉ gồm số.";
                        if (s.length < 9 || s.length > 11) {
                          return "SĐT thường 9–11 số.";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _cccdCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "CCCD",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final s = (v ?? "").trim();
                        if (s.isEmpty) return "Nhập CCCD.";
                        final onlyDigits = RegExp(r'^\d+$');
                        if (!onlyDigits.hasMatch(s)) return "CCCD chỉ gồm số.";
                        if (s.length != 12) return "CCCD thường là 12 số.";
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure1,
                      decoration: InputDecoration(
                        labelText: "Mật khẩu",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure1 = !_obscure1),
                          icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off),
                        ),
                      ),
                      validator: (v) {
                        final s = v ?? "";
                        if (s.isEmpty) return "Nhập mật khẩu.";
                        if (s.length < 6) return "Ít nhất 6 ký tự.";
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: _obscure2,
                      decoration: InputDecoration(
                        labelText: "Nhập lại mật khẩu",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure2 = !_obscure2),
                          icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
                        ),
                      ),
                      validator: (v) {
                        final s = v ?? "";
                        if (s.isEmpty) return "Nhập lại mật khẩu.";
                        if (s != _passCtrl.text) return "Mật khẩu không khớp.";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _register,
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text("Tạo tài khoản"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
