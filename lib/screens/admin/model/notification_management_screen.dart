import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:baocaocuoiky/services/notification_service.dart';

class NotificationManagementScreen extends StatefulWidget {
  const NotificationManagementScreen({Key? key}) : super(key: key);

  @override
  State<NotificationManagementScreen> createState() => _NotificationManagementScreenState();
}

class _NotificationManagementScreenState extends State<NotificationManagementScreen> {
  final Color primaryColor = const Color(0xFF16A34A); // Xanh lá chủ đạo

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4), // Nền xanh lá rất nhạt
      appBar: AppBar(
        title: const Text("Quản Lý Thông Báo", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: NotificationService.instance.streamAllNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  Text("Chưa có thông báo nào", style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16).copyWith(bottom: 80),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final id = docs[index].id;
              final title = data['title'] ?? 'Không tiêu đề';
              final subtitle = data['subtitle'] ?? '';
              final colorVal = data['color'] ?? 0xFF80A4FF;
              
              // Xử lý ngày hết hạn
              DateTime? expireDate;
              if (data['expirationDate'] != null) {
                expireDate = (data['expirationDate'] as Timestamp).toDate();
              }
              final bool isExpired = expireDate != null && expireDate.isBefore(DateTime.now());

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isExpired ? Colors.red.shade200 : Colors.transparent),
                  boxShadow: [
                    BoxShadow(
                      color: Color(colorVal).withOpacity(0.15),
                      offset: const Offset(0, 4),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(colorVal).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.campaign, color: Color(colorVal)),
                  ),
                  title: Row(
                    children: [
                      Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
                      if (isExpired)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(4)),
                          child: const Text("Đã hết hạn", style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                        )
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (subtitle.isNotEmpty) 
                        Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.event_available, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            expireDate != null 
                              ? "Hết hạn: ${DateFormat('dd/MM/yyyy').format(expireDate)}"
                              : "Hiệu lực vĩnh viễn",
                            style: TextStyle(fontSize: 12, color: isExpired ? Colors.red : Colors.grey[500]),
                          ),
                        ],
                      )
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _confirmDelete(context, id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateNotificationDialog(context),
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add),
        label: const Text("Tạo Thông Báo"),
      ),
    );
  }

  // --- DIALOG TẠO MỚI (Đã thêm chọn ngày) ---
  Future<void> _showCreateNotificationDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final subtitleCtrl = TextEditingController();
    DateTime? selectedExpirationDate;
    
    final List<Color> colorOptions = [
      const Color(0xFF3B82F6), const Color(0xFFEF4444), const Color(0xFF10B981),
      const Color(0xFFF59E0B), const Color(0xFF8B5CF6),
    ];
    Color chosenColor = colorOptions[0];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Tạo Thông Báo Mới", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
                    const SizedBox(height: 20),
                    
                    // Nhập nội dung
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: "Tiêu đề",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true, fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: subtitleCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "Nội dung chi tiết",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true, fillColor: Colors.grey[50],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    // Chọn ngày hết hạn
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setStateDialog(() => selectedExpirationDate = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedExpirationDate == null 
                                ? "Chọn ngày hết hạn (Tùy chọn)" 
                                : "Hết hạn: ${DateFormat('dd/MM/yyyy').format(selectedExpirationDate!)}",
                              style: TextStyle(color: selectedExpirationDate == null ? Colors.grey[600] : Colors.black),
                            ),
                            if (selectedExpirationDate != null)
                              GestureDetector(
                                onTap: () => setStateDialog(() => selectedExpirationDate = null),
                                child: const Icon(Icons.close, size: 18, color: Colors.red),
                              )
                            else
                              const Icon(Icons.calendar_today, size: 18, color: Colors.blue),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text("Màu sắc thẻ:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: colorOptions.map((c) => GestureDetector(
                        onTap: () => setStateDialog(() => chosenColor = c),
                        child: CircleAvatar(
                          backgroundColor: c,
                          radius: 18,
                          child: chosenColor == c ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                        ),
                      )).toList(),
                    ),

                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (titleCtrl.text.isEmpty) return;
                          await NotificationService.instance.createGlobalNotification(
                            title: titleCtrl.text.trim(),
                            subtitle: subtitleCtrl.text.trim(),
                            color: chosenColor,
                            expirationDate: selectedExpirationDate, // Lưu ngày
                          );
                          if (mounted) Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Đăng Thông Báo", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận"),
        content: const Text("Bạn có chắc muốn xóa thông báo này?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          TextButton(
            onPressed: () {
              NotificationService.instance.deleteNotification(id);
              Navigator.pop(ctx);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}