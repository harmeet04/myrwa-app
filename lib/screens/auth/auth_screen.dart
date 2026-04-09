import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/mock_data.dart';
import '../../utils/helpers.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
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

  // --- Auth Logic (preserved exactly) ---

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
        debugPrint('Phone Auth Error: $error');
        showSnack(context, 'Auth error: $error', isError: true);
      },
      onAutoVerify: (credential) async {
        if (!mounted) return;
        try {
          await FirebaseAuth.instance.signInWithCredential(credential);
          final hasProfile = await AuthService.loadUserProfile();
          if (!mounted) return;
          if (hasProfile) { _goHome(); return; }
          final autoFilled = await _tryAutoFillFromPreRegistered();
          if (!mounted) return;
          if (autoFilled) {
            showSnack(context, 'Welcome! Your profile was set up automatically.');
            _goHome();
            return;
          }
          setState(() { _loading = false; _step = 2; });
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
      // 1. Check if user already has a profile in Firestore
      final hasProfile = await AuthService.loadUserProfile();
      if (!mounted) return;
      if (hasProfile) {
        _goHome();
        return;
      }
      // 2. Check if phone is pre-registered — auto-fill and go home
      final autoFilled = await _tryAutoFillFromPreRegistered();
      if (!mounted) return;
      if (autoFilled) {
        showSnack(context, 'Welcome! Your profile was set up automatically.');
        _goHome();
        return;
      }
      // 3. New user — manual profile setup
      setState(() { _loading = false; _step = 2; });
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

  /// Check if this phone number has pre-registered data.
  /// If yes, pre-fill all fields and save directly — skip manual steps.
  Future<bool> _tryAutoFillFromPreRegistered() async {
    final phone = _phoneCtrl.text;
    if (phone.isEmpty) return false;

    final data = await FirestoreService.lookupPreRegisteredUser(phone);
    if (data == null) return false;

    // Pre-registered user found — save profile and go home
    try {
      await AuthService.saveUserProfile(
        name: data['name'] ?? '',
        flat: data['flat'] ?? '',
        phone: phone,
        society: data['society'] ?? '',
        communityType: data['communityType'] ?? 'society',
        isAdmin: data['isAdmin'] ?? false,
      );
      await NotificationService.init();
      return true;
    } catch (e) {
      debugPrint('Pre-register auto-fill error: $e');
      // Fallback: pre-fill form fields so user can manually confirm
      _nameCtrl.text = data['name'] ?? '';
      _flatCtrl.text = data['flat'] ?? '';
      _selectedSociety = data['society'] ?? MockData.societyNames[0];
      _communityType = data['communityType'] ?? 'society';
      _loginAsAdmin = data['isAdmin'] ?? false;
      return false;
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

  bool get _isSector => _communityType == 'sector';

  // --- Step metadata ---

  static const _stepEmojis = ['\u{1F3E0}', '\u{1F4F1}', '\u{1F44B}', '\u{1F3D8}\u{FE0F}'];

  String get _stepTitle {
    switch (_step) {
      case 0: return 'Welcome to your community';
      case 1: return 'We sent you a code';
      case 2: return 'Tell us about yourself';
      case 3: return 'Find your community';
      default: return '';
    }
  }

  String get _stepSubtitle {
    switch (_step) {
      case 0: return "Let's get you set up in under a minute";
      case 1: return 'Enter the 6-digit OTP sent to +91 ${_phoneCtrl.text}';
      case 2: return 'Just a few details so your neighbours know you';
      case 3: return 'Select your community type and society';
      default: return '';
    }
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _buildStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    return KeyedSubtree(
      key: ValueKey<int>(_step),
      child: Column(
        children: [
          // Top illustrated area
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.surfaceLight, Color(0xFFFEF3C7)],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Text(
                    _stepEmojis[_step],
                    style: const TextStyle(fontSize: 72),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildProgressDots(),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
          // Bottom form area
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusModal)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, AppSpacing.lg,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - AppSpacing.xxl - AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _stepTitle,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _stepSubtitle,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        if (_step == 0) _phoneStep(),
                        if (_step == 1) _otpStep(),
                        if (_step == 2) _profileStep(),
                        if (_step == 3) _societyStep(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Progress Dots ---

  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final isCompleted = i < _step;
        final isCurrent = i == _step;
        final isFuture = i > _step;
        return Row(
          children: [
            if (i > 0)
              Container(
                width: 24,
                height: 2,
                color: isCompleted ? AppColors.primaryAmber : AppColors.cardBorder,
              ),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppColors.primaryAmber
                    : isCurrent
                        ? Colors.white
                        : Colors.transparent,
                border: Border.all(
                  color: isFuture ? AppColors.textTertiary : AppColors.primaryAmber,
                  width: 2,
                ),
                boxShadow: isCurrent
                    ? [BoxShadow(color: AppColors.primaryAmber.withValues(alpha: 0.4), blurRadius: 8)]
                    : null,
              ),
            ),
          ],
        );
      }),
    );
  }

  // --- Action Button ---

  Widget _buildActionButton({required String label, required VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: _loading ? null : onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: (_loading ? null : AppColors.primaryGradient),
          color: _loading ? AppColors.textTertiary : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
        ),
        alignment: Alignment.center,
        child: _loading
            ? const SizedBox(
                height: 20, width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // --- Step 0: Phone ---

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
      const SizedBox(height: AppSpacing.xl),
      _buildActionButton(label: 'Send OTP', onPressed: _sendOtp),
      const SizedBox(height: AppSpacing.lg),
      const Row(
        children: [
          Expanded(child: Divider()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text('OR', style: TextStyle(color: AppColors.textTertiary)),
          ),
          Expanded(child: Divider()),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      OutlinedButton.icon(
        onPressed: _loading ? null : _signInWithGoogle,
        icon: const Icon(Icons.g_mobiledata, size: 28),
        label: const Text('Sign in with Google', style: TextStyle(fontSize: 16)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppColors.primaryAmber),
          foregroundColor: AppColors.primaryAmber,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          ),
        ),
      ),
    ],
  );

  // --- Step 1: OTP ---

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
      const SizedBox(height: AppSpacing.xl),
      _buildActionButton(label: 'Verify OTP', onPressed: _verifyOtp),
      const SizedBox(height: AppSpacing.sm),
      TextButton(
        onPressed: () => setState(() => _step = 0),
        child: const Text(
          'Change number',
          style: TextStyle(color: AppColors.primaryAmber),
        ),
      ),
    ],
  );

  // --- Step 2: Profile ---

  Widget _profileStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        controller: _nameCtrl,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Full Name',
          prefixIcon: Icon(Icons.person),
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      TextField(
        controller: _flatCtrl,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(
          labelText: _isSector ? 'House Number (e.g. 1323)' : 'Flat Number (e.g. A-101)',
          prefixIcon: const Icon(Icons.home),
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      _buildActionButton(
        label: 'Next',
        onPressed: () {
          if (_nameCtrl.text.isEmpty || _flatCtrl.text.isEmpty) {
            showSnack(context, 'Please fill name and ${_isSector ? "house number" : "flat number"}', isError: true);
            return;
          }
          setState(() => _step = 3);
        },
      ),
    ],
  );

  // --- Step 3: Society Selection ---

  Widget _societyStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _communityTypeSelector(),
      const SizedBox(height: AppSpacing.lg),
      DropdownButtonFormField<String>(
        initialValue: _selectedSociety,
        decoration: InputDecoration(
          labelText: _isSector ? 'Select Sector/Colony' : 'Select Society',
          prefixIcon: Icon(_isSector ? Icons.holiday_village : Icons.apartment),
        ),
        items: MockData.societyNames
            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
            .toList(),
        onChanged: (v) => setState(() => _selectedSociety = v!),
      ),
      const SizedBox(height: AppSpacing.xxl),
      _buildActionButton(
        label: _isSector ? 'Join Community' : 'Join Society',
        onPressed: _completeProfile,
      ),
      const SizedBox(height: AppSpacing.sm),
      TextButton(
        onPressed: () => setState(() => _step = 2),
        child: const Text(
          'Back',
          style: TextStyle(color: AppColors.primaryAmber),
        ),
      ),
    ],
  );

  // --- Community Type Selector ---

  Widget _communityTypeSelector() {
    return Row(
      children: [
        Expanded(child: _communityCard(
          type: 'society',
          emoji: '\u{1F3E2}',
          title: 'Society',
          subtitle: 'Apartment complex, gated society',
        )),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _communityCard(
          type: 'sector',
          emoji: '\u{1F3D8}\u{FE0F}',
          title: 'Sector / Colony',
          subtitle: 'Open sector, colony, neighbourhood',
        )),
      ],
    );
  }

  Widget _communityCard({
    required String type,
    required String emoji,
    required String title,
    required String subtitle,
  }) {
    final selected = _communityType == type;
    return GestureDetector(
      onTap: () => setState(() => _communityType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.amberBg : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(
            color: selected ? AppColors.primaryAmber : AppColors.cardBorder,
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
              color: selected ? AppColors.primaryAmber : AppColors.textPrimary,
            )),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
