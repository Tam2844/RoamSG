import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GuideDetailBookingsPage extends StatelessWidget {
  final String bookingId;

  const GuideDetailBookingsPage({super.key, required this.bookingId});

  String _fmtDateTime(DateTime d) => DateFormat('HH:mm dd/MM').format(d);
  String _fmtMoney(int v) => NumberFormat.decimalPattern('vi').format(v);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Detail'),
        backgroundColor: const Color(0xFF79D5FF),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('tour_bookings')
            .doc(bookingId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Booking not found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _rowItem('Booking ID', bookingId),
              _tourInfoWidget((data['tourId'] ?? '').toString()),
              _userInfoWidget((data['userId'] ?? '').toString()),
              _rowItem(
                'Start Date',
                _fmtDateTime((data['startDate'] as Timestamp).toDate()),
              ),
              _rowItem(
                'End Date',
                _fmtDateTime((data['endDate'] as Timestamp).toDate()),
              ),
              _rowItem('Participants', data['participants'].toString()),
              _rowItem('Pickup Point', data['pickupPoint'] ?? 'N/A'),
              _rowItem(
                'Total Price',
                '${_fmtMoney((data['totalPrice'] as num?)?.toInt() ?? 0)}đ',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _rowItem(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(flex: 6, child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _tourInfoWidget(String tourId) {
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
        final description = (data['description'] ?? '').toString();

        return Column(
          children: [
            _rowItem('Tour', title),
            _rowItem('Description', description),
          ],
        );
      },
    );
  }

  Widget _userInfoWidget(String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading...');
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Text(userId);
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final name = (data['fullName'] ?? userId).toString();
        final email = (data['email'] ?? '').toString();
        final phone = (data['phone'] ?? '').toString();
        return Column(
          children: [
            _rowItem('Name', name),
            _rowItem('Email', email),
            _rowItem('Phone', phone),
          ],
        );
      },
    );
  }
}
