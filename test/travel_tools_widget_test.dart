import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripora/screens/emergency_help_page.dart';
import 'package:tripora/screens/travel_tools_page.dart';
import 'package:tripora/theme/theme.dart';

Widget _app(Widget home) => MaterialApp(
  theme: TriporaTheme.lightTheme,
  home: home,
);

void main() {
  testWidgets('hub lists every tool and opens the currency converter', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const TravelToolsPage()));

    // The list is lazy, so each card is scrolled into view before checking.
    for (final key in [
      'tool-compare',
      'tool-surprise',
      'tool-budget',
      'tool-split',
      'tool-luggage',
      'tool-currency',
      'tool-readiness',
      'tool-emergency',
    ]) {
      await tester.dragUntilVisible(
        find.byKey(Key(key)),
        find.byType(ListView),
        const Offset(0, -200),
      );
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
    }

    await tester.tap(find.byKey(const Key('tool-currency')));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Currency converter'), findsWidgets);
    expect(find.textContaining('not live exchange rates'), findsOneWidget);
  });

  testWidgets('currency converter shows a sample-rate conversion', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const CurrencyToolPage()));

    // Default is 100 USD to INR.
    expect(
      find.byKey(const Key('currency-result')),
      findsOneWidget,
    );
    expect(
      find.text('100.00 USD ≈ 8350.00 INR'),
      findsOneWidget,
    );
  });

  testWidgets('budget estimate shows the moderate 4-day total', (tester) async {
    await tester.pumpWidget(_app(const BudgetToolPage()));

    // Moderate, 4 days, 1 traveller: 25,520 including the 10% buffer.
    expect(find.text('₹25,520'), findsOneWidget);
    expect(find.text('₹12,000'), findsOneWidget);
  });

  testWidgets('budget estimate rejects an invalid number of days', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const BudgetToolPage()));

    await tester.enterText(find.byKey(const Key('budget-days')), '0');
    await tester.pump();

    expect(
      find.text('Enter between 1 and 60 days, and between 1 and 20 travellers.'),
      findsOneWidget,
    );
    expect(find.text('Estimated total'), findsNothing);
  });

  testWidgets('luggage planner adds up weights and flags nothing when light', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const LuggageToolPage()));

    expect(find.byKey(const Key('luggage-total')), findsOneWidget);
    expect(find.text('0.0 kg of 15 kg'), findsOneWidget);

    await tester.tap(find.byTooltip('Add Cabin bag (empty)'));
    await tester.pump();

    expect(find.text('3.0 kg of 15 kg'), findsOneWidget);
  });

  testWidgets('readiness score reflects checklist and toggles', (tester) async {
    await tester.pumpWidget(_app(const ReadinessToolPage()));

    expect(find.text('Score: 0 / 100'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '7');
    await tester.pump();
    expect(find.text('Score: 60 / 100'), findsOneWidget);

    await tester.tap(find.text('I have saved a day-wise itinerary'));
    await tester.pump();
    await tester.tap(find.text('I have requested a stay or travel service'));
    await tester.pump();
    expect(find.text('Score: 100 / 100'), findsOneWidget);
    expect(find.text('Nothing left. Have a great trip!'), findsOneWidget);
  });

  // The old test required that no number was shown. Emergency numbers are now
  // shown for India, checked against official sources (see emergency_help_test).
  testWidgets('emergency help lists the checked India numbers', (tester) async {
    // Tall enough that the list builds every number.
    tester.view.physicalSize = const Size(900, 4200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const EmergencyHelpPage()));
    await tester.pump();

    for (final number in ['112', '100', '101', '102', '1091', '1363', '011-1070']) {
      expect(find.text(number), findsOneWidget, reason: number);
    }
    expect(find.textContaining('Numbers for India'), findsOneWidget);
    expect(find.byKey(const Key('emergency-international-note')), findsOneWidget);
  });

  testWidgets('compare destinations shows two catalogue places', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const CompareDestinationsPage()));

    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Best time'), findsOneWidget);
    expect(find.text('Manali'), findsWidgets);
    expect(find.text('Goa'), findsWidgets);
  });
}
