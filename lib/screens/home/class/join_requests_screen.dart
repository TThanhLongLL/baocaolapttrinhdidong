import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class JoinRequestsScreen extends StatefulWidget {
  final String classId;
  final String className;

  const JoinRequestsScreen({
    Key? key,
    required this.classId,
    required this.className,
  }) : super(key: key);

  @override
  State<JoinRequestsScreen> createState() => _JoinRequestsScreenState();
}

class _JoinRequestsScreenState extends State<JoinRequestsScreen> {
  bool _updatingAllowJoin = false;

  Future<void> _setAllowJoin(bool value) async {
    setState(() => _updatingAllowJoin = true);
    try {
      await FirebaseFirestore.instance.collection('classes').doc(widget.classId).update({
        'allowJoin': value,
      });
    } finally {
      if (mounted) setState(() => _updatingAllowJoin = false);
    }
  }

  Future<void> _handleRequest(
      DocumentSnapshot requestDoc, {
        required bool approve,
      }) async {
    final data = requestDoc.data() as Map<String, dynamic>;
    final studentId = data['userId'] as String?;
    final studentName = data['userName'] as String? ?? 'Học sinh';

    // Lấy thêm thông tin lớp để lưu cho sinh viên (nếu cần)
    // Hoặc bạn có thể truyền tên lớp từ widget cha vào
    final className = widget.className;

    if (studentId == null) return;

    final classRef = FirebaseFirestore.instance.collection('classes').doc(widget.classId);
    final userRef = FirebaseFirestore.instance.collection('users').doc(studentId); // Reference tới sinh viên

    final batch = FirebaseFirestore.instance.batch();

    // 1. Cập nhật trạng thái yêu cầu (Approved/Rejected)
    batch.update(requestDoc.reference, {
      'status': approve ? 'approved' : 'rejected',
      'handledAt': FieldValue.serverTimestamp(),
    });

    if (approve) {
      // 2. THÊM VÀO DANH SÁCH THÀNH VIÊN CỦA LỚP (Để GV quản lý)
      // Đường dẫn: classes/{classId}/members/{studentId}
      final memberRef = classRef.collection('members').doc(studentId);
      batch.set(memberRef, {
        'userId': studentId,
        'userName': studentName,
        'role': 'student', // Đảm bảo role là student
        'joinedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      // 3. THÊM LỚP VÀO DANH SÁCH CỦA SINH VIÊN (Để SV thấy ở Home) -> QUAN TRỌNG
      // Đường dẫn: users/{studentId}/enrolledClasses/{classId}
      final enrolledRef = userRef.collection('enrolledClasses').doc(widget.classId);
      batch.set(enrolledRef, {
        'classId': widget.classId,
        'className': className,
        // Có thể lưu thêm teacherName nếu có, để hiển thị nhanh
        'joinedAt': FieldValue.serverTimestamp(),
      });

      // 4. Tăng số lượng thành viên trong lớp
      batch.update(classRef, {'memberCount': FieldValue.increment(1)});
    }

    try {
      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? "Đã duyệt thành viên!" : "Đã từ chối yêu cầu"),
            backgroundColor: approve ? Colors.green : Colors.grey,
          )
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
      );
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF5F7FB),
    appBar: AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.group_add, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Duyệt yêu cầu • ${widget.className}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF6C63FF),
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('classes').doc(widget.classId).snapshots(),
        builder: (context, classSnap) {
          if (classSnap.hasError) {
            return const Center(child: Text('Không tải được thông tin lớp'));
          }
          if (!classSnap.hasData || !classSnap.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }
          final classData = classSnap.data!.data() as Map<String, dynamic>?;
          final allowJoin = (classData?['allowJoin'] as bool?) ?? true;
          return Column(
            children: [
              ListTile(
                title: const Text('Cho phép gửi yêu cầu tham gia'),
                trailing: Switch(
                  value: allowJoin,
                  onChanged: _updatingAllowJoin ? null : _setAllowJoin,
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('classes')
                      .doc(widget.classId)
                      .collection('joinRequests')
                      .where('status', isEqualTo: 'pending')
                      .orderBy('requestedAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('Không có yêu cầu nào'));
                    }
                    final docs = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text((data['userName'] ?? 'U')[0]),
                            ),
                            title: Text(data['userName'] ?? 'Học sinh'),
                            subtitle: Text('Gửi lúc: ${_formatDate(data['requestedAt'])}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.redAccent),
                                  onPressed: () => _handleRequest(doc, approve: false),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  onPressed: () => _handleRequest(doc, approve: true),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(dynamic ts) {
    if (ts is Timestamp) {
      final dt = ts.toDate();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '';
  }
}
