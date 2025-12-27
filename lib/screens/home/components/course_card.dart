import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:baocaocuoiky/screens/home/class/class_management_screen.dart';


class CourseCard extends StatefulWidget {
  const CourseCard({
    super.key,
    required this.classId,
    this.color = const Color(0xFF2563EB),
    this.iconSrc = "assets/icons/ios.svg",
  });

  final String classId;
  final Color color;
  final String iconSrc;

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation =
        Tween<double>(begin: 1.0, end: 1.05).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _animationController.forward(),
      onExit: (_) => _animationController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        // Dùng Future.wait để lấy cả thông tin lớp VÀ đếm số bài tập cùng lúc
        child: FutureBuilder<List<dynamic>>(
          future: Future.wait([
            // 1. Lấy thông tin lớp học
            FirebaseFirestore.instance.collection('classes').doc(widget.classId).get(),
            // 2. Đếm số lượng bài tập (type == 'assignment')
            FirebaseFirestore.instance
                .collection('classes')
                .doc(widget.classId)
                .collection('posts')
                .where('type', isEqualTo: 'assignment')
                .get(), // Lấy snapshot để đếm size
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingCard();
            }

            // Kiểm tra lỗi hoặc không có dữ liệu
            if (!snapshot.hasData || (snapshot.data![0] as DocumentSnapshot).exists == false) {
              return _buildErrorCard();
            }

            // Lấy dữ liệu từ kết quả Future.wait
            final classDoc = snapshot.data![0] as DocumentSnapshot;
            final postSnapshot = snapshot.data![1] as QuerySnapshot;

            final classData = classDoc.data() as Map<String, dynamic>;

            // --- LẤY DỮ LIỆU THỰC TẾ ---
            final className = classData['className'] ?? 'Chưa có tên';
            final description = classData['khoaHoc'] ?? 'Khóa học';
            final namHoc = classData['namHoc'] ?? '';
            final teacherName = classData['teacherName'] ?? 'Giáo viên';

            // 1. Lấy số thành viên thực tế
            final memberCount = classData['memberCount'] ?? 0;

            // 2. Lấy số bài tập thực tế (đếm từ collection posts)
            final int lessons = postSnapshot.size;

            // Tính thời lượng ước tính (ví dụ: mỗi bài 45 phút)
            String duration = '${(lessons * 0.75).ceil()} giờ';
            if (lessons == 0) duration = "0 giờ";

            return GestureDetector(
              onTap: () => _navigateToDetail(context, widget.classId, className),
              child: _buildCard(
                context,
                title: className,
                description: description,
                instructor: teacherName,
                students: memberCount, // Hiển thị số thành viên thật
                duration: duration,
                lessons: lessons,      // Hiển thị số bài tập thật
                namHoc: namHoc,
              ),
            );
          },
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, String id, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassroomScreen(
          classId: id,
          className: name,
        ),
      ),
    );
  }

  Widget _buildCard(
      BuildContext context, {
        required String title,
        required String description,
        required String instructor,
        required int students,
        required String duration,
        required int lessons,
        required String namHoc,
      }) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 360,
      width: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.color,
            widget.color.withOpacity(0.75),
          ],
        ),
        borderRadius: const BorderRadius.all(Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: widget.color.withOpacity(0.3),
            offset: const Offset(0, 8),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: widget.iconSrc.endsWith('.svg')
                    ? SvgPicture.asset(
                  widget.iconSrc,
                  width: 28,
                  height: 28,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                )
                    : const Icon(Icons.school, size: 28, color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "LỚP HỌC",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            namHoc.isNotEmpty ? '$description • $namHoc' : description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Spacer(),

          // Instructor
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(Icons.person, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Giáo viên",
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    Text(
                      instructor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stats (Số liệu thực tế)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(icon: Icons.assignment, label: "Bài tập", value: "$lessons"),
                Container(width: 1, height: 30, color: Colors.white.withOpacity(0.2)),
                _buildStatItem(icon: Icons.people, label: "Học sinh", value: "$students"),
                Container(width: 1, height: 30, color: Colors.white.withOpacity(0.2)),
                _buildStatItem(icon: Icons.access_time, label: "Thời lượng", value: duration),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Nút Xem chi tiết (Full width)
          SizedBox(
            width: double.infinity,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  "Truy cập lớp học",
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 360,
      width: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [widget.color, widget.color.withOpacity(0.75)],
        ),
        borderRadius: const BorderRadius.all(Radius.circular(28)),
      ),
      child: const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 360,
      width: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey, Colors.grey.withOpacity(0.8)], // Màu xám khi lỗi
        ),
        borderRadius: const BorderRadius.all(Radius.circular(28)),
      ),
      child: const Center(
        child: Text("Không tìm thấy dữ liệu", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9), // Tăng độ rõ
        ),
      ],
    );
  }
}