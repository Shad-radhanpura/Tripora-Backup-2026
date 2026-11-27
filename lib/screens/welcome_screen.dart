
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/destinations.dart';
import '../models/destination.dart';
import '../models/saved_trip.dart';
import '../services/firestore_service.dart';
import 'explore_places_page.dart';
import '../services/favourites_store.dart';
import '../services/package_store.dart';
import '../services/login_page.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';
import '../widgets/destination_card.dart';
import '../widgets/brand/brand_intros.dart';
import '../widgets/destination_image.dart';
import '../widgets/brand/tripora_brand.dart';
import 'destination_details_screen.dart';
import 'emergency_help_page.dart';
import 'favourites_screen.dart';
import 'my_bookings_screen.dart';
import 'my_trips_screen.dart';
import 'packages_screen.dart';
import 'profile_screen.dart';
import 'support_page.dart';
import 'trip_details_screen.dart';
import 'travel_services_page.dart';
import 'travel_tools_page.dart';
import 'travel_chat_board.dart';
import '../services/app_firebase.dart';

/// The User Panel. Three tabs: Explore (destination discovery and the
/// existing planner, services and community entries), My Trips and
/// Favourites.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _tab = 0;
  final Set<int> _visited = {0};

  @override
  void initState() {
    super.initState();
    final uid = AppFirebase.auth.currentUser?.uid;
    if (uid != null) FavouritesStore.instance.start(uid);
  }

  void _goToExplore() => _selectTab(0);

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'Your trips and favourites stay saved in your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    FavouritesStore.instance.stop();
    PackageStore.instance.stop();
    try {
      PostAuthWelcome.clear();
      await AppFirebase.auth.signOut();
    } catch (e) {
      debugPrint('Sign-out failed: $e');
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _selectTab(int index) => setState(() {
        _tab = index;
        _visited.add(index);
      });

  void _openFavourites() {
    SafeNav.push(
      context,
      Builder(
        builder: (pageContext) => Scaffold(
          backgroundColor: context.palette.background,
          appBar: AppBar(title: const Text('Favourites')),
          body: FavouritesView(onExplore: () => Navigator.pop(pageContext)),
        ),
      ),
    );
  }

  Widget _buildTab(int index) {
    // Tabs are created the first time they are opened, so startup does not
    // open every Firestore listener at once.
    if (!_visited.contains(index)) return const SizedBox.shrink();
    return switch (index) {
      0 => _ExploreTab(
          onLogout: _logout,
          onOpenPackages: () => _selectTab(1),
          onOpenFavourites: _openFavourites,
          onOpenMyTrips: () => _selectTab(2),
        ),
      1 => const PackagesView(),
      2 => MyTripsView(onExplore: _goToExplore),
      3 => MyBookingsView(onBrowse: () => _selectTab(1)),
      _ => ProfileView(onLogout: _logout),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: IndexedStack(
              index: _tab,
              children: [for (var i = 0; i < 5; i++) _buildTab(i)],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _selectTab,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded, color: context.palette.blue),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_travel_outlined),
            selectedIcon: Icon(Icons.card_travel_rounded, color: context.palette.blue),
            label: 'Packages',
          ),
          NavigationDestination(
            icon: Icon(Icons.luggage_outlined),
            selectedIcon: Icon(Icons.luggage_rounded, color: context.palette.blue),
            label: 'My Trips',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded, color: context.palette.blue),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: context.palette.blue),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EXPLORE TAB
// ============================================================

class _ExploreTab extends StatefulWidget {
  final VoidCallback onLogout;
  final VoidCallback onOpenPackages;
  final VoidCallback onOpenFavourites;
  final VoidCallback onOpenMyTrips;

  const _ExploreTab({
    required this.onLogout,
    required this.onOpenPackages,
    required this.onOpenFavourites,
    required this.onOpenMyTrips,
  });

  @override
  State<_ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<_ExploreTab> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  String? _category;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _isFiltering => _query.trim().isNotEmpty || _category != null;

  void _clearFilters() {
    _search.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _query = '';
      _category = null;
    });
  }

  void _openDestination(Destination destination) {
    SafeNav.push(context, DestinationDetailsScreen(destination: destination));
  }

  void _planTrip([String? destination]) {
    SafeNav.push(context, TripDetailsScreen(initialDestination: destination));
  }

  String _firstName() {
    final user = AppFirebase.auth.currentUser;
    final name = user?.displayName?.trim();
    if (name != null && name.isNotEmpty) return name.split(' ').first;
    return 'traveller';
  }

  @override
  Widget build(BuildContext context) {
    final results =
        DestinationCatalog.search(query: _query, category: _category);

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverToBoxAdapter(child: _buildHero()),
        SliverToBoxAdapter(child: _buildSearch()),
        SliverToBoxAdapter(child: _buildCategories()),
        if (!_isFiltering) ...[
          SliverToBoxAdapter(child: _buildQuickActions()),
          SliverToBoxAdapter(child: _buildFeatured()),
          SliverToBoxAdapter(child: _buildPlannerActions()),
        ],
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 12),
          sliver: SliverToBoxAdapter(
            child: SectionHeader(
              title: _isFiltering ? 'Results' : 'All destinations',
              subtitle: _isFiltering
                  ? '${results.length} '
                      '${results.length == 1 ? 'destination' : 'destinations'} found'
                  : 'Tap a card for details, or the heart to save it.',
              trailing: _isFiltering
                  ? TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Clear'),
                    )
                  : null,
            ),
          ),
        ),
        if (results.isEmpty)
          SliverToBoxAdapter(child: _buildNoResults())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final destination = results[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DestinationCard(
                      destination: destination,
                      onOpen: () => _openDestination(destination),
                      onPlan: () => _planTrip(destination.name),
                    ),
                  );
                },
                childCount: results.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(bottom: 26),
            child: Center(
              child: Text(
                'TRIPORA  •  DISCOVER MORE, WORRY LESS',
                style: TextStyle(
                  color: Colors.black45,
                  fontSize: 10,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 10, 4),
      child: Row(
        children: [
          const TriporaLogo(height: 36, showWordmark: false),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, ${_firstName()} 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.palette.text,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Where would you like to go next?',
                  style: TextStyle(color: context.palette.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          // Shortcuts in the top bar, so the new tools are visible without
          // scrolling. The same screens are also listed lower down.
          IconButton(
            key: const Key('header-travel-tools'),
            tooltip: 'Travel tools',
            onPressed: () => SafeNav.push(context, const TravelToolsPage()),
            icon: Icon(Icons.handyman_rounded, color: context.palette.teal),
          ),
          IconButton(
            key: const Key('header-emergency'),
            tooltip: 'Emergency help',
            onPressed: () => SafeNav.push(context, const EmergencyHelpPage()),
            icon: Icon(Icons.health_and_safety_rounded, color: context.palette.danger),
          ),
          IconButton(
            key: const Key('header-help'),
            tooltip: 'Help & support',
            onPressed: () => SafeNav.push(context, const SupportPage()),
            icon: Icon(Icons.support_agent_rounded, color: context.palette.blue),
          ),
          IconButton(
            tooltip: 'Favourites',
            onPressed: widget.onOpenFavourites,
            icon: Icon(Icons.favorite_border_rounded,
                color: context.palette.pink),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: widget.onLogout,
            icon: Icon(Icons.logout_rounded, color: context.palette.text),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: LayoutBuilder(
        builder: (context, box) {
          // 16:9 on wide screens, 4:3 on phones, so the photo is not a thin strip.
          final wide = box.maxWidth >= 700;
          final height = box.maxWidth / (wide ? 16 / 9 : 4 / 3);
          return ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: SizedBox(
          height: height.clamp(170.0, 420.0),
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // A verified catalogue photo (Lake Pichola, Udaipur). Shows the
              // brand gradient while loading or if the photo is unavailable.
              DestinationImage(url: DestinationCatalog.byId('udaipur')?.imageUrl),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xE6001838)],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TagChip(
                      label: 'EXPLORE THE WORLD',
                      color: Colors.white,
                      icon: Icons.auto_awesome,
                      onDark: true,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Discover Your\nNext Adventure',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Discover places. Plan smarter. Travel better.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
        },
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.softShadow(),
        ),
        child: TextField(
          controller: _search,
          textInputAction: TextInputAction.search,
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            hintText: 'Search destinations, places or interests',
            hintStyle: TextStyle(color: context.palette.muted, fontSize: 13),
            prefixIcon: Icon(Icons.search_rounded, color: context.palette.blue),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _search.clear();
                      setState(() => _query = '');
                    },
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    final options = <String?>[null, ...DestinationCatalog.categories];

    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = options[index];
          final selected = _category == category;
          final color =
              category == null ? context.palette.blue : AppColors.forCategory(category);

          return ChoiceChip(
            selected: selected,
            showCheckmark: false,
            avatar: Icon(
              category == null
                  ? Icons.public_rounded
                  : AppColors.iconForCategory(category),
              size: 16,
              color: selected ? Colors.white : color,
            ),
            label: Text(category ?? 'All'),
            labelStyle: TextStyle(
              color: selected ? Colors.white : context.palette.text,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
            selectedColor: color,
            backgroundColor: context.palette.surface,
            side: BorderSide(color: selected ? color : context.palette.border),
            onSelected: (_) => setState(() => _category = category),
          );
        },
      ),
    );
  }

  Widget _buildFeatured() {
    final featured = DestinationCatalog.featured;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: SectionHeader(
            title: 'Featured destinations',
            subtitle: 'Hand-picked places to start dreaming about.',
          ),
        ),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: featured.length,
            separatorBuilder: (_, _) => const SizedBox(width: 13),
            itemBuilder: (context, index) {
              final destination = featured[index];
              return FeaturedDestinationCard(
                destination: destination,
                onOpen: () => _openDestination(destination),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Four shortcuts to the main features, plus the user's latest saved trip.
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _quickTile(Icons.auto_awesome, 'Plan a Trip', context.palette.coral,
                  () => _planTrip()),
              const SizedBox(width: 10),
              _quickTile(Icons.travel_explore_rounded, 'Explore Places',
                  context.palette.teal,
                  () => SafeNav.push(context, const ExplorePlacesPage())),
              const SizedBox(width: 10),
              _quickTile(Icons.luggage_rounded, 'My Trips', context.palette.blue,
                  widget.onOpenMyTrips),
              const SizedBox(width: 10),
              _quickTile(Icons.favorite_rounded, 'Favourites', context.palette.pink,
                  widget.onOpenFavourites),
            ],
          ),
          const SizedBox(height: 14),
          _buildLatestTrip(),
        ],
      ),
    );
  }

  Widget _quickTile(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.palette.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.palette.text,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The most recent saved trip from Firestore, or an empty state. Nothing
  /// here is invented: only the signed-in user's stored trips are shown.
  Widget _buildLatestTrip() {
    final uid = AppFirebase.auth.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.userTripsStream(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            describeFirestoreError(snapshot.error),
            style: TextStyle(color: context.palette.muted, fontSize: 12),
          );
        }
        if (!snapshot.hasData) return const SizedBox.shrink();
        final trips = snapshot.data!.docs
            .map((doc) => SavedTrip.fromMap(doc.id, doc.data()))
            .toList()
          ..sort(SavedTrip.newestFirst);
        if (trips.isEmpty) return _emptyLatestTrip();
        return _latestTripCard(trips.first);
      },
    );
  }

  Widget _emptyLatestTrip() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.palette.border),
      ),
      child: Row(
        children: [
          Icon(Icons.luggage_outlined, color: context.palette.teal),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No saved trips yet',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 2),
                Text(
                  'Plan a trip and save it to see it here.',
                  style: TextStyle(color: context.palette.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _latestTripCard(SavedTrip trip) {
    final name = DestinationCatalog.matchName(trip.destination)?.name ?? trip.destination;
    return Material(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: widget.onOpenMyTrips,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.palette.border),
          ),
          child: Row(
            children: [
              Icon(Icons.luggage_rounded, color: context.palette.teal),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Latest saved trip',
                      style: TextStyle(color: context.palette.muted, fontSize: 11.5),
                    ),
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    Text(
                      '${trip.daysLabel} · ${trip.budget} · ${trip.interest}',
                      style: TextStyle(color: context.palette.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: context.palette.muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlannerActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'What would you like to do?',
            subtitle: 'Everything you need for your next journey.',
          ),
          const SizedBox(height: 14),
          _ActionCard(
            icon: Icons.auto_awesome,
            title: 'Create My AI Trip',
            subtitle:
                'Get a personalised day-wise itinerary based on your budget and interests.',
            color: context.palette.blue,
            tag: 'AI POWERED',
            onTap: () => _planTrip(),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.card_travel_rounded,
            title: 'Tour Packages',
            subtitle:
                '10, 15, 20 and 30-day packages with hotels, transport and day-wise plans.',
            color: context.palette.orange,
            tag: 'READY-MADE TRIPS',
            onTap: widget.onOpenPackages,
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.confirmation_number_outlined,
            title: 'Explore Travel Services',
            subtitle: 'Search and request hotels, flights, trains, buses and cabs (demo).',
            color: const Color(0xFF0D9B79),
            tag: 'TRAVEL ESSENTIALS',
            onTap: () => SafeNav.push(context, const TravelServicesPage()),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            key: const Key('open-travel-tools'),
            icon: Icons.handyman_rounded,
            title: 'Travel Tools',
            subtitle:
                'Compare destinations, estimate budgets, split expenses, plan luggage and check trip readiness.',
            color: context.palette.teal,
            tag: 'PLANNING',
            onTap: () => SafeNav.push(context, const TravelToolsPage()),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.forum_rounded,
            title: 'Travel Community',
            subtitle:
                'Share travel questions, discover destinations and connect with fellow travellers.',
            color: const Color(0xFF8B45D6),
            tag: 'COMMUNITY',
            onTap: () => SafeNav.push(context, const TravelChatBoard()),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    final typed = _query.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: context.palette.border),
        ),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded,
                size: 46, color: context.palette.muted),
            const SizedBox(height: 10),
            Text(
              'No destinations match',
              style: TextStyle(
                color: context.palette.text,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              typed.isEmpty
                  ? 'Try another interest, or clear the filter.'
                  : 'We don\'t have "$typed" in our featured list yet, '
                      'but Tripora AI can still plan a trip there.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.muted, height: 1.4),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear filters'),
                ),
                if (typed.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () => _planTrip(typed),
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: Text('Plan a trip to $typed'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String tag;
  final VoidCallback onTap;

  const _ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.tag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE7EBF3)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 57,
                height: 57,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, color: color, size: 29),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tag,
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF172B4D),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_ios, color: color, size: 17),
            ],
          ),
        ),
      ),
    );
  }
}
