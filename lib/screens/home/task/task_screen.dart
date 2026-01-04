import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:baocaocuoiky/services/local_notification_service.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({Key? key}) : super(key: key);

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Scaffold(body: Center(child: Text("Vui lòng đăng nhập")));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        title: const Text("Danh sách công việc", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const SizedBox(), // Ẩn nút back nếu dùng ở bottom nav
        actions: [
          // Nút xóa các công việc đã xong
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.grey),
            tooltip: "Xóa công việc đã xong",
            onPressed: _deleteCompletedTasks,
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('tasks')
            .orderBy('deadline', descending: false) // Sắp xếp theo hạn chót (gần nhất lên đầu)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.checklist_rtl_rounded, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("Bạn rảnh rỗi quá nhỉ! \nThêm công việc mới ngay nào.", 
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16).copyWith(bottom: 100),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String taskId = docs[index].id;
              final String title = data['title'] ?? '';
              final String note = data['note'] ?? '';
              final bool isDone = data['isDone'] ?? false;
              final DateTime? deadline = data['deadline'] != null 
                  ? (data['deadline'] as Timestamp).toDate() 
                  : null;
              
              // Kiểm tra xem đã quá hạn chưa
              final bool isExpired = deadline != null && deadline.isBefore(DateTime.now()) && !isDone;

              return Dismissible(
                key: Key(taskId),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.redAccent,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  _deleteTask(taskId);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: isDone 
                      ? null 
                      : isExpired 
                        ? Border.all(color: Colors.red.withOpacity(0.5)) 
                        : null,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: GestureDetector(
                      onTap: () => _toggleTaskStatus(taskId, !isDone),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDone ? Colors.green : (isExpired ? Colors.red : Colors.grey),
                            width: 2,
                          ),
                          color: isDone ? Colors.green : Colors.transparent,
                        ),
                        child: isDone 
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : const Icon(Icons.circle, size: 16, color: Colors.transparent),
                      ),
                    ),
                    title: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDone ? Colors.grey : Colors.black87,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (note.isNotEmpty)
                          Text(note, maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (deadline != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(Icons.access_time_rounded, size: 14, color: isExpired ? Colors.red : Colors.blue),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('HH:mm dd/MM').format(deadline),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isExpired ? Colors.red : Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (isExpired) 
                                  const Text(" (Quá hạn)", style: TextStyle(fontSize: 12, color: Colors.red)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      // [THAY ĐỔI Ở ĐÂY]: Thêm thuộc tính này để dời nút sang trái
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat, 
      
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100.0), // Đẩy nút lên trên BottomNavBar
        child: FloatingActionButton.extended(
          onPressed: _showAddTaskDialog,
          backgroundColor: const Color(0xFF5B8DEF),
          icon: const Icon(Icons.add_task),
          label: const Text("Thêm việc"),
        ),
      ),
    );
  }

  // --- LOGIC XỬ LÝ ---

  Future<void> _showAddTaskDialog() async {
    final titleCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    
    // Mặc định nhắc nhở sau 1 tiếng
    selectedTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Tạo công việc mới", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "Tên công việc (VD: Ôn tập Toán)",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    hintText: "Ghi chú thêm...",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Chọn thời gian
                const Text("Hạn chót & Nhắc nhở", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context, initialDate: selectedDate, 
                            firstDate: DateTime.now(), lastDate: DateTime(2030)
                          );
                          if (date != null) setModalState(() => selectedDate = date);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 18, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final time = await showTimePicker(context: context, initialTime: selectedTime);
                          if (time != null) setModalState(() => selectedTime = time);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, size: 18, color: Colors.orange),
                              const SizedBox(width: 8),
                              Text(selectedTime.format(context)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty) return;
                      
                      // 1. Tính toán thời gian deadline
                      final DateTime deadline = DateTime(
                        selectedDate.year, selectedDate.month, selectedDate.day,
                        selectedTime.hour, selectedTime.minute
                      );

                      if (deadline.isBefore(DateTime.now())) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng chọn thời gian trong tương lai!")));
                        return;
                      }

                      Navigator.pop(ctx); // Đóng modal

                      // 2. Lưu vào Firestore
                      final docRef = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user!.uid)
                          .collection('tasks')
                          .add({
                        'title': titleCtrl.text.trim(),
                        'note': noteCtrl.text.trim(),
                        'isDone': false,
                        'deadline': Timestamp.fromDate(deadline),
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      // 3. Đặt lịch thông báo (Local Notification)
                      // Dùng hashCode của ID task làm ID thông báo (cần chuyển sang int)
                      int notificationId = docRef.id.hashCode; 
                      
                      await LocalNotificationService().showInstantNotification(
                        id: notificationId,
                        title: "⏰ Nhắc nhở: ${titleCtrl.text}",
                        body: "Đã đến giờ làm việc: ${titleCtrl.text}. ${noteCtrl.text}",
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã tạo công việc & đặt nhắc nhở!"), backgroundColor: Colors.green));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B8DEF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text("Lưu & Đặt nhắc nhở", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _toggleTaskStatus(String taskId, bool newStatus) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('tasks')
        .doc(taskId)
        .update({'isDone': newStatus});
  }

  void _deleteTask(String taskId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('tasks')
        .doc(taskId)
        .delete();
    // Lưu ý: Nếu muốn hủy notification thì cần dùng thư viện cancel(id), 
    // nhưng ở mức độ cơ bản có thể bỏ qua, hoặc thêm hàm cancel vào LocalNotificationService.
  }

  void _deleteCompletedTasks() async {
    final batch = FirebaseFirestore.instance.batch();
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('tasks')
        .where('isDone', isEqualTo: true)
        .get();
    
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã dọn dẹp các việc đã xong")));
  }
}