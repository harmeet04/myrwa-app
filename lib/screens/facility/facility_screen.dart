import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/helpers.dart';
import '../../utils/prefs_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';
import 'package:intl/intl.dart';

class FacilityScreen extends StatefulWidget {
  const FacilityScreen({super.key});

  @override
  State<FacilityScreen> createState() => _FacilityScreenState();
}

class _FacilityScreenState extends State<FacilityScreen> {
  DateTime _selectedDate = DateTime.now();

  final List<_Facility> _facilities = [
    _Facility(name: 'Community Hall / सभागृह', icon: Icons.meeting_room, color: AppColors.primaryAmber, capacity: 100, pricePerHour: 500, amenities: ['AC', 'Projector', 'Sound System', 'Stage']),
    _Facility(name: 'Party Hall / पार्टी हॉल', icon: Icons.celebration, color: const Color(0xFF7C3AED), capacity: 50, pricePerHour: 800, amenities: ['AC', 'Kitchen', 'DJ Setup', 'Decoration']),
    _Facility(name: 'Tennis Court / टेनिस कोर्ट', icon: Icons.sports_tennis, color: AppColors.statusSuccess, capacity: 4, pricePerHour: 200, amenities: ['Floodlights', 'Net', 'Locker Room']),
    _Facility(name: 'Swimming Pool / तरण ताल', icon: Icons.pool, color: AppColors.primaryAmber, capacity: 20, pricePerHour: 150, amenities: ['Changing Room', 'Lifeguard', 'Towels']),
    _Facility(name: 'Guest Room / अतिथि कक्ष', icon: Icons.hotel, color: AppColors.primaryOrange, capacity: 2, pricePerHour: 300, amenities: ['AC', 'TV', 'Attached Bath', 'WiFi'], isPerDay: true),
    _Facility(name: 'Gym / जिम', icon: Icons.fitness_center, color: AppColors.statusError, capacity: 15, pricePerHour: 0, amenities: ['Treadmill', 'Weights', 'Mirror Wall', 'AC']),
  ];

  // Track booked slots from Firestore
  Map<String, Set<String>> _bookedSlots = {};

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() {
    final society = PrefsService.societyName;
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    FirestoreService.collection('facility_bookings')
        .where('society', isEqualTo: society)
        .where('dateKey', isEqualTo: dateKey)
        .snapshots()
        .listen((snap) {
      final map = <String, Set<String>>{};
      for (final doc in snap.docs) {
        final d = doc.data() as Map<String, dynamic>;
        final facility = d['facilityName'] ?? '';
        final slot = d['slot'] ?? '';
        map.putIfAbsent(facility, () => {}).add(slot);
      }
      if (mounted) setState(() => _bookedSlots = map);
    });
  }

  void _showAddFacilityForm() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final timingCtrl = TextEditingController(text: '06:00 - 20:00');
    final slotsCtrl = TextEditingController(text: '12');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('Add New Facility', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Facility Name', prefixIcon: Icon(Icons.meeting_room))),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 12),
              TextField(controller: timingCtrl, decoration: const InputDecoration(labelText: 'Timings (e.g. 06:00 - 20:00)', prefixIcon: Icon(Icons.schedule))),
              const SizedBox(height: 12),
              TextField(controller: slotsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Slots per day', prefixIcon: Icon(Icons.event_available))),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  setState(() {
                    _facilities.add(_Facility(
                      name: nameCtrl.text.trim(),
                      icon: Icons.business,
                      color: AppColors.primaryAmber,
                      capacity: int.tryParse(slotsCtrl.text) ?? 10,
                      pricePerHour: 0,
                      amenities: descCtrl.text.trim().isNotEmpty ? [descCtrl.text.trim()] : [],
                    ));
                  });
                  Navigator.pop(ctx);
                  showSnack(context, 'Facility "${nameCtrl.text.trim()}" added!');
                },
                child: const Text('Add Facility'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookingsForFacility(_Facility f) {
    final society = PrefsService.societyName;
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Bookings: ${f.name.split("/")[0].trim()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Date: ${DateFormat('dd MMM, EEEE').format(_selectedDate)}', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirestoreService.collection('facility_bookings')
                    .where('society', isEqualTo: society)
                    .where('dateKey', isEqualTo: dateKey)
                    .where('facilityName', isEqualTo: f.name)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(child: Text('No bookings for this date.'));
                  }
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      return ListTile(
                        leading: const Icon(Icons.person, color: AppColors.primaryAmber),
                        title: Text(d['bookedBy'] ?? 'Unknown'),
                        subtitle: Text('Flat: ${d['flat'] ?? '-'} | Slot: ${d['slot'] ?? '-'}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMyBookings(BuildContext context) {
    final society = PrefsService.societyName;
    final userName = PrefsService.userName;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                const Text('My Bookings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirestoreService.collection('facility_bookings')
                    .where('society', isEqualTo: society)
                    .where('bookedBy', isEqualTo: userName)
                    .limit(20)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('📅', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 8),
                        Text('No bookings yet', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ));
                  }
                  return ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      final date = (d['date'] as Timestamp?)?.toDate() ?? DateTime.now();
                      final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
                      return Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isPast ? AppColors.cardBorder : AppColors.amberBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.event_available, color: isPast ? AppColors.textTertiary : AppColors.primaryAmber),
                              ),
                              title: Text(
                                (d['facilityName'] as String?)?.split('/').first.trim() ?? 'Unknown',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text('${formatDate(date)} • ${d['slot'] ?? '-'}'),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isPast ? AppColors.cardBorder : AppColors.greenBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isPast ? 'Past' : 'Upcoming',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isPast ? AppColors.textTertiary : AppColors.statusSuccess),
                                ),
                              ),
                            ),
                            if (!isPast)
                              Padding(
                                padding: const EdgeInsets.only(right: 8, bottom: 4),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: ctx,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Cancel Booking'),
                                          content: const Text('Are you sure you want to cancel this booking?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                                            FilledButton(
                                              style: FilledButton.styleFrom(backgroundColor: AppColors.statusError),
                                              onPressed: () => Navigator.pop(ctx, true),
                                              child: const Text('Cancel Booking'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await FirestoreService.deleteDoc('facility_bookings', docs[i].id);
                                        if (ctx.mounted) showSnack(ctx, 'Booking cancelled');
                                      }
                                    },
                                    child: const Text('Cancel', style: TextStyle(color: AppColors.statusError)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facility Booking / सुविधा बुकिंग'),
        actions: [
          TextButton.icon(
            onPressed: () => _showMyBookings(context),
            icon: const Icon(Icons.bookmark, size: 18),
            label: const Text('My Bookings', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
      floatingActionButton: PrefsService.isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showAddFacilityForm,
              backgroundColor: AppColors.primaryAmber,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Facility', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: 14,
                itemBuilder: (context, i) {
                  final date = DateTime.now().add(Duration(days: i));
                  final selected = date.day == _selectedDate.day && date.month == _selectedDate.month;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedDate = date);
                      _loadBookings();
                    },
                    child: Container(
                      width: 56,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: selected ? Theme.of(context).colorScheme.primary : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? Colors.transparent : AppColors.cardBorder),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(DateFormat('EEE').format(date), style: TextStyle(fontSize: 11, color: selected ? Colors.white : AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text('${date.day}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: selected ? Colors.white : Colors.black)),
                        Text(DateFormat('MMM').format(date), style: TextStyle(fontSize: 10, color: selected ? Colors.white70 : AppColors.textTertiary)),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Text('Available on ${DateFormat('dd MMM, EEEE').format(_selectedDate)}', style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: _facilities.length,
              itemBuilder: (context, i) {
                final f = _facilities[i];
                final booked = _bookedSlots[f.name] ?? <String>{};
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(color: f.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                          child: Icon(f.icon, color: f.color, size: 32),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(f.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('Capacity: ${f.capacity} • ${f.pricePerHour == 0 ? "Free / मुफ्त" : "₹${f.pricePerHour}/${f.isPerDay ? "day" : "hr"}"}',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ])),
                        _availabilityBadge(f, booked),
                      ]),
                      const SizedBox(height: 8),
                      Wrap(spacing: 6, runSpacing: 4, children: f.amenities.map((a) => Chip(
                        label: Text(a, style: const TextStyle(fontSize: 11)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      )).toList()),
                      const SizedBox(height: 8),
                      if (!f.isPerDay)
                        SizedBox(
                          height: 36,
                          child: ListView(scrollDirection: Axis.horizontal, children: f.timeSlots.map((slot) {
                            final isBooked = booked.contains(slot);
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(slot, style: TextStyle(fontSize: 11, color: isBooked ? Colors.white : null)),
                                selected: isBooked,
                                selectedColor: AppColors.statusError.withValues(alpha: 0.7),
                                onSelected: isBooked ? null : (_) => _bookSlot(f, slot),
                              ),
                            );
                          }).toList()),
                        )
                      else
                        SizedBox(width: double.infinity, child: FilledButton.icon(
                          onPressed: () => _bookSlot(f, 'Full Day'),
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Book for this day / बुक करें'),
                        )),
                      if (PrefsService.isAdmin) ...[
                        const SizedBox(height: 8),
                        Row(children: [
                          Text(
                            '${(booked).length} booking(s) today',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _showBookingsForFacility(f),
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text('View Bookings', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryAmber,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ]),
                      ],
                    ]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _availabilityBadge(_Facility f, Set<String> booked) {
    final available = f.timeSlots.length - booked.length;
    final color = available > 3 ? AppColors.statusSuccess : (available > 0 ? AppColors.statusWarning : AppColors.statusError);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
      child: Text(f.isPerDay ? (booked.isEmpty ? 'Available' : 'Booked') : '$available slots',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  void _bookSlot(_Facility f, String slot) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Book ${f.name.split('/')[0].trim()}'),
        content: Text('Date: ${formatDate(_selectedDate)}\nSlot: $slot\nPrice: ${f.pricePerHour == 0 ? "Free" : "₹${f.pricePerHour}"}\n\nConfirm booking?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await FirestoreService.addDoc('facility_bookings', {
                'facilityName': f.name,
                'slot': slot,
                'dateKey': DateFormat('yyyy-MM-dd').format(_selectedDate),
                'date': Timestamp.fromDate(_selectedDate),
                'bookedBy': PrefsService.userName,
                'flat': PrefsService.userFlat,
              });
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _loadBookings(); // refresh booked slots
              showSnack(ctx, '✅ ${f.name.split("/")[0].trim()} booked for $slot!');
            },
            child: const Text('Confirm / पक्का'),
          ),
        ],
      ),
    );
  }
}

class _Facility {
  final String name;
  final IconData icon;
  final Color color;
  final int capacity;
  final int pricePerHour;
  final List<String> amenities;
  final bool isPerDay;

  _Facility({required this.name, required this.icon, required this.color, required this.capacity,
    required this.pricePerHour, required this.amenities, this.isPerDay = false});

  List<String> get timeSlots => isPerDay
      ? ['Full Day']
      : ['06:00-07:00', '07:00-08:00', '08:00-09:00', '09:00-10:00', '10:00-11:00', '11:00-12:00',
         '14:00-15:00', '15:00-16:00', '16:00-17:00', '17:00-18:00', '18:00-19:00', '19:00-20:00'];
}
