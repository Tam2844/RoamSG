import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const Color kBg = Color(0xFFF5F8FA);
  static const Color kPrimary = Color(0xFF79D5FF);

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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
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

  InputDecoration _dec(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
    );
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    try {
      final email = _emailCtrl.text.trim();
      final password = _passCtrl.text;
      final fullName = _nameCtrl.text.trim();

      // 1) Tạo Auth
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) {
        _showSnack("Không tạo được tài khoản. Thử lại nhé.");
        return;
      }

      // 2) Cập nhật displayName (tuỳ chọn)
      await user.updateDisplayName(fullName);

      // 3) Lưu hồ sơ Firestore
      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "fullName": fullName,
        "phone": _phoneCtrl.text.trim(),
        "cccd": _cccdCtrl.text.trim(),
        "address": "",
        "isGuide": false,
        "email": email,
        "createdAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _showSnack("Đăng ký thành công!");
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      _showSnack(_friendlyAuthError(e));
    } catch (_) {
      _showSnack("Có lỗi khi tạo hồ sơ người dùng. Vui lòng thử lại.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,

      // AppBar giống style GuideHomePage
      appBar: AppBar(
        backgroundColor: kPrimary,
        toolbarHeight: 90,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
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
              'Create your account',
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
          ],
        ),
      ),

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
              child: Card(
                color: Colors.white,
                elevation: 2,
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _dec("Email"),
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
                          decoration: _dec("Họ và tên"),
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
                          decoration: _dec("Số điện thoại"),
                          validator: (v) {
                            final s = (v ?? "").trim();
                            if (s.isEmpty) return "Nhập số điện thoại.";
                            if (!RegExp(r'^\d+$').hasMatch(s)) return "SĐT chỉ gồm số.";
                            if (s.length < 9 || s.length > 11) return "SĐT thường 9–11 số.";
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _cccdCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _dec("CCCD"),
                          validator: (v) {
                            final s = (v ?? "").trim();
                            if (s.isEmpty) return "Nhập CCCD.";
                            if (!RegExp(r'^\d+$').hasMatch(s)) return "CCCD chỉ gồm số.";
                            if (s.length != 12) return "CCCD thường là 12 số.";
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscure1,
                          decoration: _dec(
                            "Mật khẩu",
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
                          decoration: _dec(
                            "Nhập lại mật khẩu",
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
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: Colors.white,
                              elevation: 2,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    "Tạo tài khoản",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        TextButton(
                          onPressed: _loading ? null : () => Navigator.pop(context),
                          child: const Text("Đã có tài khoản? Đăng nhập"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
