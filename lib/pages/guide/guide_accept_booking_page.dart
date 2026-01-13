import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:roamsg/pages/guide/guide_detail_bookings_page.dart';

class GuideAcceptBookingPage extends StatefulWidget {
  const GuideAcceptBookingPage({super.key});

  @override
  State<GuideAcceptBookingPage> createState() => _GuideAcceptBookingPageState();
}

class _GuideAcceptBookingPageState extends State<GuideAcceptBookingPage> {
  String _fmtDateTime(DateTime d) => DateFormat('HH:mm dd/MM').format(d);
  String _fmtMoney(int v) => NumberFormat.decimalPattern('vi').format(v);

  final Set<String> _updatingIds = <String>{};

  Stream<List<BookingPreview>> pendingGuideBookingsStream() {
    final guideUid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('tour_bookings')
        .where('guideId', isEqualTo: guideUid)
        .where('status', isEqualTo: 'waiting')
        .orderBy('createdAt') // cũ nhất trước (cần index)
        .limit(50)
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

  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    if (_updatingIds.contains(bookingId)) return;

    setState(() => _updatingIds.add(bookingId));
    try {
      await FirebaseFirestore.instance
          .collection('tour_bookings')
          .doc(bookingId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật: $newStatus')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật thất bại: $e')),
      );
    } finally {
      if (mounted) setState(() => _updatingIds.remove(bookingId));
    }
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

  Widget _trailingActions(BookingPreview booking) {
    final isLoading = _updatingIds.contains(booking.id);

    if (isLoading) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton(
          onPressed: () => _updateBookingStatus(booking.id, 'rejected'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: const Size(0, 32),
          ),
          child: const Text('Reject'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => _updateBookingStatus(booking.id, 'accepted'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: const Size(0, 32),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Accept'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF7FF),
      appBar: AppBar(
        title: const Text('Pending Bookings'),
        backgroundColor: const Color(0xFF79D5FF),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<BookingPreview>>(
        stream: pendingGuideBookingsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final bookings = snapshot.data ?? [];
          if (bookings.isEmpty) {
            return const Center(child: Text('No pending bookings.'));
          }

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];

              return ListTile(
                title: _tourTitleWidget(booking.tourid),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.subtitle),
                    const SizedBox(height: 2),
                    Text(
                      booking.dateTime,
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
                trailing: _trailingActions(booking),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GuideDetailBookingsPage(bookingId: booking.id),
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
