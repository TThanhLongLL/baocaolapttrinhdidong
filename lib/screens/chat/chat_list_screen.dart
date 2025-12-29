import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'chat_service.dart';
import 'chat_room_screen.dart';

// --- MÀN HÌNH 1: DANH SÁCH LỚP HỌC ---
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _auth = FirebaseAuth.instance;
  bool _isTeacher = false;

  Future<List<String>> _resolveTeacherKeys(Map<String, dynamic> userData, User user) async {
    // Gom các mã có thể dùng cho teacherId (giaoVienId, accountId, uid) để tránh lệch kiểu/field.
    final keys = <String>{};
    void addKey(dynamic raw) {
      if (raw == null) return;
      final v = raw.toString().trim();
      if (v.isNotEmpty) keys.add(v);
    }

    addKey(userData['teacherId']);
    addKey(userData['giaoVienId']);
    addKey(userData['accountId']);

    if (userData['accountId'] != null) {
      final q = await FirebaseFirestore.instance
          .collection('teachers')
          .where('accountId', isEqualTo: userData['accountId'])
          .limit(1)
          .get();
      if (q.docs.isNotEmpty) {
        final d = q.docs.first.data();
        addKey(d['giaoVienId'] ?? d['teacherId'] ?? q.docs.first.id);
      }
    }

    if (user.email != null) {
      final qEmail = await FirebaseFirestore.instance
          .collection('teachers')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();
      if (qEmail.docs.isNotEmpty) {
        final d = qEmail.docs.first.data();
        addKey(d['giaoVienId'] ?? d['teacherId'] ?? qEmail.docs.first.id);
      }
    }

    addKey(user.uid);
    return keys.toList();
  }


  Widget _buildClassListStream(Stream<QuerySnapshot> classStream) {
    return StreamBuilder<QuerySnapshot>(
      stream: classStream,
      builder: (context, classSnap) {
        if (classSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = classSnap.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.class_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 10),
                Text(
                  _isTeacher ? "Bạn chưa dạy lớp nào" : "Bạn chưa tham gia lớp nào",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            String className = data['className'] ?? 'Lớp học';
            String classId = docs[index].id;

            if (!_isTeacher) {
              classId = docs[index].id;
              className = data['className'] ?? classId;
            }

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B8DEF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.group, color: Color(0xFF5B8DEF)),
                ),
                title: Text(className, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text(_isTeacher ? "Quản lý & Trò chuyện" : "Thảo luận lớp học"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClassMembersScreen(
                        classId: classId,
                        className: className,
                        isTeacher: _isTeacher,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Vui lòng đăng nhập")));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chọn lớp để trò chuyện"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final role = userData['role'] ?? 'student';
          _isTeacher = (role == 'teacher' || role == 'admin');

          if (!_isTeacher) {
            final Stream<QuerySnapshot> classStream = FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('enrolledClasses')
                .orderBy('joinedAt', descending: true)
                .snapshots();
            return _buildClassListStream(classStream);
          }

          return FutureBuilder<List<String>>(
            future: _resolveTeacherKeys(userData, user),
            builder: (context, keySnap) {
              if (!keySnap.hasData) return const Center(child: CircularProgressIndicator());
              final teacherKeys = keySnap.data!;
              final filters = teacherKeys.length > 10 ? teacherKeys.sublist(0, 10) : teacherKeys;
              final classesRef = FirebaseFirestore.instance.collection('classes');
              final classQuery = filters.length == 1
                  ? classesRef.where('teacherId', isEqualTo: filters.first)
                  : classesRef.where('teacherId', whereIn: filters);
              final Stream<QuerySnapshot> classStream = classQuery.snapshots();
              return _buildClassListStream(classStream);
            },
          );
        },
      ),
    );
  }
}

// --- MÀN HÌNH 2: DANH SÁCH THÀNH VIÊN (Có Tìm Kiếm & Realtime Unread) ---
class ClassMembersScreen extends StatefulWidget {
  final String classId;
  final String className;
  final bool isTeacher;

  const ClassMembersScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.isTeacher,
  });

  @override
  State<ClassMembersScreen> createState() => _ClassMembersScreenState();
}

class _ClassMembersScreenState extends State<ClassMembersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchText = "";
  final ChatService _chatService = ChatService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.className),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // THANH TÌM KIẾM
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchText = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Tìm kiếm học sinh...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // DANH SÁCH THÀNH VIÊN
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('classes').doc(widget.classId).snapshots(),
              builder: (context, classSnap) {
                if (!classSnap.hasData) return const Center(child: CircularProgressIndicator());
                
                final classData = classSnap.data!.data() as Map<String, dynamic>?;
                if (classData == null) return const SizedBox();

                // Lấy thông tin GV
                final teacherId = classData['teacherId'];
                final teacherName = classData['teacherName'] ?? 'Giáo viên';

                // Lấy danh sách members (Học sinh)
                return StreamBuilder<QuerySnapshot>(
                  stream: classSnap.data!.reference.collection('members').snapshots(),
                  builder: (context, membersSnap) {
                    if (!membersSnap.hasData) return const Center(child: CircularProgressIndicator());

                    final List<Map<String, dynamic>> allMembers = [];

                    // 1. Thêm GV vào list (nếu mình không phải là GV)
                    if (teacherId != null && teacherId != _currentUserId) {
                      allMembers.add({
                        'uid': teacherId,
                        'name': teacherName,
                        'role': 'Giáo viên',
                        'avatar': null, // Có thể fetch thêm nếu cần
                      });
                    }

                    // 2. Thêm Học sinh
                    for (var doc in membersSnap.data!.docs) {
                      final mData = doc.data() as Map<String, dynamic>;
                      if (mData['userId'] == _currentUserId) continue; // Bỏ qua chính mình
                      
                      allMembers.add({
                        'uid': mData['userId'],
                        'name': mData['userName'] ?? 'Học sinh',
                        'role': 'Học sinh',
                        'avatar': null,
                      });
                    }

                    // 3. Lọc theo tìm kiếm
                    final filteredMembers = allMembers.where((m) {
                      final name = (m['name'] as String).toLowerCase();
                      return name.contains(_searchText);
                    }).toList();

                    if (filteredMembers.isEmpty) {
                      return const Center(child: Text("Không tìm thấy ai"));
                    }

                    return ListView.builder(
                      itemCount: filteredMembers.length,
                      itemBuilder: (context, index) {
                        final member = filteredMembers[index];
                        return _buildMemberTile(member);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> member) {
    return StreamBuilder<DocumentSnapshot>(
      // Stream để lắng nghe thay đổi unread count realtime
      stream: _chatService.getConversationStream(_currentUserId, member['uid']),
      builder: (context, convSnap) {
        int unread = 0;
        String subtitle = member['role'];
        String timeStr = "";

        if (convSnap.hasData && convSnap.data!.exists) {
          final data = convSnap.data!.data() as Map<String, dynamic>;
          
          // Check unread
          final unreadMap = data['unreadCounts'] as Map<String, dynamic>?;
          unread = (unreadMap?[_currentUserId] ?? 0) as int;

          // Hiển thị tin nhắn cuối
          if (data['lastMessage'] != null && data['lastMessage'].toString().isNotEmpty) {
            subtitle = data['lastMessage'];
            if (data['lastSenderId'] == _currentUserId) {
              subtitle = "Bạn: $subtitle";
            }
          }
          
          // Thời gian
          if (data['updatedAt'] != null) {
            final dt = (data['updatedAt'] as Timestamp).toDate();
            timeStr = DateFormat('HH:mm').format(dt);
          }
        }

        return ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: member['role'] == 'Giáo viên' ? const Color(0xFFFFF7E6) : const Color(0xFFF0F5FF),
                child: Text(
                  (member['name'] as String)[0].toUpperCase(),
                  style: TextStyle(
                    color: member['role'] == 'Giáo viên' ? Colors.orange : Colors.blue,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
              if (member['role'] == 'Giáo viên')
                const Positioned(
                  right: 0, bottom: 0,
                  child: Icon(Icons.verified, size: 14, color: Colors.orange),
                )
            ],
          ),
          title: Text(member['name'], style: TextStyle(fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal)),
          subtitle: Text(
            subtitle, 
            maxLines: 1, 
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: unread > 0 ? Colors.black87 : Colors.grey,
              fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (timeStr.isNotEmpty)
                Text(timeStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 4),
              if (unread > 0)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unread > 9 ? "9+" : "$unread",
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          onTap: () async {
            final convId = await _chatService.ensureConversation(
              userId: _currentUserId,
              peerId: member['uid'],
              classId: widget.classId,
              userName: FirebaseAuth.instance.currentUser?.displayName,
              peerName: member['name'],
            );
            
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatRoomScreen(
                  conversationId: convId,
                  peerId: member['uid'],
                  peerName: member['name'],
                  participants: [_currentUserId, member['uid']],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
