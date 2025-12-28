import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'components/course_card.dart';
import 'components/secondary_course_card.dart';

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

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final bool isTeacher = _role == 'teacher' || _role == 'admin';
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: SafeArea(
        bottom: false,
        child: ListView(
          // --- SỬA Ở ĐÂY: Tăng padding top lên 80 để né nút Menu ---
          padding: const EdgeInsets.fromLTRB(20, 80, 20, 100),
          // ---------------------------------------------------------
          children: [
            // --- HEADER ---
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

            // --- PHẦN 1: NHẬP MÃ (Chỉ cho Sinh viên) ---
            if (!isTeacher) ...[
              Container(
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
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng tạo lớp')));
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text("Tạo lớp"),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // --- STREAM BUILDER ---
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
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('notifications').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: const Text("Không có thông báo mới", style: TextStyle(color: Colors.grey)),
                  );
                }
                final notifications = snapshot.data!.docs;
                return Column(
                  children: notifications.map((doc) {
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
  
  // ✅ Filter ra những classId hợp lệ
  final validClassIds = <String>[];
  for (final doc in docs) {
    final classId = doc.id;
    validClassIds.add(classId);
  }

  // Nếu sau khi filter mà không còn card nào -> hiện thông báo
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
}