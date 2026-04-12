import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/prefs_service.dart';
import '../../utils/helpers.dart';
import '../../utils/locale_provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';
import '../auth/auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  const ProfileScreen({super.key, required this.onThemeToggle});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late bool _darkMode;
  late bool _notifications;
  late int _fontIndex;

  @override
  void initState() {
    super.initState();
    _darkMode = PrefsService.isDarkMode;
    _notifications = PrefsService.notificationsEnabled;
    _fontIndex = PrefsService.fontSizeIndex;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final locale = context.watch<LocaleProvider>();
    final fontLabels = [locale.get('small'), locale.get('normal'), locale.get('large')];

    return Scaffold(
      appBar: AppBar(title: Text(locale.get('profile_settings'))),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          Center(child: Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: cs.primary,
                child: Text(
                  PrefsService.userName.isNotEmpty ? PrefsService.userName[0] : '?',
                  style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              if (PrefsService.isAdmin) Positioned(
                bottom: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAmber,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Text('Admin', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ),
            ],
          )),
          const SizedBox(height: 12),
          Center(child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(PrefsService.userName.isEmpty ? 'Resident' : PrefsService.userName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              if (PrefsService.isAdmin) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.amberBg, borderRadius: BorderRadius.circular(6)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.admin_panel_settings, size: 14, color: AppColors.primaryOrange),
                    const SizedBox(width: 2),
                    Text('Admin', style: TextStyle(fontSize: 11, color: AppColors.primaryOrange, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ],
            ],
          )),
          Center(child: Text('Flat ${PrefsService.userFlat} • ${PrefsService.societyName}',
              style: TextStyle(color: AppColors.textSecondary))),
          const SizedBox(height: 16),

          _SectionHeader(locale.get('account')),
          _SettingsTile(icon: Icons.person, title: locale.get('edit_profile'), onTap: () => _editProfile(context)),
          _SettingsTile(icon: Icons.phone, title: 'Phone', subtitle: '+91 ${PrefsService.userPhone}'),
          _SettingsTile(icon: Icons.apartment, title: 'Society', subtitle: PrefsService.societyName),

          _SectionHeader(locale.get('preferences')),
          // Language
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(locale.get('language')),
            subtitle: Text(languageNames[locale.language] ?? 'English'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguagePicker(context, locale),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: Text(locale.get('dark_mode')),
            value: _darkMode,
            onChanged: (v) {
              setState(() => _darkMode = v);
              PrefsService.isDarkMode = v;
              widget.onThemeToggle();
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: Text(locale.get('notifications')),
            value: _notifications,
            onChanged: (v) {
              setState(() => _notifications = v);
              PrefsService.notificationsEnabled = v;
            },
          ),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: Text(locale.get('font_size')),
            subtitle: Text(fontLabels[_fontIndex]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('A', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: _fontIndex.toDouble(),
                    min: 0, max: 2, divisions: 2,
                    label: fontLabels[_fontIndex],
                    onChanged: (v) {
                      setState(() => _fontIndex = v.round());
                      PrefsService.fontSizeIndex = _fontIndex;
                      widget.onThemeToggle();
                    },
                  ),
                ),
                const Text('A', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          _SectionHeader(locale.get('about')),
          _SettingsTile(icon: Icons.info_outline, title: locale.get('app_version'), subtitle: '2.0.0'),
          _SettingsTile(icon: Icons.policy, title: locale.get('privacy_policy'), onTap: () {}),
          _SettingsTile(icon: Icons.description, title: locale.get('terms'), onTap: () {}),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, color: AppColors.statusError),
              label: Text(locale.get('logout'), style: const TextStyle(color: AppColors.statusError)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.statusError),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton.icon(
              onPressed: () => _deleteAccount(context),
              icon: const Icon(Icons.delete_forever, color: AppColors.statusError, size: 20),
              label: const Text('Delete Account', style: TextStyle(color: AppColors.statusError, fontSize: 13)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, LocaleProvider locale) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                padding: EdgeInsets.all(16),
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
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _editProfile(BuildContext context) {
    final nameCtrl = TextEditingController(text: PrefsService.userName);
    final flatCtrl = TextEditingController(text: PrefsService.userFlat);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Edit Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
            const SizedBox(height: 12),
            TextField(controller: flatCtrl, decoration: const InputDecoration(labelText: 'Flat Number')),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                await AuthService.saveUserProfile(
                  name: nameCtrl.text,
                  flat: flatCtrl.text,
                  phone: PrefsService.userPhone,
                  society: PrefsService.societyName,
                  communityType: PrefsService.communityType,
                  isAdmin: PrefsService.isAdmin,
                );
                setState(() {});
                if (!context.mounted) return;
                Navigator.pop(ctx);
                showSnack(context, 'Profile updated!');
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all associated data. This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.statusError),
            onPressed: () async {
              try {
                final user = AuthService.currentUser;
                if (user != null) {
                  // Delete user doc from Firestore
                  await FirestoreService.deleteDoc('users', user.uid);
                  // Delete Firebase Auth account
                  await user.delete();
                }
                await AuthService.signOut();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => AuthScreen(onThemeToggle: widget.onThemeToggle)),
                  (_) => false,
                );
              } catch (e) {
                if (!context.mounted) return;
                Navigator.pop(context);
                showSnack(context, 'Failed to delete account: $e', isError: true);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await AuthService.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => AuthScreen(onThemeToggle: widget.onThemeToggle)),
                (_) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  const _SettingsTile({required this.icon, required this.title, this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    subtitle: subtitle != null ? Text(subtitle!) : null,
    trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
    onTap: onTap,
  );
}

