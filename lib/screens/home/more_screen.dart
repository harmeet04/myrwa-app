import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/prefs_service.dart';
import '../../utils/locale_provider.dart';
import '../bills/bills_screen.dart';
import '../profile/profile_screen.dart';
import '../gate_log/gate_log_screen.dart';
import '../admin/admin_panel_screen.dart';
import '../qr_pass/qr_pass_screen.dart';
import '../sos/sos_screen.dart';
import '../vendor/vendor_screen.dart';
import '../accounting/accounting_screen.dart';
import '../documents/documents_screen.dart';
import '../guard/guard_screen.dart';
import '../ai_assistant/ai_assistant_screen.dart';
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
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          _MoreTile(
            icon: Icons.smart_toy,
            title: 'AI Assistant',
            subtitle: 'Ask anything about your society',
            iconColor: AppColors.primaryAmber,
            bgColor: AppColors.amberBg,
            onTap: () => _push(context, const AiAssistantScreen()),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _SectionHeader('Finances'),
          _MoreTile(
            icon: Icons.receipt_long,
            title: locale.get('bill_payments'),
            subtitle: locale.get('sub_bills'),
            iconColor: AppColors.primaryAmber,
            bgColor: AppColors.amberBg,
            onTap: () => _push(context, const BillsScreen()),
          ),
          if (PrefsService.isAdmin)
            _MoreTile(
              icon: Icons.account_balance,
              title: locale.get('accounting'),
              subtitle: locale.get('sub_accounting'),
              iconColor: AppColors.primaryOrange,
              bgColor: AppColors.amberBg,
              onTap: () => _push(context, const AccountingScreen()),
            ),

          if (PrefsService.isGatedCommunity) ...[
            _SectionHeader('Gate & Security'),
            _MoreTile(
              icon: Icons.door_front_door,
              title: locale.get('visitor_management'),
              subtitle: locale.get('sub_visitors'),
              iconColor: AppColors.statusSuccess,
              bgColor: AppColors.greenBg,
              onTap: () => _push(context, const VisitorsScreen()),
            ),
            _MoreTile(
              icon: Icons.door_sliding,
              title: locale.get('gate_log'),
              subtitle: locale.get('sub_gate_log'),
              iconColor: AppColors.statusSuccess,
              bgColor: AppColors.greenBg,
              onTap: () => _push(context, const GateLogScreen()),
            ),
            _MoreTile(
              icon: Icons.qr_code,
              title: locale.get('qr_pass'),
              subtitle: locale.get('sub_qr_pass'),
              iconColor: AppColors.statusSuccess,
              bgColor: AppColors.greenBg,
              onTap: () => _push(context, const QrPassScreen()),
            ),
            if (PrefsService.isAdmin)
              _MoreTile(
                icon: Icons.security,
                title: locale.get('guard'),
                subtitle: locale.get('sub_guard'),
                iconColor: AppColors.textSecondary,
                bgColor: const Color(0xFFF5F5F4),
                onTap: () => _push(context, const GuardScreen()),
              ),
          ],
          _MoreTile(
            icon: Icons.sos,
            title: locale.get('sos'),
            subtitle: locale.get('sub_sos'),
            iconColor: AppColors.statusError,
            bgColor: AppColors.redBg,
            onTap: () => _push(context, const SosScreen()),
          ),

          _SectionHeader('Governance'),
          _MoreTile(
            icon: Icons.folder,
            title: locale.get('documents'),
            subtitle: locale.get('sub_documents'),
            iconColor: const Color(0xFF7C3AED),
            bgColor: AppColors.purpleBg,
            onTap: () => _push(context, const DocumentsScreen()),
          ),
          _MoreTile(
            icon: Icons.handyman,
            title: locale.get('vendors'),
            subtitle: locale.get('sub_vendors'),
            iconColor: const Color(0xFF7C3AED),
            bgColor: AppColors.purpleBg,
            onTap: () => _push(context, const VendorScreen()),
          ),
          if (PrefsService.isAdmin) ...[
            _SectionHeader('Admin'),
            _MoreTile(
              icon: Icons.admin_panel_settings,
              title: locale.get('admin_panel'),
              subtitle: locale.get('sub_admin'),
              iconColor: AppColors.primaryOrange,
              bgColor: const Color(0xFFFFF7ED),
              onTap: () => _push(context, const AdminPanelScreen()),
            ),
          ],

          _SectionHeader('Settings'),
          _MoreTile(
            icon: Icons.language,
            title: locale.get('language'),
            subtitle: languageNames[locale.language] ?? 'English',
            iconColor: AppColors.textSecondary,
            bgColor: const Color(0xFFF5F5F4),
            onTap: () => _showLanguagePicker(context, locale),
          ),
          _MoreTile(
            icon: Icons.person,
            title: locale.get('profile_settings'),
            subtitle: locale.get('sub_profile'),
            iconColor: AppColors.textSecondary,
            bgColor: const Color(0xFFF5F5F4),
            onTap: () => _push(context, ProfileScreen(onThemeToggle: onThemeToggle)),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, LocaleProvider locale) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusModal))),
      builder: (ctx) => SafeArea(
        child: RadioGroup<AppLanguage>(
          groupValue: locale.language,
          onChanged: (v) {
            if (v == null) return;
            locale.setLanguage(v);
            Navigator.pop(ctx);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text('Select Language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ...AppLanguage.values.map((lang) => ListTile(
                leading: Radio<AppLanguage>(
                  value: lang,
                ),
                title: Text(languageNames[lang] ?? lang.name),
                subtitle: Text(lang.name[0].toUpperCase() + lang.name.substring(1)),
                onTap: () {
                  locale.setLanguage(lang);
                  Navigator.pop(ctx);
                },
              )),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
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
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xs),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.textTertiary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _MoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: onTap,
    );
  }
}
