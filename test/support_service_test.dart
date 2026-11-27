// Support tickets and the audit trail, run against an in-memory Firestore.
// Nothing here touches the live project. Access rules are tested separately
// in firestore_rules_test (emulator).
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripora/models/support_ticket.dart';
import 'package:tripora/services/app_firebase.dart';
import 'package:tripora/services/audit_service.dart';
import 'package:tripora/services/support_service.dart';

const adminUid = 'admin-uid';
const userUid = 'user-uid';
const otherUid = 'other-uid';

late FakeFirebaseFirestore db;

void setUpDb() {
  db = FakeFirebaseFirestore();
  AppFirebase.useForTesting(
    auth: MockFirebaseAuth(signedIn: false),
    db: db,
  );
}

Future<void> createTicket({
  String uid = userUid,
  String subject = 'Hotel booking question',
  String message = 'Can I change the check-in date on my demo request?',
  String category = SupportCategory.booking,
}) {
  return SupportService.create(
    userId: uid,
    category: category,
    subject: subject,
    message: message,
  );
}

void main() {
  setUp(setUpDb);

  group('validation', () {
    test('subject and message limits match the rules', () {
      expect(SupportRules.validateSubject('ab'), isNotNull);
      expect(SupportRules.validateSubject('abc'), isNull);
      expect(SupportRules.validateSubject('a' * 101), isNotNull);
      expect(SupportRules.validateMessage('short'), isNotNull);
      expect(SupportRules.validateMessage('0123456789'), isNull);
      expect(SupportRules.validateMessage('x' * 1001), isNotNull);
    });

    test('create refuses bad input without writing anything', () async {
      await expectLater(
        createTicket(subject: 'hi'),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        createTicket(message: 'too short'),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        createTicket(category: 'refunds-please'),
        throwsA(isA<ArgumentError>()),
      );
      final snapshot = await db.collection('support_tickets').get();
      expect(snapshot.docs, isEmpty);
    });
  });

  group('user tickets', () {
    test('create stores an open ticket owned by the user', () async {
      await createTicket();

      final snapshot = await db.collection('support_tickets').get();
      expect(snapshot.docs.length, 1);
      final data = snapshot.docs.single.data();
      expect(data['userId'], userUid);
      expect(data['status'], SupportStatus.open);
      expect(data['category'], SupportCategory.booking);
      expect(data.containsKey('adminReply'), isFalse);
    });

    test('myTickets only returns the signed-in user\'s tickets', () async {
      await createTicket(subject: 'Mine one');
      await createTicket(uid: otherUid, subject: 'Someone else');
      await createTicket(subject: 'Mine two');

      final mine = await SupportService.myTickets(userUid).first;
      expect(mine.map((t) => t.subject).toSet(), {'Mine one', 'Mine two'});
      expect(mine.every((t) => t.userId == userUid), isTrue);
    });

    test('a user can withdraw their own ticket', () async {
      await createTicket();
      final ticket = (await SupportService.myTickets(userUid).first).single;

      await SupportService.withdraw(ticket);

      expect(await SupportService.myTickets(userUid).first, isEmpty);
    });
  });

  group('admin workflow', () {
    test('a reply sets status and text and writes an audit entry', () async {
      await createTicket();
      final ticket = (await SupportService.allTickets().first).single;

      await SupportService.adminUpdate(
        adminUid: adminUid,
        ticket: ticket,
        status: SupportStatus.resolved,
        reply: '  Your request has been updated.  ',
      );

      final updated = (await SupportService.allTickets().first).single;
      expect(updated.status, SupportStatus.resolved);
      expect(updated.adminReply, 'Your request has been updated.');
      expect(updated.hasReply, isTrue);
      expect(updated.repliedAt, isNotNull);

      final audit = await AuditService.recent().first;
      expect(audit.length, 1);
      expect(audit.single.action, 'support_reply');
      expect(audit.single.actorUid, adminUid);
      expect(audit.single.target, 'support_tickets/${ticket.id}');
    });

    test('a status-only change does not touch the reply', () async {
      await createTicket();
      final ticket = (await SupportService.allTickets().first).single;

      await SupportService.adminUpdate(
        adminUid: adminUid,
        ticket: ticket,
        status: SupportStatus.inProgress,
      );

      final updated = (await SupportService.allTickets().first).single;
      expect(updated.status, SupportStatus.inProgress);
      expect(updated.hasReply, isFalse);

      final audit = await AuditService.recent().first;
      expect(audit.single.action, 'support_status');
    });

    test('an unknown status is refused before writing', () async {
      await createTicket();
      final ticket = (await SupportService.allTickets().first).single;

      await expectLater(
        SupportService.adminUpdate(
          adminUid: adminUid,
          ticket: ticket,
          status: 'deleted',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(await AuditService.recent().first, isEmpty);
    });

    test('the user sees the reply on their own ticket', () async {
      await createTicket();
      final ticket = (await SupportService.allTickets().first).single;
      await SupportService.adminUpdate(
        adminUid: adminUid,
        ticket: ticket,
        status: SupportStatus.resolved,
        reply: 'Thanks, this is sorted.',
      );

      final mine = (await SupportService.myTickets(userUid).first).single;
      expect(mine.adminReply, 'Thanks, this is sorted.');
    });
  });

  group('SupportCategory and SupportStatus labels', () {
    test('every known value has a readable label', () {
      for (final c in SupportCategory.all) {
        expect(SupportCategory.label(c), isNot(isEmpty));
      }
      for (final s in SupportStatus.all) {
        expect(SupportStatus.label(s), isNot(isEmpty));
      }
      expect(SupportStatus.label('in_progress'), 'In progress');
    });
  });
}
