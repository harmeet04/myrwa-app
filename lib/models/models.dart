class Resident {
  final String id;
  final String name;
  final String flat;
  final String phone;
  final bool isAdmin;
  final int avatarColor;

  const Resident({
    required this.id,
    required this.name,
    required this.flat,
    required this.phone,
    this.isAdmin = false,
    this.avatarColor = 0xFF1565C0,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'flat': flat, 'phone': phone,
    'isAdmin': isAdmin, 'avatarColor': avatarColor,
  };

  factory Resident.fromJson(Map<String, dynamic> j) => Resident(
    id: j['id'] ?? '', name: j['name'] ?? '', flat: j['flat'] ?? '',
    phone: j['phone'] ?? '', isAdmin: j['isAdmin'] ?? false,
    avatarColor: j['avatarColor'] ?? 0xFF1565C0,
  );
}

class Notice {
  final String id;
  final String title;
  final String body;
  final String author;
  final String authorFlat;
  final DateTime date;
  bool isPinned;
  int likes;
  final String category;
  final List<Comment> comments;
  String? attachmentName; // mock document attachment

  Notice({
    required this.id,
    required this.title,
    required this.body,
    required this.author,
    required this.authorFlat,
    required this.date,
    this.isPinned = false,
    this.likes = 0,
    this.category = 'General',
    List<Comment>? comments,
    this.attachmentName,
  }) : comments = comments ?? [];
}

class Comment {
  final String id;
  final String author;
  final String text;
  final DateTime date;

  const Comment({
    required this.id,
    required this.author,
    required this.text,
    required this.date,
  });
}

enum ComplaintStatus { open, inProgress, resolved }
enum Priority { low, medium, high }

class Complaint {
  final String id;
  final String title;
  final String description;
  final String category;
  ComplaintStatus status;
  final Priority priority;
  final String raisedBy;
  final String flat;
  final DateTime date;
  String? adminResponse;
  bool hasPhoto;

  Complaint({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.priority,
    required this.raisedBy,
    required this.flat,
    required this.date,
    this.adminResponse,
    this.hasPhoto = false,
  });
}

class MarketItem {
  final String id;
  final String title;
  final String description;
  final double price;
  final String category;
  final String seller;
  final String sellerFlat;
  final DateTime date;
  bool isSold;
  bool hasPhoto;

  MarketItem({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.seller,
    required this.sellerFlat,
    required this.date,
    this.isSold = false,
    this.hasPhoto = false,
  });
}

class ServiceItem {
  final String id;
  final String shopName;
  final String description;
  final String category;
  final String timings;
  final String contact;
  final String flat;

  const ServiceItem({
    required this.id,
    required this.shopName,
    required this.description,
    required this.category,
    required this.timings,
    required this.contact,
    required this.flat,
  });
}

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final String organizer;
  int rsvpCount;
  int maybeCount;
  final int maxCapacity;
  bool hasRsvpd;
  int plusOnes;
  final List<String> attendees;
  final List<String> maybeAttendees;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.organizer,
    this.rsvpCount = 0,
    this.maybeCount = 0,
    this.maxCapacity = 50,
    this.hasRsvpd = false,
    this.plusOnes = 0,
    List<String>? attendees,
    List<String>? maybeAttendees,
  }) : attendees = attendees ?? [],
       maybeAttendees = maybeAttendees ?? [];
}

class EmergencyContact {
  final String name;
  final String phone;
  final String category;
  final double rating;

  const EmergencyContact({
    required this.name,
    required this.phone,
    required this.category,
    this.rating = 0,
  });
}

enum VisitorStatus { pending, approved, rejected, completed }

class Visitor {
  final String id;
  final String name;
  final String purpose;
  final String flat;
  final DateTime date;
  final String otp;
  VisitorStatus status;

  Visitor({
    required this.id,
    required this.name,
    required this.purpose,
    required this.flat,
    required this.date,
    required this.otp,
    this.status = VisitorStatus.pending,
  });
}

class Poll {
  final String id;
  final String question;
  final List<String> options;
  final List<int> votes;
  final int totalVoters;
  final DateTime endDate;
  final String createdBy;
  final bool isAnonymous;
  int? votedIndex;

  Poll({
    required this.id,
    required this.question,
    required this.options,
    required this.votes,
    required this.totalVoters,
    required this.endDate,
    required this.createdBy,
    this.isAnonymous = false,
    this.votedIndex,
  });

  bool get isActive => endDate.isAfter(DateTime.now());
  int get totalVotes => votes.fold(0, (a, b) => a + b);
}

enum BillStatus { pending, paid, overdue }

class Bill {
  final String id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final String category;
  BillStatus status;
  DateTime? paidDate;
  final String description;
  final String flat;

  Bill({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.category,
    required this.status,
    this.paidDate,
    this.description = '',
    this.flat = '',
  });
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String text;
  final DateTime time;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.text,
    required this.time,
  });
}

class ChatThread {
  final String oderId;
  final String otherName;
  final String otherFlat;
  final String lastMessage;
  final DateTime lastTime;
  final int unread;

  const ChatThread({
    required this.oderId,
    required this.otherName,
    required this.otherFlat,
    required this.lastMessage,
    required this.lastTime,
    this.unread = 0,
  });
}

class GateEntry {
  final String id;
  final String visitorName;
  final String flatVisiting;
  final DateTime timeIn;
  DateTime? timeOut;
  final String approvedBy;
  bool exited;

  GateEntry({
    required this.id,
    required this.visitorName,
    required this.flatVisiting,
    required this.timeIn,
    this.timeOut,
    required this.approvedBy,
    this.exited = false,
  });
}
