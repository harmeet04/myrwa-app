import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/prefs_service.dart';
import '../../utils/locale_provider.dart';
import '../bills/bills_screen.dart';
import '../profile/profile_screen.dart';
import '../gate_log/gate_log_screen.dart';
import '../admin/admin_panel_screen.dart';
import '../qr_pass/qr_pass_screen.dart';
import '../vehicle/vehicle_screen.dart';
import '../sos/sos_screen.dart';
import '../vendor/vendor_screen.dart';
import '../accounting/accounting_screen.dart';
import '../voting/voting_screen.dart';
import '../documents/documents_screen.dart';
import '../guard/guard_screen.dart';
import '../visitors/visitors_screen.dart';

class MoreScreen extends StatelessWidget {
  final VoidCallback onThemeToggle;
  const MoreScreen({super.key, required this.onThemeToggle});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(locale.get('nav_more')),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader('Finances'),
          _MoreTile(icon: Icons.receipt_long, title: locale.get('bill_payments'), subtitle: locale.get('sub_bills'), color: Colors.green,
              onTap: () => _push(context, const BillsScreen())),
          _MoreTile(icon: Icons.account_balance, title: locale.get('accounting'), subtitle: locale.get('sub_accounting'), color: Colors.green.shade800,
              onTap: () => _push(context, const AccountingScreen())),

          _SectionHeader('Gate & Security'),
          _MoreTile(icon: Icons.door_front_door, title: locale.get('visitor_management'), subtitle: locale.get('sub_visitors'), color: Colors.orange,
              onTap: () => _push(context, const VisitorsScreen())),
          _MoreTile(icon: Icons.door_sliding, title: locale.get('gate_log'), subtitle: locale.get('sub_gate_log'), color: Colors.deepPurple,
              onTap: () => _push(context, const GateLogScreen())),
          _MoreTile(icon: Icons.qr_code, title: locale.get('qr_pass'), subtitle: locale.get('sub_qr_pass'), color: Colors.cyan,
              onTap: () => _push(context, const QrPassScreen())),
          _MoreTile(icon: Icons.security, title: locale.get('guard'), subtitle: locale.get('sub_guard'), color: Colors.grey.shade700,
              onTap: () => _push(context, const GuardScreen())),
          _MoreTile(icon: Icons.sos, title: locale.get('sos'), subtitle: locale.get('sub_sos'), color: Colors.red,
              onTap: () => _push(context, const SosScreen())),

          _SectionHeader('Vehicle & Parking'),
          _MoreTile(icon: Icons.local_parking, title: locale.get('vehicles'), subtitle: locale.get('sub_vehicles'), color: Colors.brown,
              onTap: () => _push(context, const VehicleScreen())),

          _SectionHeader('Governance'),
          _MoreTile(icon: Icons.how_to_vote, title: locale.get('voting'), subtitle: locale.get('sub_voting'), color: Colors.amber.shade800,
              onTap: () => _push(context, const VotingScreen())),
          _MoreTile(icon: Icons.folder, title: locale.get('documents'), subtitle: locale.get('sub_documents'), color: Colors.blue,
              onTap: () => _push(context, const DocumentsScreen())),
          _MoreTile(icon: Icons.handyman, title: locale.get('vendors'), subtitle: locale.get('sub_vendors'), color: Colors.teal,
              onTap: () => _push(context, const VendorScreen())),

          if (PrefsService.isAdmin) ...[
            _SectionHeader('Admin'),
            _MoreTile(icon: Icons.admin_panel_settings, title: locale.get('admin_panel'), subtitle: locale.get('sub_admin'), color: Colors.red,
                onTap: () => _push(context, const AdminPanelScreen())),
          ],

          _SectionHeader('Settings'),
          _MoreTile(
            icon: Icons.language,
            title: locale.get('language'),
            subtitle: languageNames[locale.language] ?? 'English',
            color: Colors.blue,
            onTap: () => _showLanguagePicker(context, locale),
          ),
          _MoreTile(icon: Icons.person, title: locale.get('profile_settings'), subtitle: locale.get('sub_profile'), color: Colors.blueGrey,
              onTap: () => _push(context, ProfileScreen(onThemeToggle: onThemeToggle))),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, LocaleProvider locale) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Select Language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ...AppLanguage.values.map((lang) => ListTile(
              leading: Radio<AppLanguage>(
                value: lang,
                groupValue: locale.language,
                onChanged: (v) {
                  locale.setLanguage(v!);
                  Navigator.pop(ctx);
                },
              ),
              title: Text(languageNames[lang] ?? lang.name),
              subtitle: Text(lang.name[0].toUpperCase() + lang.name.substring(1)),
              onTap: () {
                locale.setLanguage(lang);
                Navigator.pop(ctx);
              },
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5)),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MoreTile({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }
}
