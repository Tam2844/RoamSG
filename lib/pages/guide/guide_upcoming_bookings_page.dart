import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:roamsg/pages/guide/guide_detail_bookings_page.dart';

class GuideUpcomingBookingsPage extends StatelessWidget {
  const GuideUpcomingBookingsPage({super.key});
  String _fmtDateTime(DateTime d) => DateFormat('HH:mm dd/MM').format(d);
  String _fmtMoney(int v) => NumberFormat.decimalPattern('vi').format(v);

  DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Stream<List<BookingPreview>> upcomingGuideBookingsStream() {
    final guideUid = FirebaseAuth.instance.currentUser!.uid;
    final todayStart = Timestamp.fromDate(_startOfToday());

    return FirebaseFirestore.instance
        .collection('tour_bookings')
        .where('guideId', isEqualTo: guideUid)
        .where('status', isEqualTo: 'accepted')
        .where('startDate', isGreaterThanOrEqualTo: todayStart)
        .orderBy('startDate')
        .limit(10)
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            final data = doc.data();

            final start = (data['startDate'] as Timestamp).toDate();
            final end = (data['endDate'] as Timestamp).toDate();

            final totalPrice = (data['totalPrice'] as num?)?.toInt() ?? 0;
            final participants = (data['participants'] as num?)?.toInt() ?? 0;
            final pickup = (data['pickupPoint'] ?? '-').toString();

            final tourId = (data['tourId'] ?? '').toString();

            return BookingPreview(
              doc.id,
              tourId,
              "$participants người · Đón: $pickup · ${_fmtMoney(totalPrice)}đ",
              "${_fmtDateTime(start)} → ${_fmtDateTime(end)}",
            );
          }).toList();
        });
  }

  Widget _tourTitleWidget(String tourId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('tours').doc(tourId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading...');
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Text(tourId);
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final title = (data['title'] ?? tourId).toString();

        return Text(title);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF7FF),
      appBar: AppBar(
        title: const Text('Upcoming Bookings'),
        backgroundColor: const Color(0xFF79D5FF),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<BookingPreview>>(
        stream: upcomingGuideBookingsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final bookings = snapshot.data ?? [];
          if (bookings.isEmpty) {
            return const Center(child: Text('No upcoming bookings.'));
          }

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];

              return ListTile(
                title: _tourTitleWidget(booking.tourid),
                subtitle: Text(booking.subtitle),
                trailing: Text(booking.dateTime),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          GuideDetailBookingsPage(bookingId: booking.id),
                    ),
                  );
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
  final String tourid;
  final String subtitle;
  final String dateTime;

  const BookingPreview(this.id, this.tourid, this.subtitle, this.dateTime);
}
