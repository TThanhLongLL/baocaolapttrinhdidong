import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'components/course_card.dart';
import 'components/secondary_course_card.dart';
import '../../services/notification_service.dart';
import '../../services/local_notification_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _codeCtrl = TextEditingController();
  bool _submitting = false;
  String _role = 'student';
  String? _accountId;
  String? _teacherId;
  bool _joinExpanded = false;
  
  // Controller tạo lớp
  final TextEditingController _newClassNameCtrl = TextEditingController();
  final TextEditingController _newClassCodeCtrl = TextEditingController();
  final TextEditingController _newKhoaHocCtrl = TextEditingController();
  final TextEditingController _newNamHocCtrl = TextEditingController();
  final TextEditingController _newMaxMembersCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRole();
    
    // Khởi tạo và báo luôn
    LocalNotificationService().init().then((_) {
      print("🔔 Service Init Xong -> Bắt đầu quét dữ liệu...");
      _checkAndNotifyImmediately(); 
      _checkAssignmentsAndNotify();
    });
  }

  // --- LOGIC MỚI: QUÉT VÀ BÁO NGAY ---
  Future<void> _checkAndNotifyImmediately() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    
    // 1. Lấy danh sách lớp đã tham gia
    final enrolledQuery = await FirebaseFirestore.instance
        .collection('users').doc(user.uid).collection('enrolledClasses').get();
    final classIds = enrolledQuery.docs.map((e) => e.id).toList();

    if (classIds.isEmpty) return;

    // 2. Tìm lịch học NGÀY MAI
    final tomorrow = now.add(const Duration(days: 1));
    final startOfTomorrow = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    final endOfTomorrow = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59, 59);
    
    int lessonCount = 0;
    String firstLessonTopic = "";

    for (String classId in classIds) {
      final lessons = await FirebaseFirestore.instance
          .collection('classes').doc(classId).collection('lessons')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfTomorrow))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfTomorrow))
          .get();
      
      if (lessons.docs.isNotEmpty) {
        lessonCount += lessons.docs.length;
        if (firstLessonTopic.isEmpty) {
          firstLessonTopic = lessons.docs.first.data()['topic'] ?? "Buổi học";
        }
      }
    }

    // NẾU CÓ LỊCH -> BẮN THÔNG BÁO NGAY
    if (lessonCount > 0) {
      await LocalNotificationService().showInstantNotification(
        id: 1001,
        title: "📅 Lịch học ngày mai",
        body: "Bạn có $lessonCount buổi học ngày mai (VD: $firstLessonTopic). Chuẩn bị nhé!",
      );
    }

    // 3. Tìm bài tập sắp hết hạn (trong 24h tới)
    int assignmentCount = 0;
    final deadlineThreshold = now.add(const Duration(hours: 24));
    
    for (String classId in classIds) {
      final assignments = await FirebaseFirestore.instance
          .collection('classes').doc(classId).collection('posts')
          .where('type', isEqualTo: 'assignment')
          .where('deadline', isGreaterThan: Timestamp.fromDate(now))
          .where('deadline', isLessThan: Timestamp.fromDate(deadlineThreshold))
          .get();
      assignmentCount += assignments.docs.length;
    }

    // NẾU CÓ BÀI TẬP -> BẮN THÔNG BÁO NGAY
    if (assignmentCount > 0) {
       await LocalNotificationService().showInstantNotification(
        id: 2002,
        title: "⏰ Deadline sắp đến!",
        body: "Bạn có $assignmentCount bài tập cần nộp trong 24h tới. Đừng quên nhé!",
      );
    }
  }
  // --- HÀM MỚI: QUÉT VÀ THÔNG BÁO BÀI TẬP ---
Future<void> _checkAssignmentsAndNotify() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final now = DateTime.now();
  // Ngưỡng thời gian: Kiểm tra bài tập hết hạn trong 24 giờ tới
  final deadlineThreshold = now.add(const Duration(hours: 24));

  try {
    // 1. Lấy danh sách lớp đã tham gia
    final enrolledQuery = await FirebaseFirestore.instance
        .collection('users').doc(user.uid).collection('enrolledClasses').get();
    
    final classIds = enrolledQuery.docs.map((e) => e.id).toList();

    if (classIds.isEmpty) return;

    int assignmentCount = 0;
    String firstAssignmentTitle = "";

    // 2. Duyệt qua từng lớp để tìm bài tập
    for (String classId in classIds) {
      // Lấy các bài post là 'assignment' và có deadline chưa qua
      final assignments = await FirebaseFirestore.instance
          .collection('classes').doc(classId).collection('posts')
          .where('type', isEqualTo: 'assignment') // Chỉ lấy bài tập
          .where('deadline', isGreaterThan: Timestamp.fromDate(now)) // Chưa hết hạn
          .where('deadline', isLessThan: Timestamp.fromDate(deadlineThreshold)) // Sắp hết hạn (trong 24h)
          .get();

      if (assignments.docs.isNotEmpty) {
        assignmentCount += assignments.docs.length;
        // Lấy tên bài đầu tiên để hiện trong thông báo cho cụ thể
        if (firstAssignmentTitle.isEmpty) {
          final data = assignments.docs.first.data();
          firstAssignmentTitle = data['title'] ?? "Bài tập mới";
        }
      }
    }

    // 3. Nếu có bài tập sắp hết hạn -> BẮN THÔNG BÁO
    if (assignmentCount > 0) {
      String bodyText = "";
      if (assignmentCount == 1) {
        bodyText = "Bạn có bài tập \"$firstAssignmentTitle\" sắp hết hạn. Nộp ngay kẻo muộn!";
      } else {
        bodyText = "Gấp! Bạn có $assignmentCount bài tập sắp hết hạn trong 24h tới (VD: $firstAssignmentTitle).";
      }

      await LocalNotificationService().showInstantNotification(
        id: 2024, // ID khác với lịch học để không bị đè
        title: "⏰ Nhắc nhở bài tập",
        body: bodyText,
      );
    } else {
      print("✅ Không có bài tập nào sắp hết hạn trong 24h tới.");
    }

  } catch (e) {
    print("❌ Lỗi quét bài tập: $e");
  }
}

  // ... (Giữ nguyên các hàm _loadRole, _requestJoin, dispose...)
  @override
  void dispose() {
    _newClassNameCtrl.dispose();
    _newClassCodeCtrl.dispose();
    _newKhoaHocCtrl.dispose();
    _newNamHocCtrl.dispose();
    _newMaxMembersCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRole() async {
     final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data() ?? {};

    String role = data['role'] ?? 'student';
    String? accountId = data['accountId'] as String?;
    String? foundTeacherId = (data['teacherId'] ?? data['giaoVienId']) as String?;

    if ((role == 'teacher' || role == 'admin') && foundTeacherId == null) {
      if (accountId != null) {
        final q = await FirebaseFirestore.instance
            .collection('teachers')
            .where('accountId', isEqualTo: accountId)
            .limit(1)
            .get();
        if (q.docs.isNotEmpty) {
          final tData = q.docs.first.data();
          foundTeacherId = tData['giaoVienId'] ?? tData['teacherId'] ?? q.docs.first.id;
        }
      }
      if (foundTeacherId == null && user.email != null) {
        final qEmail = await FirebaseFirestore.instance
            .collection('teachers')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();
        if (qEmail.docs.isNotEmpty) {
          final tData = qEmail.docs.first.data();
          foundTeacherId = tData['giaoVienId'] ?? qEmail.docs.first.id;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _role = role;
      _accountId = accountId;
      _teacherId = foundTeacherId;
    });
  }
  
  Future<void> _requestJoin(BuildContext context) async {
      // ... (Copy lại code cũ của bạn vào đây) ...
      final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('classes')
          .where('classCode', isEqualTo: code)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mã lớp không tồn tại')));
        return;
      }

      final doc = snap.docs.first;
      final data = doc.data();
      final allowJoin = data['allowJoin'] ?? true;

      if (!allowJoin) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lớp này đang khóa tham gia')));
        return;
      }

      final reqCheck = await doc.reference.collection('joinRequests').doc(user.uid).get();
      if (reqCheck.exists) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bạn đã gửi yêu cầu rồi, vui lòng chờ duyệt')));
        return;
      }

      await doc.reference.collection('joinRequests').doc(user.uid).set({
        'userId': user.uid,
        'userName': user.displayName ?? 'Học sinh',
        'email': user.email,
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'role': 'student',
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi yêu cầu thành công!'), backgroundColor: Colors.green));
      _codeCtrl.clear();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ... (Phần UI build giữ nguyên, CHỈ SỬA NÚT TEST) ...

  @override
  Widget build(BuildContext context) {
    final bool isTeacher = _role == 'teacher' || _role == 'admin';
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 80, 20, 100),
          children: [
            // --- HEADER (Giữ nguyên) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Xin chào, ${user?.displayName?.split(' ').last ?? 'Bạn'}",
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isTeacher ? "Quản lý lớp học của bạn" : "Hôm nay bạn muốn học gì?",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                CircleAvatar(
                  radius: 24,
                  backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                  backgroundColor: Colors.blue.shade100,
                  child: user?.photoURL == null ? const Icon(Icons.person, color: Colors.blue) : null,
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- PHẦN 1: NHẬP MÃ (SỬA NÚT TEST Ở ĐÂY) ---
            if (!isTeacher) ...[
              Container(
                // ... (Code giao diện nhập mã giữ nguyên) ...
                 padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      offset: const Offset(0, 10),
                      blurRadius: 20,
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() => _joinExpanded = !_joinExpanded),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.qr_code_rounded, color: Color(0xFF3B82F6)),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "Tham gia lớp học mới",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                              ),
                            ),
                            AnimatedRotation(
                              turns: _joinExpanded ? 0.0 : 0.25,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(Icons.chevron_right, color: Color(0xFF3B82F6)),
                            )
                          ],
                        ),
                      ),
                    ),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 250),
                      crossFadeState: _joinExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      firstChild: const SizedBox.shrink(),
                      secondChild: Column(
                        children: [
                          const SizedBox(height: 12),
                          TextField(
                            controller: _codeCtrl,
                            decoration: InputDecoration(
                              hintText: "Nhập mã lớp (VD: 123456)",
                              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: _submitting
                                  ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                                  : IconButton(
                                icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF3B82F6)),
                                onPressed: () => _requestJoin(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
            ],

            // ... (Phần còn lại giữ nguyên: Danh sách lớp, Thông báo...) ...
             // --- PHẦN 2: DANH SÁCH LỚP HỌC ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isTeacher ? "Lớp đang dạy" : "Lớp đang học",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                ),
                if (isTeacher)
                  TextButton.icon(
                    onPressed: () => _showCreateClassDialog(context),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text("Tạo lớp"),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // STREAM BUILDER LỚP HỌC
            isTeacher
                ? StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('classes')
                  .where('teacherId', isEqualTo: _teacherId ?? _accountId ?? user?.uid)
                  .snapshots(),
              builder: (context, snapshot) => _buildClassList(snapshot, isTeacher: true),
            )
                : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .collection('enrolledClasses')
                  .orderBy('joinedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) => _buildClassList(snapshot, isTeacher: false),
            ),

            const SizedBox(height: 30),

            // --- THÔNG BÁO ---
            const Text(
              "Bảng tin trường",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
            ),
            const SizedBox(height: 16),
            
            // --- STREAM THÔNG BÁO ---
            StreamBuilder<QuerySnapshot>(
              stream: NotificationService.instance.streamAllNotifications(), 
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: const Text("Không có thông báo mới", style: TextStyle(color: Colors.grey)),
                  );
                }
                
                final now = DateTime.now();
                // Lọc thông báo chưa hết hạn
                final activeNotifications = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['expirationDate'] == null) return true;
                  final expire = (data['expirationDate'] as Timestamp).toDate();
                  return expire.isAfter(now);
                }).toList();

                if (activeNotifications.isEmpty) {
                   return Container(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: const Text("Không có thông báo mới", style: TextStyle(color: Colors.grey)),
                  );
                }

                return Column(
                  children: activeNotifications.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    Color cardColor = const Color(0xFF80A4FF);
                    if (data['color'] != null) cardColor = Color(data['color']);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SecondaryCourseCard(
                        title: data['title'] ?? "Thông báo",
                        subtitle: data['subtitle'] ?? "Xem chi tiết",
                        color: cardColor,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ... (Giữ nguyên các hàm _buildClassList, _showCreateClassDialog, _buildTextField...)
   Widget _buildClassList(AsyncSnapshot<QuerySnapshot> snapshot, {required bool isTeacher}) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            isTeacher ? "Bạn chưa dạy lớp nào" : "Bạn chưa tham gia lớp nào",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final docs = snapshot.data!.docs;
    final validClassIds = <String>[];
    for (final doc in docs) {
      validClassIds.add(doc.id);
    }

    if (validClassIds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            isTeacher ? "Bạn chưa dạy lớp nào" : "Bạn chưa tham gia lớp nào",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: validClassIds.map((classId) {
          return Padding(
            padding: const EdgeInsets.only(right: 20),
            child: CourseCard(
              classId: classId,
              iconSrc: "assets/icons/ios.svg",
              color: const Color(0xFF7553F6),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showCreateClassDialog(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _newClassNameCtrl.clear();
    _newKhoaHocCtrl.clear();
    _newClassCodeCtrl.text = "CL-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
    _newNamHocCtrl.text = "${DateTime.now().year}-${DateTime.now().year + 1}";
    _newMaxMembersCtrl.text = "50";

    DateTime dateStart = DateTime.now();
    DateTime dateEnd = DateTime.now().add(const Duration(days: 30 * 4));

    const Color primaryColor = Color(0xFF6F5DE8);
    const Color secondaryColor = Color(0xFF8B80F8); 

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add_business_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            "Tạo Lớp Học Mới",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close, color: Colors.white70),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],

                    ),
                  ),

                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Thông tin cơ bản"),
                          const SizedBox(height: 8),
                          _buildTextField(_newClassNameCtrl, "Tên lớp (VD: 12A1)", Icons.class_, primaryColor),
                          const SizedBox(height: 16),
                          _buildTextField(_newKhoaHocCtrl, "Môn học (VD: Toán)", Icons.menu_book_rounded, primaryColor),
                          const SizedBox(height: 16),
                          _buildTextField(_newClassCodeCtrl, "Mã lớp (Tự động)", Icons.qr_code_2_rounded, primaryColor, isReadOnly: true),
                          
                          const SizedBox(height: 24),
                          _buildLabel("Chi tiết"),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _buildTextField(_newNamHocCtrl, "Năm học", Icons.calendar_month, primaryColor)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildTextField(_newMaxMembersCtrl, "Sĩ số", Icons.groups_rounded, primaryColor, isNumber: true)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFEEEFFF)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildCompactDatePicker(context, "Bắt đầu", dateStart, (val) => setStateDialog(() => dateStart = val)),
                                ),
                                Container(
                                  width: 1, 
                                  height: 40, 
                                  color: Colors.grey.withOpacity(0.3), 
                                  margin: const EdgeInsets.symmetric(horizontal: 12)
                                ),
                                Expanded(
                                  child: _buildCompactDatePicker(context, "Kết thúc", dateEnd, (val) => setStateDialog(() => dateEnd = val)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_newClassNameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text("Vui lòng nhập tên lớp!"),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              )
                            );
                            return;
                          }
                          Navigator.pop(ctx);

                          final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                          final userData = userDoc.data() ?? {};
                          final teacherName = userData['fullName'] ?? user.displayName ?? 'Giáo viên';
                          final teacherId = _teacherId ?? _accountId ?? user.uid;

                          await FirebaseFirestore.instance.collection('classes').add({
                            'className': _newClassNameCtrl.text.trim(),
                            'khoaHoc': _newKhoaHocCtrl.text.trim(),
                            'classCode': _newClassCodeCtrl.text.trim(),
                            'namHoc': _newNamHocCtrl.text.trim(),
                            'dateStart': Timestamp.fromDate(dateStart),
                            'dateEnd': Timestamp.fromDate(dateEnd),
                            'teacherId': teacherId,
                            'teacherName': teacherName,
                            'allowJoin': true,
                            'memberCount': 0,
                            'maxMembers': int.tryParse(_newMaxMembersCtrl.text) ?? 50,
                            'createdAt': FieldValue.serverTimestamp(),
                            'lopId': DateTime.now().millisecondsSinceEpoch.toString(),
                          });

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("🎉 Tạo lớp thành công!"), backgroundColor: Color(0xFF43A047)),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: primaryColor.withOpacity(0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          "Hoàn tất & Tạo lớp",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF9CA3AF),
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, Color accentColor, {bool isNumber = false, bool isReadOnly = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: ctrl,
        readOnly: isReadOnly,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF374151)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
          prefixIcon: Icon(icon, color: accentColor.withOpacity(0.8), size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCompactDatePicker(BuildContext context, String label, DateTime date, Function(DateTime) onSelect) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(primary: Color(0xFF6F5DE8)),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onSelect(picked);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                DateFormat('dd/MM/yyyy').format(date),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF374151), fontSize: 14),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }
}