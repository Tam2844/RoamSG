import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:roamsg/pages/guide/guide_detail_bookings_page.dart';

class GuideHistoryBookingsPage extends StatelessWidget {
  const GuideHistoryBookingsPage({super.key});

  String _fmtDateTime(DateTime d) => DateFormat('HH:mm dd/MM').format(d);
  String _fmtMoney(int v) => NumberFormat.decimalPattern('vi').format(v);

  DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Stream<List<BookingPreview>> _historyStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(const <BookingPreview>[]);
    }

    final uid = user.uid;
    final today = Timestamp.fromDate(_startOfToday());

    return FirebaseFirestore.instance
        .collection('guide_bookings')
        .where('guideId', isEqualTo: uid)
        .where('date', isLessThan: today)
        .orderBy('date', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            final data = doc.data();
            final date = (data['date'] as Timestamp).toDate();
            final price = (data['price'] ?? 0) as int;
            final userId = (data['userId'] ?? '').toString();
            final shortUser = userId.length > 6
                ? userId.substring(0, 6)
                : userId;

            return BookingPreview(
              doc.id,
              "History",
              "User: $shortUser · Giá: ${_fmtMoney(price)}đ",
              _fmtDateTime(date),
            );
          }).toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF7FF),
      appBar: AppBar(
        title: const Text('History Bookings'),
        backgroundColor: const Color(0xFF79D5FF),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<BookingPreview>>(
        stream: _historyStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final bookings = snapshot.data ?? [];
          if (bookings.isEmpty) {
            return const Center(child: Text('No history bookings.'));
          }

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return ListTile(
                title: Text(booking.title),
                subtitle: Text(booking.subtitle),
                trailing: Text(booking.dateTime),
                onTap: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (_) => GuideDetailBookingsPage(
                  //       bookingId: booking.id,
                  //     ),
                  //   ),
                  // );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class BookingPreview {
  final String id;
  final String title;
  final String subtitle;
  final String dateTime;

  const BookingPreview(this.id, this.title, this.subtitle, this.dateTime);
}
