import 'package:flutter_test/flutter_test.dart';
import 'package:myrwa/models/models.dart';

void main() {
  group('Resident', () {
    test('toJson/fromJson round-trip preserves all fields', () {
      const resident = Resident(
        id: 'r1',
        name: 'Amit Sharma',
        flat: 'A-101',
        phone: '9876543210',
        isAdmin: true,
        avatarColor: 0xFF1565C0,
      );

      final json = resident.toJson();
      final restored = Resident.fromJson(json);

      expect(restored.id, resident.id);
      expect(restored.name, resident.name);
      expect(restored.flat, resident.flat);
      expect(restored.phone, resident.phone);
      expect(restored.isAdmin, resident.isAdmin);
      expect(restored.avatarColor, resident.avatarColor);
    });

    test('fromJson uses defaults for missing fields', () {
      final resident = Resident.fromJson({'id': 'r2', 'name': 'Test', 'flat': 'B-202', 'phone': '1234567890'});
      expect(resident.isAdmin, false);
      expect(resident.avatarColor, 0xFF1565C0);
    });
  });

  group('Enums', () {
    test('ComplaintStatus has 3 values', () {
      expect(ComplaintStatus.values.length, 3);
      expect(ComplaintStatus.values, contains(ComplaintStatus.open));
      expect(ComplaintStatus.values, contains(ComplaintStatus.inProgress));
      expect(ComplaintStatus.values, contains(ComplaintStatus.resolved));
    });

    test('Priority has 3 values', () {
      expect(Priority.values.length, 3);
      expect(Priority.values, contains(Priority.low));
      expect(Priority.values, contains(Priority.medium));
      expect(Priority.values, contains(Priority.high));
    });

    test('VisitorStatus has 4 values', () {
      expect(VisitorStatus.values.length, 4);
      expect(VisitorStatus.values, contains(VisitorStatus.pending));
      expect(VisitorStatus.values, contains(VisitorStatus.approved));
      expect(VisitorStatus.values, contains(VisitorStatus.rejected));
      expect(VisitorStatus.values, contains(VisitorStatus.completed));
    });

    test('BillStatus has 3 values', () {
      expect(BillStatus.values.length, 3);
      expect(BillStatus.values, contains(BillStatus.pending));
      expect(BillStatus.values, contains(BillStatus.paid));
      expect(BillStatus.values, contains(BillStatus.overdue));
    });
  });

  group('Poll', () {
    test('isActive returns true for future endDate', () {
      final poll = Poll(
        id: '1',
        question: 'Test?',
        options: ['A', 'B'],
        votes: [5, 3],
        totalVoters: 8,
        endDate: DateTime.now().add(const Duration(days: 1)),
        createdBy: 'admin',
      );
      expect(poll.isActive, true);
    });

    test('isActive returns false for past endDate', () {
      final poll = Poll(
        id: '1',
        question: 'Test?',
        options: ['A', 'B'],
        votes: [5, 3],
        totalVoters: 8,
        endDate: DateTime.now().subtract(const Duration(days: 1)),
        createdBy: 'admin',
      );
      expect(poll.isActive, false);
    });

    test('totalVotes sums votes list correctly', () {
      final poll = Poll(
        id: '1',
        question: 'Test?',
        options: ['A', 'B', 'C'],
        votes: [5, 3, 2],
        totalVoters: 10,
        endDate: DateTime.now().add(const Duration(days: 1)),
        createdBy: 'admin',
      );
      expect(poll.totalVotes, 10);
    });

    test('totalVotes is 0 for empty votes', () {
      final poll = Poll(
        id: '2',
        question: 'Empty?',
        options: ['Yes', 'No'],
        votes: [0, 0],
        totalVoters: 0,
        endDate: DateTime.now().add(const Duration(hours: 1)),
        createdBy: 'admin',
      );
      expect(poll.totalVotes, 0);
    });
  });
}
