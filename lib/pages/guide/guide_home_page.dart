import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roamsg/pages/guide/guide_booking_history_page.dart';
import 'package:roamsg/pages/guide/guide_upcoming_bookings_page.dart';

class GuideHomePage extends StatefulWidget {
  const GuideHomePage({super.key});

  @override
  State<GuideHomePage> createState() => _GuideHomePageState();
}

class _GuideHomePageState extends State<GuideHomePage> {
  bool _isOnline = true;

  final String _name = 'Guide';

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
        .collection('guide_bookings')
        .where('guideId', isEqualTo: guideUid)
        .where('date', isGreaterThan: todayStart)
        .orderBy('date')
        .limit(3)
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            final data = doc.data();
            final date = (data['date'] as Timestamp).toDate();
            final price = (data['price'] ?? 0) as int;
            final userId = (data['userId'] ?? '').toString();

            return BookingPreview(
              doc.id,
              "Upcoming",
              "User: ${userId.length > 6 ? userId.substring(0, 6) : userId} · Giá: ${_fmtMoney(price)}đ",
              _fmtDateTime(date),
            );
          }).toList();
        });
  }

  Stream<List<BookingPreview>> historyGuideBookingsStream() {
    final guideUid = FirebaseAuth.instance.currentUser!.uid;
    final todayStart = Timestamp.fromDate(_startOfToday());

    return FirebaseFirestore.instance
        .collection('guide_bookings')
        .where('guideId', isEqualTo: guideUid)
        .where('date', isLessThan: todayStart)
        .orderBy('date', descending: true)
        .limit(3)
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            final data = doc.data();
            final date = (data['date'] as Timestamp).toDate();
            final price = (data['price'] ?? 0) as int;
            final userId = (data['userId'] ?? '').toString();

            return BookingPreview(
              doc.id,
              "Histoy",
              "User: ${userId.length > 6 ? userId.substring(0, 6) : userId} · Giá: ${_fmtMoney(price)}đ",
              _fmtDateTime(date),
            );
          }).toList();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF79D5FF),
        toolbarHeight: 90,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'RoamSG',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
                SizedBox(width: 10),
                Text(
                  'Hello, $_name',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Switch(
            value: _isOnline,
            onChanged: (value) {
              setState(() {
                _isOnline = value;
              });
            },
            activeColor: Colors.green,
            inactiveThumbColor: Colors.red,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Upcoming Bookings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to all bookings page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GuideUpcomingBookingsPage(),
                        ),
                      );
                    },
                    child: Text('See all'),
                  ),
                ],
              ),
              SizedBox(height: 12),
              StreamBuilder<List<BookingPreview>>(
                stream: upcomingGuideBookingsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Lỗi tải bookings: ${snapshot.error}'),
                    );
                  }
                  final bookings = snapshot.data ?? [];
                  if (bookings.isEmpty) {
                    return Center(child: Text('No upcoming bookings'));
                  }
                  return _buildBookingCard(context, bookings);
                },
              ),
              Row(
                children: [
                  Text(
                    'History Bookings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to all bookings page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GuideHistoryBookingsPage(),
                        ),
                      );
                    },
                    child: Text('See all'),
                  ),
                ],
              ),
              SizedBox(height: 12),

              StreamBuilder<List<BookingPreview>>(
                stream: upcomingGuideBookingsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Lỗi tải bookings: ${snapshot.error}'),
                    );
                  }
                  final bookings = snapshot.data ?? [];
                  if (bookings.isEmpty) {
                    return Center(child: Text('No history bookings'));
                  }
                  return _buildBookingCard(context, bookings);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BookingPreview {
  final String _id;
  final String _title;
  final String _subtitle;
  final String _time;

  BookingPreview(this._id, this._title, this._subtitle, this._time);
}

Widget _buildBookingCard(BuildContext context, List<BookingPreview> bookings) {
  return Card(
    color: Colors.white,
    elevation: 2,
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (var booking in bookings) ...[
          ListTile(
            leading: Icon(Icons.event_note_outlined),
            title: Text(
              booking._title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              booking._subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: Text(booking._time),
            onTap: () {
              // Navigate to booking detail page
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (_) => GuideBookingDetailPage(bookingId: booking._id),
              //   ),
              // );
            },
          ),
          Divider(height: 1),
        ],
      ],
    ),
  );
}
