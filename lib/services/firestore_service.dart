import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../utils/prefs_service.dart';
import 'auth_service.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ──── USERS ────
  static CollectionReference get _users => _db.collection('users');

  static Stream<QuerySnapshot> residentsStream(String society) {
    return _users.where('society', isEqualTo: society).snapshots();
  }

  static Future<List<Resident>> getResidents(String society) async {
    final snap = await _users.where('society', isEqualTo: society).get();
    return snap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      return Resident(
        id: d.id,
        name: data['name'] ?? '',
        flat: data['flat'] ?? '',
        phone: data['phone'] ?? '',
        isAdmin: data['isAdmin'] ?? false,
        avatarColor: data['avatarColor'] ?? 0xFF1565C0,
      );
    }).toList();
  }

  // ──── NOTICES ────
  static CollectionReference get _notices => _db.collection('notices');

  static Stream<QuerySnapshot> noticesStream(String society) {
    return _notices
        .where('society', isEqualTo: society)
        .orderBy('date', descending: true)
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
    );
  }

  static Future<void> addNotice(Notice n) async {
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
  }

  static Future<void> updateNotice(String id, Map<String, dynamic> data) async {
    await _notices.doc(id).update(data);
  }

  // ──── COMPLAINTS ────
  static CollectionReference get _complaints => _db.collection('complaints');

  static Stream<QuerySnapshot> complaintsStream(String society) {
    return _complaints
        .where('society', isEqualTo: society)
        .orderBy('date', descending: true)
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

  static Future<void> addComplaint(Complaint c) async {
    await _complaints.add({
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
    });
  }

  static Future<void> updateComplaint(String id, Map<String, dynamic> data) async {
    await _complaints.doc(id).update(data);
  }

  // ──── EVENTS ────
  static CollectionReference get _events => _db.collection('events');

  static Stream<QuerySnapshot> eventsStream(String society) {
    return _events
        .where('society', isEqualTo: society)
        .orderBy('date', descending: false)
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

  static Future<void> addEvent(Event e) async {
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
  }

  static Future<void> updateEvent(String id, Map<String, dynamic> data) async {
    await _events.doc(id).update(data);
  }

  // ──── POLLS ────
  static CollectionReference get _polls => _db.collection('polls');

  static Stream<QuerySnapshot> pollsStream(String society) {
    return _polls
        .where('society', isEqualTo: society)
        .orderBy('endDate', descending: true)
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

  static Future<void> addPoll(Poll p) async {
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
        .orderBy('date', descending: true)
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

  static Future<void> addVisitor(Visitor v) async {
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
  }

  static Future<void> updateVisitor(String id, Map<String, dynamic> data) async {
    await _visitors.doc(id).update(data);
  }

  // ──── GATE LOG ────
  static CollectionReference get _gateLog => _db.collection('gate_log');

  static Stream<QuerySnapshot> gateLogStream(String society) {
    return _gateLog
        .where('society', isEqualTo: society)
        .orderBy('timeIn', descending: true)
        .limit(50)
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
    return q.orderBy('dueDate', descending: true).snapshots();
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
        .orderBy('date', descending: true)
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

  // ──── CHAT ────
  static CollectionReference get _chatRooms => _db.collection('chat_rooms');

  static Stream<QuerySnapshot> chatRoomsStream(String userId) {
    return _chatRooms
        .where('participants', arrayContains: userId)
        .orderBy('lastTime', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot> messagesStream(String roomId) {
    return _chatRooms
        .doc(roomId)
        .collection('messages')
        .orderBy('time', descending: false)
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
        .orderBy('time', descending: true)
        .limit(20)
        .snapshots();
  }

  static Future<void> sendSosAlert(String type) async {
    await _sosAlerts.add({
      'type': type,
      'flat': PrefsService.userFlat,
      'userName': PrefsService.userName,
      'time': FieldValue.serverTimestamp(),
      'isActive': true,
      'society': PrefsService.societyName,
      'userId': AuthService.uid,
    });
  }

  // ──── GENERIC COLLECTIONS (for screens with local mock data) ────
  // These provide simple CRUD for collections that use private mock classes

  static CollectionReference collection(String name) => _db.collection(name);

  static Future<DocumentReference> addDoc(String collectionName, Map<String, dynamic> data) async {
    data['society'] = PrefsService.societyName;
    data['createdBy'] = AuthService.uid;
    data['createdAt'] = FieldValue.serverTimestamp();
    return await _db.collection(collectionName).add(data);
  }

  static Future<void> updateDoc(String collectionName, String docId, Map<String, dynamic> data) async {
    await _db.collection(collectionName).doc(docId).update(data);
  }

  static Future<void> deleteDoc(String collectionName, String docId) async {
    await _db.collection(collectionName).doc(docId).delete();
  }

  static Stream<QuerySnapshot> collectionStream(String collectionName, String society) {
    return _db.collection(collectionName)
        .where('society', isEqualTo: society)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
