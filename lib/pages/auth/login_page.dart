import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_page.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      // AuthGate sẽ tự chuyển sang HomePage khi đăng nhập thành công.
    } on FirebaseAuthException catch (e) {
      final msg = _friendlyAuthError(e);
      if (mounted) _showSnack(msg);
    } catch (_) {
      if (mounted) _showSnack("Có lỗi xảy ra. Thử lại nhé.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showSnack("Nhập email trước đã.");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) _showSnack("Đã gửi email đặt lại mật khẩu.");
    } on FirebaseAuthException catch (e) {
      if (mounted) _showSnack(_friendlyAuthError(e));
    }
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case "invalid-email":
        return "Email không hợp lệ.";
      case "user-not-found":
        return "Không tìm thấy tài khoản này.";
      case "wrong-password":
        return "Sai mật khẩu.";
      case "invalid-credential":
        return "Thông tin đăng nhập không đúng.";
      case "email-already-in-use":
        return "Email đã được sử dụng.";
      case "weak-password":
        return "Mật khẩu yếu. Hãy dùng ít nhất 6 ký tự.";
      case "operation-not-allowed":
        return "Chưa bật Email/Password trong Firebase Authentication.";
      case "network-request-failed":
        return "Lỗi mạng. Kiểm tra internet rồi thử lại.";
      default:
        return e.message ?? "Đăng nhập thất bại.";
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text("Đăng nhập")),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
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
                            controller: _passCtrl,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: "Mật khẩu",
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscure = !_obscure),
                                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                              ),
                            ),
                            validator: (v) {
                              final s = v ?? "";
                              if (s.isEmpty) return "Nhập mật khẩu.";
                              if (s.length < 6) return "Ít nhất 6 ký tự.";
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _login,
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text("Đăng nhập"),
                            ),
                          ),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _loading
                                      ? null
                                      : () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => const RegisterPage()),
                                          );
                                        },
                                  child: const Text("Tạo tài khoản"),
                                ),

                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextButton(
                                  onPressed: _loading ? null : _resetPassword,
                                  child: const Text("Quên mật khẩu"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

}
