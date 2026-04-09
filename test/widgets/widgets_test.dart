import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrwa/widgets/status_chip.dart';
import 'package:myrwa/widgets/priority_badge.dart';
import 'package:myrwa/widgets/empty_state.dart';
import 'package:myrwa/widgets/section_header.dart';

void main() {
  group('StatusChip', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StatusChip(label: 'Open'))),
      );
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('renders with custom color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusChip(label: 'Resolved', color: Colors.green),
          ),
        ),
      );
      expect(find.text('Resolved'), findsOneWidget);
    });
  });

  group('PriorityBadge', () {
    testWidgets('shows HIGH for high priority', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PriorityBadge(priority: 'high')),
        ),
      );
      expect(find.text('HIGH'), findsOneWidget);
    });

    testWidgets('shows MED for medium priority', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PriorityBadge(priority: 'medium')),
        ),
      );
      expect(find.text('MED'), findsOneWidget);
    });

    testWidgets('shows LOW for low priority', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PriorityBadge(priority: 'low')),
        ),
      );
      expect(find.text('LOW'), findsOneWidget);
    });

    testWidgets('uppercases unknown priority', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PriorityBadge(priority: 'critical')),
        ),
      );
      expect(find.text('CRITICAL'), findsOneWidget);
    });
  });

  group('EmptyState', () {
    testWidgets('renders emoji and title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(emoji: '🎉', title: 'Nothing here'),
          ),
        ),
      );
      expect(find.text('🎉'), findsOneWidget);
      expect(find.text('Nothing here'), findsOneWidget);
    });

    testWidgets('renders optional subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              emoji: '🔍',
              title: 'No results',
              subtitle: 'Try different keywords',
            ),
          ),
        ),
      );
      expect(find.text('Try different keywords'), findsOneWidget);
    });

    testWidgets('does not render subtitle when not provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(emoji: '📭', title: 'Empty'),
          ),
        ),
      );
      // Only emoji and title texts should be present
      expect(find.byType(Text), findsNWidgets(2));
    });
  });

  group('SectionHeader', () {
    testWidgets('renders emoji and title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(emoji: '⚡', title: 'Test Section'),
          ),
        ),
      );
      expect(find.text('⚡'), findsOneWidget);
      expect(find.text('Test Section'), findsOneWidget);
    });

    testWidgets('shows See all when onSeeAll is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              emoji: '⚡',
              title: 'Test',
              onSeeAll: () {},
            ),
          ),
        ),
      );
      expect(find.text('See all'), findsOneWidget);
    });

    testWidgets('hides See all when onSeeAll is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(emoji: '⚡', title: 'Test'),
          ),
        ),
      );
      expect(find.text('See all'), findsNothing);
    });

    testWidgets('onSeeAll callback fires on tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              emoji: '⚡',
              title: 'Test',
              onSeeAll: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('See all'));
      expect(tapped, true);
    });
  });
}
