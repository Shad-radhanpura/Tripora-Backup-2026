// Starts the real app (TriporaApp -> AuthGate -> panels) and checks that each
// new feature can be reached by tapping through the UI, the same way a user
// would. Runs against in-memory fakes of Firebase; nothing touches the live
// project.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripora/main.dart';
import 'package:tripora/screens/profile_screen.dart';
import 'package:tripora/services/experience_store.dart';
import 'package:tripora/services/feedback_outbox.dart';
import 'package:tripora/screens/travel_services_page.dart';
import 'package:tripora/services/app_firebase.dart';
import 'package:tripora/services/favourites_store.dart';
import 'package:tripora/services/package_store.dart';
import 'package:tripora/theme/theme.dart';

const _userUid = 'nav-user';
const _adminUid = 'nav-admin';

/// A phone-sized screen (412 x 915 logical pixels), so that "below the fold"
/// means what it would mean on a real phone.
void _usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(412 * 3, 915 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

/// Pumps frames for a few seconds of fake time so streams and timers finish.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Starts TriporaApp signed in as [uid]. An admin gets an admins/{uid} doc,
/// which AuthGate reads to choose the Admin Panel.
Future<void> _startApp(WidgetTester tester, {required bool admin}) async {
  final uid = admin ? _adminUid : _userUid;
  final db = FakeFirebaseFirestore();
  final auth = MockFirebaseAuth(
    signedIn: true,
    mockUser: MockUser(
      uid: uid,
      email: '$uid@example.com',
      displayName: admin ? 'Admin Person' : 'Test Traveller',
    ),
  );
  AppFirebase.useForTesting(auth: auth, db: db);
  FavouritesStore.instance.stop();
  PackageStore.instance.stop();
  if (admin) {
    await db.collection('admins').doc(uid).set({'role': 'admin'});
  }
  await tester.pumpWidget(const TriporaApp());
  await _settle(tester);
}

/// Scrolls [scrollable] until [finder] is built and visible. Defaults to the
/// first scrollable on screen, which is right when only one screen is open.
Future<void> _scrollTo(
  WidgetTester tester,
  Finder finder, {
  Finder? scrollable,
}) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: scrollable ?? find.byType(Scrollable).first,
  );
  await _settle(tester);
}

void main() {
  testWidgets('traveller reaches Travel Tools from Explore', (tester) async {
    _usePhoneScreen(tester);
    await _startApp(tester, admin: false);

    final card = find.byKey(const Key('open-travel-tools'));
    await _scrollTo(tester, card);
    expect(card, findsOneWidget);

    await tester.tap(card);
    await _settle(tester);
    expect(find.text('Travel tools'), findsOneWidget);

    // One of the tools opens its own screen.
    // The hub now lists more tools, so scroll to the currency converter first.
    await _scrollTo(tester, find.byKey(const Key('tool-currency')));
    await tester.tap(find.byKey(const Key('tool-currency')));
    await _settle(tester);
    expect(find.text('Currency converter'), findsWidgets);
    expect(find.textContaining('not live exchange rates'), findsOneWidget);
  });

  testWidgets('traveller reaches Help & support from Profile', (tester) async {
    _usePhoneScreen(tester);
    await _startApp(tester, admin: false);

    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await _settle(tester);

    // Explore is still built in the tab stack, so scroll the Profile list only.
    final row = find.text('Help & support');
    await _scrollTo(
      tester,
      row,
      scrollable: find.descendant(
        of: find.byType(ProfileView),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(row);
    await _settle(tester);

    expect(find.text('How can we help?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('support-new')));
    await _settle(tester);
    expect(find.text('New support request'), findsOneWidget);
    expect(find.byKey(const Key('support-submit')), findsOneWidget);
  });

  testWidgets('admin reaches Support Tickets and Audit Log from the dashboard', (
    tester,
  ) async {
    _usePhoneScreen(tester);
    await _startApp(tester, admin: true);

    final support = find.byKey(const Key('admin-tool-support'));
    await _scrollTo(tester, support);
    await tester.tap(support);
    await _settle(tester);
    expect(find.text('Feedback & issues'), findsOneWidget);
    expect(find.text('No support requests'), findsOneWidget);

    // Back to the dashboard, then open the audit log.
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await _settle(tester);

    final audit = find.byKey(const Key('admin-tool-audit'));
    await _scrollTo(tester, audit);
    await tester.tap(audit);
    await _settle(tester);
    expect(find.text('Audit log'), findsOneWidget);
    expect(find.text('No admin actions yet'), findsOneWidget);
  });

  testWidgets('hotel comparison works from a hotel search', (tester) async {
    _usePhoneScreen(tester);
    FavouritesStore.instance.stop();
    PackageStore.instance.stop();
    AppFirebase.useForTesting(
      auth: MockFirebaseAuth(signedIn: false),
      db: FakeFirebaseFirestore(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: TriporaTheme.lightTheme,
        home: const TravelServicesPage(initialService: 'Hotels'),
      ),
    );
    await _settle(tester);

    await tester.enterText(find.byKey(const Key('service-to')), 'Goa');
    await tester.tap(find.byKey(const Key('service-search')));
    await _settle(tester);

    // Nothing is compared yet, so the compare bar is not shown.
    expect(find.textContaining('Comparing'), findsNothing);

    await _scrollTo(tester, find.byKey(const Key('hotel-compare-hotel-goa-0')));
    await tester.tap(find.byKey(const Key('hotel-compare-hotel-goa-0')));
    await _settle(tester);
    await _scrollTo(tester, find.byKey(const Key('hotel-compare-hotel-goa-1')));
    await tester.tap(find.byKey(const Key('hotel-compare-hotel-goa-1')));
    await _settle(tester);

    // The compare bar sits above the results, so scroll back up to it.
    await tester.scrollUntilVisible(
      find.textContaining('Comparing 2 of 3'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await _settle(tester);
    expect(find.text('Comparing 2 of 3 hotels'), findsOneWidget);
    await tester.tap(find.byKey(const Key('hotel-compare-open')));
    await _settle(tester);
    expect(find.text('Compare hotels'), findsOneWidget);
    expect(find.text('Total price'), findsOneWidget);
  });

  testWidgets('top-bar shortcuts open Travel tools and Help without scrolling', (
    tester,
  ) async {
    _usePhoneScreen(tester);
    await _startApp(tester, admin: false);

    final tools = find.byKey(const Key('header-travel-tools'));
    final help = find.byKey(const Key('header-help'));
    final screenHeight = tester.view.physicalSize.height / 3.0;
    expect(tester.getRect(tools).bottom, lessThan(screenHeight));
    expect(tester.getRect(help).bottom, lessThan(screenHeight));

    await tester.tap(tools);
    await _settle(tester);
    expect(find.text('Travel tools'), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await _settle(tester);

    await tester.tap(help);
    await _settle(tester);
    expect(find.text('How can we help?'), findsOneWidget);
  });

  testWidgets('admin top-bar shortcuts open Support Tickets and Audit Log', (
    tester,
  ) async {
    _usePhoneScreen(tester);
    await _startApp(tester, admin: true);

    final support = find.byKey(const Key('admin-header-support'));
    final audit = find.byKey(const Key('admin-header-audit'));
    final screenHeight = tester.view.physicalSize.height / 3.0;
    expect(tester.getRect(support).bottom, lessThan(screenHeight));
    expect(tester.getRect(audit).bottom, lessThan(screenHeight));

    await tester.tap(support);
    await _settle(tester);
    expect(find.text('Feedback & issues'), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await _settle(tester);

    await tester.tap(audit);
    await _settle(tester);
    expect(find.text('Audit log'), findsOneWidget);
  });

  testWidgets('home quick action opens Explore Places; latest trip shows its empty state', (
    tester,
  ) async {
    _usePhoneScreen(tester);
    await _startApp(tester, admin: false);

    // A new user has no saved trips, so the card says so instead of showing data.
    expect(find.text('No saved trips yet'), findsOneWidget);
    expect(find.text('Latest saved trip'), findsNothing);

    await tester.tap(find.text('Explore Places'));
    await _settle(tester);
    expect(find.text('Explore places'), findsOneWidget);
  });
  testWidgets('profile lists the new sections and opens the new pages', (tester) async {
    _usePhoneScreen(tester);
    // Device storage for the experience and feedback lists uses an in-memory mock.
    SharedPreferences.setMockInitialValues({});
    // Tall enough that every profile section is on screen, so no scrolling.
    tester.view.physicalSize = const Size(412 * 3, 2600 * 3);
    await _startApp(tester, admin: false);

    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await _settle(tester);

    for (final title in [
      'Personal information',
      'My trips & bookings',
      'My favourites',
      'My travel experiences',
      'My feedback & issues',
      'Appearance and dark mode',
      'Help and support',
    ]) {
      expect(
        find.descendant(of: find.byType(ProfileView), matching: find.text(title)),
        findsOneWidget,
        reason: title,
      );
    }
    expect(find.byKey(const Key('profile-sign-out')), findsOneWidget);

    // My travel experiences opens with its empty state.
    // Device storage is read outside the fake clock, as on a real phone.
    await tester.runAsync(() => ExperienceStore.instance.load());
    await tester.tap(find.byKey(const Key('profile-experiences')));
    await _settle(tester);
    expect(find.text('You have not written an experience yet'), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await _settle(tester);

    // Appearance opens Settings.
    await tester.tap(find.byKey(const Key('profile-appearance')));
    await _settle(tester);
    expect(find.text('Applies across the whole app.'), findsOneWidget);
    expect(find.text('System default'), findsWidgets);
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await _settle(tester);

    // My feedback & issues opens its list, which is empty for a new user.
    await tester.runAsync(() => FeedbackOutbox.instance.load());
    await tester.tap(find.byKey(const Key('profile-feedback')));
    await _settle(tester);
    expect(find.text('No feedback yet'), findsOneWidget);
  });
  testWidgets('emergency help opens from the home top bar and from the profile', (tester) async {
    _usePhoneScreen(tester);
    await _startApp(tester, admin: false);

    // The top-bar icon is visible without scrolling on a phone-sized screen.
    final header = find.byKey(const Key('header-emergency'));
    expect(tester.getRect(header).bottom, lessThan(915));
    await tester.tap(header);
    await _settle(tester);
    expect(find.textContaining('Numbers for India'), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await _settle(tester);

    // Profile lists it in Help and support; make the screen tall enough to see it.
    tester.view.physicalSize = const Size(412 * 3, 2600 * 3);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('profile-emergency')));
    await _settle(tester);
    expect(find.textContaining('Numbers for India'), findsOneWidget);
  });
}
