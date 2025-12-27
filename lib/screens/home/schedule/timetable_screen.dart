import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({Key? key}) : super(key: key);

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final User? user = FirebaseAuth.instance.currentUser;

  // Thứ trong tuần: 2, 3, 4, 5, 6, 7, 8(CN)
  final List<int> _weekDays = [1, 2, 3, 4, 5, 6, 7];
  final List<String> _dayLabels = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"];

  @override
  void initState() {
    super.initState();
    // Tự động chọn tab là ngày hôm nay
    int initialIndex = DateTime.now().weekday - 1;
    _tabController = TabController(length: 7, vsync: this, initialIndex: initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        title: const Text("Thời Khóa Biểu", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF7553F6),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF7553F6),
          tabs: _dayLabels.map((day) => Tab(text: day)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _weekDays.map((day) => _buildScheduleList(day)).toList(),
      ),
    );
  }

  // Hàm tải danh sách buổi học theo Thứ
  Widget _buildScheduleList(int weekday) {
    if (user == null) return const Center(child: Text("Vui lòng đăng nhập"));

    return FutureBuilder<List<String>>(
      // Bước 1: Lấy danh sách ID lớp học của user
      future: _getClassIds(),
      builder: (context, snapshotClassIds) {
        if (snapshotClassIds.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final classIds = snapshotClassIds.data ?? [];
        if (classIds.isEmpty) {
          return _buildEmptyState("Bạn chưa có lớp học nào");
        }

        // Bước 2: Query các buổi học của những lớp đó trong ngày này
        // Lưu ý: Đây là query phức tạp, ta dùng StreamBuilder lồng nhau hoặc Future.wait
        // Để đơn giản và hiệu quả, ta sẽ query lessons của từng lớp
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchLessonsForDay(classIds, weekday),
          builder: (context, snapshotLessons) {
            if (snapshotLessons.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final lessons = snapshotLessons.data ?? [];
            if (lessons.isEmpty) {
              return _buildEmptyState("Hôm nay không có lịch học");
            }

            // Sắp xếp theo giờ học
            lessons.sort((a, b) => (a['startTime'] as String).compareTo(b['startTime']));

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final data = lessons[index];
                // Random màu thẻ cho đẹp
                final List<Color> colors = [Colors.blue, Colors.orange, Colors.green, Colors.purple, Colors.redAccent];
                final color = colors[index % colors.length];

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
                    title: Text(
                      data['topic'] ?? "Buổi học",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.class_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            // Nếu bạn đã lưu className vào lesson thì hiển thị, nếu không thì cần query thêm
                            Text("Lớp học (ID: ...${data['classId'].toString().substring(0,4)})"),
                          ],
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

  // Helper: Lấy danh sách ID lớp
  Future<List<String>> _getClassIds() async {
    List<String> ids = [];

    // Kiểm tra role trong bảng users trước
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    final role = userDoc.data()?['role'] ?? 'student';

    if (role == 'teacher') {
      // Nếu là GV: Lấy từ bảng classes
      // Cần chắc chắn teacherId đúng (như bạn đã fix ở Home)
      final teacherIdQuery = await FirebaseFirestore.instance
          .collection('classes')
          .where('teacherId', isEqualTo: userDoc.data()?['teacherId'] ?? userDoc.data()?['giaoVienId'] ?? user!.uid)
          .get();
      ids = teacherIdQuery.docs.map((e) => e.id).toList();
    } else {
      // Nếu là SV: Lấy từ sub-collection enrolledClasses
      final enrolledQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('enrolledClasses')
          .get();
      ids = enrolledQuery.docs.map((e) => e.id).toList();
    }
    return ids;
  }

  // Helper: Lấy lessons của danh sách lớp trong ngày cụ thể
  Future<List<Map<String, dynamic>>> _fetchLessonsForDay(List<String> classIds, int weekday) async {
    List<Map<String, dynamic>> allLessons = [];

    // Ngày hiện tại để lọc các buổi học trong tương lai gần (hoặc trong khoảng khóa học)
    // Ở đây ta lọc đơn giản: Lấy các lesson có dayOfWeek == weekday
    // VÀ date >= hôm nay (để không hiện lịch quá khứ, tùy bạn)

    DateTime now = DateTime.now();
    DateTime todayMidnight = DateTime(now.year, now.month, now.day);

    for (String classId in classIds) {
      final query = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('lessons')
      // Chỉ lấy những buổi có ngày trong tuần khớp
      // Lưu ý: Bạn cần lưu trường 'dayOfWeek' (int) khi tạo lịch (trong CreateScheduleScreen)
      // Nếu chưa lưu thì phải tải về rồi lọc (hơi chậm) -> Tốt nhất nên lưu.
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayMidnight)) // Lấy từ hôm nay trở đi
          .get();

      for (var doc in query.docs) {
        final data = doc.data();
        DateTime date = (data['date'] as Timestamp).toDate();

        // Lọc đúng thứ (Vì Firestore không hỗ trợ where dayOfWeek kết hợp range date dễ dàng)
        if (date.weekday == weekday) {
          data['classId'] = classId; // Gắn thêm ID lớp để biết môn gì
          allLessons.add(data);
        }
      }
    }
    return allLessons;
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(msg, style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        ],
      ),
    );
  }
}