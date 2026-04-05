import '../models/models.dart';

class MockData {
  static const List<String> societyNames = [
    'Sunrise Residency', 'Green Valley Apartments', 'Royal Palms Society',
    'Shanti Nagar CHS', 'Paradise Heights', 'Lakeview Towers',
    'Sai Krupa Apartments', 'Ganesh Nagar Society',
  ];

  static const List<String> residentNames = [
    'Rajesh Sharma', 'Priya Patel', 'Amit Kumar', 'Sneha Desai',
    'Vikram Singh', 'Anjali Mehta', 'Suresh Reddy', 'Kavita Joshi',
    'Rohit Verma', 'Neha Gupta', 'Deepak Iyer', 'Pooja Nair',
    'Manish Agarwal', 'Sunita Rao', 'Arjun Pillai', 'Meera Chatterjee',
  ];

  static const List<String> flatNumbers = [
    'A-101', 'A-102', 'A-201', 'A-202', 'A-301', 'A-302',
    'B-101', 'B-102', 'B-201', 'B-202', 'B-301', 'B-302',
    'C-101', 'C-102', 'C-201', 'C-202',
  ];

  static const List<String> phoneNumbers = [
    '9876543210', '9876543211', '9876543212', '9876543213',
    '9876543214', '9876543215', '9876543216', '9876543217',
    '9876543218', '9876543219', '9876543220', '9876543221',
    '9876543222', '9876543223', '9876543224', '9876543225',
  ];

  static List<Resident> get residents {
    return List.generate(residentNames.length, (i) => Resident(
      id: 'r_$i',
      name: residentNames[i],
      flat: flatNumbers[i],
      phone: phoneNumbers[i],
      isAdmin: i == 0,
      avatarColor: _avatarColors[i % _avatarColors.length],
    ));
  }

  static const List<int> _avatarColors = [
    0xFF1565C0, 0xFFC62828, 0xFF2E7D32, 0xFF6A1B9A,
    0xFFEF6C00, 0xFF00838F, 0xFF4E342E, 0xFF37474F,
  ];

  static List<Notice> get notices => [
    Notice(
      id: 'n_1',
      title: 'Annual Maintenance Charges - Q1 2026',
      body: 'Dear residents, Q1 maintenance of ₹4,500 is due by March 15, 2026. Please pay via UPI or bank transfer. Late fee of ₹500 will be applicable after the due date.',
      author: 'Rajesh Sharma', authorFlat: 'A-101',
      date: DateTime(2026, 2, 18), isPinned: true, likes: 12, category: 'Announcement',
    ),
    Notice(
      id: 'n_2',
      title: 'Water Tank Cleaning - 22nd Feb',
      body: 'Water supply will be interrupted from 9 AM to 2 PM on 22nd February for tank cleaning. Please store water accordingly.',
      author: 'Vikram Singh', authorFlat: 'A-301',
      date: DateTime(2026, 2, 17), isPinned: true, likes: 8, category: 'Announcement',
    ),
    Notice(
      id: 'n_3',
      title: 'New CCTV Installation',
      body: 'CCTV cameras will be installed in parking area B and the back gate this weekend. Vendor access has been approved.',
      author: 'Rajesh Sharma', authorFlat: 'A-101',
      date: DateTime(2026, 2, 15), isPinned: false, likes: 15, category: 'Announcement',
    ),
    Notice(
      id: 'n_4',
      title: 'Holi Celebration 2026 🎨',
      body: 'Holi celebration in the society garden on March 14th from 10 AM. Organic colors will be provided. Snacks and thandai for everyone! RSVP on the Events page.',
      author: 'Anjali Mehta', authorFlat: 'B-201',
      date: DateTime(2026, 2, 14), isPinned: false, likes: 32, category: 'Announcement',
    ),
    Notice(
      id: 'n_5',
      title: 'AGM Minutes - January 2026',
      body: 'Minutes of the Annual General Meeting held on January 25, 2026 are now available. Key decisions: security upgrade approved, new playground equipment sanctioned.',
      author: 'Rajesh Sharma', authorFlat: 'A-101',
      date: DateTime(2026, 2, 12), isPinned: false, likes: 5, category: 'AGM Minutes',
      attachmentName: 'AGM_Minutes_Jan2026.pdf',
    ),
    Notice(
      id: 'n_6',
      title: 'Updated Society Rules 2026',
      body: 'Please review the updated society rules effective from March 1, 2026. Changes include pet policy, parking rules, and noise guidelines.',
      author: 'Rajesh Sharma', authorFlat: 'A-101',
      date: DateTime(2026, 2, 10), isPinned: false, likes: 9, category: 'Rules',
      attachmentName: 'Society_Rules_2026.pdf',
    ),
    Notice(
      id: 'n_7',
      title: 'Q4 2025 Financial Report',
      body: 'The financial report for Q4 2025 is available. Total collection: ₹7,20,000. Expenditure: ₹5,85,000. Surplus: ₹1,35,000.',
      author: 'Rajesh Sharma', authorFlat: 'A-101',
      date: DateTime(2026, 2, 8), isPinned: false, likes: 7, category: 'Financial Report',
    ),
  ];

  static List<Complaint> get complaints => [
    Complaint(
      id: 'c_1',
      title: 'Water leakage in parking B1',
      description: 'Continuous water leakage from the ceiling of parking area B1, near slot 15. Cars are getting damaged.',
      category: 'Plumbing', status: ComplaintStatus.inProgress, priority: Priority.high,
      raisedBy: 'Amit Kumar', flat: 'A-201', date: DateTime(2026, 2, 16),
      adminResponse: 'Plumber has been called. Will be fixed by 20th Feb.',
      hasPhoto: true,
    ),
    Complaint(
      id: 'c_2',
      title: 'Lift not working - Tower B',
      description: 'Lift in Tower B has been out of service since yesterday. Elderly residents are facing difficulty.',
      category: 'Electrical', status: ComplaintStatus.open, priority: Priority.high,
      raisedBy: 'Sneha Desai', flat: 'B-102', date: DateTime(2026, 2, 19),
    ),
    Complaint(
      id: 'c_3',
      title: 'Stray dogs in compound',
      description: 'Multiple stray dogs have entered the society compound. They chase children in the evening.',
      category: 'Security', status: ComplaintStatus.open, priority: Priority.medium,
      raisedBy: 'Kavita Joshi', flat: 'C-201', date: DateTime(2026, 2, 18),
    ),
    Complaint(
      id: 'c_4',
      title: 'Broken streetlight near gate 2',
      description: 'The streetlight near the back gate has been broken for a week. Very dark at night.',
      category: 'Electrical', status: ComplaintStatus.resolved, priority: Priority.medium,
      raisedBy: 'Rohit Verma', flat: 'A-302', date: DateTime(2026, 2, 10),
      adminResponse: 'New LED light installed on 15th Feb.',
    ),
  ];

  static List<MarketItem> get marketItems => [
    MarketItem(
      id: 'm_1', title: 'Samsung 43" Smart TV',
      description: 'Samsung 43 inch 4K Smart TV, 2 years old. Working perfectly. Upgrading to bigger size.',
      price: 18000, category: 'Electronics', seller: 'Deepak Iyer', sellerFlat: 'B-301',
      date: DateTime(2026, 2, 18), hasPhoto: true,
    ),
    MarketItem(
      id: 'm_2', title: 'Study Table + Chair',
      description: 'Wooden study table with ergonomic chair. Good condition, minor scratches.',
      price: 5500, category: 'Furniture', seller: 'Pooja Nair', sellerFlat: 'C-102',
      date: DateTime(2026, 2, 15), hasPhoto: true,
    ),
    MarketItem(
      id: 'm_3', title: 'Kids Bicycle (5-8 years)',
      description: 'Hero kids bicycle, blue color. Used for 1 year. Training wheels included.',
      price: 2000, category: 'Kids', seller: 'Neha Gupta', sellerFlat: 'A-202',
      date: DateTime(2026, 2, 14),
    ),
    MarketItem(
      id: 'm_4', title: 'Washing Machine - LG 7kg',
      description: 'LG 7kg fully automatic top load. 3 years old but runs great. Moving out.',
      price: 12000, category: 'Appliances', seller: 'Manish Agarwal', sellerFlat: 'B-202',
      date: DateTime(2026, 2, 10), isSold: true, hasPhoto: true,
    ),
  ];

  static List<ServiceItem> get services => [
    ServiceItem(id: 's_1', shopName: 'Patel General Store', description: 'Daily essentials, groceries, snacks, cold drinks',
      category: 'General Store', timings: '7 AM - 10 PM', contact: '9876543230', flat: 'Ground Floor, Shop 1'),
    ServiceItem(id: 's_2', shopName: 'Glamour Salon', description: 'Haircut, facial, threading, bridal packages',
      category: 'Salon', timings: '10 AM - 8 PM (Closed Mon)', contact: '9876543231', flat: 'Ground Floor, Shop 3'),
    ServiceItem(id: 's_3', shopName: 'Sharma Tuition Classes', description: 'Maths & Science coaching for class 5-10. Board exam prep.',
      category: 'Tuition', timings: '4 PM - 8 PM', contact: '9876543232', flat: 'A-101'),
    ServiceItem(id: 's_4', shopName: 'FitLife Gym', description: 'Modern equipment, personal training, Zumba, yoga batches',
      category: 'Gym', timings: '5 AM - 10 PM', contact: '9876543233', flat: 'Basement B1'),
    ServiceItem(id: 's_5', shopName: 'QuickWash Laundry', description: 'Wash & fold, dry cleaning, ironing. Free pickup & delivery in society.',
      category: 'Laundry', timings: '8 AM - 8 PM', contact: '9876543234', flat: 'Ground Floor, Shop 5'),
    ServiceItem(id: 's_6', shopName: 'MedPlus Pharmacy', description: 'Medicines, first aid, health supplements. Free BP check.',
      category: 'Pharmacy', timings: '8 AM - 10 PM', contact: '9876543235', flat: 'Ground Floor, Shop 2'),
  ];

  static List<Event> get events => [
    Event(
      id: 'e_1', title: 'Holi Celebration 2026 🎨',
      description: 'Grand Holi celebration with organic colors, music, snacks, and thandai. Fun for all ages!',
      date: DateTime(2026, 3, 14, 10, 0), location: 'Society Garden', organizer: 'Cultural Committee',
      rsvpCount: 45, maybeCount: 12, maxCapacity: 100,
      attendees: ['Priya Patel', 'Amit Kumar', 'Anjali Mehta', 'Rohit Verma', 'Neha Gupta', 'Meera Chatterjee'],
      maybeAttendees: ['Vikram Singh', 'Kavita Joshi'],
    ),
    Event(
      id: 'e_2', title: 'Annual General Meeting',
      description: 'AGM to discuss budget, maintenance, security upgrades, and election of new committee members.',
      date: DateTime(2026, 3, 1, 18, 0), location: 'Community Hall', organizer: 'Society Committee',
      rsvpCount: 28, maybeCount: 8, maxCapacity: 60,
      attendees: ['Rajesh Sharma', 'Suresh Reddy', 'Manish Agarwal', 'Sunita Rao'],
      maybeAttendees: ['Deepak Iyer'],
    ),
    Event(
      id: 'e_3', title: 'Kids Summer Camp Registration',
      description: 'Register your kids for 2-week summer camp. Activities: art, cricket, swimming, dance.',
      date: DateTime(2026, 4, 1, 9, 0), location: 'Club House', organizer: 'Youth Committee',
      rsvpCount: 15, maybeCount: 5, maxCapacity: 30,
      attendees: ['Sneha Desai', 'Pooja Nair'],
      maybeAttendees: ['Kavita Joshi'],
    ),
    Event(
      id: 'e_4', title: 'Tree Plantation Drive 🌳',
      description: 'Let\'s make our society greener! Saplings will be provided. Bring gloves and enthusiasm.',
      date: DateTime(2026, 3, 20, 7, 0), location: 'Back Garden', organizer: 'Green Committee',
      rsvpCount: 18, maybeCount: 6, maxCapacity: 50,
      attendees: ['Arjun Pillai', 'Meera Chatterjee', 'Amit Kumar'],
      maybeAttendees: ['Priya Patel'],
    ),
  ];

  static List<EmergencyContact> get emergencyContacts => [
    EmergencyContact(name: 'Raju Plumber', phone: '9800000001', category: 'Plumber', rating: 4.5),
    EmergencyContact(name: 'Sunil Electrician', phone: '9800000002', category: 'Electrician', rating: 4.3),
    EmergencyContact(name: 'Dr. Anita Kulkarni', phone: '9800000003', category: 'Doctor (General)', rating: 4.8),
    EmergencyContact(name: 'City Hospital', phone: '9800000004', category: 'Hospital', rating: 4.2),
    EmergencyContact(name: 'Ramesh Carpenter', phone: '9800000005', category: 'Carpenter', rating: 4.0),
    EmergencyContact(name: 'Police Control Room', phone: '100', category: 'Police', rating: 0),
    EmergencyContact(name: 'Fire Brigade', phone: '101', category: 'Fire', rating: 0),
    EmergencyContact(name: 'Ambulance', phone: '108', category: 'Ambulance', rating: 0),
  ];

  static List<Visitor> get visitors => [
    Visitor(id: 'v_1', name: 'Swiggy Delivery', purpose: 'Food Delivery', flat: 'A-201',
      date: DateTime(2026, 2, 20, 12, 30), otp: '4521', status: VisitorStatus.approved),
    Visitor(id: 'v_2', name: 'Amazon Delivery', purpose: 'Package Delivery', flat: 'B-102',
      date: DateTime(2026, 2, 20, 14, 0), otp: '7834', status: VisitorStatus.pending),
    Visitor(id: 'v_3', name: 'Ramesh Kumar', purpose: 'Guest Visit', flat: 'A-101',
      date: DateTime(2026, 2, 20, 17, 0), otp: '1256', status: VisitorStatus.approved),
  ];

  static List<Poll> get polls => [
    Poll(id: 'p_1', question: 'Should we increase parking charges from ₹500 to ₹800/month?',
      options: ['Yes, it\'s necessary', 'No, keep it same', 'Increase to ₹650 only'],
      votes: [28, 35, 12], totalVoters: 75, endDate: DateTime(2026, 2, 25),
      createdBy: 'Society Committee', isAnonymous: true),
    Poll(id: 'p_2', question: 'Preferred timing for Holi celebration?',
      options: ['10 AM - 1 PM', '2 PM - 5 PM', '4 PM - 7 PM'],
      votes: [42, 15, 28], totalVoters: 85, endDate: DateTime(2026, 2, 22),
      createdBy: 'Cultural Committee', isAnonymous: false),
    Poll(id: 'p_4', question: 'Preferred playground timing for kids?',
      options: ['4 PM - 6 PM', '5 PM - 7 PM', '6 PM - 8 PM'],
      votes: [20, 35, 15], totalVoters: 70, endDate: DateTime(2026, 3, 5),
      createdBy: 'Youth Committee', isAnonymous: false),
    Poll(id: 'p_3', question: 'Should we allow pets in the garden area?',
      options: ['Yes, with leash', 'No', 'Only during specific hours'],
      votes: [30, 20, 25], totalVoters: 75, endDate: DateTime(2026, 3, 1),
      createdBy: 'Society Committee', isAnonymous: true),
  ];

  static List<Bill> get bills => [
    Bill(id: 'b_1', title: 'Maintenance - Q1 2026', amount: 4500, dueDate: DateTime(2026, 3, 15),
      category: 'Maintenance', status: BillStatus.pending, description: 'Quarterly maintenance charges', flat: 'A-101'),
    Bill(id: 'b_2', title: 'Electricity - February', amount: 2850, dueDate: DateTime(2026, 3, 5),
      category: 'Electricity', status: BillStatus.pending, description: 'Common area electricity charges', flat: 'A-101'),
    Bill(id: 'b_3', title: 'Water Charges - Feb', amount: 450, dueDate: DateTime(2026, 3, 10),
      category: 'Water', status: BillStatus.paid, paidDate: DateTime(2026, 2, 15),
      description: 'Monthly water supply charges', flat: 'A-101'),
    Bill(id: 'b_4', title: 'Maintenance - Q4 2025', amount: 4500, dueDate: DateTime(2025, 12, 15),
      category: 'Maintenance', status: BillStatus.paid, paidDate: DateTime(2025, 12, 10),
      description: 'Quarterly maintenance charges', flat: 'A-101'),
    Bill(id: 'b_5', title: 'Gas Pipeline - Feb', amount: 680, dueDate: DateTime(2026, 3, 1),
      category: 'Gas', status: BillStatus.overdue, description: 'Piped gas monthly charges', flat: 'A-101'),
  ];

  // Society-wide bills for admin view
  static List<Bill> get allSocietyBills => [
    ...bills,
    Bill(id: 'b_6', title: 'Maintenance - Q1 2026', amount: 4500, dueDate: DateTime(2026, 3, 15),
      category: 'Maintenance', status: BillStatus.paid, paidDate: DateTime(2026, 2, 10),
      description: 'Quarterly maintenance', flat: 'A-102'),
    Bill(id: 'b_7', title: 'Maintenance - Q1 2026', amount: 4500, dueDate: DateTime(2026, 3, 15),
      category: 'Maintenance', status: BillStatus.pending, description: 'Quarterly maintenance', flat: 'A-201'),
    Bill(id: 'b_8', title: 'Maintenance - Q1 2026', amount: 4500, dueDate: DateTime(2026, 3, 15),
      category: 'Maintenance', status: BillStatus.overdue, description: 'Quarterly maintenance', flat: 'B-101'),
    Bill(id: 'b_9', title: 'Maintenance - Q1 2026', amount: 4500, dueDate: DateTime(2026, 3, 15),
      category: 'Maintenance', status: BillStatus.paid, paidDate: DateTime(2026, 2, 5),
      description: 'Quarterly maintenance', flat: 'B-201'),
    Bill(id: 'b_10', title: 'Maintenance - Q1 2026', amount: 4500, dueDate: DateTime(2026, 3, 15),
      category: 'Maintenance', status: BillStatus.pending, description: 'Quarterly maintenance', flat: 'C-101'),
  ];

  static List<GateEntry> get gateEntries => [
    GateEntry(id: 'g_1', visitorName: 'Swiggy Delivery Boy', flatVisiting: 'A-201',
      timeIn: DateTime(2026, 2, 20, 12, 30), timeOut: DateTime(2026, 2, 20, 12, 45),
      approvedBy: 'Amit Kumar', exited: true),
    GateEntry(id: 'g_2', visitorName: 'Amazon Courier', flatVisiting: 'B-102',
      timeIn: DateTime(2026, 2, 20, 14, 0), approvedBy: 'Sneha Desai'),
    GateEntry(id: 'g_3', visitorName: 'Ramesh Kumar (Guest)', flatVisiting: 'A-101',
      timeIn: DateTime(2026, 2, 20, 17, 0), approvedBy: 'Rajesh Sharma'),
    GateEntry(id: 'g_4', visitorName: 'Plumber - Raju', flatVisiting: 'C-201',
      timeIn: DateTime(2026, 2, 20, 9, 0), timeOut: DateTime(2026, 2, 20, 11, 30),
      approvedBy: 'Guard Desk', exited: true),
    GateEntry(id: 'g_5', visitorName: 'Flipkart Delivery', flatVisiting: 'A-301',
      timeIn: DateTime(2026, 2, 20, 10, 15), timeOut: DateTime(2026, 2, 20, 10, 25),
      approvedBy: 'Vikram Singh', exited: true),
  ];

  static List<ChatThread> get chatThreads => [
    ChatThread(oderId: 'r_10', otherName: 'Deepak Iyer', otherFlat: 'B-301',
      lastMessage: 'Is the TV still available?', lastTime: DateTime(2026, 2, 20, 15, 30), unread: 2),
    ChatThread(oderId: 'r_0', otherName: 'Rajesh Sharma', otherFlat: 'A-101',
      lastMessage: 'Complaint has been forwarded to plumber', lastTime: DateTime(2026, 2, 20, 10, 0), unread: 0),
    ChatThread(oderId: 'r_5', otherName: 'Anjali Mehta', otherFlat: 'B-201',
      lastMessage: 'See you at the Holi party!', lastTime: DateTime(2026, 2, 19, 18, 0), unread: 1),
  ];
}
