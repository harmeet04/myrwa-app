import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:add_2_calendar/add_2_calendar.dart' as add_2_calendar;
import '../../utils/mock_data.dart';
import '../../utils/helpers.dart';
import '../../models/models.dart';
import '../../utils/prefs_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/error_retry.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<Event>? _cachedEvents;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final society = PrefsService.societyName;
    return Scaffold(
      appBar: AppBar(title: const Text('Events / \u0915\u093E\u0930\u094D\u092F\u0915\u094D\u0930\u092E')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.eventsStream(society),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorRetry(
              message: 'Failed to load data',
              onRetry: () => setState(() {}),
            );
          }

          // Only update cache when Firestore data changes, not on every build
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            _cachedEvents = snapshot.data!.docs
                .map((d) => FirestoreService.eventFromDoc(d))
                .toList();
          } else if (_cachedEvents == null) {
            _cachedEvents = MockData.events.map((e) => Event(
              id: e.id, title: e.title, description: e.description,
              date: e.date, location: e.location, organizer: e.organizer,
              rsvpCount: e.rsvpCount, maybeCount: e.maybeCount,
              maxCapacity: e.maxCapacity, attendees: List<String>.from(e.attendees),
              maybeAttendees: List<String>.from(e.maybeAttendees),
            )).toList();
          }
          final events = _cachedEvents!;

          // Restore RSVP from prefs
          final rsvps = PrefsService.rsvpStatus;
          for (final e in events) {
            final data = rsvps[e.id];
            if (data != null) {
              e.hasRsvpd = data['rsvpd'] == true;
              e.plusOnes = data['plusOnes'] ?? 0;
            }
          }

          return RefreshIndicator(
            color: AppColors.primaryAmber,
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: events.length,
              itemBuilder: (_, i) {
                final e = events[i];
                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showDetail(context, e),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [cs.primary, cs.primary.withValues(alpha: 0.7)]),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(e.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(e.organizer, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Flexible(child: Text(formatDateTime(e.date), style: TextStyle(color: AppColors.textPrimary))),
                                  const SizedBox(width: 12),
                                  Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Flexible(child: Text(e.location, style: TextStyle(color: AppColors.textPrimary))),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text('${e.rsvpCount} going', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w500)),
                                  const Spacer(),
                                  if (!e.hasRsvpd) FilledButton.tonal(
                                    onPressed: () {
                                      setState(() {
                                        e.hasRsvpd = true;
                                        e.rsvpCount++;
                                        e.attendees.add(PrefsService.userName);
                                      });
                                      PrefsService.saveRsvp(e.id, true, e.plusOnes);
                                      if (e.id.isNotEmpty) {
                                        FirestoreService.updateEvent(e.id, {
                                          'rsvpCount': e.rsvpCount,
                                          'attendees': e.attendees,
                                        });
                                      }
                                    },
                                    style: FilledButton.styleFrom(visualDensity: VisualDensity.compact, textStyle: const TextStyle(fontSize: 12)),
                                    child: const Text('RSVP'),
                                  )
                                  else ...[
                                    OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          e.hasRsvpd = false;
                                          e.rsvpCount = (e.rsvpCount - 1 - e.plusOnes).clamp(0, 9999);
                                          e.plusOnes = 0;
                                          e.attendees.remove(PrefsService.userName);
                                        });
                                        PrefsService.saveRsvp(e.id, false, 0);
                                        if (e.id.isNotEmpty) {
                                          FirestoreService.updateEvent(e.id, {
                                            'rsvpCount': e.rsvpCount,
                                            'attendees': e.attendees,
                                          });
                                        }
                                      },
                                      style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact, textStyle: const TextStyle(fontSize: 12)),
                                      child: const Text('Cancel RSVP'),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () => _addToCalendar(e),
                                      icon: const Icon(Icons.calendar_month, size: 14),
                                      label: const Text('Calendar', style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primaryAmber,
                                        side: const BorderSide(color: AppColors.amberBorder),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _addToCalendar(Event e) {
    final event = add_2_calendar.Event(
      title: e.title,
      description: e.description,
      location: e.location,
      startDate: e.date,
      endDate: e.date.add(const Duration(hours: 2)),
    );
    add_2_calendar.Add2Calendar.addEvent2Cal(event);
  }

  void _showDetail(BuildContext context, Event e) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setBS) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          builder: (_, ctrl) => ListView(
            controller: ctrl,
            padding: const EdgeInsets.all(20),
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(e.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _Row(Icons.calendar_today, formatDateTime(e.date)),
              _Row(Icons.location_on, e.location),
              _Row(Icons.group, 'Organized by ${e.organizer}'),
              _Row(Icons.people, '${e.rsvpCount} attending'),
              const SizedBox(height: 12),
              Text(e.description, style: const TextStyle(height: 1.5)),
              // +1 / family option
              if (e.hasRsvpd) ...[
                const SizedBox(height: 16),
                Row(children: [
                  const Text('Bringing +1/family:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: e.plusOnes > 0 ? () {
                      setBS(() { e.plusOnes--; e.rsvpCount--; });
                      setState(() {});
                      PrefsService.saveRsvp(e.id, true, e.plusOnes);
                    } : null,
                  ),
                  Text('${e.plusOnes}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      setBS(() { e.plusOnes++; e.rsvpCount++; });
                      setState(() {});
                      PrefsService.saveRsvp(e.id, true, e.plusOnes);
                    },
                  ),
                ]),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _addToCalendar(e),
                  icon: const Icon(Icons.calendar_month, size: 16),
                  label: const Text('Add to Calendar', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryAmber,
                    side: const BorderSide(color: AppColors.amberBorder),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
              // Attendee list
              const SizedBox(height: 16),
              Text('Attendees (${e.attendees.length})', style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary)),
              const SizedBox(height: 8),
              if (e.attendees.isEmpty)
                Text('No attendees yet', style: TextStyle(color: AppColors.textTertiary))
              else
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: e.attendees.map((name) => Chip(
                    avatar: CircleAvatar(backgroundColor: cs.primaryContainer, child: Text(name[0], style: TextStyle(fontSize: 11, color: cs.primary))),
                    label: Text(name, style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Row(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [Icon(icon, size: 18, color: AppColors.textSecondary), const SizedBox(width: 8), Expanded(child: Text(text))]),
  );
}
