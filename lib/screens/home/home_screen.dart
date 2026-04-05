import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../utils/prefs_service.dart';
import '../../utils/mock_data.dart';
import '../../services/firestore_service.dart';
import '../../utils/helpers.dart';
import '../../utils/locale_provider.dart';
import '../events/events_screen.dart';
import '../directory/directory_screen.dart';
import '../visitors/visitors_screen.dart';
import '../polls/polls_screen.dart';
import '../bills/bills_screen.dart';
import '../gate_log/gate_log_screen.dart';
import '../qr_pass/qr_pass_screen.dart';
import '../vehicle/vehicle_screen.dart';
import '../notices/notices_screen.dart';
import '../profile/profile_screen.dart';
import '../sos/sos_screen.dart';
import '../staff/staff_screen.dart';
import '../packages/packages_screen.dart';
import '../facility/facility_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting(LocaleProvider locale) {
    final hour = DateTime.now().hour;
    if (hour < 12) return locale.get('good_morning');
    if (hour < 17) return locale.get('good_afternoon');
    return locale.get('good_evening');
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final notices = MockData.notices.take(5).toList();
    final userName = PrefsService.userName.isEmpty
        ? 'Resident'
        : PrefsService.userName.split(' ')[0];
    final societyName = PrefsService.societyName.isEmpty
        ? 'myRWA'
        : PrefsService.societyName;
    final userFlat = PrefsService.userFlat;
    final isSector = PrefsService.isSector;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: _SOSFab(onTap: () => _push(context, const SosScreen())),
      body: CustomScrollView(
        slivers: [
          // Gradient Header
          SliverToBoxAdapter(
            child: _HeaderSection(
              greeting: _greeting(locale),
              userName: userName,
              societyName: societyName,
              flat: userFlat,
              isSector: isSector,
              onNotification: () {},
              onProfile: () => _push(context, ProfileScreen(onThemeToggle: () {})),
            ),
          ),

          // Today's Summary Card
          SliverToBoxAdapter(child: _TodaySummaryCard(isSector: isSector)),

          // Quick Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(locale.get('quick_actions'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          SliverToBoxAdapter(
            child: _QuickActionsGrid(locale: locale, onPush: (w) => _push(context, w), isSector: isSector),
          ),

          // Announcements
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(locale.get('announcements'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () => _push(context, const NoticesScreen()),
                    child: Text(locale.get('view_all'),
                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: notices.length,
                itemBuilder: (ctx, i) => _AnnouncementCard(notice: notices[i]),
              ),
            ),
          ),

          // Recent Activity
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(locale.get('recent_activity'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          SliverToBoxAdapter(child: _RecentActivitySection(locale: locale, isSector: isSector)),

          // Emergency Contacts
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(locale.get('emergency'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          SliverToBoxAdapter(child: _EmergencyBar(locale: locale)),

          // Pending Bills Card
          SliverToBoxAdapter(child: _PendingBillsCard(locale: locale, onTap: () => _push(context, const BillsScreen()))),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

// ─── SOS FAB ───
class _SOSFab extends StatefulWidget {
  final VoidCallback onTap;
  const _SOSFab({required this.onTap});

  @override
  State<_SOSFab> createState() => _SOSFabState();
}

class _SOSFabState extends State<_SOSFab> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      listenable: _pulse,
      builder: (_, child) => Transform.scale(scale: _pulse.value, child: child),
      child: FloatingActionButton(
        onPressed: widget.onTap,
        backgroundColor: Colors.red,
        child: const Icon(Icons.sos, color: Colors.white, size: 28),
      ),
    );
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;
  const AnimatedBuilder({super.key, required super.listenable, required this.builder, this.child});
  @override
  Widget build(BuildContext context) => builder(context, child);
}

// ─── Today's Summary ───
class _TodaySummaryCard extends StatelessWidget {
  final bool isSector;
  const _TodaySummaryCard({this.isSector = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text("Today's Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                // Weather widget
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('☀️', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text('32°C', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blue.shade700)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!isSector) ...[
                  _SummaryChip(Icons.people_outlined, '3', 'Visitors', Colors.orange),
                  const SizedBox(width: 12),
                ],
                _SummaryChip(Icons.inventory_2_outlined, '4', 'Packages', Colors.blue),
                const SizedBox(width: 12),
                _SummaryChip(Icons.report_problem_outlined, '2', 'Complaints', Colors.red),
                const SizedBox(width: 12),
                _SummaryChip(Icons.event_outlined, '1', 'Events', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String count;
  final String label;
  final Color color;
  const _SummaryChip(this.icon, this.count, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

// ─── Header with gradient ───
class _HeaderSection extends StatelessWidget {
  final String greeting, userName, societyName, flat;
  final bool isSector;
  final VoidCallback onNotification, onProfile;

  const _HeaderSection({
    required this.greeting,
    required this.userName,
    required this.societyName,
    required this.flat,
    this.isSector = false,
    required this.onNotification,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$greeting, $userName 👋',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text('$societyName${flat.isNotEmpty ? ' • ${isSector ? 'House' : 'Flat'} $flat' : ''}',
                    style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.85))),
              ],
            ),
          ),
          IconButton(
            onPressed: onNotification,
            icon: Badge(
              label: const Text('3'),
              child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onProfile,
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions Grid with Gradient Icons ───
class _QuickActionsGrid extends StatelessWidget {
  final LocaleProvider locale;
  final void Function(Widget) onPush;
  final bool isSector;

  const _QuickActionsGrid({required this.locale, required this.onPush, this.isSector = false});

  @override
  Widget build(BuildContext context) {
    final actions = [
      if (!isSector) _QA(Icons.door_front_door_rounded, locale.get('visitors'), [const Color(0xFFFF7043), const Color(0xFFFF5722)], () => onPush(const VisitorsScreen()), 1),
      if (!isSector) _QA(Icons.door_sliding_rounded, locale.get('gate_log'), [const Color(0xFF7E57C2), const Color(0xFF5C6BC0)], () => onPush(const GateLogScreen()), 0),
      _QA(Icons.receipt_long_rounded, locale.get('bills'), [const Color(0xFF66BB6A), const Color(0xFF43A047)], () => onPush(const BillsScreen()), 2),
      _QA(Icons.event_rounded, locale.get('events'), [const Color(0xFFEC407A), const Color(0xFFD81B60)], () => onPush(const EventsScreen()), 0),
      _QA(Icons.inventory_2_rounded, 'Packages', [const Color(0xFF42A5F5), const Color(0xFF1E88E5)], () => onPush(const PackagesScreen()), 4),
      if (!isSector) _QA(Icons.qr_code_rounded, locale.get('qr_pass'), [const Color(0xFF29B6F6), const Color(0xFF039BE5)], () => onPush(const QrPassScreen()), 0),
      _QA(Icons.meeting_room_rounded, 'Amenities', [const Color(0xFFAB47BC), const Color(0xFF8E24AA)], () => onPush(const FacilityScreen()), 0),
      _QA(Icons.badge_rounded, 'Daily Help', [const Color(0xFF26A69A), const Color(0xFF00897B)], () => onPush(const StaffScreen()), 0),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.8,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: actions.length,
        itemBuilder: (ctx, i) {
          final a = actions[i];
          return GestureDetector(
            onTap: a.onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: a.gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: a.gradientColors[0].withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Icon(a.icon, color: Colors.white, size: 26),
                    ),
                    if (a.badge > 0) Positioned(
                      top: -4, right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text('${a.badge}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(a.label,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QA {
  final IconData icon;
  final String label;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  final int badge;
  const _QA(this.icon, this.label, this.gradientColors, this.onTap, this.badge);
}

// ─── Announcement Card ───
class _AnnouncementCard extends StatelessWidget {
  final Notice notice;
  const _AnnouncementCard({required this.notice});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(notice.category,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF1565C0))),
              ),
              const Spacer(),
              if (notice.isPinned) const Icon(Icons.push_pin, size: 14, color: Color(0xFF1565C0)),
              // New badge for recent notices
              if (DateTime.now().difference(notice.date).inDays < 3) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                  child: const Text('NEW', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(notice.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(formatDate(notice.date),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              const Spacer(),
              Icon(Icons.favorite, size: 12, color: Colors.red.shade300),
              const SizedBox(width: 2),
              Text('${notice.likes}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Recent Activity ───
class _RecentActivitySection extends StatelessWidget {
  final LocaleProvider locale;
  final bool isSector;
  const _RecentActivitySection({required this.locale, this.isSector = false});

  @override
  Widget build(BuildContext context) {
    final activities = [
      if (!isSector) _Activity(Icons.person_add_rounded, const Color(0xFF66BB6A), locale.get('visitor_approved'), 'Swiggy Delivery • Flat A-201', '30 min ago'),
      _Activity(Icons.inventory_2_rounded, const Color(0xFFFF9900), 'Package Arrived', 'Amazon parcel at gate', '1 hr ago'),
      _Activity(Icons.build_circle_rounded, const Color(0xFF42A5F5), locale.get('complaint_update'), 'Water leakage fix in progress', '2 hrs ago'),
      _Activity(Icons.payment_rounded, const Color(0xFFFF7043), locale.get('payment_due'), 'Maintenance Q1 - ₹4,500', '1 day ago'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: activities.asMap().entries.map((e) {
            final a = e.value;
            final isLast = e.key == activities.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: a.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(a.icon, color: a.color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(a.subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      Text(a.time, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                    ],
                  ),
                ),
                if (!isLast) Divider(height: 1, indent: 68, color: Colors.grey.shade200),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _Activity {
  final IconData icon;
  final Color color;
  final String title, subtitle, time;
  const _Activity(this.icon, this.color, this.title, this.subtitle, this.time);
}

// ─── Emergency Bar ───
class _EmergencyBar extends StatelessWidget {
  final LocaleProvider locale;
  const _EmergencyBar({required this.locale});

  @override
  Widget build(BuildContext context) {
    final contacts = [
      (locale.get('police'), '100', Icons.local_police_rounded, const Color(0xFF3949AB)),
      (locale.get('fire'), '101', Icons.fire_truck_rounded, const Color(0xFFE64A19)),
      (locale.get('ambulance'), '108', Icons.emergency_rounded, const Color(0xFFD32F2F)),
      (locale.get('women_helpline'), '1091', Icons.woman_rounded, const Color(0xFF7B1FA2)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: contacts.map((c) => GestureDetector(
            onTap: () => showSnack(context, 'Calling ${c.$1} (${c.$2})...'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: c.$4.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(c.$3, size: 24, color: c.$4),
                ),
                const SizedBox(height: 6),
                Text(c.$2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: c.$4)),
                Text(c.$1, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }
}

// ─── Pending Bills Card ───
class _PendingBillsCard extends StatelessWidget {
  final LocaleProvider locale;
  final VoidCallback onTap;
  const _PendingBillsCard({required this.locale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pending = MockData.bills.where((b) => b.status != BillStatus.paid).toList();
    if (pending.isEmpty) return const SizedBox.shrink();
    final total = pending.fold<double>(0, (s, b) => s + b.amount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.deepOrange.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${pending.length} ${locale.get('pending_bills')}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text('${locale.get('total')}: ${formatCurrency(total)}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
