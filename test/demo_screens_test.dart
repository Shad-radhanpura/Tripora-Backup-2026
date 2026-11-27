// Widget tests for the demo catalogue, offers, gift cards and nearby services.
// Firebase is replaced by an in-memory fake and storage by an in-memory mock.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripora/data/demo_catalogue.dart';
import 'package:tripora/data/nearby_services.dart';
import 'package:tripora/screens/demo_catalogue_pages.dart';
import 'package:tripora/screens/nearby_services_page.dart';
import 'package:tripora/screens/offers_gift_pages.dart';
import 'package:tripora/services/app_firebase.dart';
import 'package:tripora/services/gift_card_service.dart';
import 'package:tripora/theme/theme.dart';

Widget _app(Widget home) => MaterialApp(theme: TriporaTheme.lightTheme, home: home);

void _tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 4800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void _signIn() {
  AppFirebase.useForTesting(
    auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'demo-user', email: 'demo@example.com')),
    db: FakeFirebaseFirestore(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _signIn();
  });

  testWidgets('catalogue: choosing a group changes the results, and clear filters resets them', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(_app(const DemoCataloguePage()));
    await tester.pump();

    final total = DemoCatalogue.all.length;
    expect(find.text('$total of $total packages'), findsOneWidget);

    await tester.tap(find.byKey(const Key('group-family')));
    await tester.pump();
    final family = DemoCatalogue.all.where((p) => p.groupTypes.contains(TravelGroup.family)).length;
    expect(find.text('$family of $total packages'), findsOneWidget);

    await tester.tap(find.byKey(const Key('catalogue-clear')));
    await tester.pump();
    expect(find.text('$total of $total packages'), findsOneWidget);
  });

  testWidgets('package detail: a departure, a valid coupon, and the preview total', (tester) async {
    _tallScreen(tester);
    final pkg = DemoCatalogue.byId('demo-goa-weekend-escape')!;
    await tester.pumpWidget(_app(DemoPackageDetailPage(packageId: pkg.id)));
    await tester.pump();

    expect(find.byKey(const Key('preview-continue')), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byKey(const Key('preview-continue')));
    expect(button.onPressed, isNull, reason: 'no departure chosen yet');

    await tester.tap(find.textContaining('seats left').first);
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byKey(const Key('preview-continue'))).onPressed, isNotNull);

    await tester.enterText(find.byKey(const Key('coupon-input')), 'demo10');
    await tester.tap(find.byKey(const Key('coupon-apply')));
    await tester.pump();
    expect(find.textContaining('DEMO10 applied'), findsOneWidget);
    expect(find.byKey(const Key('coupon-remove')), findsOneWidget);

    await tester.tap(find.byKey(const Key('coupon-remove')));
    await tester.pump();
    expect(find.textContaining('Coupon removed'), findsOneWidget);
  });

  testWidgets('offers: expired offers are hidden until "Active only" is switched off', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(_app(const OffersPage()));
    await tester.pump();

    expect(find.byKey(const Key('offer-DEMO10')), findsOneWidget);
    expect(find.byKey(const Key('offer-SUMMER50')), findsNothing);

    await tester.tap(find.byKey(const Key('offers-active-only')));
    await tester.pump();
    expect(find.byKey(const Key('offer-SUMMER50')), findsOneWidget);
  });

  testWidgets('gift cards: the four amounts are offered and the demo notice is shown', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(_app(const GiftCardsPage()));
    await tester.pump();

    for (final amount in DemoGiftCards.denominations) {
      expect(find.byKey(Key('gift-amount-$amount')), findsOneWidget);
    }
    expect(find.textContaining('No payment has been taken'), findsWidgets);
    await tester.tap(find.byKey(const Key('gift-amount-5000')));
    await tester.pump();
    expect(find.byKey(const Key('gift-review')), findsOneWidget);
  });

  testWidgets('nearby services: search narrows the records and says so', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(_app(const NearbyServicesPage()));
    await tester.pump();

    final total = NearbyServices.all.length;
    expect(find.textContaining('$total records'), findsWidgets);

    await tester.enterText(find.byKey(const Key('nearby-search')), 'sample hospital 1, jaipur');
    await tester.pump();
    expect(find.textContaining('1 record'), findsOneWidget);
  });
}
