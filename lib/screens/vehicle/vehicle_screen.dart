import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/helpers.dart';
import '../../utils/prefs_service.dart';
import '../../services/firestore_service.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final society = PrefsService.societyName;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle & Parking / वाहन'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.directions_car), text: 'My Vehicles'),
            Tab(icon: Icon(Icons.local_parking), text: 'Parking Slots'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addVehicle,
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildVehicleList(society),
          _buildParkingGrid(society),
        ],
      ),
    );
  }

  Widget _buildVehicleList(String society) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.collectionStream('vehicles', society),
      builder: (context, snapshot) {
        List<_Vehicle> vehicles;
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          vehicles = snapshot.data!.docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return _Vehicle(
              id: doc.id,
              name: d['name'] ?? '',
              number: d['number'] ?? '',
              type: d['type'] ?? 'Car',
              parkingSlot: d['parkingSlot'] ?? 'Unassigned',
              isInside: d['isInside'] ?? true,
            );
          }).toList();
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else {
          vehicles = _MockVehicles.vehicles;
        }

        if (vehicles.isEmpty) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.directions_car_outlined, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No vehicles registered', style: TextStyle(color: Colors.grey.shade500)),
          ]));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: vehicles.length,
          itemBuilder: (context, i) {
            final v = vehicles[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(color: v.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                    child: Icon(v.icon, size: 36, color: v.color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.amber.shade400)),
                      child: Text(v.number, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey.shade800)),
                    ),
                    const SizedBox(height: 4),
                    Text('Slot: ${v.parkingSlot} • ${v.type}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ])),
                  Column(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: v.isInside ? Colors.green.shade100 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(v.isInside ? '🟢 Inside' : '⚪ Outside',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: v.isInside ? Colors.green.shade800 : Colors.grey.shade700)),
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      onPressed: () async {
                        if (v.id != null) {
                          await FirestoreService.updateDoc('vehicles', v.id!, {'isInside': !v.isInside});
                        }
                        if (mounted) showSnack(context, !v.isInside ? '${v.number} marked as entered' : '${v.number} marked as exited');
                      },
                      icon: Icon(v.isInside ? Icons.logout : Icons.login, color: Theme.of(context).colorScheme.primary),
                    ),
                  ]),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildParkingGrid(String society) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.collection('parking_slots').where('society', isEqualTo: society).snapshots(),
      builder: (context, snapshot) {
        List<_ParkingSlot> slots;
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          slots = snapshot.data!.docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return _ParkingSlot(id: d['slotId'] ?? doc.id, status: d['status'] ?? 'available', flat: d['flat']);
          }).toList();
        } else {
          slots = _MockVehicles.slots;
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _legend(Colors.green.shade100, 'Available / खाली'),
              const SizedBox(width: 16),
              _legend(Colors.red.shade100, 'Occupied / भरा'),
              const SizedBox(width: 16),
              _legend(Colors.amber.shade100, 'Reserved'),
            ]),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.2),
                itemCount: slots.length,
                itemBuilder: (context, i) {
                  final s = slots[i];
                  return InkWell(
                    onTap: s.status == 'available' ? () => showSnack(context, 'Slot ${s.id} assigned to you') : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: s.status == 'available' ? Colors.green.shade50 : s.status == 'reserved' ? Colors.amber.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: s.status == 'available' ? Colors.green.shade300 : s.status == 'reserved' ? Colors.amber.shade300 : Colors.red.shade300),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(s.status == 'available' ? Icons.check_circle_outline : Icons.directions_car, size: 24,
                          color: s.status == 'available' ? Colors.green : s.status == 'reserved' ? Colors.amber.shade700 : Colors.red),
                        const SizedBox(height: 4),
                        Text(s.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        if (s.flat != null) Text(s.flat!, style: const TextStyle(fontSize: 10)),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _legend(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 11)),
  ]);

  void _addVehicle() {
    final nameCtrl = TextEditingController();
    final numberCtrl = TextEditingController();
    String selectedType = 'Car';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Add Vehicle / वाहन जोड़ें', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Vehicle Name (e.g. Swift Dzire)', prefixIcon: Icon(Icons.directions_car))),
          const SizedBox(height: 12),
          TextField(controller: numberCtrl, decoration: const InputDecoration(labelText: 'Number Plate / नंबर प्लेट', prefixIcon: Icon(Icons.pin)), textCapitalization: TextCapitalization.characters),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedType,
            decoration: const InputDecoration(labelText: 'Vehicle Type', prefixIcon: Icon(Icons.category)),
            items: ['Car', 'Bike', 'Scooter', 'EV'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => selectedType = v ?? 'Car',
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 52, child: FilledButton.icon(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || numberCtrl.text.isEmpty) { showSnack(context, 'Please fill all fields', isError: true); return; }
              await FirestoreService.addDoc('vehicles', {
                'name': nameCtrl.text,
                'number': numberCtrl.text.toUpperCase(),
                'type': selectedType,
                'parkingSlot': 'Unassigned',
                'isInside': false,
              });
              if (!context.mounted) return;
              Navigator.pop(ctx);
              showSnack(context, 'Vehicle added successfully!');
            },
            icon: const Icon(Icons.add),
            label: const Text('Register Vehicle', style: TextStyle(fontSize: 16)),
          )),
        ]),
      ),
    );
  }
}

class _Vehicle {
  final String? id;
  final String name;
  final String number;
  final String type;
  final String parkingSlot;
  bool isInside;

  _Vehicle({this.id, required this.name, required this.number, required this.type, required this.parkingSlot, this.isInside = true});

  IconData get icon {
    switch (type) {
      case 'Bike': return Icons.two_wheeler;
      case 'Scooter': return Icons.electric_scooter;
      case 'EV': return Icons.electric_car;
      default: return Icons.directions_car;
    }
  }

  Color get color {
    switch (type) {
      case 'Bike': return Colors.orange;
      case 'Scooter': return Colors.purple;
      case 'EV': return Colors.green;
      default: return Colors.blue;
    }
  }
}

class _ParkingSlot {
  final String id;
  String status;
  String? flat;
  _ParkingSlot({required this.id, required this.status, this.flat});
}

class _MockVehicles {
  static List<_Vehicle> get vehicles => [
    _Vehicle(name: 'Maruti Swift Dzire', number: 'MH 12 AB 1234', type: 'Car', parkingSlot: 'B1-05', isInside: true),
    _Vehicle(name: 'Honda Activa 6G', number: 'MH 12 CD 5678', type: 'Scooter', parkingSlot: 'B2-12', isInside: false),
    _Vehicle(name: 'Tata Nexon EV', number: 'MH 12 EV 9012', type: 'EV', parkingSlot: 'B1-01', isInside: true),
  ];

  static List<_ParkingSlot> get slots => [
    _ParkingSlot(id: 'B1-01', status: 'occupied', flat: 'A-101'),
    _ParkingSlot(id: 'B1-02', status: 'occupied', flat: 'A-102'),
    _ParkingSlot(id: 'B1-03', status: 'available'),
    _ParkingSlot(id: 'B1-04', status: 'occupied', flat: 'A-201'),
    _ParkingSlot(id: 'B1-05', status: 'occupied', flat: 'A-202'),
    _ParkingSlot(id: 'B1-06', status: 'available'),
    _ParkingSlot(id: 'B1-07', status: 'reserved', flat: 'Visitor'),
    _ParkingSlot(id: 'B1-08', status: 'occupied', flat: 'A-302'),
    _ParkingSlot(id: 'B2-01', status: 'available'),
    _ParkingSlot(id: 'B2-02', status: 'occupied', flat: 'B-101'),
    _ParkingSlot(id: 'B2-03', status: 'occupied', flat: 'B-102'),
    _ParkingSlot(id: 'B2-04', status: 'available'),
  ];
}
