import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Stream<List<BookingPreview>> recentGuideBookingsStream() {
    final guideUid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('guide_bookings')
        .where('guideId', isEqualTo: guideUid)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            final data = doc.data();
            final bookedAt = (data['bookedAt'] as Timestamp).toDate();
            final price = (data['price'] ?? 0) as int;
            final userId = (data['userId'] ?? '').toString();

            return BookingPreview(
              "Guide booking",
              "User: ${userId.length > 6 ? userId.substring(0, 6) : userId} · Giá: ${_fmtMoney(price)}đ",
              _fmtDateTime(bookedAt),
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
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 2,
                        ),
                        icon: Icon(Icons.map_outlined),
                        label: Text("My tours"),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 2,
                        ),
                        icon: Icon(Icons.schedule_outlined),
                        label: Text("Schedule"),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                "Recent Bookings",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),

              StreamBuilder<List<BookingPreview>>(
                stream: recentGuideBookingsStream(),
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
                    return Center(child: Text('No recent bookings'));
                  }
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              booking._subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            trailing: Text(booking._time),
                          ),
                          Divider(height: 1),
                        ],
                      ],
                    ),
                  );
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
  final String _title;
  final String _subtitle;
  final String _time;

  BookingPreview(this._title, this._subtitle, this._time);
}
