import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tour_booking_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFF),
      body: SafeArea(
        child: IndexedStack(
          index: _tab,
          children: [
            _HomeTab(onLogout: _logout),
            const _PlaceholderTab(title: "Newsfeed"),
            const _PlaceholderTab(title: "Support"),
            const _PlaceholderTab(title: "Chat"),
            const _PlaceholderTab(title: "Profile"),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF6C63FF),
        unselectedItemColor: Colors.black54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.newspaper_rounded), label: "Newsfeed"),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent_rounded), label: "Support"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profile"),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }
}

class _HomeTab extends StatelessWidget {
  final VoidCallback onLogout;
  const _HomeTab({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _TopHeader(
            userName: user?.email?.split("@").first ?? "Guest",
            onLogout: onLogout,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _SearchBar(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _CategoryRow(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: _SectionTitle(title: "Book now", actionText: "Book now"),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: _PromoRow(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: _SectionTitle(title: "Best Places", actionText: "See more"),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 160,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              scrollDirection: Axis.horizontal,
              children: const [
                _PlaceCard(title: "Independence Palace", subtitle: "District 1", icon: Icons.account_balance),
                _PlaceCard(title: "Hoang Phap Pagoda", subtitle: "Hoc Mon", icon: Icons.temple_buddhist),
                _PlaceCard(title: "Ben Thanh Market", subtitle: "District 1", icon: Icons.storefront),
              ],
            ),
          ),
        ),
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
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _FilterChips(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          sliver: SliverList.separated(
            itemCount: 6,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _DealTile(
              title: "Hotel Deal #${i + 1}",
              subtitle: "Up to 50% off · District ${i % 3 + 1}",
            ),
          ),
        ),
      ],
    );
  }
}

class _TopHeader extends StatelessWidget {
  final String userName;
  final VoidCallback onLogout;

  const _TopHeader({
    required this.userName,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF67D4FF), Color(0xFF4C7DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                "RoamSG",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const Spacer(),
              const Icon(Icons.location_on_outlined, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              const Text(
                "District 3, HCM city",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text("Eng", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withOpacity(0.25),
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Welcome back!",
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                tooltip: "Logout",
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(blurRadius: 18, color: Color(0x14000000), offset: Offset(0, 8)),
              ],
            ),
            child: Row(
              children: const [
                Icon(Icons.search, color: Colors.black54),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Search place, hotel, guide...",
                    style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFE9F7FF),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(blurRadius: 18, color: Color(0x14000000), offset: Offset(0, 8)),
            ],
          ),
          child: const Icon(Icons.tune, color: Color(0xFF4C7DFF)),
        ),
      ],
    );
  }
}


class _CategoryRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      ("Guide", Icons.person_pin_circle, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TourBookingPage()),
        );
      }),
      ("Hotels", Icons.apartment_rounded, null),
      ("Car Rental", Icons.directions_car_rounded, null),
      ("Plan Your Trip", Icons.event_note_rounded, null),
      ("More", Icons.more_horiz_rounded, null),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items
          .map((e) => _CategoryItem(title: e.$1, icon: e.$2, onTap: e.$3))
          .toList(),
    );
  }
}


class _CategoryItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap; // thêm

  const _CategoryItem({required this.title, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          //..
        ],
      ),
    );
  }
}



class _SectionTitle extends StatelessWidget {
  final String title;
  final String actionText;
  const _SectionTitle({required this.title, required this.actionText});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const Spacer(),
        Text(actionText, style: const TextStyle(color: Color(0xFF4C7DFF), fontWeight: FontWeight.w800)),
        const SizedBox(width: 6),
        const Icon(Icons.chevron_right, color: Color(0xFF4C7DFF)),
      ],
    );
  }
}

class _PromoRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _PromoCardBig()),
        SizedBox(width: 12),
        Expanded(child: _PromoCardSmall()),
      ],
    );
  }
}

class _PromoCardBig extends StatelessWidget {
  const _PromoCardBig();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(blurRadius: 14, color: Color(0x14000000), offset: Offset(0, 6))],
      ),
      child: Row(
        children: const [
          Expanded(
            child: Text(
              "40%\nOFF\non booking\nyour guide",
              style: TextStyle(fontWeight: FontWeight.w900, height: 1.1),
            ),
          ),
          Icon(Icons.discount_rounded, size: 42, color: Color(0xFF67D4FF)),
        ],
      ),
    );
  }
}

class _PromoCardSmall extends StatelessWidget {
  const _PromoCardSmall();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F7FF),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(blurRadius: 14, color: Color(0x14000000), offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text("Special", style: TextStyle(fontWeight: FontWeight.w900)),
          SizedBox(height: 10),
          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text("Up to\n30% off", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _PlaceCard({required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
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
            child: Icon(icon, color: const Color(0xFF4C7DFF), size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(subtitle, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chips = const ["All", "District 1", "District 2", "District 3", "Hoc Mon"];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final selected = i == 0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFB7F0E8) : Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [BoxShadow(blurRadius: 14, color: Color(0x14000000), offset: Offset(0, 6))],
            ),
            child: Text(chips[i], style: const TextStyle(fontWeight: FontWeight.w800)),
          );
        },
      ),
    );
  }
}

class _DealTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const _DealTile({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: const Icon(Icons.local_offer_rounded, color: Color(0xFF6C63FF)),
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
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String title;
  const _PlaceholderTab({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
    );
  }
}
