import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/destinations.dart';
import '../data/tour_packages.dart';
import '../models/app_user.dart';
import '../models/saved_trip.dart';
import '../services/firestore_service.dart';
import '../services/package_store.dart';
import '../services/login_page.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';
import 'itinerary_page.dart';
import 'admin_bookings_page.dart';
import 'admin_packages_page.dart';
import 'admin_reviews_page.dart';
import 'admin_support_page.dart';
import 'admin_audit_page.dart';
import 'my_trips_screen.dart' show TripCard, confirmAndDeleteTrip;
import '../services/app_firebase.dart';

/// Tripora Admin Panel.
///
/// Every number and list here comes from live Firestore streams
/// (`users`, `trips`, and the `favourites` collection group). Nothing is
/// hard-coded. Access requires a Firebase sign-in whose UID has an
/// `admins/{uid}` document; the proposed security rules enforce the same
/// check on the server.
class AdminDashboard extends StatefulWidget {
  /// True when the login screen has just confirmed the admin role, so the
  /// panel does not read admins/{uid} a second time. The security rules
  /// still check the role on every admin read and write.
  final bool roleVerified;

  const AdminDashboard({super.key, this.roleVerified = false});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late Future<bool> _isAdmin;

  @override
  void initState() {
    super.initState();
    _isAdmin = widget.roleVerified ? Future.value(true) : _check();
  }

  // Re-checks admins/{uid} (role == "admin") every time the panel opens.
  // Errors are NOT turned into "not an admin"; they are shown separately.
  Future<bool> _check() {
    final uid = AppFirebase.auth.currentUser?.uid;
    if (uid == null) return Future.value(false);
    return FirestoreService.isAdmin(uid).timeout(const Duration(seconds: 12));
  }

  void _retry() => setState(() => _isAdmin = _check());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdmin,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: LoadingState(message: 'Checking admin access…'),
          );
        }
        if (snapshot.hasError) {
          debugPrint('Admin role check failed: ${snapshot.error}');
          return _RoleCheckFailed(error: snapshot.error, onRetry: _retry);
        }
        if (snapshot.data != true) return const _AccessDenied();
        return const _AdminHome();
      },
    );
  }
}

class _RoleCheckFailed extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;

  const _RoleCheckFailed({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: EmptyState(
                  icon: Icons.gpp_maybe_outlined,
                  color: context.palette.orange,
                  title: 'Could not verify admin access',
                  message: describeFirestoreError(error),
                ),
              ),
              Wrap(
                spacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                  OutlinedButton(
                    onPressed: () => _adminLogout(context),
                    child: const Text('Log out'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _adminLogout(BuildContext context) async {
  PackageStore.instance.stop();
  try {
    await AppFirebase.auth.signOut();
  } catch (e) {
    debugPrint('Sign-out failed: $e');
  }
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginPage()),
    (route) => false,
  );
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: EmptyState(
          icon: Icons.admin_panel_settings_outlined,
          color: context.palette.danger,
          title: 'Admin access required',
          message:
              'This account is not an administrator. Admin access needs a '
              'document admins/{your UID} with the field role = "admin", '
              'created in the Firebase Console.',
          actionLabel: 'Back to login',
          onAction: () => _adminLogout(context),
        ),
      ),
    );
  }
}

// ============================================================
// OVERVIEW
// ============================================================

class _AdminHome extends StatefulWidget {
  const _AdminHome();

  @override
  State<_AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<_AdminHome> {
  // Created once so rebuilds do not re-subscribe.
  final _users = FirestoreService.allUsersStream();
  final _trips = FirestoreService.allTripsStream();
  final _favourites = FirestoreService.allFavouritesStream();
  final _admins = FirestoreService.adminsStream();
  final _bookings = FirestoreService.allBookingsStream();
  final _packages = FirestoreService.packagesStream();

  @override
  Widget build(BuildContext context) {
    final email = AppFirebase.auth.currentUser?.email ?? 'Administrator';

    return Scaffold(
      backgroundColor: context.palette.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _header(context, email)),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
                  child: _LiveData(
                    users: _users,
                    trips: _trips,
                    builder: (context, users, trips) =>
                        _overview(context, users, trips),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, String email) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        22,
        MediaQuery.of(context).padding.top + 20,
        12,
        26,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TRIPORA ADMIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Signed in as $email',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('admin-header-support'),
            tooltip: 'Feedback & issues',
            onPressed: () => SafeNav.push(context, const AdminSupportPage()),
            icon: const Icon(Icons.support_agent_rounded, color: Colors.white),
          ),
          IconButton(
            key: const Key('admin-header-audit'),
            tooltip: 'Audit log',
            onPressed: () => SafeNav.push(context, const AdminAuditPage()),
            icon: const Icon(Icons.history_rounded, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: () => _adminLogout(context),
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _overview(
    BuildContext context,
    List<AppUser> users,
    List<SavedTrip> trips,
  ) {
    final now = DateTime.now();
    final activeWeek = users
        .where(
          (u) =>
              u.lastLoginAt != null &&
              now.difference(u.lastLoginAt!).inDays < 7,
        )
        .length;
    final usersById = {for (final u in users) u.uid: u};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Dashboard overview',
          subtitle: 'Live figures from Cloud Firestore.',
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 700 ? 3 : 2;
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: width,
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _admins,
                    builder: (context, snap) => _StatTile(
                      icon: Icons.people_alt_rounded,
                      color: context.palette.blue,
                      value: '${users.length}',
                      label: 'User profiles',
                      note: snap.hasData
                          ? 'incl. ${snap.data!.docs.where((d) => d.data()['role'] == 'admin').length} admin'
                          : 'in Firestore',
                    ),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _StatTile(
                    icon: Icons.luggage_rounded,
                    color: context.palette.teal,
                    value: '${trips.length}',
                    label: 'Saved trips',
                    note: 'all users',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _favourites,
                    builder: (context, snap) => _StatTile(
                      icon: Icons.favorite_rounded,
                      color: context.palette.pink,
                      value: snap.hasError
                          ? '—'
                          : snap.hasData
                          ? '${snap.data!.docs.length}'
                          : '…',
                      label: 'Favourites',
                      note: snap.hasError
                          ? describeFirestoreError(snap.error)
                          : 'destinations liked',
                    ),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _StatTile(
                    icon: Icons.login_rounded,
                    color: context.palette.purple,
                    value: '$activeWeek',
                    label: 'Signed in (7 days)',
                    note: 'tracked from this update',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _bookings,
                    builder: (context, snap) => _StatTile(
                      icon: Icons.receipt_long_rounded,
                      color: context.palette.orange,
                      value: snap.hasError
                          ? '—'
                          : snap.hasData
                          ? '${snap.data!.docs.length}'
                          : '…',
                      label: 'Bookings (demo)',
                      note: snap.hasError
                          ? describeFirestoreError(snap.error)
                          : snap.hasData
                          ? '${snap.data!.docs.where((d) => d.data()['status'] == 'pending').length} awaiting review'
                          : 'loading',
                    ),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _packages,
                    builder: (context, snap) => _StatTile(
                      icon: Icons.card_travel_rounded,
                      color: context.palette.navy,
                      value: snap.hasError
                          ? '—'
                          : snap.hasData
                          ? '${TourPackageCatalog.all.length + snap.data!.docs.where((d) => TourPackageCatalog.byId(d.id) == null).length}'
                          : '…',
                      label: 'Tour packages',
                      note: snap.hasError
                          ? describeFirestoreError(snap.error)
                          : snap.hasData
                          ? '${snap.data!.docs.length} admin edits'
                          : 'loading',
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        const _InfoNote(
          text:
              'User profiles counts documents in the Firestore "users" '
              'collection. Firebase Authentication can hold accounts that '
              'never got a profile document (for example if a write failed); '
              'those appear here after their next login. The exact '
              'Authentication account total is visible in Firebase Console > '
              'Authentication.',
        ),
        const SizedBox(height: 22),
        _ResponsivePair(
          left: _Panel(
            title: 'Trips by budget',
            icon: Icons.account_balance_wallet_outlined,
            child: _BarList(
              counts: _countBy(trips, (t) => _titleCase(t.budget)),
              color: context.palette.green,
              emptyText: 'No trips saved yet.',
            ),
          ),
          right: _Panel(
            title: 'Top destinations',
            icon: Icons.place_outlined,
            child: _BarList(
              counts: _countBy(
                trips,
                (t) =>
                    DestinationCatalog.matchName(t.destination)?.name ??
                    _titleCase(t.destination),
              ),
              color: context.palette.blue,
              limit: 5,
              emptyText: 'No trips saved yet.',
            ),
          ),
        ),
        const SizedBox(height: 14),
        _ResponsivePair(
          left: _Panel(
            title: 'Trips by interest',
            icon: Icons.interests_outlined,
            child: _BarList(
              counts: _countBy(trips, (t) => _titleCase(t.interest)),
              color: context.palette.purple,
              emptyText: 'No trips saved yet.',
            ),
          ),
          right: _Panel(
            title: 'Recent sign-ins',
            icon: Icons.history_rounded,
            child: _RecentUsers(
              users: users.where((u) => u.lastLoginAt != null).toList()
                ..sort(
                  (a, b) => compareNewestFirst(a.lastLoginAt, b.lastLoginAt),
                ),
              dateOf: (u) => u.lastLoginAt,
              emptyText:
                  'No sign-ins recorded yet. Sign-in tracking starts '
                  'with this update; earlier logins were never stored.',
            ),
          ),
        ),
        const SizedBox(height: 14),
        _ResponsivePair(
          left: _Panel(
            title: 'Recent registrations',
            icon: Icons.person_add_alt_rounded,
            child: _RecentUsers(
              users: users.where((u) => u.createdAt != null).toList()
                ..sort((a, b) => compareNewestFirst(a.createdAt, b.createdAt)),
              dateOf: (u) => u.createdAt,
              emptyText: 'No registrations with a recorded date.',
            ),
          ),
          right: _Panel(
            title: 'Recently saved trips',
            icon: Icons.luggage_outlined,
            child: _RecentTrips(
              trips: [...trips]..sort(SavedTrip.newestFirst),
              usersById: usersById,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Administration tools'),
        const SizedBox(height: 12),
        _ToolTile(
          icon: Icons.manage_accounts_rounded,
          title: 'User Management',
          subtitle: 'Search users, see sign-in activity and trip counts',
          color: context.palette.blue,
          onTap: () => SafeNav.push(context, const UserManagementPage()),
        ),
        _ToolTile(
          icon: Icons.map_rounded,
          title: 'Trip Management',
          subtitle: 'Search and filter every saved itinerary',
          color: context.palette.teal,
          onTap: () => SafeNav.push(context, const TripManagementPage()),
        ),
        _ToolTile(
          icon: Icons.receipt_long_rounded,
          title: 'Booking Management',
          subtitle: 'Review demo booking requests and update their status',
          color: context.palette.orange,
          onTap: () => SafeNav.push(context, const AdminBookingsPage()),
        ),
        _ToolTile(
          icon: Icons.card_travel_rounded,
          title: 'Package Management',
          subtitle: 'Add, edit, hide or restore tour packages',
          color: context.palette.purple,
          onTap: () => SafeNav.push(context, const AdminPackagesPage()),
        ),
        _ToolTile(
          icon: Icons.reviews_rounded,
          title: 'Ratings & Reviews',
          subtitle: 'Moderate reviews and see live rating statistics',
          color: context.palette.green,
          onTap: () => SafeNav.push(context, const AdminReviewsPage()),
        ),
        _ToolTile(
          key: const Key('admin-tool-support'),
          icon: Icons.support_agent_rounded,
          title: 'Feedback & Issues',
          subtitle: 'Read traveller requests, change their status and reply',
          color: context.palette.blue,
          onTap: () => SafeNav.push(context, const AdminSupportPage()),
        ),
        _ToolTile(
          key: const Key('admin-tool-audit'),
          icon: Icons.history_rounded,
          title: 'Audit Log',
          subtitle: 'Record of replies and status changes made by admins',
          color: context.palette.navy,
          onTap: () => SafeNav.push(context, const AdminAuditPage()),
        ),
      ],
    );
  }
}

// ============================================================
// SHARED DATA HELPERS
// ============================================================

typedef _DataBuilder =
    Widget Function(
      BuildContext context,
      List<AppUser> users,
      List<SavedTrip> trips,
    );

/// Listens to the users and trips streams and shows loading / error states.
class _LiveData extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> users;
  final Stream<QuerySnapshot<Map<String, dynamic>>> trips;
  final _DataBuilder builder;

  const _LiveData({
    required this.users,
    required this.trips,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: users,
      builder: (context, userSnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: trips,
          builder: (context, tripSnap) {
            final error = userSnap.error ?? tripSnap.error;
            if (error != null) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: ErrorState(
                  error: error,
                  title: 'Could not load admin data',
                ),
              );
            }
            if (!userSnap.hasData || !tripSnap.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: LoadingState(message: 'Loading live data…'),
              );
            }
            final userList = userSnap.data!.docs.map(AppUser.fromDoc).toList();
            final tripList = tripSnap.data!.docs
                .map(SavedTrip.fromDoc)
                .toList();
            return builder(context, userList, tripList);
          },
        );
      },
    );
  }
}

Map<String, int> _countBy(
  List<SavedTrip> trips,
  String Function(SavedTrip trip) keyOf,
) {
  final counts = <String, int>{};
  for (final trip in trips) {
    final key = keyOf(trip);
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return counts;
}

String _titleCase(String value) {
  final text = value.trim();
  if (text.isEmpty) return 'Not specified';
  return text
      .split(RegExp(r'\s+'))
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

Map<String, int> _tripCountsByUser(List<SavedTrip> trips) {
  final counts = <String, int>{};
  for (final trip in trips) {
    counts[trip.userId] = (counts[trip.userId] ?? 0) + 1;
  }
  return counts;
}

void _openTrip(BuildContext context, SavedTrip trip, AppUser? owner) {
  if (!trip.hasItinerary) {
    showAppMessage(context, 'This trip has no stored itinerary.');
    return;
  }
  // Read-only view of the stored itinerary. Nothing is modified.
  SafeNav.push(
    context,
    ItineraryPage(
      itinerary: trip.itinerary,
      destination: trip.destination,
      days: trip.days ?? 0,
      budget: trip.budget,
      interest: trip.interest,
      isSaved: true,
      savedAt: trip.createdAt,
      showPlanAnother: false,
      subtitle:
          'Saved by ${owner?.displayName ?? 'unknown user'} · '
          '${formatDate(trip.createdAt)}',
    ),
  );
}

// ============================================================
// SMALL WIDGETS
// ============================================================

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final String note;

  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.palette.border),
        boxShadow: AppColors.softShadow(color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: context.palette.navy,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: context.palette.text,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            note,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.palette.muted, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  final String text;

  const _InfoNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: context.palette.surfaceTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: context.palette.blue,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: context.palette.text,
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponsivePair extends StatelessWidget {
  final Widget left;
  final Widget right;

  const _ResponsivePair({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return Column(children: [left, const SizedBox(height: 14), right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 14),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Panel({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    // Material (not a coloured Container) so the ListTiles inside show
    // their tap ripple.
    return Material(
      color: context.palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: context.palette.border),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: context.palette.navy),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: context.palette.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _BarList extends StatelessWidget {
  final Map<String, int> counts;
  final Color color;
  final int? limit;
  final String emptyText;

  const _BarList({
    required this.counts,
    required this.color,
    required this.emptyText,
    this.limit,
  });

  @override
  Widget build(BuildContext context) {
    if (counts.isEmpty) {
      return Text(emptyText, style: TextStyle(color: context.palette.muted));
    }

    var entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (limit != null && entries.length > limit!) {
      entries = entries.sublist(0, limit!);
    }
    final max = entries.first.value;

    return Column(
      children: entries
          .map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(
                      e.key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.palette.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: e.value / max,
                        minHeight: 10,
                        color: color,
                        backgroundColor: color.withValues(alpha: 0.10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${e.value}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: context.palette.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _RecentUsers extends StatelessWidget {
  final List<AppUser> users;
  final DateTime? Function(AppUser user) dateOf;
  final String emptyText;

  const _RecentUsers({
    required this.users,
    required this.dateOf,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Text(
        emptyText,
        style: TextStyle(color: context.palette.muted, height: 1.4),
      );
    }
    return Column(
      children: users
          .take(5)
          .map(
            (u) => ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: _Avatar(user: u),
              title: Text(
                u.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                u.email ?? 'No email stored',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                formatDate(dateOf(u)),
                style: TextStyle(color: context.palette.muted, fontSize: 11),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _RecentTrips extends StatelessWidget {
  final List<SavedTrip> trips;
  final Map<String, AppUser> usersById;

  const _RecentTrips({required this.trips, required this.usersById});

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return Text(
        'No trips saved yet.',
        style: TextStyle(color: context.palette.muted),
      );
    }
    return Column(
      children: trips.take(5).map((t) {
        final owner = usersById[t.userId];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: CircleAvatar(
            backgroundColor: context.palette.teal.withValues(alpha: 0.12),
            child: Icon(
              Icons.flight_takeoff_rounded,
              color: context.palette.teal,
              size: 18,
            ),
          ),
          title: Text(
            t.destination,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            '${owner?.displayName ?? 'Unknown user'} · ${t.daysLabel} · '
            '${t.budget}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            formatDate(t.createdAt),
            style: TextStyle(color: context.palette.muted, fontSize: 11),
          ),
          onTap: () => _openTrip(context, t, owner),
        );
      }).toList(),
    );
  }
}

class _Avatar extends StatelessWidget {
  final AppUser user;

  const _Avatar({required this.user});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: context.palette.blue.withValues(alpha: 0.12),
      child: Text(
        user.initials,
        style: TextStyle(
          color: context.palette.blue,
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ToolTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: context.palette.border),
          ),
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onTap: onTap,
        ),
      ),
    );
  }
}

// ============================================================
// USER MANAGEMENT
// ============================================================

enum _UserSort { newest, lastLogin, mostTrips, name }

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final _users = FirestoreService.allUsersStream();
  final _trips = FirestoreService.allTripsStream();
  final _admins = FirestoreService.adminsStream();
  final _search = TextEditingController();

  String _query = '';
  _UserSort _sort = _UserSort.newest;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: context.palette.navy,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      ),
      body: _LiveData(
        users: _users,
        trips: _trips,
        builder: (context, users, trips) {
          final tripCounts = _tripCountsByUser(trips);
          final filtered = users.where((u) => u.matches(_query)).toList()
            ..sort((a, b) {
              switch (_sort) {
                case _UserSort.newest:
                  return compareNewestFirst(a.createdAt, b.createdAt);
                case _UserSort.lastLogin:
                  return compareNewestFirst(a.lastLoginAt, b.lastLoginAt);
                case _UserSort.mostTrips:
                  return (tripCounts[b.uid] ?? 0).compareTo(
                    tripCounts[a.uid] ?? 0,
                  );
                case _UserSort.name:
                  return a.displayName.toLowerCase().compareTo(
                    b.displayName.toLowerCase(),
                  );
              }
            });

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _admins,
            builder: (context, adminSnap) {
              final adminIds =
                  adminSnap.data?.docs
                      .where((d) => d.data()['role'] == 'admin')
                      .map((d) => d.id)
                      .toSet() ??
                  <String>{};

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SearchField(
                    controller: _search,
                    hint: 'Search by name, email or user ID',
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${filtered.length} of ${users.length} users',
                          style: TextStyle(
                            color: context.palette.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      DropdownButton<_UserSort>(
                        value: _sort,
                        underline: const SizedBox.shrink(),
                        onChanged: (v) => setState(() => _sort = v ?? _sort),
                        items: const [
                          DropdownMenuItem(
                            value: _UserSort.newest,
                            child: Text('Newest registered'),
                          ),
                          DropdownMenuItem(
                            value: _UserSort.lastLogin,
                            child: Text('Recent sign-in'),
                          ),
                          DropdownMenuItem(
                            value: _UserSort.mostTrips,
                            child: Text('Most trips'),
                          ),
                          DropdownMenuItem(
                            value: _UserSort.name,
                            child: Text('Name A–Z'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (users.isEmpty)
                    const _ListMessage('No user profiles in Firestore yet.')
                  else if (filtered.isEmpty)
                    const _ListMessage('No users match your search.')
                  else
                    ...filtered.map(
                      (u) => _UserCard(
                        user: u,
                        tripCount: tripCounts[u.uid] ?? 0,
                        isAdmin: adminIds.contains(u.uid),
                        onTap: () => SafeNav.push(
                          context,
                          _UserDetailPage(
                            user: u,
                            trips:
                                trips.where((t) => t.userId == u.uid).toList()
                                  ..sort(SavedTrip.newestFirst),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AppUser user;
  final int tripCount;
  final bool isAdmin;
  final VoidCallback onTap;

  const _UserCard({
    required this.user,
    required this.tripCount,
    required this.isAdmin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.palette.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(user: user),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.palette.text,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 6),
                            TagChip(
                              label: 'ADMIN',
                              color: context.palette.purple,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email ?? 'No email stored',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.palette.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          TagChip(
                            label:
                                '$tripCount '
                                '${tripCount == 1 ? 'trip' : 'trips'}',
                            color: context.palette.teal,
                            icon: Icons.luggage_rounded,
                          ),
                          TagChip(
                            label: 'Joined ${formatDate(user.createdAt)}',
                            color: context.palette.blue,
                            icon: Icons.event_rounded,
                          ),
                          TagChip(
                            label: user.lastLoginAt == null
                                ? 'Last login not recorded'
                                : 'Last login ${formatDate(user.lastLoginAt)}',
                            color: context.palette.purple,
                            icon: Icons.login_rounded,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: context.palette.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserDetailPage extends StatelessWidget {
  final AppUser user;
  final List<SavedTrip> trips;

  const _UserDetailPage({required this.user, required this.trips});

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value, {bool selectable = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: TextStyle(color: context.palette.muted, fontSize: 12.5),
              ),
            ),
            Expanded(
              child: selectable
                  ? SelectableText(
                      value,
                      style: TextStyle(
                        color: context.palette.text,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : Text(
                      value,
                      style: TextStyle(
                        color: context.palette.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: Text(user.displayName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Panel(
            title: 'Profile',
            icon: Icons.person_rounded,
            child: Column(
              children: [
                row('Name', user.name ?? 'Not stored'),
                row('Email', user.email ?? 'Not stored'),
                row('User ID', user.uid, selectable: true),
                row('Registered', formatDate(user.createdAt, withTime: true)),
                row('Last login', formatDate(user.lastLoginAt, withTime: true)),
                row(
                  'Logins recorded',
                  user.loginCount?.toString() ?? 'Not recorded',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionHeader(
            title: 'Saved trips (${trips.length})',
            subtitle: 'Tap a trip to read its stored itinerary.',
          ),
          const SizedBox(height: 10),
          if (trips.isEmpty)
            const _ListMessage('This user has not saved any trips.')
          else
            ...trips.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TripCard(
                  trip: t,
                  onTap: () => _openTrip(context, t, user),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// TRIP MANAGEMENT
// ============================================================

class TripManagementPage extends StatefulWidget {
  const TripManagementPage({super.key});

  @override
  State<TripManagementPage> createState() => _TripManagementPageState();
}

class _TripManagementPageState extends State<TripManagementPage> {
  final _users = FirestoreService.allUsersStream();
  final _trips = FirestoreService.allTripsStream();
  final _search = TextEditingController();

  String _query = '';
  String? _budget;
  String? _interest;

  static const _budgets = ['Budget', 'Moderate', 'Luxury'];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        title: const Text('Trip Management'),
        backgroundColor: context.palette.navy,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      ),
      body: _LiveData(
        users: _users,
        trips: _trips,
        builder: (context, users, trips) {
          final usersById = {for (final u in users) u.uid: u};
          final q = _query.trim().toLowerCase();

          final filtered = trips.where((t) {
            if (_budget != null &&
                t.budget.toLowerCase() != _budget!.toLowerCase()) {
              return false;
            }
            if (_interest != null &&
                t.interest.toLowerCase() != _interest!.toLowerCase()) {
              return false;
            }
            if (q.isEmpty) return true;
            final owner = usersById[t.userId];
            return t.destination.toLowerCase().contains(q) ||
                (owner?.name?.toLowerCase().contains(q) ?? false) ||
                (owner?.email?.toLowerCase().contains(q) ?? false);
          }).toList()..sort(SavedTrip.newestFirst);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SearchField(
                controller: _search,
                hint: 'Search by destination, user name or email',
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final b in [null, ..._budgets])
                    ChoiceChip(
                      label: Text(b ?? 'All budgets'),
                      selected: _budget == b,
                      onSelected: (_) => setState(() => _budget = b),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final i in [null, ...DestinationCatalog.categories])
                    ChoiceChip(
                      label: Text(i ?? 'All interests'),
                      selected: _interest == i,
                      onSelected: (_) => setState(() => _interest = i),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${filtered.length} of ${trips.length} trips',
                style: TextStyle(
                  color: context.palette.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              if (trips.isEmpty)
                const _ListMessage('No trips have been saved yet.')
              else if (filtered.isEmpty)
                const _ListMessage('No trips match these filters.')
              else
                ...filtered.map((t) {
                  final owner = usersById[t.userId];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TripCard(
                      trip: t,
                      ownerLabel:
                          '${owner?.displayName ?? 'Unknown user'}'
                          ' · ${formatDate(t.createdAt)}',
                      onTap: () => _openTrip(context, t, owner),
                      onDelete: () => confirmAndDeleteTrip(context, t),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(Icons.search_rounded, color: context.palette.blue),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
      ),
    );
  }
}

class _ListMessage extends StatelessWidget {
  final String text;

  const _ListMessage(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.palette.border),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: context.palette.muted),
      ),
    );
  }
}
