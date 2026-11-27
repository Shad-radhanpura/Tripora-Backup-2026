// Feedback & Support: validation, sending with a fallback to this device, the
// "not sent yet" list, and the admin workflow. Firestore is an in-memory fake;
// the live project and its rules are not touched (rules are tested in
// firestore_rules_test with the emulator).
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripora/models/support_ticket.dart';
import 'package:tripora/screens/admin_support_page.dart';
import 'package:tripora/screens/support_page.dart';
import 'package:tripora/services/app_firebase.dart';
import 'package:tripora/services/feedback_outbox.dart';
import 'package:tripora/services/support_service.dart';
import 'package:tripora/theme/theme.dart';

const _user = 'feedback-user';
const _admin = 'feedback-admin';

Future<void> _failingWriter(Map<String, dynamic> data) async {
  throw StateError('rules deny this write');
}

Future<void> _workingWriter(Map<String, dynamic> data) async {}

/// An outbox that the device refuses to write to.
class _RefusingOutbox extends FeedbackOutbox {
  _RefusingOutbox() : super();

  @override
  Future<void> add(FeedbackDraft draft) async {
    throw StateError('device refused to save');
  }
}

Future<FeedbackOutbox> _outbox() async {
  final prefs = await SharedPreferences.getInstance();
  final outbox = FeedbackOutbox(prefs);
  await outbox.load();
  return outbox;
}

Future<SubmitOutcome> _submitBug(FeedbackOutbox outbox, {Future<void> Function(Map<String, dynamic>)? writer}) {
  return SupportService.submit(
    userId: _user,
    category: 'bug',
    priority: 'normal',
    subject: 'Save button does nothing',
    message: 'Tapping save on a trip does nothing at all.',
    writer: writer ?? _failingWriter,
    outbox: outbox,
  );
}

/// Lets fake timers and fake streams finish.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  // fake_cloud_firestore must be set up before any FieldValue is created,
  // because the first use of FieldValue fixes which implementation is used.
  setUpAll(() {
    FakeFirebaseFirestore();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('validation', () {
    test('new reports use the feedback topics, not the older booking topic', () {
      expect(
        () => SupportService.validate(
          category: 'booking',
          priority: 'normal',
          subject: 'Hotel question',
          message: 'Can I change my check-in date?',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('priority and text limits are enforced', () {
      expect(
        () => SupportService.validate(
          category: 'bug',
          priority: 'critical',
          subject: 'Save fails',
          message: 'Save fails every time I tap it.',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => SupportService.validate(
          category: 'bug',
          priority: 'urgent',
          subject: 'hi',
          message: 'Save fails every time I tap it.',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => SupportService.validate(
          category: 'bug',
          priority: 'urgent',
          subject: 'Save fails',
          message: 'Save fails every time I tap it.',
        ),
        returnsNormally,
      );
    });

    test('statuses use the names from the brief, in order', () {
      expect(
        [for (final s in SupportStatus.all) SupportStatus.label(s)],
        ['Submitted', 'In review', 'In progress', 'Resolved', 'Closed'],
      );
    });

    test('older requests without a priority count as normal', () {
      expect(SupportPriority.fromData(null), SupportPriority.normal);
      expect(SupportPriority.fromData('whatever'), SupportPriority.normal);
      expect(SupportPriority.fromData('high'), SupportPriority.high);
    });
  });

  group('sending', () {
    test('a report the team receives is reported as sent and not kept on the device', () async {
      final outbox = await _outbox();
      Map<String, dynamic>? sent;

      final outcome = await SupportService.submit(
        userId: _user,
        category: 'bug',
        priority: 'high',
        subject: '  Save button does nothing  ',
        message: 'Tapping save on a trip does nothing at all.',
        writer: (data) async {
          sent = data;
        },
        outbox: outbox,
      );

      expect(outcome, SubmitOutcome.sent);
      expect(outbox.forUser(_user), isEmpty);
      expect(sent!['status'], SupportStatus.open);
      expect(sent!['priority'], 'high');
      expect(sent!['subject'], 'Save button does nothing');
    });

    test('a report the team cannot receive is kept on this device, not shown as sent', () async {
      final outbox = await _outbox();

      final outcome = await _submitBug(outbox);

      expect(outcome, SubmitOutcome.savedOnDevice);
      final drafts = outbox.forUser(_user);
      expect(drafts, hasLength(1));
      expect(drafts.single.subject, 'Save button does nothing');
      expect(drafts.single.category, 'bug');
      expect(outbox.forUser('someone-else'), isEmpty);
    });

    test('saved reports survive a restart', () async {
      final prefs = await SharedPreferences.getInstance();
      final first = FeedbackOutbox(prefs);
      await first.load();
      await _submitBug(first);

      final second = FeedbackOutbox(prefs);
      await second.load();
      expect(second.forUser(_user), hasLength(1));
    });

    test('if the device cannot save either, the user gets an error, not a false success', () async {
      await expectLater(
        _submitBug(_RefusingOutbox()),
        throwsA(isA<StateError>()),
      );
    });

    test('a saved report leaves the device only after it reaches the team', () async {
      final outbox = await _outbox();
      await _submitBug(outbox);
      final draft = outbox.forUser(_user).single;

      expect(
        await SupportService.sendDraft(draft, writer: _failingWriter, outbox: outbox),
        isFalse,
      );
      expect(outbox.forUser(_user), hasLength(1));

      expect(
        await SupportService.sendDraft(draft, writer: _workingWriter, outbox: outbox),
        isTrue,
      );
      expect(outbox.forUser(_user), isEmpty);
    });
  });

  group('admin workflow', () {
    test('status can move to In review with a reply, and the change is logged', () async {
      final db = FakeFirebaseFirestore();
      AppFirebase.useForTesting(auth: MockFirebaseAuth(signedIn: false), db: db);
      await SupportService.create(
        userId: _user,
        category: SupportCategory.bug,
        subject: 'Save button does nothing',
        message: 'Tapping save on a trip does nothing at all.',
      );
      final ticket = (await SupportService.allTickets().first).single;

      await SupportService.adminUpdate(
        adminUid: _admin,
        ticket: ticket,
        status: SupportStatus.inReview,
        reply: 'We are looking into it.',
      );

      final updated = (await SupportService.allTickets().first).single;
      expect(updated.status, SupportStatus.inReview);
      expect(updated.hasReply, isTrue);
      final audit = await db.collection('admin_audit').get();
      expect(audit.docs, hasLength(1));
      expect(audit.docs.single.data()['actorUid'], _admin);
    });
  });

  group('screens', () {
    testWidgets('a traveller sends a bug report and sees that it was sent', (tester) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final db = FakeFirebaseFirestore();
      AppFirebase.useForTesting(
        auth: MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: _user, email: 'user@example.com'),
        ),
        db: db,
      );

      await tester.pumpWidget(MaterialApp(
        theme: TriporaTheme.lightTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NewSupportRequestPage(initialCategory: 'bug'),
                ),
              ),
              child: const Text('open form'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open form'));
      await _settle(tester);

      expect(find.text('New support request'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('support-subject')),
        'Save button does nothing',
      );
      await tester.enterText(
        find.byKey(const Key('support-message')),
        'Tapping save on a trip does nothing at all.',
      );
      await tester.tap(find.byKey(const Key('support-submit')));
      await _settle(tester);

      expect(find.textContaining('Sent to the Tripora team'), findsOneWidget);
      final docs = await tester.runAsync(() => db.collection('support_tickets').get());
      expect(docs!.docs, hasLength(1));
      expect(docs.docs.single.data()['category'], 'bug');
      expect(docs.docs.single.data()['priority'], 'normal');
      expect(docs.docs.single.data()['status'], 'open');
    });

    testWidgets('the admin filters reports by priority, changes status and replies', (tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final db = FakeFirebaseFirestore();
      AppFirebase.useForTesting(
        auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: _admin)),
        db: db,
      );
      await db.collection('support_tickets').doc('tk-urgent').set({
        'userId': _user,
        'category': 'bug',
        'priority': 'urgent',
        'subject': 'App crashes on save',
        'message': 'It crashes every time I save a trip.',
        'status': 'open',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      await db.collection('support_tickets').doc('tk-low').set({
        'userId': _user,
        'category': 'ui',
        'priority': 'low',
        'subject': 'Nicer colour for buttons',
        'message': 'The buttons could use a slightly softer colour.',
        'status': 'open',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      await tester.pumpWidget(MaterialApp(
        theme: TriporaTheme.lightTheme,
        home: const AdminSupportPage(),
      ));
      await _settle(tester);
      expect(find.text('Feedback & issues'), findsOneWidget);
      expect(find.text('App crashes on save'), findsOneWidget);
      expect(find.text('Nicer colour for buttons'), findsOneWidget);

      // Filter by priority: only the low-priority report stays.
      await tester.tap(find.descendant(
        of: find.byKey(const Key('support-filter-priority')),
        matching: find.byType(DropdownButton<String?>),
      ));
      await _settle(tester);
      await tester.tap(find.text('Low').last);
      await _settle(tester);
      expect(find.text('App crashes on save'), findsNothing);
      expect(find.text('Nicer colour for buttons'), findsOneWidget);

      // Back to all priorities, then open the urgent report.
      await tester.tap(find.descendant(
        of: find.byKey(const Key('support-filter-priority')),
        matching: find.byType(DropdownButton<String?>),
      ));
      await _settle(tester);
      await tester.tap(find.text('All').last);
      await _settle(tester);
      await tester.tap(find.byKey(const Key('support-ticket-tk-urgent')));
      await _settle(tester);

      expect(find.textContaining('Priority: Urgent'), findsOneWidget);
      expect(find.text('No account record found for this user.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('support-status')));
      await _settle(tester);
      await tester.tap(find.text('In review').last);
      await _settle(tester);
      await tester.enterText(
        find.byKey(const Key('support-reply')),
        'Thanks, we are looking into it.',
      );
      await tester.tap(find.byKey(const Key('support-save')));
      await _settle(tester);

      final saved = await tester.runAsync(
        () => db.collection('support_tickets').doc('tk-urgent').get(),
      );
      expect(saved!.data()!['status'], 'in_review');
      expect(saved.data()!['adminReply'], 'Thanks, we are looking into it.');
    });
  });
}
