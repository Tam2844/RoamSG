import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roamsg/pages/guide/guide_accept_booking_page.dart';
import 'package:roamsg/pages/guide/guide_booking_history_page.dart';
import 'package:roamsg/pages/guide/guide_create_tour_page.dart';
import 'package:roamsg/pages/guide/guide_detail_bookings_page.dart';
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
        .collection('tour_bookings')
        .where('guideId', isEqualTo: guideUid)
        .where('status', isEqualTo: 'accepted')
        .where('startDate', isGreaterThanOrEqualTo: todayStart)
        .orderBy('startDate')
        .limit(3)
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
            final userId = (data['userId'] ?? '').toString();

            return BookingPreview(
              doc.id,
              tourId,
              "$participants người · Đón: $pickup · ${_fmtMoney(totalPrice)}đ",
              "${_fmtDateTime(start)} → ${_fmtDateTime(end)}",
            );
          }).toList();
        });
  }

  Stream<List<BookingPreview>> historyGuideBookingsStream() {
    final guideUid = FirebaseAuth.instance.currentUser!.uid;
    final todayStart = Timestamp.fromDate(_startOfToday());

    return FirebaseFirestore.instance
        .collection('tour_bookings')
        .where('guideId', isEqualTo: guideUid)
        .where('status', isEqualTo: 'accepted')
        .where('endDate', isLessThan: todayStart)
        .orderBy('endDate', descending: true)
        .limit(3)
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            final data = doc.data();

            final start = (data['startDate'] as Timestamp?)?.toDate();
            final end = (data['endDate'] as Timestamp?)?.toDate();

            final totalPrice = (data['totalPrice'] as num?)?.toInt() ?? 0;
            final participants = (data['participants'] as num?)?.toInt() ?? 0;
            final pickup = (data['pickupPoint'] ?? '-').toString();

            final tourId = (data['tourId'] ?? '').toString();

            final timeText = (start != null && end != null)
                ? "${_fmtDateTime(start)} → ${_fmtDateTime(end)}"
                : "-";

            return BookingPreview(
              doc.id,
              tourId,
              "$participants người · Đón: $pickup · ${_fmtMoney(totalPrice)}đ",
              timeText,
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

  Widget _buildBookingCard(
    BuildContext context,
    List<BookingPreview> bookings,
  ) {
    return Card(
      color: Colors.white,
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var booking in bookings) ...[
            ListTile(
              leading: Icon(Icons.event_note_outlined),
              title: _tourTitleWidget(booking.tourid),
              subtitle: Text(
                booking.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: Text(booking.time),
              onTap: () {
                // Navigate to booking detail page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        GuideDetailBookingsPage(bookingId: booking.id),
                  ),
                );
              },
            ),
            Divider(height: 1),
          ],
        ],
      ),
    );
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

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GuideCreateTourPage()),
          );
        },
        label: const Text("Tạo tour"),
        backgroundColor: const Color(0xFF79D5FF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,

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
                      //Navigate to all bookings page
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
              SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    'Pending Bookings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GuideAcceptBookingPage(),
                        ),
                      );
                    },
                    child: Text('See all'),
                  ),
                ],
              ),
              SizedBox(height: 12),

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
                stream: historyGuideBookingsStream(),
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
  final String id;
  final String tourid;
  final String subtitle;
  final String time;
  BookingPreview(this.id, this.tourid, this.subtitle, this.time);
}
