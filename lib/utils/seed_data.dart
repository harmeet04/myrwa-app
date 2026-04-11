import '../services/firestore_service.dart';

/// One-time seed for pre-registered demo users.
/// Call from admin panel or a temporary main.dart hook.
class SeedData {
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
