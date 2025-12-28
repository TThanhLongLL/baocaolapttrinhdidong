import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({Key? key}) : super(key: key);

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final Color primaryColor = const Color(0xFF8B5CF6);
  final Color accentColor = const Color(0xFF10B981);
  final Color bgColor = const Color(0xFFF0F9FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "Quản Lý Học Sinh",
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
      body: _buildStudentList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(context, null),
        backgroundColor: accentColor,
        elevation: 4,
        icon: const Icon(Icons.add, size: 28),
        label: const Text(
          "Thêm Học Sinh",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
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
                  child: Icon(Icons.person, size: 60, color: primaryColor),
                ),
                const SizedBox(height: 16),
                Text(
                  "Chưa có học sinh",
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
            final student = Student.fromFirestore(doc);

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
                      child: Icon(Icons.person, color: primaryColor, size: 24),
                    ),
                    title: Text(
                      student.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        "${student.maHocSinh} • Lớp: ${student.className ?? '---'} • Sinh: ${student.ngaySinh != null ? student.ngaySinh.toString().split(' ')[0] : '---'}",
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

  void _showFormDialog(BuildContext context, DocumentSnapshot? doc) async {
  bool isEditing = doc != null;
  late Student student;
  
  if (isEditing) {
    student = Student.fromFirestore(doc!);
  } else {
    student = Student(
      hocSinhId: '',
      fullName: '',
      maHocSinh: '',
      email: '',
    );
  }

  final controllerFullName = TextEditingController(text: student.fullName);
  final controllerMaHocSinh = TextEditingController(text: student.maHocSinh);
  final controllerEmail = TextEditingController(text: student.email);

  String? selectedGioiTinh = student.gioiTinh;
  DateTime? ngaySinh = student.ngaySinh;
  String? accountId = student.accountId;  // ✅ Thêm dòng này

  List<String> classList = [];
  String? selectedClass = student.className;
  String? selectedLopId = student.lopId;

  var snapshot = await FirebaseFirestore.instance.collection('classes').get();
  classList = snapshot.docs
      .where((d) => d.data()['className'] != null && d.data()['className'].toString().isNotEmpty)
      .map((d) => d.data()['className'] as String)
      .toList();

  if (!context.mounted) return;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isEditing ? Icons.edit : Icons.person_add,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEditing ? "Cập nhật học sinh" : "Thêm học sinh mới",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTextField(controllerFullName, "Họ tên học sinh", Icons.text_fields),
                      const SizedBox(height: 12),
                      _buildTextField(controllerMaHocSinh, "Mã học sinh", Icons.badge),
                      const SizedBox(height: 12),
                      _buildTextField(controllerEmail, "Email (liên kết tài khoản)", Icons.email),
                      const SizedBox(height: 12),
                      // ✅ Hiển thị accountId nếu đã liên kết
                      if (accountId != null && accountId!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: accentColor, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Tài khoản: $accountId",
                                  style: TextStyle(
                                    color: accentColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Ngày sinh
                      _buildDatePickerField(
                        "Ngày sinh",
                        ngaySinh,
                        (newDate) {
                          setState(() {
                            ngaySinh = newDate;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      // Giới tính
                      DropdownButtonFormField<String>(
                        value: selectedGioiTinh,
                        decoration: InputDecoration(
                          labelText: 'Giới tính',
                          prefixIcon: Icon(Icons.wc, color: primaryColor.withOpacity(0.7)),
                          filled: true,
                          fillColor: primaryColor.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                          DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                          DropdownMenuItem(value: 'Khác', child: Text('Khác')),
                        ],
                        onChanged: (val) {
                          setState(() {
                            selectedGioiTinh = val;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      // Chọn lớp
                      DropdownButtonFormField<String>(
                        value: selectedClass,
                        decoration: InputDecoration(
                          labelText: 'Chọn lớp học',
                          prefixIcon: Icon(Icons.class_, color: primaryColor.withOpacity(0.7)),
                          filled: true,
                          fillColor: primaryColor.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: classList.map((className) {
                          return DropdownMenuItem(
                            value: className,
                            child: Text(className),
                          );
                        }).toList(),
                        onChanged: (val) async {
                          setState(() {
                            selectedClass = val;
                          });
                          
                          // Lấy lopId từ className
                          if (val != null) {
                            final classDoc = await FirebaseFirestore.instance
                                .collection('classes')
                                .where('className', isEqualTo: val)
                                .limit(1)
                                .get();
                            if (classDoc.docs.isNotEmpty) {
                              setState(() {
                                selectedLopId = classDoc.docs.first.id;
                              });
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                // Actions
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
                        child: const Text("Hủy bỏ", style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (controllerFullName.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Vui lòng nhập tên học sinh")),
                            );
                            return;
                          }

                          // ✅ Lấy accountId từ email
                          if (controllerEmail.text.isNotEmpty && !isEditing) {
                            final userSnapshot = await FirebaseFirestore.instance
                                .collection('users')
                                .where('email', isEqualTo: controllerEmail.text.trim())
                                .limit(1)
                                .get();

                            if (userSnapshot.docs.isEmpty) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Email không tìm thấy trong hệ thống")),
                                );
                              }
                              return;
                            }

                            // ✅ Lưu accountId
                            accountId = userSnapshot.docs.first['accountId'];
                            setState(() {});
                          }

                          final newStudent = Student(
                            hocSinhId: isEditing ? student.hocSinhId : DateTime.now().millisecondsSinceEpoch.toString(),
                            fullName: controllerFullName.text,
                            maHocSinh: controllerMaHocSinh.text,
                            email: controllerEmail.text,
                            accountId: accountId,  // ✅ Truyền accountId
                            ngaySinh: ngaySinh,
                            gioiTinh: selectedGioiTinh,
                            className: selectedClass,
                            lopId: selectedLopId,
                            createdAt: isEditing ? student.createdAt : DateTime.now(),
                          );

                          if (isEditing) {
                            await FirebaseFirestore.instance
                                .collection('students')
                                .doc(doc!.id)
                                .update(newStudent.toFirestore());
                          } else {
                            await FirebaseFirestore.instance
                                .collection('students')
                                .add(newStudent.toFirestore());

                            // Tăng memberCount khi thêm học sinh mới
                            if (selectedLopId != null) {
                              final classDoc = await FirebaseFirestore.instance
                                  .collection('classes')
                                  .doc(selectedLopId)
                                  .get();
                              if (classDoc.exists) {
                                final currentCount = classDoc['memberCount'] ?? 0;
                                await FirebaseFirestore.instance
                                    .collection('classes')
                                    .doc(selectedLopId)
                                    .update({'memberCount': currentCount + 1});
                              }
                            }
                          }
                          if (context.mounted) Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: Icon(isEditing ? Icons.save : Icons.add_circle),
                        label: Text(
                          isEditing ? "Lưu thay đổi" : "Thêm ngay",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
      enabled: true,
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
    DateTime? selectedDate,
    Function(DateTime) onDateChanged,
  ) {
    return GestureDetector(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(1990),
          lastDate: DateTime.now(),
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
              selectedDate == null
                  ? label
                  : "$label: ${selectedDate.toLocal().toString().split(' ')[0]}",
              style: TextStyle(
                color: selectedDate == null ? Colors.grey[600] : Colors.black87,
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
          "Bạn có chắc chắn muốn xóa học sinh này không?\nHành động này không thể hoàn tác.",
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
            onPressed: () async {
              // Lấy thông tin học sinh trước khi xóa để giảm memberCount
              final studentDoc = await FirebaseFirestore.instance
                  .collection('students')
                  .doc(docId)
                  .get();
              
              if (studentDoc.exists) {
                final student = Student.fromFirestore(studentDoc);
                if (student.lopId != null) {
                  final classDoc = await FirebaseFirestore.instance
                      .collection('classes')
                      .doc(student.lopId)
                      .get();
                  if (classDoc.exists) {
                    final currentCount = classDoc['memberCount'] ?? 0;
                    if (currentCount > 0) {
                      await FirebaseFirestore.instance
                          .collection('classes')
                          .doc(student.lopId)
                          .update({'memberCount': currentCount - 1});
                    }
                  }
                }
              }

              await FirebaseFirestore.instance
                  .collection('students')
                  .doc(docId)
                  .delete();
              
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("✓ Đã xóa học sinh thành công!"),
                    backgroundColor: Colors.red[600],
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text("Xóa", style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}