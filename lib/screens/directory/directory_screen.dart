import 'package:flutter/material.dart';
import '../../utils/mock_data.dart';
import '../../services/firestore_service.dart';
import '../../utils/helpers.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final residents = MockData.residents.where((r) =>
        _search.isEmpty || r.name.toLowerCase().contains(_search.toLowerCase()) || r.flat.toLowerCase().contains(_search.toLowerCase())).toList();
    residents.sort((a, b) => a.name.compareTo(b.name));
    final emergency = MockData.emergencyContacts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Directory'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: 'Residents'), Tab(text: 'Emergency')],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          Column(
            children: [
              // Always visible search
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search by name or flat...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _search = ''))
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                ),
              ),
              Expanded(
                child: residents.isEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.person_search_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text('No residents found', style: TextStyle(color: Colors.grey.shade500)),
                      ]))
                    : RefreshIndicator(
                        onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
                        child: ListView.builder(
                          itemCount: residents.length,
                          itemBuilder: (_, i) {
                            final r = residents[i];
                            // Alphabetical section header
                            final showHeader = i == 0 || r.name[0].toUpperCase() != residents[i - 1].name[0].toUpperCase();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showHeader) Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                                  child: Text(r.name[0].toUpperCase(),
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.primary)),
                                ),
                                Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: Color(r.avatarColor),
                                          child: Text(r.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(children: [
                                              Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                              if (r.isAdmin) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                  decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(4)),
                                                  child: Text('Admin', style: TextStyle(fontSize: 10, color: cs.primary, fontWeight: FontWeight.w600)),
                                                ),
                                              ],
                                            ]),
                                            const SizedBox(height: 2),
                                            Text(r.phone, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                          ],
                                        )),
                                        // Flat number prominently
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: cs.primaryContainer.withValues(alpha: 0.5),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(r.flat, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.primary)),
                                        ),
                                        const SizedBox(width: 8),
                                        // Quick action buttons
                                        IconButton(
                                          icon: const Icon(Icons.phone, color: Colors.green, size: 20),
                                          onPressed: () => showSnack(context, 'Calling ${r.name}...'),
                                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                          padding: EdgeInsets.zero,
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.chat, color: Colors.green.shade700, size: 20),
                                          onPressed: () => showSnack(context, 'Opening WhatsApp for ${r.name}...'),
                                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
          // Emergency contacts tab
          RefreshIndicator(
            onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: emergency.length,
              itemBuilder: (_, i) {
                final e = emergency[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _emergencyColor(e.category).withValues(alpha: 0.15),
                      child: Icon(_emergencyIcon(e.category), color: _emergencyColor(e.category)),
                    ),
                    title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(e.category),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (e.rating > 0) ...[
                          Icon(Icons.star, size: 16, color: Colors.amber.shade700),
                          const SizedBox(width: 2),
                          Text(e.rating.toString(), style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 8),
                        ],
                        IconButton(icon: const Icon(Icons.phone, color: Colors.green), onPressed: () => showSnack(context, 'Calling ${e.name}...')),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _emergencyIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'plumber': return Icons.plumbing;
      case 'electrician': return Icons.electrical_services;
      case 'doctor (general)': return Icons.medical_services;
      case 'hospital': return Icons.local_hospital;
      case 'carpenter': return Icons.handyman;
      case 'police': return Icons.local_police;
      case 'fire': return Icons.fire_truck;
      case 'ambulance': return Icons.emergency;
      default: return Icons.phone;
    }
  }

  Color _emergencyColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'plumber': return Colors.blue;
      case 'electrician': return Colors.orange;
      case 'doctor (general)': return Colors.red;
      case 'hospital': return Colors.red;
      case 'carpenter': return Colors.brown;
      case 'police': return Colors.indigo;
      case 'fire': return Colors.deepOrange;
      case 'ambulance': return Colors.red;
      default: return Colors.grey;
    }
  }
}
