import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Cần import intl để format ngày tháng
import 'package:baocaocuoiky/screens/home/schedule/create_schedule_screen.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({Key? key}) : super(key: key);

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final User? user = FirebaseAuth.instance.currentUser;

  // Quản lý ngày bắt đầu của tuần hiện tại (Luôn là Thứ 2)
  late DateTime _startOfWeek;

  final List<String> _dayLabels = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"];

  // Biến trạng thái Role
  bool _isTeacher = false;
  String? _teacherAccountId;
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    _initializeWeek(); // 1. Khởi tạo tuần hiện tại
    _loadUserRole();

    // Tab mặc định là ngày hôm nay (nếu trong tuần hiện tại) hoặc Thứ 2
    int initialIndex = DateTime.now().weekday - 1;
    _tabController = TabController(length: 7, vsync: this, initialIndex: initialIndex);
  }

  // Logic tìm ngày Thứ 2 đầu tuần của tuần hiện tại
 void _initializeWeek() {
    DateTime now = DateTime.now();
    // Luôn lấy thứ 2 của tuần hiện tại
    // Nếu hôm nay >= T2, lấy T2 tuần này; còn không lấy T2 tuần trước
    int daysToMonday = (now.weekday - 1); // 0 nếu T2, 1 nếu T3, ..., 6 nếu CN
    _startOfWeek = now.subtract(Duration(days: daysToMonday));
  }
  // Hàm chuyển tuần (Next / Previous)
  void _changeWeek(int offset) {
    setState(() {
      _startOfWeek = _startOfWeek.add(Duration(days: 7 * offset));
    });
  }

  // Logic Load Role (Giữ nguyên từ code trước)
  Future<void> _loadUserRole() async {
    if (user == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      final data = userDoc.data() ?? {};

      String role = data['role'] ?? 'student';
      String? accountId = data['accountId'];
      String? foundTeacherId = data['teacherId'] ?? data['giaoVienId'];

      if (role == 'teacher' && foundTeacherId == null) {
        if (accountId != null) {
          final q = await FirebaseFirestore.instance.collection('teachers').where('accountId', isEqualTo: accountId).limit(1).get();
          if (q.docs.isNotEmpty) foundTeacherId = q.docs.first.data()['giaoVienId'] ?? q.docs.first.data()['teacherId'];
        }
        if (foundTeacherId == null && user!.email != null) {
          final qEmail = await FirebaseFirestore.instance.collection('teachers').where('email', isEqualTo: user!.email).limit(1).get();
          if (qEmail.docs.isNotEmpty) foundTeacherId = qEmail.docs.first.data()['giaoVienId'] ?? qEmail.docs.first.data()['teacherId'];
        }
      }
      final finalId = foundTeacherId ?? user!.uid;
      if (mounted) {
        setState(() {
          _isTeacher = role == 'teacher';
          _teacherAccountId = finalId;
          _isLoadingRole = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRole = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRole) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Tính toán ngày hiển thị cho Header
    final String weekRange = "${DateFormat('dd/MM').format(_startOfWeek)} - ${DateFormat('dd/MM').format(_startOfWeek.add(const Duration(days: 6)))}";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const SizedBox(), // Ẩn nút back mặc định
        centerTitle: true,
        // TIÊU ĐỀ: Gồm nút điều hướng tuần
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.black),
              onPressed: () => _changeWeek(-1), // Lùi 1 tuần
            ),
            Text(weekRange, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.black),
              onPressed: () => _changeWeek(1), // Tiến 1 tuần
            ),
          ],
        ),
        // TAB BAR: Hiển thị Thứ + Ngày
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF7553F6),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF7553F6),
          // Tạo Tab động dựa trên _startOfWeek
          tabs: List.generate(7, (index) {
            DateTime date = _startOfWeek.add(Duration(days: index));
            // Kiểm tra xem có phải "Hôm nay" không để đổi màu cho nổi bật
            bool isToday = DateUtils.isSameDay(date, DateTime.now());

            return Tab(
              height: 70,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_dayLabels[index], style: TextStyle(fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
                  const SizedBox(height: 4),
                  Text(
                      DateFormat('dd').format(date),
                      style: TextStyle(fontSize: 12, color: isToday ? const Color(0xFF7553F6) : Colors.grey)
                  ),
                ],
              ),
            );
          }),
        ),
      ),

      // BODY: Hiển thị danh sách buổi học
      body: TabBarView(
        controller: _tabController,
        // Tạo 7 trang, mỗi trang truyền vào đúng ngày cụ thể
        children: List.generate(7, (index) {
          DateTime date = _startOfWeek.add(Duration(days: index));
          return _buildScheduleListForDate(date);
        }),
      ),

      // NÚT TẠO LỊCH (BÊN TRÁI)
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: _isTeacher
          ? Padding(
        padding: const EdgeInsets.only(bottom: 100.0),
        child: FloatingActionButton.extended(
          onPressed: _showClassPickerForSchedule,
          backgroundColor: const Color(0xFF5B8DEF),
          icon: const Icon(Icons.add),
          label: const Text("Tạo lịch"),
        ),
      )
          : null,
    );
  }

  // --- LOGIC HIỂN THỊ DANH SÁCH LỊCH (CÓ CHECK TRÙNG LỊCH) ---
  Widget _buildScheduleListForDate(DateTime targetDate) {
    if (user == null) return const Center(child: Text("Vui lòng đăng nhập"));

    return FutureBuilder<List<String>>(
      future: _getClassIds(),
      builder: (context, snapshotClassIds) {
        if (snapshotClassIds.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final classIds = snapshotClassIds.data ?? [];
        if (classIds.isEmpty) return _buildEmptyState("Chưa tham gia lớp nào");

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchLessonsForSpecificDate(classIds, targetDate),
          builder: (context, snapshotLessons) {
            if (snapshotLessons.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final lessons = snapshotLessons.data ?? [];
            if (lessons.isEmpty) {
              return _buildEmptyState("Trống lịch");
            }

            // 1. Sắp xếp theo giờ bắt đầu
            lessons.sort((a, b) => (a['startTime'] as String).compareTo(b['startTime']));

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final data = lessons[index];

                // --- 2. LOGIC KIỂM TRA TRÙNG LỊCH ---
                bool isConflict = false;

                // Lấy phút bắt đầu và kết thúc của bài hiện tại
                int currentStart = _parseTime(data['startTime']);
                int currentEnd = _parseTime(data['endTime']);

                // So sánh với các bài khác trong list
                for (int i = 0; i < lessons.length; i++) {
                  if (i == index) continue; // Bỏ qua chính nó

                  int otherStart = _parseTime(lessons[i]['startTime']);
                  int otherEnd = _parseTime(lessons[i]['endTime']);

                  // Công thức trùng nhau: (StartA < EndB) && (StartB < EndA)
                  if (currentStart < otherEnd && otherStart < currentEnd) {
                    isConflict = true;
                    break;
                  }
                }
                // -------------------------------------

                // Nếu trùng thì màu đỏ, không thì random màu
                final List<Color> colors = [Colors.blue, Colors.orange, Colors.green, Colors.purple];
                final color = isConflict ? Colors.red : colors[index % colors.length];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.1), offset: const Offset(0, 4), blurRadius: 10)
                    ],
                    border: Border(left: BorderSide(color: color, width: 6)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            data['topic'] ?? "Buổi học",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        // Nếu trùng thì hiện icon cảnh báo
                        if (isConflict)
                          const Tooltip(
                            message: "Trùng lịch học!",
                            child: Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 16, color: color),
                            const SizedBox(width: 6),
                            Text(
                              "${data['startTime']} - ${data['endTime']}",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isConflict ? Colors.red : Colors.grey[700]
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (data['className'] != null)
                          Text("Lớp: ${data['className']}", style: const TextStyle(fontSize: 12)),

                        if (isConflict)
                          const Text(
                            "⚠ Đang bị trùng giờ!",
                            style: TextStyle(color: Colors.red, fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Hàm phụ: Đổi giờ "09:30" thành số phút (9*60 + 30 = 570) để so sánh
  int _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } catch (e) {
      return 0;
    }
  }

  // Helper: Fetch IDs lớp học
  Future<List<String>> _getClassIds() async {
    List<String> ids = [];
    if (user == null) return ids;

    if (_isTeacher) {
      final teacherId = _teacherAccountId ?? user!.uid;
      final teacherIdQuery = await FirebaseFirestore.instance.collection('classes').where('teacherId', isEqualTo: teacherId).get();
      ids = teacherIdQuery.docs.map((e) => e.id).toList();
    } else {
      final enrolledQuery = await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('enrolledClasses').get();
      ids = enrolledQuery.docs.map((e) => e.id).toList();
    }
    return ids;
  }

  // --- QUERY CHÍNH XÁC NGÀY ---
  Future<List<Map<String, dynamic>>> _fetchLessonsForSpecificDate(List<String> classIds, DateTime date) async {
    List<Map<String, dynamic>> allLessons = [];

    // Tạo Timestamp cho 00:00:00 ngày hôm đó (để khớp với lúc tạo lịch)
    DateTime midnight = DateTime(date.year, date.month, date.day);
    Timestamp queryTs = Timestamp.fromDate(midnight);

    for (String classId in classIds) {
      final query = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('lessons')
          .where('date', isEqualTo: queryTs) // Chỉ lấy đúng ngày này
          .get();

      for (var doc in query.docs) {
        final data = doc.data();
        data['classId'] = classId;
        allLessons.add(data);
      }
    }
    return allLessons;
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 50, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(msg, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        ],
      ),
    );
  }

  // Modal chọn lớp (Giữ nguyên)
  Future<void> _showClassPickerForSchedule() async {
    if (!_isTeacher || user == null) return;
    final teacherId = _teacherAccountId ?? user!.uid;
    final classesSnapshot = await FirebaseFirestore.instance.collection('classes').where('teacherId', isEqualTo: teacherId).get();

    if (!mounted) return;
    if (classesSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bạn chưa có lớp để tạo lịch")));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1E6F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                const ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(0xFFEEF2FF),
                    child: Icon(Icons.event_available, color: Color(0xFF5B8DEF)),
                  ),
                  title: Text("Chọn lớp để tạo lịch", style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text("Danh sách lớp bạn đang dạy", style: TextStyle(color: Color(0xFF6A7280))),
                ),
                ...classesSnapshot.docs.map((doc) {
                  final data = doc.data();
                  final className = (data['className'] ?? 'Lớp chưa đặt tên').toString();
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFEEF2FF),
                      child: const Icon(Icons.class_rounded, color: Color(0xFF5B8DEF)),
                    ),
                    title: Text(className, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text("ID: ${doc.id}", style: const TextStyle(color: Color(0xFF6A7280))),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF9AA3B1)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateScheduleScreen(
                            classId: doc.id,
                            className: className,
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}
