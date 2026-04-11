import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

/// One-time seed for pre-registered demo users.
/// Call from admin panel or a temporary main.dart hook.
class SeedData {
  static final _db = FirebaseFirestore.instance;

  /// Force-update existing users from pre_registered_users data.
  /// This ensures isAdmin/isGated flags are always in sync.
  static Future<void> syncUsersFromPreRegistered() async {
    try {
      final preRegSnap = await _db.collection('pre_registered_users').get();
      for (final preDoc in preRegSnap.docs) {
        final data = preDoc.data();
        final phone = data['phone'] as String? ?? '';
        if (phone.isEmpty) continue;

        // Find the user doc with this phone number
        final userSnap = await _db.collection('users')
            .where('phone', isEqualTo: phone)
            .limit(1)
            .get();

        if (userSnap.docs.isNotEmpty) {
          // Force-update the user doc with pre-registered flags
          await userSnap.docs.first.reference.update({
            'isAdmin': data['isAdmin'] ?? false,
            'isGated': data['isGated'] ?? true,
            'name': data['name'] ?? '',
            'flat': data['flat'] ?? '',
            'society': data['society'] ?? '',
            'communityType': data['communityType'] ?? 'society',
          });
        }
      }
    } catch (e) {
      // Silently fail — user might not be authenticated yet
    }
  }

  static Future<void> seedDemoUsers() async {
    // User 1: Original demo user
    await FirestoreService.seedPreRegisteredUser(
      phone: '9582733460',
      name: 'Harmeet',
      flat: '1323',
      society: 'Sector 15 Part 2, Gurgaon',
      communityType: 'sector',
      isAdmin: false,
      isGated: false,
    );

    // User 2: Admin test — non-gated
    await FirestoreService.seedPreRegisteredUser(
      phone: '9876543210',
      name: 'Admin_test',
      flat: '111',
      society: 'Test sector',
      communityType: 'sector',
      isAdmin: true,
      isGated: false,
    );

    // User 3: Gated test
    await FirestoreService.seedPreRegisteredUser(
      phone: '9988776655',
      name: 'gated_test',
      flat: '69',
      society: 'gated society',
      communityType: 'society',
      isAdmin: false,
      isGated: true,
    );
  }
}
