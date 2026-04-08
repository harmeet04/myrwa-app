import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/mock_data.dart';
import '../../utils/helpers.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../widgets/filter_chip_bar.dart';
import '../../widgets/warm_card.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/empty_state.dart';

class VisitorsScreen extends StatefulWidget {
  const VisitorsScreen({super.key});

  @override
  State<VisitorsScreen> createState() => _VisitorsScreenState();
}

class _VisitorsScreenState extends State<VisitorsScreen> {
  late List<Visitor> _visitors;
  int _filterIndex = 0;

  static const _filterOptions = ['All', '⏳ Pending', '✅ Approved', '✓ Completed'];

  @override
  void initState() {
    super.initState();
    _visitors = MockData.visitors;
  }

  List<Visitor> get _filtered {
    switch (_filterIndex) {
      case 1:
        return _visitors.where((v) => v.status == VisitorStatus.pending).toList();
      case 2:
        return _visitors.where((v) => v.status == VisitorStatus.approved).toList();
      case 3:
        return _visitors.where((v) => v.status == VisitorStatus.completed).toList();
      default:
        return _visitors;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: AppColors.scaffoldLight,
      appBar: AppBar(
        title: const Text('Visitor Management'),
        backgroundColor: AppColors.scaffoldLight,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: _buildFab(),
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          FilterChipBar(
            options: _filterOptions,
            selectedIndex: _filterIndex,
            onSelected: (i) => setState(() => _filterIndex = i),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    emoji: '🏠',
                    title: 'No visitors today',
                    subtitle: 'Pre-approve a visitor using the button below.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _VisitorCard(
                      visitor: filtered[i],
                      onApprove: () => setState(() => filtered[i].status = VisitorStatus.approved),
                      onReject: () => setState(() => filtered[i].status = VisitorStatus.rejected),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
        boxShadow: AppColors.fabShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAddVisitor(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('➕', style: TextStyle(fontSize: 16)),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'Pre-approve Visitor',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddVisitor(BuildContext context) {
    final nameCtrl = TextEditingController();
    final purposeCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusModal)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Pre-approve Visitor',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildField(nameCtrl, 'Visitor Name', Icons.person_outline),
            const SizedBox(height: AppSpacing.md),
            _buildField(purposeCtrl, 'Purpose (e.g. Guest, Delivery)', Icons.info_outline),
            const SizedBox(height: AppSpacing.xl),
            _buildSubmitButton(ctx, nameCtrl, purposeCtrl),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.amberBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          borderSide: const BorderSide(color: AppColors.amberBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          borderSide: const BorderSide(color: AppColors.amberBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          borderSide: const BorderSide(color: AppColors.primaryAmber, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext ctx, TextEditingController nameCtrl, TextEditingController purposeCtrl) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
        boxShadow: AppColors.fabShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (nameCtrl.text.isNotEmpty) {
              final otp = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000))
                  .toString()
                  .substring(0, 4);
              setState(() {
                _visitors.insert(
                  0,
                  Visitor(
                    id: 'v_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text,
                    purpose: purposeCtrl.text.isEmpty ? 'Guest Visit' : purposeCtrl.text,
                    flat: 'A-101',
                    date: DateTime.now(),
                    otp: otp,
                    status: VisitorStatus.approved,
                  ),
                );
              });
              Navigator.pop(ctx);
              showSnack(context, 'Visitor pre-approved! OTP: $otp');
            }
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              'Approve & Generate OTP',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Visitor Card ──────────────────────────────────────────────────────────────

class _VisitorCard extends StatelessWidget {
  final Visitor visitor;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _VisitorCard({
    required this.visitor,
    required this.onApprove,
    required this.onReject,
  });

  static Map<String, dynamic> _purposeStyle(String purpose) {
    final p = purpose.toLowerCase();
    if (p.contains('delivery')) return {'emoji': '📦', 'bg': AppColors.greenBg};
    if (p.contains('guest'))    return {'emoji': '👤', 'bg': AppColors.blueBg};
    if (p.contains('cab'))      return {'emoji': '🚕', 'bg': AppColors.amberBg};
    return {'emoji': '🚶', 'bg': AppColors.purpleBg};
  }

  Color _statusChipColor(VisitorStatus s) {
    switch (s) {
      case VisitorStatus.approved:  return AppColors.statusSuccess;
      case VisitorStatus.pending:   return AppColors.statusWarning;
      case VisitorStatus.rejected:  return AppColors.statusError;
      case VisitorStatus.completed: return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _purposeStyle(visitor.purpose);
    final isPending = visitor.status == VisitorStatus.pending;

    return WarmCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Purpose emoji icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: style['bg'] as Color,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(style['emoji'] as String, style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: AppSpacing.md),
              // Middle column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visitor.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${visitor.purpose} • ${timeAgo(visitor.date)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Status chip
              StatusChip(
                label: visitor.status.name,
                color: _statusChipColor(visitor.status),
              ),
            ],
          ),

          // OTP row
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.home_outlined, size: 12, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                'Flat ${visitor.flat}',
                style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(Icons.access_time, size: 12, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                formatTime(visitor.date),
                style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.amberBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
                  border: Border.all(color: AppColors.amberBorder, width: 0.5),
                ),
                child: Text(
                  'OTP: ${visitor.otp}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textOnPrimary,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),

          // Approve / Reject row for pending visitors
          if (isPending) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: '✓ Approve',
                    color: AppColors.statusSuccess,
                    onTap: onApprove,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ActionButton(
                    label: '✗ Reject',
                    color: AppColors.statusError,
                    onTap: onReject,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Small action button ───────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
