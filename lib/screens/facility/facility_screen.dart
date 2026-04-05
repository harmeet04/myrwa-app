import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/helpers.dart';
import '../../utils/prefs_service.dart';
import '../../services/firestore_service.dart';
import 'package:intl/intl.dart';

class FacilityScreen extends StatefulWidget {
  const FacilityScreen({super.key});

  @override
  State<FacilityScreen> createState() => _FacilityScreenState();
}

class _FacilityScreenState extends State<FacilityScreen> {
  DateTime _selectedDate = DateTime.now();

  final List<_Facility> _facilities = [
    _Facility(name: 'Community Hall / सभागृह', icon: Icons.meeting_room, color: Colors.blue, capacity: 100, pricePerHour: 500, amenities: ['AC', 'Projector', 'Sound System', 'Stage']),
    _Facility(name: 'Party Hall / पार्टी हॉल', icon: Icons.celebration, color: Colors.purple, capacity: 50, pricePerHour: 800, amenities: ['AC', 'Kitchen', 'DJ Setup', 'Decoration']),
    _Facility(name: 'Tennis Court / टेनिस कोर्ट', icon: Icons.sports_tennis, color: Colors.green, capacity: 4, pricePerHour: 200, amenities: ['Floodlights', 'Net', 'Locker Room']),
    _Facility(name: 'Swimming Pool / तरण ताल', icon: Icons.pool, color: Colors.cyan, capacity: 20, pricePerHour: 150, amenities: ['Changing Room', 'Lifeguard', 'Towels']),
    _Facility(name: 'Guest Room / अतिथि कक्ष', icon: Icons.hotel, color: Colors.orange, capacity: 2, pricePerHour: 300, amenities: ['AC', 'TV', 'Attached Bath', 'WiFi'], isPerDay: true),
    _Facility(name: 'Gym / जिम', icon: Icons.fitness_center, color: Colors.red, capacity: 15, pricePerHour: 0, amenities: ['Treadmill', 'Weights', 'Mirror Wall', 'AC']),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Facility Booking / सुविधा बुकिंग')),
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
                        border: Border.all(color: selected ? Colors.transparent : Colors.grey.shade300),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(DateFormat('EEE').format(date), style: TextStyle(fontSize: 11, color: selected ? Colors.white : Colors.grey.shade600)),
                        const SizedBox(height: 4),
                        Text('${date.day}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: selected ? Colors.white : Colors.black)),
                        Text(DateFormat('MMM').format(date), style: TextStyle(fontSize: 10, color: selected ? Colors.white70 : Colors.grey.shade500)),
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
                final booked = _bookedSlots[f.name] ?? (f.isPerDay ? {} : {'10:00-11:00', '14:00-15:00'});
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
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
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
                                selectedColor: Colors.red.shade300,
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
    final color = available > 3 ? Colors.green : (available > 0 ? Colors.orange : Colors.red);
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
      builder: (_) => AlertDialog(
        title: Text('Book ${f.name.split('/')[0].trim()}'),
        content: Text('Date: ${formatDate(_selectedDate)}\nSlot: $slot\nPrice: ${f.pricePerHour == 0 ? "Free" : "₹${f.pricePerHour}"}\n\nConfirm booking?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
              if (!context.mounted) return;
              Navigator.pop(context);
              showSnack(context, '✅ ${f.name.split("/")[0].trim()} booked for $slot!');
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
