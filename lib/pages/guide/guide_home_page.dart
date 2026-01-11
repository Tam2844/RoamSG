import 'package:flutter/material.dart';

class GuideHomePage extends StatelessWidget {
  const GuideHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guide Home Page')),
      body: const Center(child: Text('Welcome to the Guide Home Page!')),
    );
  }
}
