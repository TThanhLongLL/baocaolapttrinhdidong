import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 🎨 Màu sắc hiện đại
  final Color primaryColor = const Color(0xFF2563EB); // Xanh dương
  final Color accentColor = const Color(0xFF10B981); // Xanh lá
  final Color bgColor = const Color(0xFFF0F9FF); // Nền xanh nhạt
  final Color cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: primaryColor,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: accentColor,
              indicatorWeight: 4,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.class_, size: 24), text: "Lớp học"),
                Tab(icon: Icon(Icons.people, size: 24), text: "Học sinh"),
                Tab(icon: Icon(Icons.school, size: 24), text: "Giáo viên"),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildManagementTab(
            collectionName: 'classes',
            titleField: 'className',
            subtitleField: 'description',
            icon: Icons.class_,
            color: const Color(0xFF3B82F6),
          ),
          _buildManagementTab(
            collectionName: 'students',
            titleField: 'fullName',
            subtitleField: 'studentId',
            icon: Icons.person,
            color: const Color(0xFF8B5CF6),
          ),
          _buildManagementTab(
            collectionName: 'teachers',
            titleField: 'fullName',
            subtitleField: 'subject',
            icon: Icons.school,
            color: const Color(0xFFF59E0B),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showFormDialog(context, _tabController.index, null);
        },
        backgroundColor: accentColor,
        elevation: 4,
        icon: const Icon(Icons.add, size: 28),
        label: const Text(
          "Thêm mới",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }

  // Widget hiển thị danh sách
  Widget _buildManagementTab({
    required String collectionName,
    required String titleField,
    required String subtitleField,
    required IconData icon,
    required Color color,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collectionName)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Lỗi: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: primaryColor),
          );
        }

        final data = snapshot.data?.docs ?? [];

        if (data.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 60, color: color),
                ),
                const SizedBox(height: 16),
                Text(
                  "Chưa có dữ liệu",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16).copyWith(bottom: 100),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final doc = data[index];
            final item = doc.data() as Map<String, dynamic>;
            final title = item[titleField] ?? 'Không tên';
            final subtitle = item[subtitleField] ?? '---';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.08),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showFormDialog(context, _tabController.index, doc),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.edit, size: 18, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Chỉnh sửa'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Xóa'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showFormDialog(context, _tabController.index, doc);
                        } else if (value == 'delete') {
                          _confirmDelete(context, collectionName, doc.id);
                        }
                      },
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFormDialog(BuildContext context, int tabIndex, DocumentSnapshot? doc) {
    bool isEditing = doc != null;
    String collection = '';
    String label1 = '';
    String label2 = '';
    String field1 = '';
    String field2 = '';
    IconData iconDialog = Icons.add_circle_outline;
    Color dialogColor = primaryColor;

    if (tabIndex == 0) {
      collection = 'classes';
      label1 = 'Tên lớp (VD: 12A1)';
      field1 = 'className';
      label2 = 'Mô tả / Phòng học';
      field2 = 'description';
      iconDialog = Icons.class_;
      dialogColor = const Color(0xFF3B82F6);
    } else if (tabIndex == 1) {
      collection = 'students';
      label1 = 'Họ tên học sinh';
      field1 = 'fullName';
      label2 = 'Mã học sinh / Email';
      field2 = 'studentId';
      iconDialog = Icons.person_add;
      dialogColor = const Color(0xFF8B5CF6);
    } else {
      collection = 'teachers';
      label1 = 'Họ tên giáo viên';
      field1 = 'fullName';
      label2 = 'Môn dạy';
      field2 = 'subject';
      iconDialog = Icons.school;
      dialogColor = const Color(0xFFF59E0B);
    }

    final Map<String, dynamic>? data =
        isEditing ? doc.data() as Map<String, dynamic> : null;
    final controller1 = TextEditingController(text: data?[field1] ?? '');
    final controller2 = TextEditingController(text: data?[field2] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [dialogColor, dialogColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isEditing ? Icons.edit : iconDialog,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isEditing ? "Cập nhật thông tin" : "Thêm mới",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            _buildCustomTextField(controller1, label1, Icons.text_fields, dialogColor),
            const SizedBox(height: 16),
            _buildCustomTextField(controller2, label2, Icons.description, dialogColor),
            const SizedBox(height: 10),
          ],
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
            child: const Text(
              "Hủy bỏ",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              if (controller1.text.isEmpty) return;

              final mapData = {
                field1: controller1.text,
                field2: controller2.text,
                if (!isEditing) 'createdAt': FieldValue.serverTimestamp(),
              };

              if (isEditing) {
                await FirebaseFirestore.instance
                    .collection(collection)
                    .doc(doc.id)
                    .update(mapData);
              } else {
                await FirebaseFirestore.instance
                    .collection(collection)
                    .add(mapData);
              }
              if (context.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: dialogColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: Icon(isEditing ? Icons.save : Icons.add_circle),
            label: Text(
              isEditing ? "Lưu thay đổi" : "Thêm ngay",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String collection, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.red[600],
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Xác nhận xóa",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        content: const Text(
          "Bạn có chắc chắn muốn xóa mục này không?\nHành động này không thể hoàn tác.",
          style: TextStyle(color: Colors.black87, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text("Không", style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              FirebaseFirestore.instance
                  .collection(collection)
                  .doc(docId)
                  .delete();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("✓ Đã xóa thành công!"),
                  backgroundColor: Colors.red[600],
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text("Xóa", style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    Color color,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color.withOpacity(0.7), size: 20),
        filled: true,
        fillColor: color.withOpacity(0.05),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        labelStyle: TextStyle(color: color, fontWeight: FontWeight.w500),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color.withOpacity(0.3), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 2),
        ),
      ),
    );
  }
}