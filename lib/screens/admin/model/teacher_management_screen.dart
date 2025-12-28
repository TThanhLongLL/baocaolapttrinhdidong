import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'teacher.dart';

class TeacherManagementScreen extends StatefulWidget {
  const TeacherManagementScreen({Key? key}) : super(key: key);

  @override
  State<TeacherManagementScreen> createState() => _TeacherManagementScreenState();
}

class _TeacherManagementScreenState extends State<TeacherManagementScreen> {
  final Color primaryColor = const Color(0xFFF59E0B);
  final Color accentColor = const Color(0xFF10B981);
  final Color bgColor = const Color(0xFFF0F9FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "Quản Lý Giáo Viên",
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
      body: _buildTeacherList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(context, null),
        backgroundColor: accentColor,
        elevation: 4,
        icon: const Icon(Icons.add, size: 28),
        label: const Text(
          "Thêm Giáo Viên",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildTeacherList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teachers')
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
                  child: Icon(Icons.school, size: 60, color: primaryColor),
                ),
                const SizedBox(height: 16),
                Text(
                  "Chưa có giáo viên",
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
            final teacher = Teacher.fromFirestore(doc);

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
                      child: Icon(Icons.school, color: primaryColor, size: 24),
                    ),
                    title: Text(
                      teacher.hoTen,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        "${teacher.maGiaoVien} • ${teacher.boMonId ?? '---'} • Dạy: ${teacher.lopDangDay.join(', ').isEmpty ? '---' : teacher.lopDangDay.join(', ')}",
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
  late Teacher teacher;

  if (isEditing) {
    teacher = Teacher.fromFirestore(doc!);
  } else {
    teacher = Teacher(
      giaoVienId: '',
      maGiaoVien: '',
      hoTen: '',
    );
  }

  final controllerMaGiaoVien = TextEditingController(text: teacher.maGiaoVien);
  final controllerHoTen = TextEditingController(text: teacher.hoTen);
  final controllerEmail = TextEditingController(text: teacher.accountId ?? ''); // ✅ Email thay vì accountId
  String? currentAccountId = isEditing ? teacher.accountId : null;

  String? selectedGioiTinh = teacher.gioiTinh;
  DateTime? ngaySinh = teacher.ngaySinh;
  String? selectedBoMon = teacher.boMonId;
  List<String> selectedLopDangDay = List.from(teacher.lopDangDay);
  
  // Lấy danh sách lớp
List<String> classList = [];
  var classSnapshot = await FirebaseFirestore.instance.collection('classes').get();
  classList = classSnapshot.docs
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
                        isEditing ? "Cập nhật giáo viên" : "Thêm giáo viên mới",
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
                      _buildTextField(controllerHoTen, "Họ tên giáo viên", Icons.text_fields),
                      const SizedBox(height: 12),
                      _buildTextField(controllerMaGiaoVien, "Mã giáo viên", Icons.badge),
                      const SizedBox(height: 12),
                      _buildTextField(controllerEmail, "Email (liên kết Account ID)", Icons.email), // ✅ Email input
                      const SizedBox(height: 12),
                      _buildTextField(
                        TextEditingController(text: selectedBoMon ?? ''),
                        "Bộ môn",
                        Icons.library_books,
                        onChanged: (value) {
                          setState(() {
                            selectedBoMon = value.isEmpty ? null : value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 16),
                      // Danh sách lớp đang dạy
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Chọn lớp đang dạy:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: primaryColor.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: classList.length,
                          itemBuilder: (context, index) {
                            final className = classList[index];
                            return CheckboxListTile(
                              title: Text(className),
                              value: selectedLopDangDay.contains(className),
                              onChanged: (isSelected) {
                                setState(() {
                                  if (isSelected ?? false) {
                                    selectedLopDangDay.add(className);
                                  } else {
                                    selectedLopDangDay.remove(className);
                                  }
                                });
                              },
                              activeColor: primaryColor,
                            );
                          },
                        ),
                      ),
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
                          if (controllerHoTen.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Vui lòng nhập tên giáo viên")),
                            );
                            return;
                          }

                          // ✅ Lấy accountId từ email
                          String? accountId = currentAccountId;
                          if (controllerEmail.text.trim() != (teacher.accountId ?? '')) {
                            if (controllerEmail.text.isNotEmpty) {
                              // Tìm accountId từ email trong collection users
                              final userSnapshot = await FirebaseFirestore.instance
                                  .collection('users')
                                  .where('email', isEqualTo: controllerEmail.text.trim())
                                  .limit(1)
                                  .get();

                              if (userSnapshot.docs.isNotEmpty) {
                                accountId = userSnapshot.docs.first['accountId'];
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Email không tìm thấy trong hệ thống")),
                                  );
                                }
                                return;
                              }
                            }
                          }

                          final newTeacher = Teacher(
                            giaoVienId: isEditing ? teacher.giaoVienId : DateTime.now().millisecondsSinceEpoch.toString(),
                            maGiaoVien: controllerMaGiaoVien.text,
                            hoTen: controllerHoTen.text,
                            ngaySinh: ngaySinh,
                            gioiTinh: selectedGioiTinh,
                            boMonId: selectedBoMon,
                            accountId: accountId, // ✅ Sử dụng accountId từ email
                            lopDangDay: selectedLopDangDay,
                            createdAt: isEditing ? teacher.createdAt : DateTime.now(),
                          );

                          if (isEditing) {
                            await FirebaseFirestore.instance
                                .collection('teachers')
                                .doc(doc!.id)
                                .update(newTeacher.toFirestore());
                          } else {
                            await FirebaseFirestore.instance
                                .collection('teachers')
                                .add(newTeacher.toFirestore());
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
    IconData icon, {
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      enabled: true,  // ✅ Thêm dòng này
      onChanged: onChanged,
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
          firstDate: DateTime(1960),
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
          "Bạn có chắc chắn muốn xóa giáo viên này không?\nHành động này không thể hoàn tác.",
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
              FirebaseFirestore.instance.collection('teachers').doc(docId).delete();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("✓ Đã xóa giáo viên thành công!"),
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