import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


// Import theo cấu trúc hiện tại của chủ nhân
import 'user_tour_search_page.dart';
import 'user_tour_detail_page.dart';
import 'user_guide_detail_page.dart';
import 'user_booking_history_page.dart';
import '../profile/user_profile_page.dart';

import '../guide/guide_home_page.dart';


class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int _tab = 0;

  User? get _user => FirebaseAuth.instance.currentUser;
  bool _guideMode = false;

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Chưa đăng nhập")),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(body: Center(child: Text("Lỗi load user: ${snap.error}")));
        }
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final data = snap.data!.data() ?? {};
        final fullName = (data['fullName'] ?? user.displayName ?? user.email ?? "User").toString();
        final address = (data['address'] ?? "District 3, HCM city").toString();
        final isGuide = (data['isGuide'] ?? false) == true;


        return Scaffold(
          backgroundColor: const Color(0xFFF6FAFF),
          body: IndexedStack(
          index: _tab,
          children: [
               _HomeTab(
                fullName: fullName,
                address: address,
                isGuide: isGuide,
                onLogout: _logout,
                guideMode: _guideMode,
                onGuideModeChanged: (v) => setState(() => _guideMode = v),
                onOpenTourSearch: () => setState(() => _tab = 1),

                
                onOpenBookingHistory: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const UserBookingHistoryPage()));
                },
                onSwitchMode: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GuideHomePage()),
                  );
                },
            ),

           UserTourSearchPage(
              onBackToHomeTab: () => setState(() => _tab = 0),
            ),
            const ProfilePage(),
          ],
        ),

          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _tab,
            onTap: (i) => setState(() => _tab = i),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF6C63FF),
            unselectedItemColor: Colors.black54,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
              BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: "Tours"),
              BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profile"),
            ],
          ),
        );
      },
    );
  }
}

class _HomeTab extends StatelessWidget {
  final String fullName;
  final String address;
  final bool isGuide;
  final VoidCallback onLogout;
  final bool guideMode;

  final VoidCallback onOpenTourSearch;
  final VoidCallback onOpenBookingHistory;
  final VoidCallback onSwitchMode;
  final ValueChanged<bool> onGuideModeChanged;


  const _HomeTab({
    required this.fullName,
    required this.address,
    required this.isGuide,
    required this.onLogout,
    required this.onOpenTourSearch,
    required this.onOpenBookingHistory,
    required this.onSwitchMode,
    required this.guideMode,
    required this.onGuideModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _TopHeader(
            userName: fullName,
            isGuide: isGuide,
            guideMode: guideMode,
            onGuideModeChanged: onGuideModeChanged,
            onSwitchMode: onSwitchMode,
          ),

        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _SearchBar(
              onTap: onOpenTourSearch,
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _QuickActions(
              onTours: onOpenTourSearch,
              onHistory: onOpenBookingHistory,
            ),

          ),
        ),

        // ===== Featured Tours (Horizontal) =====
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: _SectionTitle(title: "Featured Tours", actionText: "See all", onAction: onOpenTourSearch),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 185,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
  // 1) Lấy guide đang hoạt động
  stream: FirebaseFirestore.instance
      .collection('guides')
      .where('isActive', isEqualTo: true)
      .snapshots(),
  builder: (context, guideSnap) {
    if (guideSnap.hasError) {
      return _HorizontalMessage(text: "Lỗi tải guides: ${guideSnap.error}");
    }
    if (!guideSnap.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final activeGuideIds = guideSnap.data!.docs.map((d) => d.id).toSet();
    if (activeGuideIds.isEmpty) {
      return const _HorizontalMessage(text: "Hiện không có hướng dẫn viên đang hoạt động.");
    }

    // 2) Lấy tours rồi lọc theo guideId thuộc activeGuideIds
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('tours')
            .orderBy('createdAt', descending: true)
            // tăng limit để sau khi lọc vẫn còn đủ item hiển thị
            .limit(30)
            .snapshots(),
        builder: (context, tourSnap) {
          if (tourSnap.hasError) {
            return _HorizontalMessage(text: "Lỗi tải tours: ${tourSnap.error}");
          }
          if (!tourSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = tourSnap.data!.docs;

          // tour phải có guideId và guide đó phải isActive=true
          final filtered = allDocs.where((doc) {
            final data = doc.data();
            final guideId = (data['guideId'] ?? '').toString();
            return guideId.isNotEmpty && activeGuideIds.contains(guideId);
          }).take(10).toList();

          if (filtered.isEmpty) {
            return const _HorizontalMessage(
              text: "Không có tour nào từ hướng dẫn viên đang hoạt động.",
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            scrollDirection: Axis.horizontal,
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final doc = filtered[i];
              final data = doc.data();

              return _TourCard(
                title: (data['title'] ?? 'Tour').toString(),
                subtitle: (data['city'] ?? '').toString(),
                price: _asInt(data['price']),
                durationHours: _asInt(data['durationHours']),
                imageUrl: (data['imageUrl'] ?? '').toString(),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserTourDetailPage(tourId: doc.id),
                    ),
                  );
                },
              );
            },
          );
        },
      );
    },
  ),

          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: _SectionTitle(title: "Top Guides", actionText: "", onAction: () {}),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 165,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                .collection('guides')
                .where('isActive', isEqualTo: true)
                .limit(10)
                .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return _HorizontalMessage(text: "Lỗi tải guides: ${snap.error}");
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  // Nếu chưa có guides collection thì vẫn không crash
                  return const _HorizontalMessage(text: "Chưa có guide nào (collection: guides).");
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  scrollDirection: Axis.horizontal,
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data();

                    final name = (data['displayName'] ?? data['fullName'] ?? 'Guide').toString();
                    final bio = (data['bio'] ?? '').toString();
                    final ratingAvg = _asDouble(data['ratingAvg']);
                    final ratingCount = _asInt(data['ratingCount']);
                    final pricePerHour = _asInt(data['pricePerHour']);
                    final avatarUrl = (data['avatarUrl'] ?? '').toString();

                    return _GuideCard(
                      name: name,
                      bio: bio,
                      avatarUrl: avatarUrl,
                      ratingAvg: ratingAvg,
                      ratingCount: ratingCount,
                      pricePerHour: pricePerHour,
                      onTap: () {
                        // ✅ SỬA constructor ở đây nếu file detail của chủ nhân khác
                        Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => UserGuideDetailPage(guideKey: doc.id)),
                      );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),

        // ===== HOT DEALS (Vertical list) =====
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFB7F0E8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  "HOT DEALS",
                  style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.6),
                ),
              ),
            ),
          ),
        ),

        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('tours')
              .orderBy('createdAt', descending: true)
              .limit(20)
              .snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                  child: Text("Lỗi tải tours: ${snap.error}"),
                ),
              );
            }
            if (!snap.hasData) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 18),
                  child: Text("Chưa có tour nào để hiển thị."),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              sliver: SliverList.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final data = doc.data();

                  final title = (data['title'] ?? 'Tour').toString();
                  final city = (data['city'] ?? '').toString();
                  final price = _asInt(data['price']);
                  final duration = _asInt(data['durationHours']);

                  return _DealTile(
                    title: title,
                    subtitle: "$city · ${duration}h · ${_money(price)}",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserTourDetailPage(tourId: doc.id),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

// ===== UI blocks (functional) =====

class _TopHeader extends StatelessWidget {
  final String userName;
  final bool isGuide;
  final VoidCallback onSwitchMode;
  final bool guideMode;
  final ValueChanged<bool> onGuideModeChanged;

  const _TopHeader({
    required this.userName,
    required this.isGuide,
    required this.onSwitchMode,
    required this.guideMode,
    required this.onGuideModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topPad + 14, 16, 14),
      color: const Color(0xFF86D9FF), // ✅ xanh nhạt như ảnh
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "RoamSG",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Your profile",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          if (isGuide)
            InkWell(
              onTap: onSwitchMode,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.35)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "Guide",
                      style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}



class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(blurRadius: 18, color: Color(0x14000000), offset: Offset(0, 8)),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: Colors.black54),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Search tour, place, guide...",
                style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onTours;
  final VoidCallback onHistory;

  const _QuickActions({
    required this.onTours,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.map_rounded,
            title: "Tours",
            subtitle: "Search & book",
            onTap: onTours,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.receipt_long_rounded,
            title: "History",
            subtitle: "Your bookings",
            onTap: onHistory,
          ),
        ),
      ],
    );
  }
}


class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(blurRadius: 14, color: Color(0x14000000), offset: Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF4C7DFF)),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback onAction;

  const _SectionTitle({
    required this.title,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const Spacer(),
        if (actionText.isNotEmpty)
          InkWell(
            onTap: onAction,
            child: Row(
              children: [
                Text(actionText, style: const TextStyle(color: Color(0xFF4C7DFF), fontWeight: FontWeight.w800)),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, color: Color(0xFF4C7DFF)),
              ],
            ),
          ),
      ],
    );
  }
}


class _HorizontalMessage extends StatelessWidget {
  final String text;
  const _HorizontalMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _TourCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int price;
  final int durationHours;
  final String imageUrl;
  final VoidCallback onTap;

  const _TourCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.durationHours,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 270,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(blurRadius: 14, color: Color(0x14000000), offset: Offset(0, 6))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 88,
                height: 88,
                child: imageUrl.isEmpty
                    ? Container(
                        color: const Color(0xFFE9F7FF),
                        child: const Icon(Icons.image, color: Color(0xFF4C7DFF)),
                      )
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFE9F7FF),
                          child: const Icon(Icons.broken_image, color: Color(0xFF4C7DFF)),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text("$subtitle · ${durationHours}h",
                      style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F7FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _money(price),
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF4C7DFF)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  final String name;
  final String bio;
  final String avatarUrl;
  final double ratingAvg;
  final int ratingCount;
  final int pricePerHour;
  final VoidCallback onTap;

  const _GuideCard({
    required this.name,
    required this.bio,
    required this.avatarUrl,
    required this.ratingAvg,
    required this.ratingCount,
    required this.pricePerHour,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 270,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(blurRadius: 14, color: Color(0x14000000), offset: Offset(0, 6))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 72,
                height: 72,
                child: avatarUrl.isEmpty
                    ? Container(
                        color: const Color(0xFFE9F7FF),
                        child: const Icon(Icons.person, color: Color(0xFF4C7DFF)),
                      )
                    : Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFE9F7FF),
                          child: const Icon(Icons.person, color: Color(0xFF4C7DFF)),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(bio.isEmpty ? "Local guide" : bio,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Text(
                        ratingAvg <= 0 ? "New" : ratingAvg.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(width: 6),
                      Text("($ratingCount)", style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Text(
                        pricePerHour <= 0 ? "" : "${_money(pricePerHour)}/h",
                        style: const TextStyle(color: Color(0xFF4C7DFF), fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DealTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DealTile({required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(blurRadius: 14, color: Color(0x14000000), offset: Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFE9F7FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.tour_rounded, color: Color(0xFF6C63FF)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

// ===== Helpers =====

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is num) return v.toInt();
  return int.tryParse((v ?? '0').toString()) ?? 0;
}

double _asDouble(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is num) return v.toDouble();
  return double.tryParse((v ?? '0').toString()) ?? 0;
}

String _money(int vnd) {
  final s = vnd.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final left = s.length - i;
    buf.write(s[i]);
    if (left > 1 && left % 3 == 1) buf.write('.');
  }
  return "${buf.toString()}đ";
}
