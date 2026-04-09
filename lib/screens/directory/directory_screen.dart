import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/models.dart';
import '../../utils/mock_data.dart';
import '../../utils/helpers.dart';
import '../../utils/app_colors.dart';
import '../../utils/prefs_service.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../chat/chat_screen.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _search = '';
  Set<String> _blockedIds = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _blockedIds = PrefsService.blockedUserIds.toSet();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _callResident(Resident r) async {
    final uri = Uri(scheme: 'tel', path: r.phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _toggleBlock(Resident r) async {
    final isBlocked = _blockedIds.contains(r.id);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isBlocked ? 'Unblock ${r.name}?' : 'Block ${r.name}?'),
        content: Text(
          isBlocked
              ? '${r.name} will be able to message and call you again.'
              : "${r.name} won't be able to message or call you.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isBlocked ? 'Unblock' : 'Block',
                style: TextStyle(color: isBlocked ? AppColors.statusSuccess : AppColors.statusError)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        if (isBlocked) {
          _blockedIds.remove(r.id);
        } else {
          _blockedIds.add(r.id);
        }
      });
      await PrefsService.setBlockedUserIds(_blockedIds.toList());
      if (AuthService.uid.isNotEmpty) {
        FirestoreService.updateDoc('users', AuthService.uid, {
          'blockedUserIds': _blockedIds.toList(),
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final society = PrefsService.societyName;
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
          // Residents tab - uses Firestore StreamBuilder
          StreamBuilder<QuerySnapshot>(
            stream: FirestoreService.residentsStream(society),
            builder: (context, snapshot) {
              List<Resident> allResidents;
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                allResidents = snapshot.data!.docs
                    .map((d) => FirestoreService.residentFromDoc(d))
                    .toList();
              } else {
                allResidents = MockData.residents;
              }

              final residents = allResidents.where((r) =>
                  _search.isEmpty || r.name.toLowerCase().contains(_search.toLowerCase()) || r.flat.toLowerCase().contains(_search.toLowerCase())).toList();
              residents.sort((a, b) => a.name.compareTo(b.name));

              return Column(
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
                            Icon(Icons.person_search_outlined, size: 64, color: AppColors.cardBorder),
                            const SizedBox(height: 8),
                            Text('No residents found', style: TextStyle(color: AppColors.textTertiary)),
                          ]))
                        : RefreshIndicator(
                            onRefresh: () async => setState(() {}),
                            child: ListView.builder(
                              itemCount: residents.length,
                              itemBuilder: (_, i) {
                                final r = residents[i];
                                final isBlocked = _blockedIds.contains(r.id);
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
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
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
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            // Action buttons row or blocked badge
                                            if (isBlocked)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: AppColors.statusError.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: AppColors.statusError.withValues(alpha: 0.4)),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(Icons.block, size: 14, color: AppColors.statusError),
                                                        const SizedBox(width: 6),
                                                        Text('Blocked', style: TextStyle(fontSize: 12, color: AppColors.statusError, fontWeight: FontWeight.w600)),
                                                      ],
                                                    ),
                                                    TextButton(
                                                      onPressed: () => _toggleBlock(r),
                                                      style: TextButton.styleFrom(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        minimumSize: Size.zero,
                                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                      ),
                                                      child: Text('Unblock', style: TextStyle(fontSize: 12, color: AppColors.statusSuccess)),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            else
                                              Row(
                                                children: [
                                                  // Message button
                                                  Expanded(
                                                    child: OutlinedButton.icon(
                                                      onPressed: () => Navigator.push(context, MaterialPageRoute(
                                                        builder: (_) => ChatScreen(
                                                          otherName: r.name,
                                                          otherFlat: r.flat,
                                                          otherId: r.id,
                                                        ),
                                                      )),
                                                      icon: const Icon(Icons.message, size: 16, color: AppColors.primaryAmber),
                                                      label: const Text('Message', style: TextStyle(fontSize: 12, color: AppColors.primaryAmber)),
                                                      style: OutlinedButton.styleFrom(
                                                        side: const BorderSide(color: AppColors.amberBorder),
                                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // Call button (uses url_launcher, number hidden)
                                                  Expanded(
                                                    child: OutlinedButton.icon(
                                                      onPressed: () => _callResident(r),
                                                      icon: const Icon(Icons.phone, size: 16, color: AppColors.statusSuccess),
                                                      label: const Text('Call', style: TextStyle(fontSize: 12, color: AppColors.statusSuccess)),
                                                      style: OutlinedButton.styleFrom(
                                                        side: const BorderSide(color: AppColors.greenBorder),
                                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // Block button
                                                  IconButton(
                                                    onPressed: () => _toggleBlock(r),
                                                    icon: Icon(
                                                      Icons.more_vert,
                                                      color: AppColors.textTertiary,
                                                      size: 20,
                                                    ),
                                                    tooltip: 'More',
                                                  ),
                                                ],
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
              );
            },
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
                          Icon(Icons.star, size: 16, color: AppColors.primaryAmber),
                          const SizedBox(width: 2),
                          Text(e.rating.toString(), style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 8),
                        ],
                        IconButton(icon: const Icon(Icons.phone, color: AppColors.statusSuccess), onPressed: () => showSnack(context, 'Calling ${e.name}...')),
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
      case 'plumber': return AppColors.primaryAmber;
      case 'electrician': return AppColors.primaryOrange;
      case 'doctor (general)': return AppColors.statusError;
      case 'hospital': return AppColors.statusError;
      case 'carpenter': return const Color(0xFF78350F);
      case 'police': return AppColors.primaryAmber;
      case 'fire': return AppColors.primaryOrange;
      case 'ambulance': return AppColors.statusError;
      default: return AppColors.textTertiary;
    }
  }
}
