// Emergency help: the verified India numbers, tap-to-call links, copy, sources,
// and what happens when the phone app cannot be opened. The call and link
// openers are replaced with fakes, so no call or browser window starts.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripora/data/emergency_contacts.dart';
import 'package:tripora/screens/emergency_help_page.dart';
import 'package:tripora/theme/theme.dart';

void main() {
  group('directory', () {
    test('India has the verified numbers, unified number first', () {
      final numbers = [for (final c in EmergencyDirectory.india) c.number];
      expect(numbers, ['112', '100', '101', '102', '1091', '1363', '011-1070']);
      expect(EmergencyDirectory.indiaName, 'India');
    });

    test('every number has a service name, a reason and an https source', () {
      for (final contact in EmergencyDirectory.india) {
        expect(contact.service.trim(), isNotEmpty);
        expect(contact.whenToCall.trim(), isNotEmpty, reason: contact.service);
        expect(contact.source.url, startsWith('https://'), reason: contact.service);
      }
    });

    test('dial digits drop hyphens', () {
      final disaster = EmergencyDirectory.india.last;
      expect(disaster.dialDigits, '0111070');
      expect(EmergencyDirectory.india.first.dialDigits, '112');
    });

    test('the international note says numbers differ by country', () {
      expect(EmergencyDirectory.internationalNote, contains('differ from country to country'));
      expect(EmergencyDirectory.internationalNote, contains('112 does not work everywhere'));
    });

    test('the check date is recorded', () {
      expect(EmergencyDirectory.checkedOn, '17 October 2026');
    });
  });

  group('screen', () {
    Widget app(UriOpener opener) => MaterialApp(
      theme: TriporaTheme.lightTheme,
      home: EmergencyHelpPage(opener: opener),
    );

    void useTallScreen(WidgetTester tester) {
      tester.view.physicalSize = const Size(900, 4200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    testWidgets('shows India, each number, and the international note', (tester) async {
      useTallScreen(tester);
      await tester.pumpWidget(app((_) async => true));
      await tester.pump();

      expect(find.textContaining('Numbers for India'), findsOneWidget);
      for (final contact in EmergencyDirectory.india) {
        expect(find.text(contact.number), findsOneWidget, reason: contact.number);
        expect(find.byKey(Key('call-${contact.dialDigits}')), findsWidgets, reason: contact.number);
      }
      expect(find.byKey(const Key('emergency-international-note')), findsOneWidget);
      expect(find.textContaining('Travelling outside India?'), findsOneWidget);
    });

    testWidgets('Call 112 at the top opens the dialler with tel:112', (tester) async {
      useTallScreen(tester);
      final opened = <Uri>[];
      await tester.pumpWidget(app((uri) async {
        opened.add(uri);
        return true;
      }));
      await tester.pump();

      await tester.tap(find.byKey(const Key('emergency-top-call')));
      await tester.pump();

      expect(opened.map((u) => u.toString()), ['tel:112']);
    });

    testWidgets('each number has its own call link, using digits only', (tester) async {
      useTallScreen(tester);
      final opened = <Uri>[];
      await tester.pumpWidget(app((uri) async {
        opened.add(uri);
        return true;
      }));
      await tester.pump();

      await tester.tap(find.byKey(const Key('call-1091')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('call-0111070')));
      await tester.pump();

      expect(opened.map((u) => u.toString()), ['tel:1091', 'tel:0111070']);
    });

    testWidgets('copy puts the number on the clipboard and confirms it', (tester) async {
      useTallScreen(tester);
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await tester.pumpWidget(app((_) async => true));
      await tester.pump();

      await tester.tap(find.byKey(const Key('copy-0111070')));
      await tester.pump();

      expect(copied, '011-1070');
      expect(find.text('Copied 011-1070.'), findsOneWidget);
    });

    testWidgets('a phone that cannot make the call shows the number to dial by hand', (tester) async {
      useTallScreen(tester);
      await tester.pumpWidget(app((_) async => false));
      await tester.pump();

      await tester.tap(find.byKey(const Key('call-100')));
      await tester.pump();

      expect(
        find.text('Could not open the phone app. Dial 100 on your phone instead.'),
        findsOneWidget,
      );
    });

    testWidgets('an error while opening the call is reported the same way', (tester) async {
      useTallScreen(tester);
      await tester.pumpWidget(app((_) async => throw StateError('no dialler')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('call-101')));
      await tester.pump();

      expect(
        find.text('Could not open the phone app. Dial 101 on your phone instead.'),
        findsOneWidget,
      );
    });

    testWidgets('a source opens its official page', (tester) async {
      useTallScreen(tester);
      final opened = <Uri>[];
      await tester.pumpWidget(app((uri) async {
        opened.add(uri);
        return true;
      }));
      await tester.pump();

      await tester.tap(find.byKey(const Key('source-0')));
      await tester.pump();

      expect(opened.single.toString(), EmergencyDirectory.mhaSource.url);
    });
  });
}
