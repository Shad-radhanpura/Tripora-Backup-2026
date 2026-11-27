// Brand logo and intro animations: the one-time post-login welcome, the
// launch intro handing over to the app, reduced motion, and logo sizing.
// No Firebase is used; the gates are tested with plain child widgets.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripora/widgets/brand/brand_intros.dart';
import 'package:tripora/widgets/brand/tripora_brand.dart';

Future<void> _pumpFor(WidgetTester tester, Duration total) async {
  var elapsed = Duration.zero;
  const step = Duration(milliseconds: 100);
  while (elapsed < total) {
    await tester.pump(step);
    elapsed += step;
  }
}

Widget _app(Widget home, {bool reduced = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced, size: const Size(412, 915)),
        child: home,
      ),
    );

void main() {
  setUp(PostAuthWelcome.clear);

  group('post-login welcome flag', () {
    test('a request is consumed exactly once', () {
      expect(PostAuthWelcome.consume(), isFalse, reason: 'nothing requested yet');
      PostAuthWelcome.request();
      expect(PostAuthWelcome.consume(), isTrue);
      expect(PostAuthWelcome.consume(), isFalse, reason: 'second check must not replay');
    });

    test('clearing removes a pending request, for example on sign-out', () {
      PostAuthWelcome.request();
      PostAuthWelcome.clear();
      expect(PostAuthWelcome.consume(), isFalse);
    });
  });

  group('launch intro', () {
    testWidgets('shows the brand first, then hands over to the app', (tester) async {
      await tester.pumpWidget(_app(const LaunchIntroGate(child: Text('app home'))));
      await tester.pump();

      expect(find.text(TriporaBrand.wordmark), findsOneWidget);
      expect(find.text('app home'), findsOneWidget, reason: 'the app builds underneath');

      await _pumpFor(tester, TriporaBrand.launchIntro + const Duration(milliseconds: 300));
      expect(find.text(TriporaBrand.wordmark), findsNothing);
      expect(find.text('app home'), findsOneWidget);
    });

    testWidgets('reduced motion shortens the intro', (tester) async {
      await tester.pumpWidget(_app(const LaunchIntroGate(child: Text('app home')), reduced: true));
      await _pumpFor(tester, TriporaBrand.reducedIntro + const Duration(milliseconds: 200));
      expect(find.text(TriporaBrand.wordmark), findsNothing);
      expect(find.text('app home'), findsOneWidget);
    });

    testWidgets('tapping the intro skips it', (tester) async {
      await tester.pumpWidget(_app(const LaunchIntroGate(child: Text('app home'))));
      await tester.pump();
      await tester.tap(find.text(TriporaBrand.tagline));
      await tester.pump();
      expect(find.text(TriporaBrand.tagline), findsNothing);
      expect(find.text('app home'), findsOneWidget);
    });
  });

  group('post-login welcome intro', () {
    testWidgets('plays after a request and then shows the home screen', (tester) async {
      PostAuthWelcome.request();
      await tester.pumpWidget(_app(const PostAuthWelcomeGate(child: Text('home'))));
      await tester.pump();

      expect(find.text('Welcome to ${TriporaBrand.wordmark}'), findsOneWidget);
      await _pumpFor(tester, TriporaBrand.welcomeIntro + const Duration(milliseconds: 300));
      expect(find.text('Welcome to ${TriporaBrand.wordmark}'), findsNothing);
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('without a request (session restore) there is no welcome intro', (tester) async {
      await tester.pumpWidget(_app(const PostAuthWelcomeGate(child: Text('home'))));
      await tester.pump();
      expect(find.text('Welcome to ${TriporaBrand.wordmark}'), findsNothing);
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('rebuilding the screen does not replay the intro', (tester) async {
      PostAuthWelcome.request();
      await tester.pumpWidget(_app(const PostAuthWelcomeGate(child: Text('home'))));
      await _pumpFor(tester, TriporaBrand.welcomeIntro + const Duration(milliseconds: 300));

      // Rebuild with the same route, as happens when auth state notifies again.
      await tester.pumpWidget(_app(const PostAuthWelcomeGate(child: Text('home'))));
      await tester.pump();
      expect(find.text('Welcome to ${TriporaBrand.wordmark}'), findsNothing);
    });

    testWidgets('a second welcome gate does not play twice for one request', (tester) async {
      PostAuthWelcome.request();
      await tester.pumpWidget(_app(const PostAuthWelcomeGate(key: Key('first'), child: Text('first'))));
      await tester.pump();
      // A different key makes a second, separate gate (not a rebuild of the first).
      await tester.pumpWidget(_app(const PostAuthWelcomeGate(key: Key('second'), child: Text('second'))));
      await tester.pump();
      // Only the first gate consumed the request; the second shows no intro.
      expect(find.text('Welcome to ${TriporaBrand.wordmark}'), findsNothing);
      expect(PostAuthWelcome.pendingForTest, isFalse);
    });

    testWidgets('the welcome intro uses a different composition from the launch intro', (tester) async {
      PostAuthWelcome.request();
      await tester.pumpWidget(_app(const PostAuthWelcomeGate(child: Text('home'))));
      await tester.pump();
      expect(find.text(TriporaBrand.wordmark), findsNothing, reason: 'no launch wordmark in the welcome');
      expect(find.text('Your next journey starts here'), findsOneWidget);
    });
  });

  group('logo', () {
    for (final size in [const Size(120, 40), const Size(260, 60), const Size(412, 80)]) {
      testWidgets('renders without overflow at ${size.width.toInt()} px wide', (tester) async {
        await tester.pumpWidget(_app(Scaffold(
          body: Center(
            child: SizedBox(
              width: size.width,
              child: const TriporaLogo(height: 40),
            ),
          ),
        )));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text(TriporaBrand.wordmark), findsOneWidget);
      });
    }

    testWidgets('the dark-background variant renders without overflow', (tester) async {
      await tester.pumpWidget(_app(const Scaffold(
        backgroundColor: TriporaBrand.night,
        body: Center(child: TriporaLogo(height: 56, onDark: true)),
      )));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
