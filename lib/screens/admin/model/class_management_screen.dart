import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({Key? key}) : super(key: key);

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  final Color primaryColor = const Color(0xFF3B82F6);
  final Color accentColor = const Color(0xFF10B981);
  final Color bgColor = const Color(0xFFF0F9FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "Quản Lý Lớp Học",
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
      body: _buildClassList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(context, null),
        backgroundColor: accentColor,
        elevation: 4,
        icon: const Icon(Icons.add, size: 28),
        label: const Text(
          "Thêm Lớp",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildClassList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
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

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.class_, size: 60, color: primaryColor),
                ),
                const SizedBox(height: 16),
                Text(
                  "Chưa có lớp học",
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
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final className = data['className'] ?? 'Không tên';
            final teacherName = data['teacherName'] ?? 'Chưa có GV'; // Hiện tên GV
            final memberCount = data['memberCount'] ?? 0;
            final maxMembers = data['maxMembers'] ?? 30;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.08),
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
                  onTap: () => _showFormDialog(context, doc),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.class_, color: primaryColor, size: 24),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            className,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column( // Sửa thành Column để hiện thêm tên GV
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "GVCN: $teacherName", // Hiển thị tên GV
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Thành viên: $memberCount/$maxMembers",
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                            ),
                          ),
                        ],
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
                          _showFormDialog(context, doc);
                        } else if (value == 'delete') {
                          _confirmDelete(context, doc.id);
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

  // --- HÀM QUAN TRỌNG ĐÃ SỬA ---
  void _showFormDialog(BuildContext context, DocumentSnapshot? doc) async {
    bool isEditing = doc != null;
    final data = isEditing ? doc.data() as Map<String, dynamic> : null;

    final controllerClassName = TextEditingController(text: data?['className'] ?? '');
    final controllerKhoaHoc = TextEditingController(text: data?['khoaHoc'] ?? '');
    final controllerClassCode = TextEditingController(text: data?['classCode'] ?? '');
    final controllerNamHoc = TextEditingController(text: data?['namHoc'] ?? '');
    final controllerMaxMembers = TextEditingController(text: (data?['maxMembers'] ?? 30).toString());
    
    // Biến để lưu Giáo viên được chọn
    String? selectedTeacherId = data?['teacherId'];
    String selectedTeacherName = data?['teacherName'] ?? '';

    DateTime dateStart = data != null && data['dateStart'] != null
        ? (data['dateStart'] as Timestamp).toDate()
        : DateTime.now();
    DateTime dateEnd = data != null && data['dateEnd'] != null
        ? (data['dateEnd'] as Timestamp).toDate()
        : DateTime.now().add(const Duration(days: 365));

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder( // Dùng StatefulBuilder để cập nhật Dropdown
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            titlePadding: EdgeInsets.zero,
            title: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                      isEditing ? Icons.edit : Icons.class_,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? "Cập nhật lớp học" : "Thêm lớp học mới",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  _buildTextField(controllerClassName, "Tên lớp (VD: 12A1)", Icons.text_fields),
                  const SizedBox(height: 12),
                  _buildTextField(controllerKhoaHoc, "Khóa học (VD: Tin học)", Icons.school),
                  const SizedBox(height: 12),
                  _buildTextField(controllerClassCode, "Mã lớp (VD: TC-2024-001)", Icons.code),
                  
                  // --- DROPDOWN CHỌN GIÁO VIÊN ---
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('teachers').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      // Tạo danh sách items cho Dropdown
                      List<DropdownMenuItem<String>> teacherItems = [];
                      for (var doc in snapshot.data!.docs) {
                        var teacherData = doc.data() as Map<String, dynamic>;
                        // Dùng giaoVienId (hoặc accountId) làm value, hoTen làm label hiển thị
                        // Dựa vào ảnh bạn gửi: field là 'giaoVienId' và 'hoTen'
                        String tId = teacherData['giaoVienId'] ?? doc.id; 
                        String tName = teacherData['hoTen'] ?? 'Không tên';
                        
                        teacherItems.add(
                          DropdownMenuItem(
                            value: tId,
                            child: Text(tName, overflow: TextOverflow.ellipsis),
                          )
                        );
                      }

                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: "Giáo viên chủ nhiệm",
                          prefixIcon: Icon(Icons.person, color: primaryColor.withOpacity(0.7), size: 20),
                          filled: true,
                          fillColor: primaryColor.withOpacity(0.05),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: primaryColor.withOpacity(0.3), width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: primaryColor, width: 2),
                          ),
                        ),
                        isExpanded: true,
                        value: selectedTeacherId,
                        items: teacherItems,
                        onChanged: (val) {
                          setState(() {
                            selectedTeacherId = val;
                            // Tìm tên giáo viên tương ứng để lưu
                            var selectedDoc = snapshot.data!.docs.firstWhere(
                              (d) => (d.data() as Map<String, dynamic>)['giaoVienId'] == val,
                            );
                            selectedTeacherName = (selectedDoc.data() as Map<String, dynamic>)['hoTen'];
                          });
                        },
                        hint: const Text("Chọn giáo viên"),
                      );
                    }
                  ),
                  // -------------------------------
                  
                  const SizedBox(height: 12),
                  _buildTextField(controllerNamHoc, "Năm học (VD: 2024-2025)", Icons.calendar_today),
                  const SizedBox(height: 12),
                  _buildTextField(controllerMaxMembers, "Số lượng tối đa", Icons.people),
                  const SizedBox(height: 12),
                  // Date Start
                  _buildDatePickerField(
                    "Ngày bắt đầu",
                    dateStart,
                    (newDate) {
                      setState(() {
                        dateStart = newDate;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  // Date End
                  _buildDatePickerField(
                    "Ngày kết thúc",
                    dateEnd,
                    (newDate) {
                      setState(() {
                        dateEnd = newDate;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.all(16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
                child: const Text("Hủy bỏ", style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  if (controllerClassName.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Vui lòng nhập tên lớp")),
                    );
                    return;
                  }
                  
                  // Kiểm tra xem đã chọn giáo viên chưa
                  if (selectedTeacherId == null) {
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Vui lòng chọn giáo viên")),
                    );
                    return;
                  }

                  final mapData = {
                    'className': controllerClassName.text,
                    'khoaHoc': controllerKhoaHoc.text,
                    'classCode': controllerClassCode.text,
                    'namHoc': controllerNamHoc.text,
                    'dateStart': Timestamp.fromDate(dateStart),
                    'dateEnd': Timestamp.fromDate(dateEnd),
                    // Lưu ID và Tên giáo viên đã chọn từ Dropdown
                    'teacherId': selectedTeacherId, 
                    'teacherName': selectedTeacherName,
                    // -------------------------------------------
                    'maxMembers': int.tryParse(controllerMaxMembers.text) ?? 30,
                    if (!isEditing) 'memberCount': 0,
                    if (!isEditing) 'lopId': DateTime.now().millisecondsSinceEpoch.toString(),
                    if (!isEditing) 'createdAt': FieldValue.serverTimestamp(),
                  };

                  if (isEditing) {
                    await FirebaseFirestore.instance
                        .collection('classes')
                        .doc(doc!.id)
                        .update(mapData);
                  } else {
                    await FirebaseFirestore.instance
                        .collection('classes')
                        .add(mapData);
                  }
                  if (context.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: Icon(isEditing ? Icons.save : Icons.add_circle),
                label: Text(
                  isEditing ? "Lưu thay đổi" : "Thêm ngay",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.7), size: 20),
        filled: true,
        fillColor: primaryColor.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        labelStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.w500),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.3), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildDatePickerField(
    String label,
    DateTime selectedDate,
    Function(DateTime) onDateChanged,
  ) {
    return GestureDetector(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (pickedDate != null) {
          onDateChanged(pickedDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primaryColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "$label: ${selectedDate.toLocal().toString().split(' ')[0]}",
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(Icons.calendar_today, color: primaryColor.withOpacity(0.7), size: 18),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.red[600],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Xác nhận xóa",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        content: const Text(
          "Bạn có chắc chắn muốn xóa lớp học này không?\nHành động này không thể hoàn tác.",
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
              FirebaseFirestore.instance.collection('classes').doc(docId).delete();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("✓ Đã xóa lớp học thành công!"),
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
}