import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'join_requests_screen.dart';
import 'package:file_picker/file_picker.dart'; 
import 'file_handler.dart'; 


class ClassPost {
  String id;
  String type;
  String title;
  String content;
  DateTime createdAt;
  String authorName;
  DateTime? deadline;

  ClassPost({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.authorName,
    this.deadline,
  });
}

class ClassroomScreen extends StatefulWidget {
  final String classId;
  final String className;
  final String bannerColorHex;

  const ClassroomScreen({
    Key? key,
    required this.classId,
    required this.className,
    this.bannerColorHex = "0xFF6C63FF",
  }) : super(key: key);

  @override
  State<ClassroomScreen> createState() => _ClassroomScreenState();
}

class _ClassroomScreenState extends State<ClassroomScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String userRole = 'student';
  String? userAccountId;
  String? userFullName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    if (currentUser == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    if (doc.exists) {
      setState(() {
        userRole = doc.data()?['role'] ?? 'student';
        userAccountId = doc.data()?['accountId'] as String?;
        userFullName = doc.data()?['fullName'] as String?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Color(int.parse(widget.bannerColorHex));
    final Color accentColor = const Color(0xFF1F9CF0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 220,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: primaryColor,
              actions: [
                if (userRole == 'teacher' || userRole == 'admin')
                  IconButton(
                    icon: const Icon(Icons.group_add_outlined),
                    tooltip: 'Duyệt yêu cầu tham gia',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JoinRequestsScreen(
                            classId: widget.classId,
                            className: widget.className,
                          ),
                        ),
                      );
                    },
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: false,
                // Extra bottom padding keeps the title from overlapping the TabBar.
                titlePadding: const EdgeInsets.only(left: 20, bottom: 64, right: 20),
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.className,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor,
                            primaryColor.withOpacity(0.8),
                            accentColor.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -20,
                      bottom: -10,
                      child: Icon(Icons.auto_awesome, size: 160, color: Colors.white.withOpacity(0.08)),
                    ),
                    Positioned(
                      left: -30,
                      top: 30,
                      child: Icon(Icons.blur_on, size: 140, color: Colors.white.withOpacity(0.06)),
                    ),
                  ],
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(58),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    labelColor: primaryColor,
                    unselectedLabelColor: Colors.white.withOpacity(0.8),
                    indicatorPadding: const EdgeInsets.all(6),
                    tabs: const [
                      Tab(text: "Bảng tin"),
                      Tab(text: "Bài tập"),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF7F9FC), Color(0xFFF0F4FA)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildStreamTab(primaryColor),
              _buildClassworkTab(primaryColor),
            ],
          ),
        ),
      ),
      floatingActionButton: userRole == 'teacher' || userRole == 'admin'
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateDialog(context),
              label: const Text("Tạo mới"),
              icon: const Icon(Icons.add),
              backgroundColor: accentColor,
              elevation: 6,
            )
          : null,
    );
  }

  Widget _buildStreamTab(Color primaryColor) {
    return Column(
      children: [
        if (userRole == 'teacher' || userRole == 'admin')
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: _StyledActionButton(
                    color: primaryColor,
                    icon: Icons.campaign,
                    label: "Thêm thông báo",
                    onTap: () => _showCreateDialog(context, isAnnouncement: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StyledActionButton.outlined(
                    color: primaryColor,
                    icon: Icons.assignment,
                    label: "Thêm bài tập",
                    onTap: () => _showCreateDialog(context, isAnnouncement: false),
                  ),
                ),
              ],
            ),
          ),
        if (userRole == 'teacher' || userRole == 'admin')
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Material(
              elevation: 3,
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: primaryColor.withOpacity(0.12),
                  child: Icon(Icons.edit_outlined, color: primaryColor),
                ),
                title: const Text("Thông báo điều gì đó cho lớp...", style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => _showCreateDialog(context, isAnnouncement: true),
              ),
            ),
          ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('classes')
                .doc(widget.classId)
                .collection('posts')
                .where('type', isEqualTo: 'announcement')  
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
               if (snapshot.hasError) {
                  return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Center(
                  child: Text("Chưa có thông báo nào.", style: TextStyle(color: Colors.grey)),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final type = data['type'] ?? 'announcement';
                  final isAssignment = type == 'assignment';
                  final Color badgeColor = isAssignment ? const Color(0xFF1F9CF0) : const Color(0xFFFFA726);

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _openPostDetail(docs[index].id, data),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isAssignment ? Icons.assignment : Icons.campaign,
                                    color: badgeColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['authorName'] ?? "Giáo viên",
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                    ),
                                    Text(
                                      _formatDate(data['createdAt']),
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isAssignment ? "Bài tập" : "Thông báo",
                                    style: TextStyle(color: badgeColor, fontWeight: FontWeight.w700, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              data['title'] ?? "",
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, height: 1.2),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              data['content'] ?? "",
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[700], height: 1.4),
                            ),
                            if (isAssignment) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.schedule, size: 16, color: Colors.redAccent),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Hạn nộp: ${_formatDate(data['deadline'])}",
                                    style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w600),
                                  ),
                                  const Spacer(),
                                  const Text("Xem chi tiết >", style: TextStyle(fontSize: 12, color: Color(0xFF1F9CF0))),
                                ],
                              ),
                            ],
                          ],
                        ),
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
  }

  Widget _buildClassworkTab(Color primaryColor) {
    return Column(
      children: [
        if (userRole == 'teacher' || userRole == 'admin')
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: _StyledActionButton(
                color: primaryColor,
                icon: Icons.add,
                label: "Thêm bài tập",
                onTap: () => _showCreateDialog(context, isAnnouncement: false),
              ),
            ),
          ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('classes')
                .doc(widget.classId)
                .collection('posts')
                .where('type', isEqualTo: 'assignment')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.assignment_turned_in, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text("Chưa có bài tập nào", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.assignment, color: primaryColor),
                      ),
                      title: Text(data['title'], style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text("Hạn nộp: ${_formatDate(data['deadline'])}", style: const TextStyle(color: Colors.redAccent)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openPostDetail(docs[index].id, data),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCreateDialog(BuildContext context, {bool isAnnouncement = false}) {
    String type = isAnnouncement ? 'announcement' : 'assignment';
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    DateTime deadline = DateTime.now().add(const Duration(days: 7));
    final Color primaryColor = Color(int.parse(widget.bannerColorHex));
    const Color accentColor = Color(0xFF1F9CF0);
    
    // Biến lưu file của giáo viên
    PlatformFile? attachment;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(isAnnouncement ? "Tạo Thông Báo" : "Tạo Bài Tập Mới"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ... (Phần Dropdown và TextField giữ nguyên) ...
                  if (!isAnnouncement)
                    DropdownButtonFormField<String>(
                      value: type,
                      items: const [
                        DropdownMenuItem(value: 'announcement', child: Text("📢 Thông báo")),
                        DropdownMenuItem(value: 'assignment', child: Text("📝 Bài tập")),
                      ],
                      onChanged: (val) => setStateDialog(() => type = val!),
                      decoration: _inputDecoration("Loại bài đăng", primaryColor),
                    ),
                  const SizedBox(height: 10),
                  TextField(controller: titleCtrl, decoration: _inputDecoration("Tiêu đề", primaryColor)),
                  const SizedBox(height: 10),
                  TextField(controller: contentCtrl, decoration: _inputDecoration("Nội dung chi tiết", primaryColor), maxLines: 3),
                  
                  // --- PHẦN MỚI: CHỌN FILE ĐÍNH KÈM ---
                  const SizedBox(height: 10),
                  ListTile(
                    tileColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    leading: const Icon(Icons.attach_file),
                    title: Text(attachment != null ? attachment!.name : "Đính kèm file (Tùy chọn)"),
                    trailing: attachment != null 
                      ? IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => setStateDialog(() => attachment = null))
                      : const Icon(Icons.add_circle_outline, color: Colors.blue),
                    onTap: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles();
                      if (result != null) {
                        setStateDialog(() => attachment = result.files.first);
                      }
                    },
                  ),
                  // ------------------------------------

                  if (type == 'assignment') ...[
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text("Hạn nộp: ${DateFormat('dd/MM/yyyy').format(deadline)}"),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context, initialDate: deadline,
                          firstDate: DateTime.now(), lastDate: DateTime(2100),
                        );
                        if (picked != null) setStateDialog(() => deadline = picked);
                      },
                    ),
                  ]
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text("Hủy", style: TextStyle(color: primaryColor))),
              ElevatedButton(
                onPressed: isUploading ? null : () async {
                  if (titleCtrl.text.isEmpty) return;
                  setStateDialog(() => isUploading = true); // Hiện loading

                  // Upload file nếu có
                  String? fileUrl;
                  String? fileName;
                  if (attachment != null) {
                    fileUrl = await CloudinaryService.uploadFile(attachment!);
                    fileName = attachment!.name;
                  }

                  await FirebaseFirestore.instance
                      .collection('classes')
                      .doc(widget.classId)
                      .collection('posts')
                      .add({
                    'type': type,
                    'title': titleCtrl.text,
                    'content': contentCtrl.text,
                    'createdAt': FieldValue.serverTimestamp(),
                    'authorId': userAccountId ?? currentUser?.uid,
                    'authorName': userFullName ?? "Giáo viên",
                    'deadline': type == 'assignment' ? Timestamp.fromDate(deadline) : null,
                    'attachmentUrl': fileUrl, // Lưu link file
                    'attachmentName': fileName, // Lưu tên file
                  });
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: accentColor),
                child: isUploading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Đăng bài"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openPostDetail(String postId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(
          classId: widget.classId,
          postId: postId,
          postData: data,
          userRole: userRole,
          accountId: userAccountId,
          userName: userFullName ?? currentUser?.displayName,
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "";
    if (timestamp is Timestamp) {
      return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
    }
    return "";
  }

  Future<void> _openGradingDialog(BuildContext context, String postId, String submissionId, String grade, String note) async {
    final gradeCtrl = TextEditingController(text: grade);
    final noteCtrl = TextEditingController(text: note);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Chấm điểm & nhận xét"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: gradeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Điểm (VD: 9.5)"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: "Nhận xét"),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('classes')
                  .doc(widget.classId)
                  .collection('posts')
                  .doc(postId)
                  .collection('submissions')
                  .doc(submissionId)
                  .set({
                'grade': gradeCtrl.text,
                'teacherNote': noteCtrl.text,
              }, SetOptions(merge: true));
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lưu điểm/nhận xét"), backgroundColor: Colors.green));
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration(String label, Color primaryColor) {
  return InputDecoration(
    labelText: label,
    floatingLabelStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
    filled: true,
    fillColor: const Color(0xFFF5F7FB),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: primaryColor.withOpacity(0.25)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: primaryColor, width: 1.3),
    ),
  );
}

class _StyledActionButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool outlined;

  const _StyledActionButton({
    Key? key,
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  })  : outlined = false,
        super(key: key);

  const _StyledActionButton.outlined({
    Key? key,
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  })  : outlined = true,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = outlined
        ? OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            elevation: 2,
          );

    final Widget child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );

    return outlined
        ? OutlinedButton(onPressed: onTap, style: style, child: child)
        : ElevatedButton(onPressed: onTap, style: style, child: child);
  }
}

class PostDetailScreen extends StatelessWidget {
  final String classId;
  final String postId;
  final Map<String, dynamic> postData;
  final String userRole;
  final String? accountId;
  final String? userName;

  PostDetailScreen({
    Key? key,
    required this.classId,
    required this.postId,
    required this.postData,
    required this.userRole,
    this.accountId,
    this.userName,
  }) : super(key: key);

  final commentCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final bool isAssignment = postData['type'] == 'assignment';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: Text(isAssignment ? "Chi tiết bài tập" : "Chi tiết thông báo"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.6,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isAssignment ? Icons.assignment : Icons.campaign,
                              size: 30,
                              color: isAssignment ? const Color(0xFF1F9CF0) : const Color(0xFFFFA726),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                postData['title'],
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1F3A6F)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Đăng bởi: ${postData['authorName']} • ${_formatDate(postData['createdAt'])}",
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const Divider(height: 28),
                        Text(
                          postData['content'],
                          style: const TextStyle(fontSize: 16, height: 1.6, color: Color(0xFF2F3640)),
                        ),
                        if (postData['attachmentUrl'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: InkWell(
                              onTap: () => CloudinaryService.downloadFile(postData['attachmentUrl']),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.file_download, color: Colors.blue),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        postData['attachmentName'] ?? "Tài liệu đính kèm",
                                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (isAssignment) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F9FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF1F9CF0).withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Trạng thái bài làm:", style: TextStyle(fontWeight: FontWeight.bold)),
                                    _buildSubmissionStatus(),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Text("Hạn chót:", style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(_formatDate(postData['deadline']), style: const TextStyle(color: Colors.red)),
                                const SizedBox(height: 16),
                                if (userRole == 'teacher' || userRole == 'admin') ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _pickNewDeadline(context),
                                          icon: const Icon(Icons.edit_calendar),
                                          label: const Text("Sửa hạn nộp"),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _confirmDeletePost(context),
                                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.redAccent,
                                            side: const BorderSide(color: Colors.redAccent),
                                          ),
                                          label: const Text("Xóa bài"),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (userRole == 'student')
                                  StreamBuilder<DocumentSnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('classes')
                                        .doc(classId)
                                        .collection('posts')
                                        .doc(postId)
                                        .collection('submissions')
                                        .doc(accountId ?? FirebaseAuth.instance.currentUser?.uid)
                                        .snapshots(),
                                    builder: (context, snap) {
                                      final bool submitted = snap.hasData && snap.data!.exists;
                                      final data = snap.data?.data() as Map<String, dynamic>?;
                                      final String fileName = data?['fileName'] ?? '';
                                      final String fileUrl = data?['fileUrl'] ?? '';
                                      final DateTime? deadline = postData['deadline'] is Timestamp
                                          ? (postData['deadline'] as Timestamp).toDate()
                                          : null;
                                      final bool deadlinePassed = deadline != null && deadline.isBefore(DateTime.now());
                                      final String submissionId = accountId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
                                      return Column(
                                        children: [
                                          if (submitted && fileName.isNotEmpty)
                                            ListTile(
                                              leading: const Icon(Icons.file_present, color: Colors.green),
                                              title: Text(fileName, overflow: TextOverflow.ellipsis),
                                              subtitle: const Text("Bài đã nộp"),
                                              trailing: IconButton(
                                                icon: const Icon(Icons.cloud_download, color: Colors.blue),
                                                onPressed: fileUrl.isEmpty ? null : () => CloudinaryService.downloadFile(fileUrl),
                                              ),
                                            ),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: (!submitted && !deadlinePassed) ? () => _submitAssignment(context) : null,
                                              icon: Icon(
                                                submitted
                                                    ? Icons.check_circle
                                                    : deadlinePassed
                                                        ? Icons.lock_clock
                                                        : Icons.upload_file,
                                              ),
                                              label: Text(
                                                submitted
                                                    ? "Đã nộp"
                                                    : deadlinePassed
                                                        ? "Đã hết hạn"
                                                        : "Nộp bài tập / Đính kèm ảnh",
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF1F9CF0),
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                          ),
                                          if (submitted && !deadlinePassed)
                                            TextButton.icon(
                                              onPressed: () => _cancelSubmission(context, submissionId),
                                              icon: const Icon(Icons.undo, color: Colors.redAccent),
                                              label: const Text(
                                                "Hủy nộp để nộp lại",
                                                style: TextStyle(color: Colors.redAccent),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                  if (userRole == 'teacher')
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          // Hiện BottomSheet danh sách nộp
                                          showModalBottomSheet(context: context, builder: (ctx) => _buildSubmissionList(ctx));
                                        },
                                        icon: const Icon(Icons.people),
                                        label: const Text("Xem bài làm học sinh"),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text("Bình luận của lớp học", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('classes')
                        .doc(classId)
                        .collection('posts')
                        .doc(postId)
                        .collection('comments')
                        .orderBy('createdAt', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final comments = snapshot.data!.docs;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final cmt = comments[index].data() as Map<String, dynamic>;
                          final String name = cmt['userName'] ?? "U";
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFEEF2F7),
                                child: Text(name.isNotEmpty ? name[0] : "U"),
                              ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text(cmt['content']),
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, -2)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentCtrl,
                    decoration: InputDecoration(
                      hintText: "Thêm nhận xét...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF1F9CF0)),
                  onPressed: () => _sendComment(context),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSubmissionStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();
    final String submissionId = accountId ?? user.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('posts')
          .doc(postId)
          .collection('submissions')
          .doc(submissionId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          return const Text("Đã nộp", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold));
        }
        return const Text("Chưa nộp", style: TextStyle(color: Colors.grey));
      },
    );
  }

  void _submitAssignment(BuildContext context) {
    // Chuyển sang màn hình nộp bài mới
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubmissionScreen(
          classId: classId,
          postId: postId,
          accountId: accountId,
          userName: userName,
        ),
      ),
    );
  }

  Future<void> _sendComment(BuildContext context) async {
    if (commentCtrl.text.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;

    await FirebaseFirestore.instance
        .collection('classes')
        .doc(classId)
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add({
      'userId': accountId ?? user?.uid,
      'userName': userName ?? user?.displayName ?? "Người dùng",
      'content': commentCtrl.text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    commentCtrl.clear();
  }

  Future<void> _openGradingDialog(BuildContext context, String submissionId, String grade, String note) async {
    final gradeCtrl = TextEditingController(text: grade);
    final noteCtrl = TextEditingController(text: note);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Chấm điểm & nhận xét", style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: gradeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Điểm (VD: 9.5)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: "Nhận xét",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('classes')
                  .doc(classId)
                  .collection('posts')
                  .doc(postId)
                  .collection('submissions')
                  .doc(submissionId)
                  .set({
                'grade': gradeCtrl.text,
                'teacherNote': noteCtrl.text,
              }, SetOptions(merge: true));
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Đã lưu điểm/nhận xét"), backgroundColor: Colors.green),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B8DEF),
              foregroundColor: Colors.white,
            ),
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelSubmission(BuildContext context, String submissionId) async {
    await FirebaseFirestore.instance
        .collection('classes')
        .doc(classId)
        .collection('posts')
        .doc(postId)
        .collection('submissions')
        .doc(submissionId)
        .delete();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã hủy nộp"), backgroundColor: Colors.orange),
      );
    }
  }

  Future<void> _pickNewDeadline(BuildContext context) async {
    DateTime initial = DateTime.now();
    if (postData['deadline'] is Timestamp) {
      initial = (postData['deadline'] as Timestamp).toDate();
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('posts')
          .doc(postId)
          .update({'deadline': Timestamp.fromDate(picked)});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã cập nhật hạn nộp"), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _confirmDeletePost(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa bài tập?"),
        content: const Text("Thao tác này sẽ xóa bài tập và các bài nộp liên quan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final submissions = await FirebaseFirestore.instance
        .collection('classes')
        .doc(classId)
        .collection('posts')
        .doc(postId)
        .collection('submissions')
        .get();
    for (final doc in submissions.docs) {
      await doc.reference.delete();
    }
    await FirebaseFirestore.instance
        .collection('classes')
        .doc(classId)
        .collection('posts')
        .doc(postId)
        .delete();
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã xóa bài tập"), backgroundColor: Colors.redAccent),
      );
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "";
    if (timestamp is Timestamp) {
      return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
    }
    return "";
  }
  Widget _buildSubmissionList(BuildContext context) {
    final double maxHeight = MediaQuery.of(context).size.height * 0.6;
    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: maxHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Danh sách nộp bài", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('classes')
                    .doc(classId)
                    .collection('posts')
                    .doc(postId)
                    .collection('submissions')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) return const Center(child: Text("Chưa có ai nộp bài"));

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final String name = data['studentName'] ?? "Học sinh";
                      final String fileName = data['fileName'] ?? "Không có file";
                      final String fileUrl = data['fileUrl'] ?? "";
                      final String submissionId = docs[index].id;
                      final String grade = data['grade']?.toString() ?? "";
                      final String note = data['teacherNote']?.toString() ?? "";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              backgroundColor: Color(0xFFE0E7FF),
                              child: Icon(Icons.person, color: Color(0xFF4F46E5)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text(fileName, style: const TextStyle(color: Colors.grey)),
                                  if (grade.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text("Điểm: $grade",
                                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                                    ),
                                  if (note.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text("Nhận xét: $note", style: const TextStyle(color: Colors.grey)),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.cloud_download, color: Colors.blue),
                                  onPressed: fileUrl.isEmpty ? null : () => CloudinaryService.downloadFile(fileUrl),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.deepPurple),
                                  onPressed: () => _openGradingDialog(context, submissionId, grade, note),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

}
