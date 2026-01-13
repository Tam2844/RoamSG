import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roamsg/pages/guide/guide_accept_booking_page.dart';
import 'package:roamsg/pages/guide/guide_booking_history_page.dart';
import 'package:roamsg/pages/guide/guide_create_tour_page.dart';
import 'package:roamsg/pages/guide/guide_detail_bookings_page.dart';
import 'package:roamsg/pages/guide/guide_upcoming_bookings_page.dart';
import 'package:roamsg/pages/user/user_home_page.dart';


class GuideHomePage extends StatefulWidget {
  const GuideHomePage({super.key});

  @override
  State<GuideHomePage> createState() => _GuideHomePageState();
}

class _GuideHomePageState extends State<GuideHomePage> {

  final String _name = 'Guide';
  final Set<String> _updatingIds = <String>{};
  bool _activeToggling = false;



  String _fmtDateTime(DateTime d) => DateFormat('HH:mm dd/MM').format(d);
  String _fmtMoney(int v) => NumberFormat.decimalPattern('vi').format(v);

  DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
  Stream<DocumentSnapshot<Map<String, dynamic>>> _guideDocStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance.collection('guides').doc(uid).snapshots();
  }
  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isInDay(DateTime dt, DateTime dayStart) {
    final dayEnd = dayStart.add(const Duration(days: 1));
    return !dt.isBefore(dayStart) && dt.isBefore(dayEnd);
  }

  Future<void> _showInfoDialog(String title, String message) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmRejectWaitingDialog(int count) async {
    if (!mounted) return false;
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận tắt hoạt động'),
        content: Text(
          'Hôm nay đang có $count đơn ở trạng thái chờ (waiting).\n'
          'Nếu tắt hoạt động, bạn có muốn từ chối (reject) các đơn này không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject & Tắt'),
          ),
        ],
      ),
    );
    return res == true;
  }

  Future<void> _handleGuideActiveToggle(bool newValue, bool currentIsActive) async {
    if (_activeToggling) return;

    // bật lên thì cho bật luôn
    if (newValue == true) {
      setState(() => _activeToggling = true);
      try {
        await _setGuideActive(true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật thất bại: $e')),
        );
      } finally {
        if (mounted) setState(() => _activeToggling = false);
      }
      return;
    }

    // chỉ xử lý khi đang bật và muốn tắt
    if (!currentIsActive) return;

    setState(() => _activeToggling = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final todayStart = _startOfDay(DateTime.now());

      // 1) Check accepted hôm nay => không cho tắt
      final acceptedSnap = await FirebaseFirestore.instance
          .collection('tour_bookings')
          .where('guideId', isEqualTo: uid)
          .where('status', isEqualTo: 'accepted')
          .get();

      final acceptedToday = acceptedSnap.docs.where((d) {
        final ts = d.data()['startDate'];
        if (ts is Timestamp) {
          return _isInDay(ts.toDate(), todayStart);
        }
        return false;
      }).toList();

      if (acceptedToday.isNotEmpty) {
        await _showInfoDialog(
          'Không thể tắt hoạt động',
          'Bạn có ${acceptedToday.length} đơn đã nhận (accepted) bắt đầu trong hôm nay.\n'
          'Vui lòng hoàn tất/đổi lịch trước khi tắt trạng thái hoạt động.',
        );
        return; // không set isActive = false
      }

      // 2) Check waiting hôm nay => hỏi có reject không
      final waitingSnap = await FirebaseFirestore.instance
          .collection('tour_bookings')
          .where('guideId', isEqualTo: uid)
          .where('status', isEqualTo: 'waiting')
          .get();

      final waitingToday = waitingSnap.docs.where((d) {
        final ts = d.data()['startDate'];
        if (ts is Timestamp) {
          return _isInDay(ts.toDate(), todayStart);
        }
        return false;
      }).toList();

      if (waitingToday.isNotEmpty) {
        final ok = await _confirmRejectWaitingDialog(waitingToday.length);
        if (!ok) return; // user bấm Hủy, giữ isActive=true

        // Reject các đơn waiting hôm nay + set isActive=false trong 1 batch
        final batch = FirebaseFirestore.instance.batch();

        for (final doc in waitingToday) {
          batch.update(doc.reference, {
            'status': 'rejected',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        final guideRef = FirebaseFirestore.instance.collection('guides').doc(uid);
        batch.set(
          guideRef,
          {
            'isActive': false,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        await batch.commit();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã reject ${waitingToday.length} đơn và tắt hoạt động.')),
        );
        return;
      }

      // 3) Không có accepted hôm nay + không có waiting hôm nay => tắt bình thường
      await _setGuideActive(false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xử lý tắt hoạt động thất bại: $e')),
      );
    } finally {
      if (mounted) setState(() => _activeToggling = false);
    }
  }

  Future<void> _setGuideActive(bool value) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('guides').doc(uid).set({
      'isActive': value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<BookingPreview>> pendingGuideBookingsStream() {
    final guideUid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('tour_bookings')
        .where('guideId', isEqualTo: guideUid)
        .where('status', isEqualTo: 'waiting')
        .orderBy('createdAt') // cũ nhất trước
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
  
  Widget _buildPendingBookingCard(BuildContext context, List<BookingPreview> bookings) {
    return Card(
      color: Colors.white,
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final booking in bookings) ...[
            ListTile(
              leading: const Icon(Icons.event_note_outlined),
              title: _tourTitleWidget(booking.tourid),

              // Vẫn hiển thị info + time giống “upcoming”, nhưng đưa time xuống subtitle
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    booking.time,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),

              trailing: _updatingIds.contains(booking.id)
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
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
                    ),

              // giữ onTap xem chi tiết (cậu thích bỏ thì xoá đoạn này)
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GuideDetailBookingsPage(bookingId: booking.id),
                  ),
                );
              },
            ),
            const Divider(height: 1),
          ],
        ],
      ),
    );
  }
  Widget _guideActiveBar() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _guideDocStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _statusCard(
            title: 'Trạng thái hoạt động của guide',
            subtitle: 'Đang tải...',
            trailing: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (snap.hasError) {
          return _statusCard(
            title: 'Trạng thái hoạt động của guide',
            subtitle: 'Lỗi tải trạng thái: ${snap.error}',
            trailing: const Icon(Icons.error_outline, color: Colors.red),
          );
        }

        final data = snap.data?.data();
        if (data == null) {
          return _statusCard(
            title: 'Trạng thái hoạt động của guide',
            subtitle: 'Không tìm thấy hồ sơ guide trong collection "guides".',
            trailing: const Icon(Icons.info_outline, color: Colors.orange),
          );
        }

        final isActive = (data['isActive'] ?? false) == true;

        return _statusCard(
          title: 'Trạng thái hoạt động của guide',
          subtitle: isActive
              ? 'Đang bật. Bạn sẽ nhận booking mới.'
              : 'Đang tắt. Bạn tạm dừng nhận booking.',
          trailing: _activeToggling
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Switch(
                value: isActive,
                onChanged: (v) => _handleGuideActiveToggle(v, isActive),
                activeColor: Colors.green,
                inactiveThumbColor: Colors.red,
              ),

                );
              },
            );
          }

  Widget _statusCard({
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  void _backToUserHome() {
    if (!mounted) return;
      Navigator.pop(context); // quay lại route trước (UserHome đang nằm dưới)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: TextButton.icon(
              onPressed: _backToUserHome,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.25),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: const Text(
                'User',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _guideActiveBar(),
              const SizedBox(height: 14),
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
              StreamBuilder<List<BookingPreview>>(
              stream: pendingGuideBookingsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Lỗi tải pending: ${snapshot.error}'));
                  }
                  final bookings = snapshot.data ?? [];
                  if (bookings.isEmpty) {
                    return const Center(child: Text('No pending bookings'));
                  }
                  return _buildPendingBookingCard(context, bookings);
                },
              ),
            const SizedBox(height: 24),

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
