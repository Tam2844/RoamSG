import 'package:flutter/material.dart';

class GuideCreateTourPage extends StatelessWidget {
  const GuideCreateTourPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Tour'),
        backgroundColor: const Color(0xFF79D5FF),
        foregroundColor: Colors.white,
      ),
      body: const Center(child: Text('Create Tour Page Content Here')),
    );
  }
}
