import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder(
      stream: authService.authStateChanges(),
      builder: (context, snapshot) {
        // 1) Chờ Firebase trả trạng thái
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2) Nếu chưa đăng nhập -> LoginPage
        final user = snapshot.data;
        if (user == null) return const LoginPage();

        // 3) Đã đăng nhập -> HomePage
        return const HomePage();
      },
    );
  }
}
