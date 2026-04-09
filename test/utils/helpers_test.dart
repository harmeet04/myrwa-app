import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrwa/utils/helpers.dart';
import 'package:myrwa/utils/app_colors.dart';

void main() {
  group('timeAgo', () {
    test('returns Just now for time within last minute', () {
      expect(timeAgo(DateTime.now()), 'Just now');
      expect(timeAgo(DateTime.now().subtract(const Duration(seconds: 30))), 'Just now');
    });

    test('returns minutes ago for time within last hour', () {
      final fiveMinAgo = DateTime.now().subtract(const Duration(minutes: 5));
      expect(timeAgo(fiveMinAgo), '5m ago');
    });

    test('returns hours ago for time within last day', () {
      final threeHoursAgo = DateTime.now().subtract(const Duration(hours: 3));
      expect(timeAgo(threeHoursAgo), '3h ago');
    });

    test('returns days ago for time within last week', () {
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      expect(timeAgo(twoDaysAgo), '2d ago');
    });

    test('returns formatted date for time older than a week', () {
      // Older than 7 days returns a formatted date string (not empty)
      final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));
      final result = timeAgo(twoWeeksAgo);
      expect(result.isNotEmpty, true);
      expect(result.contains('ago'), false);
    });
  });

  group('statusColor', () {
    test('returns statusError for open', () {
      expect(statusColor('open'), AppColors.statusError);
    });

    test('returns statusWarning for inprogress', () {
      expect(statusColor('inprogress'), AppColors.statusWarning);
    });

    test('returns statusSuccess for resolved', () {
      expect(statusColor('resolved'), AppColors.statusSuccess);
    });

    test('returns statusError for pending', () {
      expect(statusColor('pending'), AppColors.statusError);
    });

    test('returns statusSuccess for paid', () {
      expect(statusColor('paid'), AppColors.statusSuccess);
    });
  });

  group('priorityColor', () {
    test('returns statusError for high', () {
      expect(priorityColor('high'), AppColors.statusError);
    });

    test('returns statusWarning for medium', () {
      expect(priorityColor('medium'), AppColors.statusWarning);
    });

    test('returns statusSuccess for low', () {
      expect(priorityColor('low'), AppColors.statusSuccess);
    });
  });

  group('categoryIcon', () {
    test('returns plumbing icon for plumbing', () {
      expect(categoryIcon('plumbing'), Icons.plumbing);
    });

    test('returns electrical icon for electrical', () {
      expect(categoryIcon('electrical'), Icons.electrical_services);
    });

    test('returns security icon for security', () {
      expect(categoryIcon('security'), Icons.security);
    });

    test('returns elevator icon for lift', () {
      expect(categoryIcon('lift'), Icons.elevator);
    });

    test('returns build icon for maintenance', () {
      expect(categoryIcon('maintenance'), Icons.build);
    });

    test('returns default report_problem icon for unknown category', () {
      expect(categoryIcon('unknown'), Icons.report_problem);
      expect(categoryIcon(''), Icons.report_problem);
    });
  });
}
