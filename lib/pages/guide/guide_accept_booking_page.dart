import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class GuideAcceptBookingPage extends StatelessWidget {
  const GuideAcceptBookingPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accept Bookings'),
        backgroundColor: const Color(0xFF79D5FF),
        foregroundColor: Colors.white,
      ),
      body: const Center(child: Text('Accept Booking Page Content Here')),
    );
  }
}
