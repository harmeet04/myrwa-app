import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../utils/prefs_service.dart';
import 'auth_service.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ──── USERS ────
  static CollectionReference get _users => _db.collection('users');

  /// Look up a pre-registered user by phone number.
  /// Returns the document data if found, null otherwise.
  static Future<Map<String, dynamic>?> lookupPreRegisteredUser(String phone) async {
    final snap = await _db
        .collection('pre_registered_users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data();
  }

  /// Seed a pre-registered user (for demo/testing purposes).
  static Future<void> seedPreRegisteredUser({
    required String phone,
    required String name,
    required String flat,
    required String society,
    required String communityType,
    bool isAdmin = false,
    bool isGated = true,
  }) async {
    await _db.collection('pre_registered_users').doc(phone).set({
      'phone': phone,
      'name': name,
      'flat': flat,
      'society': society,
      'communityType': communityType,
      'isAdmin': isAdmin,
      'isGated': isGated,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> residentsStream(String society) {
    return _users.where('society', isEqualTo: society).snapshots();
  }

  static Resident residentFromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Resident(
      id: doc.id,
      name: data['name'] ?? '',
      flat: data['flat'] ?? '',
      phone: data['phone'] ?? '',
      isAdmin: data['isAdmin'] ?? false,
      avatarColor: data['avatarColor'] ?? 0xFF1565C0,
    );
  }

  static Future<List<Resident>> getResidents(String society) async {
    try {
      final snap = await _users.where('society', isEqualTo: society).get();
      return snap.docs.map((d) => residentFromDoc(d)).toList();
    } catch (e) {
      debugPrint('FirestoreService.getResidents error: $e');
      return [];
    }
  }

  // ──── NOTICES ────
  static CollectionReference get _notices => _db.collection('notices');

  static Stream<QuerySnapshot> noticesStream(String society) {
    return _notices
        .where('society', isEqualTo: society)
        .limit(50)
        .snapshots();
  }

  static Notice noticeFromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Notice(
      id: doc.id,
      title: d['title'] ?? '',
      body: d['body'] ?? '',
      author: d['author'] ?? '',
      authorFlat: d['authorFlat'] ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPinned: d['isPinned'] ?? false,
      likes: d['likes'] ?? 0,
      category: d['category'] ?? 'General',
      attachmentName: d['attachmentName'],
      comments: (d['comments'] as List<dynamic>?)?.map((c) => Comment(
        id: c['id'] ?? '',
        author: c['author'] ?? '',
        text: c['text'] ?? '',
        date: (c['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      )).toList() ?? [],
    );
  }

  static Future<bool> addNotice(Notice n) async {
    try {
      await _notices.add({
        'title': n.title,
        'body': n.body,
        'author': n.author,
        'authorFlat': n.authorFlat,
        'date': Timestamp.fromDate(n.date),
        'isPinned': n.isPinned,
        'likes': n.likes,
        'category': n.category,
        'attachmentName': n.attachmentName,
        'society': PrefsService.societyName,
        'createdBy': AuthService.uid,
      });
      return true;
    } catch (e) {
      debugPrint('Error adding notice: $e');
      return false;
    }
  }

  static Future<void> updateNotice(String id, Map<String, dynamic> data) async {
    await _notices.doc(id).update(data);
  }

  // ──── COMPLAINTS ────
  static CollectionReference get _complaints => _db.collection('complaints');

  static Stream<QuerySnapshot> complaintsStream(String society) {
    return _complaints
        .where('society', isEqualTo: society)
        .limit(50)
        .snapshots();
  }

  static Complaint complaintFromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Complaint(
      id: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      category: d['category'] ?? '',
      status: ComplaintStatus.values.firstWhere(
        (e) => e.name == (d['status'] ?? 'open'),
        orElse: () => ComplaintStatus.open,
      ),
      priority: Priority.values.firstWhere(
        (e) => e.name == (d['priority'] ?? 'medium'),
        orElse: () => Priority.medium,
      ),
      raisedBy: d['raisedBy'] ?? '',
      flat: d['flat'] ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminResponse: d['adminResponse'],
      hasPhoto: d['hasPhoto'] ?? false,
    );
  }

  static Future<bool> addComplaint(Complaint c,
      {Map<String, dynamic>? extraFields}) async {
    try {
      final data = {
        'title': c.title,
        'description': c.description,
        'category': c.category,
        'status': c.status.name,
        'priority': c.priority.name,
        'raisedBy': c.raisedBy,
        'flat': c.flat,
        'date': Timestamp.fromDate(c.date),
        'adminResponse': c.adminResponse,
        'hasPhoto': c.hasPhoto,
        'society': PrefsService.societyName,
        'createdBy': AuthService.uid,
        if (extraFields != null) ...extraFields,
      };
      await _complaints.add(data);
      return true;
    } catch (e) {
      debugPrint('Error adding complaint: $e');
      return false;
    }
  }

  static Future<void> updateComplaint(String id, Map<String, dynamic> data) async {
    await _complaints.doc(id).update(data);
  }

  // ──── EVENTS ────
  static CollectionReference get _events => _db.collection('events');

  static Stream<QuerySnapshot> eventsStream(String society) {
    return _events
        .where('society', isEqualTo: society)
        .limit(30)
        .snapshots();
  }

  static Event eventFromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: d['location'] ?? '',
      organizer: d['organizer'] ?? '',
      rsvpCount: d['rsvpCount'] ?? 0,
      maybeCount: d['maybeCount'] ?? 0,
      maxCapacity: d['maxCapacity'] ?? 50,
      attendees: List<String>.from(d['attendees'] ?? []),
      maybeAttendees: List<String>.from(d['maybeAttendees'] ?? []),
    );
  }

  static Future<bool> addEvent(Event e) async {
    try {
      await _events.add({
        'title': e.title,
        'description': e.description,
        'date': Timestamp.fromDate(e.date),
        'location': e.location,
        'organizer': e.organizer,
        'rsvpCount': e.rsvpCount,
        'maybeCount': e.maybeCount,
        'maxCapacity': e.maxCapacity,
        'attendees': e.attendees,
        'maybeAttendees': e.maybeAttendees,
        'society': PrefsService.societyName,
        'createdBy': AuthService.uid,
      });
      return true;
    } catch (e) {
      debugPrint('FirestoreService.addEvent error: $e');
      return false;
    }
  }

  static Future<void> updateEvent(String id, Map<String, dynamic> data) async {
    await _events.doc(id).update(data);
  }

  // ──── POLLS ────
  static CollectionReference get _polls => _db.collection('polls');

  static Stream<QuerySnapshot> pollsStream(String society) {
    return _polls
        .where('society', isEqualTo: society)
        .limit(20)
        .snapshots();
  }

  static Poll pollFromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Poll(
      id: doc.id,
      question: d['question'] ?? '',
      options: List<String>.from(d['options'] ?? []),
      votes: List<int>.from(d['votes'] ?? []),
      totalVoters: d['totalVoters'] ?? 0,
      endDate: (d['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: d['createdBy'] ?? '',
      isAnonymous: d['isAnonymous'] ?? false,
    );
  }

  static Future<bool> addPoll(Poll p) async {
    try {
      await _polls.add({
        'question': p.question,
        'options': p.options,
        'votes': p.votes,
        'totalVoters': p.totalVoters,
        'endDate': Timestamp.fromDate(p.endDate),
        'createdBy': p.createdBy,
        'isAnonymous': p.isAnonymous,
        'society': PrefsService.societyName,
        'createdByUid': AuthService.uid,
      });
      return true;
    } catch (e) {
      debugPrint('FirestoreService.addPoll error: $e');
      return false;
    }
  }

  static Future<void> votePoll(String pollId, int optionIndex) async {
    await _db.runTransaction((tx) async {
      final doc = _polls.doc(pollId);
      final snap = await tx.get(doc);
      final votes = List<int>.from((snap.data() as Map)['votes'] ?? []);
      votes[optionIndex]++;
      tx.update(doc, {'votes': votes});
    });
  }

  // ──── VISITORS ────
  static CollectionReference get _visitors => _db.collection('visitors');

  static Stream<QuerySnapshot> visitorsStream(String society) {
    return _visitors
        .where('society', isEqualTo: society)
        .limit(50)
        .snapshots();
  }

  static Visitor visitorFromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Visitor(
      id: doc.id,
      name: d['name'] ?? '',
      purpose: d['purpose'] ?? '',
      flat: d['flat'] ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      otp: d['otp'] ?? '',
      status: VisitorStatus.values.firstWhere(
        (e) => e.name == (d['status'] ?? 'pending'),
        orElse: () => VisitorStatus.pending,
      ),
    );
  }

  static Future<bool> addVisitor(Visitor v) async {
    try {
      await _visitors.add({
        'name': v.name,
        'purpose': v.purpose,
        'flat': v.flat,
        'date': Timestamp.fromDate(v.date),
        'otp': v.otp,
        'status': v.status.name,
        'society': PrefsService.societyName,
        'createdBy': AuthService.uid,
      });
      return true;
    } catch (e) {
      debugPrint('FirestoreService.addVisitor error: $e');
      return false;
    }
  }

  static Future<void> updateVisitor(String id, Map<String, dynamic> data) async {
    await _visitors.doc(id).update(data);
  }

  static Future<int> getVisitorFrequency(String visitorName, String flat) async {
    final snap = await _visitors
        .where('name', isEqualTo: visitorName)
        .where('flat', isEqualTo: flat)
        .get();
    return snap.docs.length;
  }

  static Future<bool> isTrustedVisitor(String visitorName, String flat) async {
    final count = await getVisitorFrequency(visitorName, flat);
    return count >= 3;
  }

  // ──── GATE LOG ────
  static CollectionReference get _gateLog => _db.collection('gate_log');

  static Stream<QuerySnapshot> gateLogStream(String society) {
    return _gateLog
        .where('society', isEqualTo: society)
        .limit(100)
        .snapshots();
  }

  static GateEntry gateEntryFromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return GateEntry(
      id: doc.id,
      visitorName: d['visitorName'] ?? '',
      flatVisiting: d['flatVisiting'] ?? '',
      timeIn: (d['timeIn'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeOut: (d['timeOut'] as Timestamp?)?.toDate(),
      approvedBy: d['approvedBy'] ?? '',
      exited: d['exited'] ?? false,
    );
  }

  static Future<void> addGateEntry(GateEntry g) async {
    await _gateLog.add({
      'visitorName': g.visitorName,
      'flatVisiting': g.flatVisiting,
      'timeIn': Timestamp.fromDate(g.timeIn),
      'timeOut': g.timeOut != null ? Timestamp.fromDate(g.timeOut!) : null,
      'approvedBy': g.approvedBy,
      'exited': g.exited,
      'society': PrefsService.societyName,
    });
  }

  static Future<void> updateGateEntry(String id, Map<String, dynamic> data) async {
    await _gateLog.doc(id).update(data);
  }

  // ──── BILLS ────
  static CollectionReference get _bills => _db.collection('bills');

  static Stream<QuerySnapshot> billsStream(String society, {String? flat}) {
    Query q = _bills.where('society', isEqualTo: society);
    if (flat != null) q = q.where('flat', isEqualTo: flat);
    return q.limit(50).snapshots();
  }

  static Bill billFromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Bill(
      id: doc.id,
      title: d['title'] ?? '',
      amount: (d['amount'] ?? 0).toDouble(),
      dueDate: (d['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      category: d['category'] ?? '',
      status: BillStatus.values.firstWhere(
        (e) => e.name == (d['status'] ?? 'pending'),
        orElse: () => BillStatus.pending,
      ),
      paidDate: (d['paidDate'] as Timestamp?)?.toDate(),
      description: d['description'] ?? '',
      flat: d['flat'] ?? '',
    );
  }

  static Future<void> addBill(Bill b) async {
    await _bills.add({
      'title': b.title,
      'amount': b.amount,
      'dueDate': Timestamp.fromDate(b.dueDate),
      'category': b.category,
      'status': b.status.name,
      'paidDate': b.paidDate != null ? Timestamp.fromDate(b.paidDate!) : null,
      'description': b.description,
      'flat': b.flat,
      'society': PrefsService.societyName,
    });
  }

  static Future<void> updateBill(String id, Map<String, dynamic> data) async {
    await _bills.doc(id).update(data);
  }

  // ──── MARKETPLACE ────
  static CollectionReference get _marketplace => _db.collection('marketplace');

  static Stream<QuerySnapshot> marketplaceStream(String society) {
    return _marketplace
        .where('society', isEqualTo: society)
        .limit(50)
        .snapshots();
  }

  static MarketItem marketItemFromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MarketItem(
      id: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      price: (d['price'] ?? 0).toDouble(),
      category: d['category'] ?? '',
      seller: d['seller'] ?? '',
      sellerFlat: d['sellerFlat'] ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSold: d['isSold'] ?? false,
      hasPhoto: d['hasPhoto'] ?? false,
    );
  }

  static Future<void> addMarketItem(MarketItem m) async {
    await _marketplace.add({
      'title': m.title,
      'description': m.description,
      'price': m.price,
      'category': m.category,
      'seller': m.seller,
      'sellerFlat': m.sellerFlat,
      'date': Timestamp.fromDate(m.date),
      'isSold': m.isSold,
      'hasPhoto': m.hasPhoto,
      'society': PrefsService.societyName,
      'createdBy': AuthService.uid,
    });
  }

  static Future<void> updateMarketItem(String id, Map<String, dynamic> data) async {
    await _marketplace.doc(id).update(data);
  }

  // ──── SERVICES ────
  static CollectionReference get _services => _db.collection('services');

  static Stream<QuerySnapshot> servicesStream(String society) {
    return _services
        .where('society', isEqualTo: society)
        .limit(30)
        .snapshots();
  }

  static ServiceItem serviceItemFromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ServiceItem(
      id: doc.id,
      shopName: d['shopName'] ?? '',
      description: d['description'] ?? '',
      category: d['category'] ?? '',
      timings: d['timings'] ?? '',
      contact: d['contact'] ?? '',
      flat: d['flat'] ?? '',
    );
  }

  // ──── CHAT ────
  static CollectionReference get _chatRooms => _db.collection('chat_rooms');

  static Stream<QuerySnapshot> chatRoomsStream(String userId) {
    return _chatRooms
        .where('participants', arrayContains: userId)
        .snapshots();
  }

  static Stream<QuerySnapshot> messagesStream(String roomId) {
    return _chatRooms
        .doc(roomId)
        .collection('messages')
        .snapshots();
  }

  static Future<String> getOrCreateChatRoom(String otherUserId, String otherName, String otherFlat) async {
    final uid = AuthService.uid;
    // Check existing room
    final snap = await _chatRooms
        .where('participants', arrayContains: uid)
        .get();
    for (final doc in snap.docs) {
      final participants = List<String>.from((doc.data() as Map)['participants'] ?? []);
      if (participants.contains(otherUserId)) return doc.id;
    }
    // Create new room
    final doc = await _chatRooms.add({
      'participants': [uid, otherUserId],
      'participantNames': {uid: PrefsService.userName, otherUserId: otherName},
      'participantFlats': {uid: PrefsService.userFlat, otherUserId: otherFlat},
      'lastMessage': '',
      'lastTime': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  static Future<void> sendMessage(String roomId, String text) async {
    final uid = AuthService.uid;
    final batch = _db.batch();
    final msgRef = _chatRooms.doc(roomId).collection('messages').doc();
    batch.set(msgRef, {
      'senderId': uid,
      'senderName': PrefsService.userName,
      'text': text,
      'time': FieldValue.serverTimestamp(),
    });
    batch.update(_chatRooms.doc(roomId), {
      'lastMessage': text,
      'lastTime': FieldValue.serverTimestamp(),
      'lastSenderId': uid,
    });
    await batch.commit();
  }

  // ──── SOS ALERTS ────
  static CollectionReference get _sosAlerts => _db.collection('sos_alerts');

  static Stream<QuerySnapshot> sosAlertsStream(String society) {
    return _sosAlerts
        .where('society', isEqualTo: society)
        .limit(20)
        .snapshots();
  }

  static Future<bool> sendSosAlert(String type) async {
    try {
      await _sosAlerts.add({
        'type': type,
        'flat': PrefsService.userFlat,
        'userName': PrefsService.userName,
        'time': FieldValue.serverTimestamp(),
        'isActive': true,
        'society': PrefsService.societyName,
        'userId': AuthService.uid,
      });
      return true;
    } catch (e) {
      debugPrint('Error sending SOS alert: $e');
      return false;
    }
  }

  // ──── COMMUNITY BOARD ────
  static CollectionReference get _communityBoard =>
      _db.collection('community_board');

  static Stream<QuerySnapshot> communityBoardStream(
      String society, String type) {
    return _communityBoard
        .where('society', isEqualTo: society)
        .where('type', isEqualTo: type)
        .limit(30)
        .snapshots();
  }

  static Future<void> addBoardPost(Map<String, dynamic> data) async {
    data['society'] = PrefsService.societyName;
    data['author'] = PrefsService.userName.isEmpty ? 'Resident' : PrefsService.userName;
    data['flat'] = PrefsService.userFlat;
    data['createdAt'] = FieldValue.serverTimestamp();
    data['isActive'] = true;
    await _communityBoard.add(data);
  }

  // ──── GENERIC COLLECTIONS (for screens with local mock data) ────
  // These provide simple CRUD for collections that use private mock classes

  static CollectionReference collection(String name) => _db.collection(name);

  static Future<DocumentReference?> addDoc(String collectionName, Map<String, dynamic> data) async {
    try {
      data['society'] = PrefsService.societyName;
      data['createdBy'] = AuthService.uid;
      data['createdAt'] = FieldValue.serverTimestamp();
      return await _db.collection(collectionName).add(data);
    } catch (e) {
      debugPrint('FirestoreService.addDoc error ($collectionName): $e');
      return null;
    }
  }

  static Future<bool> updateDoc(String collectionName, String docId, Map<String, dynamic> data) async {
    try {
      await _db.collection(collectionName).doc(docId).update(data);
      return true;
    } catch (e) {
      debugPrint('Error updating doc $collectionName/$docId: $e');
      return false;
    }
  }

  static Future<bool> deleteDoc(String collectionName, String docId) async {
    try {
      await _db.collection(collectionName).doc(docId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting doc $collectionName/$docId: $e');
      return false;
    }
  }

  static Stream<QuerySnapshot> collectionStream(String collectionName, String society) {
    return _db.collection(collectionName)
        .where('society', isEqualTo: society)
        .snapshots();
  }
}
