import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/prefs_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static User? get currentUser => _auth.currentUser;
  static String get uid => _auth.currentUser?.uid ?? '';
  static bool get isLoggedIn => _auth.currentUser != null;

  // Phone OTP
  static Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(String error) onError,
    required Function(PhoneAuthCredential credential) onAutoVerify,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: '+91$phoneNumber',
      timeout: const Duration(seconds: 60),
      verificationCompleted: onAutoVerify,
      verificationFailed: (e) => onError('[${e.code}] ${e.message ?? 'Unknown error'}'),
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  static Future<UserCredential> verifyOtp({
    required String verificationId,
    required String otp,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );
    return await _auth.signInWithCredential(credential);
  }

  // Google Sign-In
  static Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return await _auth.signInWithCredential(credential);
  }

  // Save/update user profile in Firestore
  static Future<void> saveUserProfile({
    required String name,
    required String flat,
    required String phone,
    required String society,
    required String communityType,
    bool isAdmin = false,
    bool isGated = true,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = _db.collection('users').doc(user.uid);
    final snap = await doc.get();

    final data = {
      'name': name,
      'flat': flat,
      'phone': phone,
      'society': society,
      'communityType': communityType,
      'isAdmin': isAdmin,
      'isGated': isGated,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!snap.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['avatarColor'] = 0xFF1565C0;
      await doc.set(data);
    } else {
      await doc.update(data);
    }

    // Update local prefs
    PrefsService.userName = name;
    PrefsService.userFlat = flat;
    PrefsService.userPhone = phone;
    PrefsService.societyName = society;
    PrefsService.communityType = communityType;
    PrefsService.isAdmin = isAdmin;
    PrefsService.isLoggedIn = true;
    PrefsService.hasOnboarded = true;
    PrefsService.userId = user.uid;
  }

  // Load user profile from Firestore into prefs
  static Future<bool> loadUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return false;

    final d = doc.data()!;
    PrefsService.userName = d['name'] ?? '';
    PrefsService.userFlat = d['flat'] ?? '';
    PrefsService.userPhone = d['phone'] ?? '';
    PrefsService.societyName = d['society'] ?? '';
    PrefsService.communityType = d['communityType'] ?? 'society';
    PrefsService.isAdmin = d['isAdmin'] ?? false;
    PrefsService.isGatedCommunity = d['isGated'] ?? true;
    PrefsService.isLoggedIn = true;
    PrefsService.userId = user.uid;
    final blockedIds = List<String>.from(d['blockedUserIds'] ?? []);
    await PrefsService.setBlockedUserIds(blockedIds);
    return true;
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    PrefsService.logout();
  }
}
