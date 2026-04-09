import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/mock_data.dart';
import '../../utils/helpers.dart';
import '../../utils/prefs_service.dart';
import '../../models/models.dart';
import '../../utils/app_colors.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../chat/chat_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _filter = 'All';
  String _serviceFilter = 'All';
  String _sortBy = 'Date';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  List<MarketItem> _applyFilter(List<MarketItem> items) {
    var list = _filter == 'All' ? items : items.where((i) => i.category == _filter).toList();
    switch (_sortBy) {
      case 'Price \u2191': list.sort((a, b) => a.price.compareTo(b.price));
      case 'Price \u2193': list.sort((a, b) => b.price.compareTo(a.price));
      default: list.sort((a, b) => b.date.compareTo(a.date));
    }
    return list;
  }

  List<ServiceItem> _applyServiceFilter(List<ServiceItem> services) =>
      _serviceFilter == 'All' ? services : services.where((s) => s.category == _serviceFilter).toList();

  static const _conditions = ['Like New', 'Used', 'Good', 'Fair'];
  String _conditionFor(MarketItem item) => _conditions[item.id.hashCode % _conditions.length];

  Color _conditionColor(String c) {
    switch (c) {
      case 'Like New': return AppColors.statusSuccess;
      case 'Used': return AppColors.statusWarning;
      case 'Good': return AppColors.primaryAmber;
      default: return AppColors.textTertiary;
    }
  }

  IconData _itemCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'electronics': return Icons.devices;
      case 'furniture': return Icons.chair;
      case 'kids': return Icons.child_care;
      case 'appliances': return Icons.kitchen;
      case 'clothing': return Icons.checkroom;
      case 'books': return Icons.menu_book;
      default: return Icons.category;
    }
  }

  Color _itemCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'electronics': return const Color(0xFF42A5F5);
      case 'furniture': return const Color(0xFF8D6E63);
      case 'kids': return const Color(0xFFEC407A);
      case 'appliances': return const Color(0xFF66BB6A);
      default: return const Color(0xFF7E57C2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final society = PrefsService.societyName;
    final serviceCats = ['All', 'General Store', 'Salon', 'Tuition', 'Gym', 'Laundry', 'Pharmacy'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: 'Items'), Tab(text: 'Services')],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItem(context),
        icon: const Icon(Icons.add),
        label: const Text('Sell'),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // Items tab - Firestore StreamBuilder
          StreamBuilder<QuerySnapshot>(
            stream: FirestoreService.marketplaceStream(society),
            builder: (context, snapshot) {
              List<MarketItem> items;
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                items = snapshot.data!.docs
                    .map((d) => FirestoreService.marketItemFromDoc(d))
                    .toList();
              } else {
                items = MockData.marketItems;
              }

              final cats = ['All', ...{...items.map((i) => i.category)}];
              final filtered = _applyFilter(items);

              return Column(
                children: [
                  // Filters row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: cats.length,
                              itemBuilder: (_, i) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: FilterChip(label: Text(cats[i], style: const TextStyle(fontSize: 12)), selected: _filter == cats[i],
                                  onSelected: (_) => setState(() => _filter = cats[i]),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.sort, size: 20),
                          onSelected: (v) => setState(() => _sortBy = v),
                          itemBuilder: (_) => ['Date', 'Price \u2191', 'Price \u2193'].map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.shopping_bag_outlined, size: 72, color: AppColors.cardBorder),
                            const SizedBox(height: 12),
                            Text('No items found', style: TextStyle(fontSize: 16, color: AppColors.textTertiary)),
                          ]))
                        : RefreshIndicator(
                            onRefresh: () async => setState(() {}),
                            child: GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, childAspectRatio: 0.62, crossAxisSpacing: 10, mainAxisSpacing: 10,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) => _ItemCard(
                                item: filtered[i],
                                condition: _conditionFor(filtered[i]),
                                conditionColor: _conditionColor(_conditionFor(filtered[i])),
                                categoryIcon: _itemCategoryIcon(filtered[i].category),
                                categoryColor: _itemCategoryColor(filtered[i].category),
                                onTap: () => _showItemDetail(context, filtered[i]),
                              ),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
          // Services tab - Firestore StreamBuilder
          StreamBuilder<QuerySnapshot>(
            stream: FirestoreService.servicesStream(society),
            builder: (context, snapshot) {
              List<ServiceItem> services;
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                services = snapshot.data!.docs
                    .map((d) => FirestoreService.serviceItemFromDoc(d))
                    .toList();
              } else {
                services = MockData.services;
              }

              final filteredServices = _applyServiceFilter(services);

              return Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: serviceCats.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(label: Text(serviceCats[i]), selected: _serviceFilter == serviceCats[i],
                          onSelected: (_) => setState(() => _serviceFilter = serviceCats[i])),
                      ),
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async => setState(() {}),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: filteredServices.length,
                        itemBuilder: (_, i) {
                          final s = filteredServices[i];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    CircleAvatar(
                                      backgroundColor: _serviceCatColor(s.category).withValues(alpha: 0.15),
                                      child: Icon(_serviceCatIcon(s.category), color: _serviceCatColor(s.category)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(s.shopName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Text(s.category, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                      ],
                                    )),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: AppColors.greenBg, borderRadius: BorderRadius.circular(8)),
                                      child: Text(s.timings, style: TextStyle(fontSize: 11, color: AppColors.statusSuccess, fontWeight: FontWeight.w500)),
                                    ),
                                  ]),
                                  const SizedBox(height: 8),
                                  Text(s.description, style: TextStyle(color: AppColors.textPrimary)),
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(s.flat, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    const Spacer(),
                                    OutlinedButton.icon(
                                      onPressed: () => showSnack(context, 'Calling ${s.contact}...'),
                                      icon: const Icon(Icons.phone, size: 16),
                                      label: Text(s.contact),
                                      style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                                    ),
                                  ]),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _serviceCatIcon(String cat) {
    switch (cat) {
      case 'General Store': return Icons.store;
      case 'Salon': return Icons.content_cut;
      case 'Tuition': return Icons.school;
      case 'Gym': return Icons.fitness_center;
      case 'Laundry': return Icons.local_laundry_service;
      case 'Pharmacy': return Icons.local_pharmacy;
      default: return Icons.store;
    }
  }

  Color _serviceCatColor(String cat) {
    switch (cat) {
      case 'General Store': return AppColors.statusSuccess;
      case 'Salon': return const Color(0xFFEC4899);
      case 'Tuition': return AppColors.primaryAmber;
      case 'Gym': return AppColors.primaryOrange;
      case 'Laundry': return AppColors.primaryAmber;
      case 'Pharmacy': return AppColors.statusError;
      default: return AppColors.textTertiary;
    }
  }

  void _showItemDetail(BuildContext context, MarketItem item) {
    final condition = _conditionFor(item);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            // Image placeholder
            Container(
              height: 160, width: double.infinity,
              decoration: BoxDecoration(
                color: _itemCategoryColor(item.category).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_itemCategoryIcon(item.category), size: 56, color: _itemCategoryColor(item.category).withValues(alpha: 0.5)),
                  const SizedBox(height: 4),
                  if (item.hasPhoto) Text('Photo', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Text(item.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _conditionColor(condition).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(condition, style: TextStyle(fontSize: 11, color: _conditionColor(condition), fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(formatCurrency(item.price), style: const TextStyle(fontSize: 26, color: AppColors.statusSuccess, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(item.description, style: const TextStyle(height: 1.5)),
            const SizedBox(height: 16),
            Row(children: [
              CircleAvatar(radius: 16, backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(item.seller[0], style: TextStyle(color: Theme.of(context).colorScheme.primary))),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.seller, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Flat ${item.sellerFlat} \u2022 ${timeAgo(item.date)}', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ]),
            const SizedBox(height: 20),
            if (!item.isSold) Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => showSnack(context, 'Negotiate request sent!'),
                    icon: const Icon(Icons.handshake, size: 18),
                    label: const Text('Negotiate'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ChatScreen(otherName: item.seller, otherFlat: item.sellerFlat, otherId: 'seller_${item.id}'),
                      ));
                    },
                    icon: const Icon(Icons.chat, size: 18),
                    label: const Text('Chat with Seller'),
                  ),
                ),
              ],
            ),
            if (item.isSold) Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.redBg, borderRadius: BorderRadius.circular(12)),
              child: const Text('This item has been sold', textAlign: TextAlign.center, style: TextStyle(color: AppColors.statusError, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAddItem(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    File? pickedImage;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Sell an Item', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Item Name')),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 12),
                TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (\u20B9)', prefixText: '\u20B9 ')),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final file = await StorageService.showImagePicker(ctx);
                    if (file != null) setBS(() => pickedImage = file);
                  },
                  icon: Icon(pickedImage != null ? Icons.check_circle : Icons.camera_alt),
                  label: Text(pickedImage != null ? 'Photo attached' : 'Add Photo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: pickedImage != null ? AppColors.statusSuccess : null,
                    side: pickedImage != null ? const BorderSide(color: AppColors.statusSuccess) : null,
                  ),
                ),
                if (pickedImage != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      pickedImage!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    if (titleCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                      String? photoUrl;
                      if (pickedImage != null) {
                        photoUrl = await StorageService.uploadImage(
                          pickedImage!,
                          'marketplace/${DateTime.now().millisecondsSinceEpoch}.jpg',
                        );
                      }
                      final item = MarketItem(
                        id: 'm_${DateTime.now().millisecondsSinceEpoch}',
                        title: titleCtrl.text, description: descCtrl.text,
                        price: double.tryParse(priceCtrl.text) ?? 0, category: 'Other',
                        seller: PrefsService.userName.isEmpty ? 'You' : PrefsService.userName,
                        sellerFlat: PrefsService.userFlat.isEmpty ? 'A-101' : PrefsService.userFlat,
                        date: DateTime.now(), hasPhoto: pickedImage != null,
                        photoUrl: photoUrl,
                      );
                      FirestoreService.addMarketItem(item);
                      if (!context.mounted) return;
                      Navigator.pop(ctx);
                      showSnack(context, '\u2705 Item listed!');
                    }
                  },
                  child: const Text('List Item'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final MarketItem item;
  final String condition;
  final Color conditionColor;
  final IconData categoryIcon;
  final Color categoryColor;
  final VoidCallback onTap;

  const _ItemCard({
    required this.item, required this.condition, required this.conditionColor,
    required this.categoryIcon, required this.categoryColor, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder with category icon
            Container(
              height: 110, width: double.infinity,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  Center(child: Icon(categoryIcon, size: 48, color: categoryColor.withValues(alpha: 0.4))),
                  if (item.isSold) Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: const Center(child: Text('SOLD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))),
                  ),
                  // Condition tag
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: conditionColor.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(6)),
                      child: Text(condition, style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(formatCurrency(item.price), style: const TextStyle(color: AppColors.statusSuccess, fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 4),
                  Text('${item.seller} \u2022 ${item.sellerFlat}', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
