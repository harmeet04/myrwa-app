import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../utils/prefs_service.dart';
import '../../utils/mock_data.dart';
import '../../utils/helpers.dart';
import '../home/main_shell.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  const AuthScreen({super.key, required this.onThemeToggle});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _flatCtrl = TextEditingController();
  String _selectedSociety = MockData.societyNames[0];
  String _communityType = 'society';
  bool _loginAsAdmin = false;
  int _step = 0;
  bool _loading = false;
  String? _verificationId;

  void _sendOtp() {
    if (_phoneCtrl.text.length != 10) {
      showSnack(context, 'Enter valid 10-digit phone number', isError: true);
      return;
    }
    setState(() { _loading = true; });

    AuthService.sendOtp(
      phoneNumber: _phoneCtrl.text,
      onCodeSent: (verificationId, resendToken) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _step = 1;
          _verificationId = verificationId;
        });
        showSnack(context, 'OTP sent to +91 ${_phoneCtrl.text}');
      },
      onError: (error) {
        if (!mounted) return;
        setState(() { _loading = false; });
        showSnack(context, error, isError: true);
      },
      onAutoVerify: (credential) async {
        if (!mounted) return;
        try {
          await FirebaseAuth.instance.signInWithCredential(credential);
          final hasProfile = await AuthService.loadUserProfile();
          if (!mounted) return;
          if (hasProfile) {
            _goHome();
          } else {
            setState(() { _loading = false; _step = 2; });
          }
        } catch (e) {
          if (!mounted) return;
          setState(() { _loading = false; });
          showSnack(context, e.toString(), isError: true);
        }
      },
    );
  }

  void _verifyOtp() async {
    if (_otpCtrl.text.length < 4 || _verificationId == null) {
      showSnack(context, 'Enter valid OTP', isError: true);
      return;
    }
    setState(() { _loading = true; });
    try {
      await AuthService.verifyOtp(
        verificationId: _verificationId!,
        otp: _otpCtrl.text,
      );
      final hasProfile = await AuthService.loadUserProfile();
      if (!mounted) return;
      if (hasProfile) {
        _goHome();
      } else {
        setState(() { _loading = false; _step = 2; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; });
      showSnack(context, 'Invalid OTP. Please try again.', isError: true);
    }
  }

  void _signInWithGoogle() async {
    setState(() { _loading = true; });
    try {
      final result = await AuthService.signInWithGoogle();
      if (result == null) {
        if (!mounted) return;
        setState(() { _loading = false; });
        return;
      }
      final hasProfile = await AuthService.loadUserProfile();
      if (!mounted) return;
      if (hasProfile) {
        _goHome();
      } else {
        // Pre-fill name from Google
        _nameCtrl.text = result.user?.displayName ?? '';
        _phoneCtrl.text = result.user?.phoneNumber?.replaceAll('+91', '') ?? '';
        setState(() { _loading = false; _step = 2; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; });
      showSnack(context, 'Google sign-in failed: $e', isError: true);
    }
  }

  void _completeProfile() async {
    if (_nameCtrl.text.isEmpty || _flatCtrl.text.isEmpty) {
      showSnack(context, 'Please fill all fields', isError: true);
      return;
    }
    setState(() { _loading = true; });
    try {
      await AuthService.saveUserProfile(
        name: _nameCtrl.text,
        flat: _flatCtrl.text,
        phone: _phoneCtrl.text,
        society: _selectedSociety,
        communityType: _communityType,
        isAdmin: _loginAsAdmin,
      );
      // Init notifications after profile is saved
      await NotificationService.init();
      if (!mounted) return;
      _goHome();
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; });
      showSnack(context, 'Error saving profile: $e', isError: true);
    }
  }

  void _goHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MainShell(onThemeToggle: widget.onThemeToggle)),
    );
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _nameCtrl.dispose();
    _flatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
              Icon(Icons.apartment, size: 72, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text('myRWA', textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_stepSubtitle, textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
              const SizedBox(height: 40),
              if (_step == 0) _phoneStep(),
              if (_step == 1) _otpStep(),
              if (_step == 2) _profileStep(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _stepSubtitle {
    switch (_step) {
      case 0: return 'Enter your phone number to get started';
      case 1: return 'Enter the OTP sent to +91 ${_phoneCtrl.text}';
      case 2: return 'Complete your profile';
      default: return '';
    }
  }

  Widget _phoneStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        controller: _phoneCtrl,
        keyboardType: TextInputType.phone,
        maxLength: 10,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          labelText: 'Phone Number',
          prefixText: '+91  ',
          prefixIcon: Icon(Icons.phone),
          counterText: '',
        ),
      ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: _loading ? null : _sendOtp,
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        child: _loading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Send OTP', style: TextStyle(fontSize: 16)),
      ),
      const SizedBox(height: 16),
      const Row(
        children: [
          Expanded(child: Divider()),
          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('OR', style: TextStyle(color: Colors.grey))),
          Expanded(child: Divider()),
        ],
      ),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: _loading ? null : _signInWithGoogle,
        icon: const Icon(Icons.g_mobiledata, size: 28),
        label: const Text('Sign in with Google', style: TextStyle(fontSize: 16)),
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
      ),
    ],
  );

  Widget _otpStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        controller: _otpCtrl,
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24, letterSpacing: 12),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          labelText: 'Enter OTP',
          counterText: '',
          prefixIcon: Icon(Icons.lock),
        ),
      ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: _loading ? null : _verifyOtp,
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        child: _loading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Verify OTP', style: TextStyle(fontSize: 16)),
      ),
      TextButton(onPressed: () => setState(() => _step = 0), child: const Text('Change number')),
    ],
  );

  bool get _isSector => _communityType == 'sector';

  Widget _communityTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Community Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _communityCard(
              type: 'society',
              emoji: '🏢',
              title: 'Society',
              subtitle: 'Apartment complex, gated society, housing society',
              icon: Icons.apartment,
            )),
            const SizedBox(width: 12),
            Expanded(child: _communityCard(
              type: 'sector',
              emoji: '🏘️',
              title: 'Sector / Colony',
              subtitle: 'Open sector, colony, neighbourhood area',
              icon: Icons.holiday_village,
            )),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _communityCard({
    required String type,
    required String emoji,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _communityType == type;
    return GestureDetector(
      onTap: () => setState(() => _communityType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(title, style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: selected ? Theme.of(context).colorScheme.primary : null,
            )),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _profileStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _communityTypeSelector(),
      TextField(
        controller: _nameCtrl,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _flatCtrl,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(
          labelText: _isSector ? 'House Number (e.g. 42-B)' : 'Flat Number (e.g. A-101)',
          prefixIcon: const Icon(Icons.home),
        ),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: _selectedSociety,
        decoration: InputDecoration(
          labelText: _isSector ? 'Select Sector/Colony' : 'Select Society',
          prefixIcon: Icon(_isSector ? Icons.holiday_village : Icons.apartment),
        ),
        items: MockData.societyNames.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: (v) => setState(() => _selectedSociety = v!),
      ),
      const SizedBox(height: 16),
      TextField(
        decoration: InputDecoration(
          labelText: _isSector ? 'Area Code (optional)' : 'Society Code (optional)',
          prefixIcon: const Icon(Icons.vpn_key),
          hintText: _isSector ? 'Enter code shared by your area' : 'Enter code shared by your society',
        ),
      ),
      const SizedBox(height: 8),
      CheckboxListTile(
        title: const Text('Login as Admin (Secretary/Committee)'),
        subtitle: const Text('For demo: enables admin features', style: TextStyle(fontSize: 12)),
        value: _loginAsAdmin,
        onChanged: (v) => setState(() => _loginAsAdmin = v!),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: _loading ? null : _completeProfile,
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        child: _loading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(_isSector ? 'Join Community' : 'Join Society', style: const TextStyle(fontSize: 16)),
      ),
    ],
  );
}
