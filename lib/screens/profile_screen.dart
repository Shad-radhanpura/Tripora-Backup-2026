import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/app_firebase.dart';
import '../services/appearance_settings.dart';
import '../services/favourites_store.dart';
import '../services/firestore_service.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';
import 'experiences_page.dart';
import 'emergency_help_page.dart';
import 'favourites_screen.dart';
import 'journal_pages.dart';
import 'my_bookings_screen.dart';
import 'my_trips_screen.dart';
import 'settings_page.dart';
import 'support_page.dart';
import 'travel_chat_board.dart';
import 'travel_services_page.dart';

/// Profile tab. Sections, top to bottom: personal information, trips and
/// bookings, favourites, travel experiences, feedback and issues, appearance,
/// help and support, then sign out.
class ProfileView extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfileView({super.key, required this.onLogout});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  User? _user;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _profile;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _trips;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _bookings;

  @override
  void initState() {
    super.initState();
    _user = AppFirebase.auth.currentUser;
    final uid = _user?.uid;
    if (uid != null) {
      _profile = FirestoreService.userDocStream(uid);
      _trips = FirestoreService.userTripsStream(uid);
      _bookings = FirestoreService.userBookingsStream(uid);
    }
  }

  Future<void> _edit(Map<String, dynamic> data) async {
    final user = _user;
    if (user == null) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _EditProfileDialog(user: user, data: data),
    );
    if (saved == true && mounted) {
      showAppMessage(context, 'Profile updated.');
    }
  }

  Future<void> _resetPassword() async {
    final email = _user?.email;
    if (email == null || email.isEmpty) return;
    try {
      await AppFirebase.auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      showAppMessage(context, 'Password reset email sent to $email.');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      showAppMessage(
        context,
        'Could not send reset email (${e.code}).',
        error: true,
      );
    }
  }

  void _openFavourites() {
    SafeNav.push(
      context,
      Builder(
        builder: (pageContext) => Scaffold(
          backgroundColor: pageContext.palette.background,
          appBar: AppBar(title: const Text('Favourites')),
          body: FavouritesView(onExplore: () => Navigator.pop(pageContext)),
        ),
      ),
    );
  }

  void _openMyTrips() {
    SafeNav.push(
      context,
      Builder(
        builder: (pageContext) => Scaffold(
          backgroundColor: pageContext.palette.background,
          appBar: AppBar(title: const Text('My trips')),
          body: MyTripsView(onExplore: () => Navigator.pop(pageContext)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final profile = _profile;
    if (user == null || profile == null) {
      return const EmptyState(
        icon: Icons.lock_outline,
        title: 'Not signed in',
        message: 'Log in again to see your profile.',
      );
    }

    final palette = context.palette;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: profile,
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? const <String, dynamic>{};
        final name = (data['name'] ?? user.displayName ?? '').toString().trim();
        final phone = (data['phone'] ?? '').toString();
        final city = (data['homeCity'] ?? '').toString();
        final email = user.email ?? data['email']?.toString() ?? '';

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    child: Text(
                      (name.isNotEmpty ? name : email).isEmpty
                          ? '?'
                          : (name.isNotEmpty ? name : email)[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? 'Traveller' : name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          email,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('edit-profile'),
                    tooltip: 'Edit profile',
                    onPressed: () => _edit(data),
                    icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            if (snapshot.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  describeFirestoreError(snapshot.error),
                  style: TextStyle(color: palette.danger),
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _CountTile(label: 'Trips', stream: _trips),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ListenableBuilder(
                    listenable: FavouritesStore.instance,
                    builder: (_, _) => _StatBox(
                      label: 'Favourites',
                      value: '${FavouritesStore.instance.ids.length}',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CountTile(label: 'Bookings', stream: _bookings),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _SectionTitle('Personal information'),
            _Card(
              children: [
                _InfoRow(
                  Icons.phone_outlined,
                  'Mobile',
                  phone.isEmpty ? 'Not added' : phone,
                ),
                _InfoRow(
                  Icons.location_city_outlined,
                  'Home city',
                  city.isEmpty ? 'Not added' : city,
                ),
                _MenuRow(
                  Icons.lock_reset_rounded,
                  'Send password reset email',
                  _resetPassword,
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _SectionTitle('My trips & bookings'),
            _Card(
              children: [
                _MenuRow(
                  Icons.luggage_rounded,
                  'My trips',
                  _openMyTrips,
                  key: const Key('profile-my-trips'),
                ),
                _MenuRow(
                  Icons.receipt_long_rounded,
                  'My bookings',
                  () => SafeNav.push(context, const MyBookingsScreen()),
                ),
                _MenuRow(
                  Icons.confirmation_number_outlined,
                  'Hotels, flights, trains & buses',
                  () => SafeNav.push(context, const TravelServicesPage()),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _SectionTitle('My favourites'),
            _Card(
              children: [
                _MenuRow(
                  Icons.favorite_rounded,
                  'Saved destinations',
                  _openFavourites,
                  color: palette.pink,
                  key: const Key('profile-favourites'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _SectionTitle('My travel experiences'),
            _Card(
              children: [
                _MenuRow(
                  Icons.auto_stories_rounded,
                  'Write and manage experiences',
                  () => SafeNav.push(context, const MyExperiencesPage()),
                  subtitle: 'Share a trip, and edit or delete your own',
                  key: const Key('profile-experiences'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _SectionTitle('My travel journal'),
            _Card(
              children: [
                _MenuRow(
                  Icons.menu_book_rounded,
                  'Journal and travel calendar',
                  () => SafeNav.push(context, const JournalPage()),
                  subtitle: 'Private entries, expenses and your dates',
                  key: const Key('profile-journal'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _SectionTitle('My feedback & issues'),
            _Card(
              children: [
                _MenuRow(
                  Icons.feedback_rounded,
                  'Track reports and replies',
                  () => SafeNav.push(context, const MyFeedbackPage()),
                  subtitle: "Reports you sent, their status and the team's replies",
                  key: const Key('profile-feedback'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _SectionTitle('Appearance and dark mode'),
            _Card(
              children: [
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: AppearanceSettings.themeMode,
                  builder: (context, mode, _) => _MenuRow(
                    Icons.dark_mode_rounded,
                    'Appearance',
                    () => SafeNav.push(context, const SettingsPage()),
                    subtitle: 'Currently: ${AppearanceSettings.label(mode)}',
                    key: const Key('profile-appearance'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _SectionTitle('Help and support'),
            _Card(
              children: [
                _MenuRow(
                  Icons.support_agent_rounded,
                  'Help & support',
                  () => SafeNav.push(context, const SupportPage()),
                  subtitle: 'Report a bug, suggest a feature or ask for help',
                  key: const Key('profile-help'),
                ),
                _MenuRow(
                  Icons.health_and_safety_rounded,
                  'Emergency help',
                  () => SafeNav.push(context, const EmergencyHelpPage()),
                  subtitle: 'Police, ambulance, fire and helplines',
                  color: palette.danger,
                  key: const Key('profile-emergency'),
                ),
                _MenuRow(
                  Icons.forum_rounded,
                  'Travel community',
                  () => SafeNav.push(context, const TravelChatBoard()),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _Card(
              children: [
                _MenuRow(
                  Icons.logout_rounded,
                  'Sign out',
                  widget.onLogout,
                  color: palette.danger,
                  key: const Key('profile-sign-out'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: context.palette.text,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  final String label;
  final Stream<QuerySnapshot<Map<String, dynamic>>>? stream;

  const _CountTile({required this.label, required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) => _StatBox(
        label: label,
        value: snapshot.hasError
            ? '!'
            : snapshot.hasData
            ? '${snapshot.data!.size}'
            : '…',
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: palette.blue,
            ),
          ),
          Text(label, style: TextStyle(color: palette.muted)),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;

  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: context.palette.border),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListTile(
      leading: Icon(icon, color: palette.blue),
      title: Text(
        label,
        style: TextStyle(color: palette.muted, fontSize: 12.5),
      ),
      subtitle: Text(
        value,
        style: TextStyle(color: palette.text, fontSize: 15),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final String? subtitle;

  const _MenuRow(
    this.icon,
    this.label,
    this.onTap, {
    this.color,
    this.subtitle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListTile(
      leading: Icon(icon, color: color ?? palette.blue),
      title: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w700, color: color ?? palette.text),
      ),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: TextStyle(color: palette.muted, fontSize: 12.5)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final User user;
  final Map<String, dynamic> data;

  const _EditProfileDialog({required this.user, required this.data});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: (widget.data['name'] ?? widget.user.displayName ?? '').toString(),
  );
  late final _phone = TextEditingController(
    text: (widget.data['phone'] ?? '').toString(),
  );
  late final _city = TextEditingController(
    text: (widget.data['homeCity'] ?? '').toString(),
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final name = _name.text.trim();
      await FirestoreService.updateProfile(
        uid: widget.user.uid,
        name: name,
        phone: _phone.text.trim(),
        homeCity: _city.text.trim(),
      ).timeout(const Duration(seconds: 15));
      try {
        await widget.user.updateDisplayName(name);
      } catch (e) {
        debugPrint('Display name update failed: $e');
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = describeFirestoreError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit profile'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('profile-name'),
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? 'Enter your name' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile (optional)'),
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                if (digits.isEmpty) return null;
                return digits.length < 10 || digits.length > 13
                    ? 'Enter a valid mobile number'
                    : null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _city,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Home city (optional)',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: context.palette.danger)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('save-profile'),
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save'),
        ),
      ],
    );
  }
}
