import 'package:flutter/material.dart';

class GuideDetailBookingsPage extends StatelessWidget {
  final String bookingId;

  const GuideDetailBookingsPage({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: Center(child: Text('Details for booking ID: $bookingId')),
    );
  }
}

class BookingDetail {
  final String id;
  final String title;
  final String description;
  final String dateTime;
  BookingDetail(this.id, this.title, this.description, this.dateTime);
}
