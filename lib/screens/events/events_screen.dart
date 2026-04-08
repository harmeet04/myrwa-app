import 'package:flutter/material.dart';
import '../../utils/mock_data.dart';
import '../../utils/helpers.dart';
import '../../models/models.dart';
import '../../utils/prefs_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late List<Event> _events;

  @override
  void initState() {
    super.initState();
    _events = MockData.events;
    // Restore RSVP from prefs
    final rsvps = PrefsService.rsvpStatus;
    for (final e in _events) {
      final data = rsvps[e.id];
      if (data != null) {
        e.hasRsvpd = data['rsvpd'] == true;
        e.plusOnes = data['plusOnes'] ?? 0;
      }
    }
    _loadFromFirestore();
  }

  void _loadFromFirestore() {
    FirestoreService.eventsStream(PrefsService.societyName).listen((snap) {
      if (snap.docs.isNotEmpty && mounted) {
        setState(() {
          _events = snap.docs.map((d) => FirestoreService.eventFromDoc(d)).toList();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Events / कार्यक्रम')),
      body: RefreshIndicator(
        color: AppColors.primaryAmber,
        onRefresh: () async => setState(() {}),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _events.length,
          itemBuilder: (_, i) {
          final e = _events[i];
          final spotsLeft = e.maxCapacity - e.rsvpCount;
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
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(formatDateTime(e.date), style: TextStyle(color: AppColors.textPrimary)),
                        const SizedBox(width: 16),
                        Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(e.location, style: TextStyle(color: AppColors.textPrimary)),
                        const Spacer(),
                        Text('$spotsLeft spots left', style: TextStyle(color: spotsLeft < 10 ? AppColors.statusError : AppColors.statusSuccess, fontWeight: FontWeight.w500, fontSize: 12)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Text('${e.rsvpCount} going', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w500)),
                        if (e.maybeCount > 0) Text(', ${e.maybeCount} maybe', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        const Spacer(),
                        if (!e.hasRsvpd) FilledButton.tonal(
                          onPressed: () {
                            setState(() { e.hasRsvpd = true; e.rsvpCount++; });
                            PrefsService.saveRsvp(e.id, true, e.plusOnes);
                          },
                          child: const Text('RSVP'),
                        )
                        else OutlinedButton(
                          onPressed: () {
                            setState(() {
                              e.hasRsvpd = false;
                              e.rsvpCount = (e.rsvpCount - 1 - e.plusOnes).clamp(0, e.maxCapacity);
                              e.plusOnes = 0;
                            });
                            PrefsService.saveRsvp(e.id, false, 0);
                          },
                          child: const Text('Cancel RSVP'),
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
      ),
    );
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
              _Row(Icons.people, '${e.rsvpCount}/${e.maxCapacity} attending${e.maybeCount > 0 ? ', ${e.maybeCount} maybe' : ''}'),
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
              if (e.maybeAttendees.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Maybe (${e.maybeAttendees.length})', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: e.maybeAttendees.map((name) => Chip(
                    avatar: CircleAvatar(backgroundColor: AppColors.cardBorder, child: Text(name[0], style: const TextStyle(fontSize: 11))),
                    label: Text(name, style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
              ],
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
