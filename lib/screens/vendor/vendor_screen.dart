import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/helpers.dart';
import '../../utils/prefs_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';

class VendorScreen extends StatefulWidget {
  const VendorScreen({super.key});

  @override
  State<VendorScreen> createState() => _VendorScreenState();
}

class _VendorScreenState extends State<VendorScreen> {
  String _selectedCategory = 'All';

  static const _categories = ['All', 'Plumber', 'Electrician', 'Maid', 'Cook', 'Tutor', 'Carpenter', 'Pest Control', 'AC Repair'];

  @override
  Widget build(BuildContext context) {
    final society = PrefsService.societyName;
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Marketplace / सेवा प्रदाता')),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final cat = _categories[i];
                return FilterChip(selected: cat == _selectedCategory, label: Text(cat),
                  onSelected: (_) => setState(() => _selectedCategory = cat));
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirestoreService.collectionStream('vendors', society),
              builder: (context, snapshot) {
                List<_Vendor> vendors;
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  vendors = snapshot.data!.docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return _Vendor(
                      name: d['name'] ?? '',
                      category: d['category'] ?? '',
                      description: d['description'] ?? '',
                      rating: (d['rating'] ?? 4.0).toDouble(),
                      reviewCount: d['reviewCount'] ?? 0,
                      priceRange: d['priceRange'] ?? '',
                      area: d['area'] ?? '',
                      isVerified: d['isVerified'] ?? false,
                    );
                  }).toList();
                } else if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  vendors = _MockVendors.vendors;
                }

                final filtered = _selectedCategory == 'All' ? vendors : vendors.where((v) => v.category == _selectedCategory).toList();

                if (filtered.isEmpty) {
                  return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.handyman, size: 72, color: AppColors.cardBorder),
                    const SizedBox(height: 12),
                    Text('No vendors in this category', style: TextStyle(color: AppColors.textTertiary)),
                  ]));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final v = filtered[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            CircleAvatar(radius: 28, backgroundColor: v.color.withValues(alpha: 0.15),
                              child: Icon(v.icon, color: v.color, size: 28)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                if (v.isVerified)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: AppColors.greenBg, borderRadius: BorderRadius.circular(8)),
                                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                      Icon(Icons.verified, size: 14, color: AppColors.statusSuccess),
                                      SizedBox(width: 2),
                                      Text('RWA Verified', style: TextStyle(fontSize: 10, color: AppColors.statusSuccess, fontWeight: FontWeight.w600)),
                                    ]),
                                  ),
                              ]),
                              const SizedBox(height: 4),
                              Text(v.category, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              const SizedBox(height: 4),
                              Row(children: [
                                ...List.generate(5, (si) => Icon(
                                  si < v.rating.floor() ? Icons.star : (si < v.rating ? Icons.star_half : Icons.star_border),
                                  size: 16, color: Colors.amber)),
                                const SizedBox(width: 4),
                                Text('${v.rating} (${v.reviewCount})', style: const TextStyle(fontSize: 12)),
                              ]),
                            ])),
                          ]),
                          const SizedBox(height: 8),
                          Text(v.description, style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('💰 ${v.priceRange}  •  📍 ${v.area}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(child: OutlinedButton.icon(
                              onPressed: () => showSnack(context, 'Calling ${v.name}...'),
                              icon: const Icon(Icons.call, size: 18), label: const Text('Call / कॉल'))),
                            const SizedBox(width: 8),
                            Expanded(child: FilledButton.icon(
                              onPressed: () => _bookVendor(v),
                              icon: const Icon(Icons.calendar_today, size: 18), label: const Text('Book / बुक'))),
                          ]),
                        ]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _bookVendor(_Vendor v) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Book ${v.name}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.today),
            title: const Text('Today, 10:00 AM - 12:00 PM'),
            subtitle: const Text('Earliest available slot'),
            trailing: FilledButton(
              onPressed: () { Navigator.pop(context); showSnack(context, '✅ ${v.name} booked for today 10 AM!'); },
              child: const Text('Book')),
          ),
          ListTile(
            leading: const Icon(Icons.today),
            title: const Text('Today, 2:00 PM - 4:00 PM'),
            trailing: FilledButton(
              onPressed: () { Navigator.pop(context); showSnack(context, '✅ ${v.name} booked for today 2 PM!'); },
              child: const Text('Book')),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

class _Vendor {
  final String name;
  final String category;
  final String description;
  final double rating;
  final int reviewCount;
  final String priceRange;
  final String area;
  final bool isVerified;

  const _Vendor({required this.name, required this.category, required this.description,
    required this.rating, required this.reviewCount, required this.priceRange,
    required this.area, this.isVerified = false});

  IconData get icon {
    switch (category) {
      case 'Plumber': return Icons.plumbing;
      case 'Electrician': return Icons.electrical_services;
      case 'Maid': return Icons.cleaning_services;
      case 'Cook': return Icons.restaurant;
      case 'Tutor': return Icons.school;
      case 'Carpenter': return Icons.handyman;
      case 'Pest Control': return Icons.pest_control;
      case 'AC Repair': return Icons.ac_unit;
      default: return Icons.build;
    }
  }

  Color get color {
    switch (category) {
      case 'Plumber': return AppColors.primaryAmber;
      case 'Electrician': return AppColors.primaryOrange;
      case 'Maid': return const Color(0xFF7C3AED);
      case 'Cook': return AppColors.primaryOrange;
      case 'Tutor': return AppColors.primaryAmber;
      case 'Carpenter': return const Color(0xFF78350F);
      case 'Pest Control': return AppColors.statusSuccess;
      case 'AC Repair': return AppColors.primaryAmber;
      default: return AppColors.textTertiary;
    }
  }
}

class _MockVendors {
  static const vendors = [
    _Vendor(name: 'Raju Plumber', category: 'Plumber', description: 'Expert in leakage repair, bathroom fitting, pipe work.', rating: 4.5, reviewCount: 48, priceRange: '₹300-800/visit', area: 'Serves within 5 km', isVerified: true),
    _Vendor(name: 'Sunil Electrician', category: 'Electrician', description: 'Wiring, MCB, fan, geyser installation & repair.', rating: 4.3, reviewCount: 35, priceRange: '₹250-600/visit', area: 'Serves within 3 km', isVerified: true),
    _Vendor(name: 'Sunita Bai', category: 'Maid', description: 'Cleaning, mopping, utensils, laundry.', rating: 4.7, reviewCount: 62, priceRange: '₹3000-5000/month', area: 'Society resident', isVerified: true),
    _Vendor(name: 'Lakshmi Devi', category: 'Cook', description: 'North & South Indian cooking.', rating: 4.6, reviewCount: 41, priceRange: '₹5000-8000/month', area: 'Serves nearby societies', isVerified: true),
    _Vendor(name: 'Ramesh Sir', category: 'Tutor', description: 'Maths & Science for Class 8-12.', rating: 4.8, reviewCount: 29, priceRange: '₹2000-4000/month', area: 'Flat A-301', isVerified: false),
    _Vendor(name: 'PestFree Services', category: 'Pest Control', description: 'Cockroach, termite, mosquito treatment.', rating: 4.4, reviewCount: 56, priceRange: '₹800-2500/visit', area: 'City-wide service', isVerified: true),
  ];
}
