import 'package:flutter/material.dart';
// Các import model giữ nguyên theo cấu trúc của bạn
import 'model/class_management_screen.dart';
import 'model/student_management_screen.dart';
import 'model/teacher_management_screen.dart';
// Import service thông báo (kiểm tra lại đường dẫn nếu cần)
import 'package:baocaocuoiky/services/notification_service.dart';
import 'model/notification_management_screen.dart'; 
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // 🎨 Màu sắc hiện đại
  final Color primaryColor = const Color(0xFF2563EB); // Xanh dương
  final Color accentColor = const Color(0xFF10B981); // Xanh lá
  final Color bgColor = const Color(0xFFF0F9FF); // Nền xanh nhạt
  final Color cardColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "Quản Lý Hệ Thống",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Card Quản Lý Lớp Học
            _buildManagementCard(
              context,
              title: "Quản Lý Lớp Học",
              subtitle: "Thêm, sửa, xóa lớp học",
              icon: Icons.class_,
              color: const Color(0xFF3B82F6),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClassManagementScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Card Quản Lý Học Sinh
            _buildManagementCard(
              context,
              title: "Quản Lý Học Sinh",
              subtitle: "Thêm, sửa, xóa học sinh",
              icon: Icons.person,
              color: const Color(0xFF8B5CF6),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StudentManagementScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Card Quản Lý Giáo Viên
            _buildManagementCard(
              context,
              title: "Quản Lý Giáo Viên",
              subtitle: "Thêm, sửa, xóa giáo viên",
              icon: Icons.school,
              color: const Color(0xFFF59E0B),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TeacherManagementScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // --- [MỚI] Card Tạo Thông Báo ---
           _buildManagementCard(
              context,
              title: "Quản Lý Thông Báo", // Đổi tên
              subtitle: "Đăng tin tức, lịch thi, sự kiện",
              icon: Icons.campaign_rounded,
              color: const Color(0xFF16A34A), // Xanh lá
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationManagementScreen()),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[200]!, width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                offset: const Offset(0, 4),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }


  // --- WIDGETS HỖ TRỢ ---
  Widget _buildLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF9CA3AF),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, Color accentColor, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF374151)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Icon(icon, color: accentColor.withOpacity(0.8), size: 22),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}