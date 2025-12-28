import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CreateScheduleScreen extends StatefulWidget {
  final String classId;
  final String className;

  const CreateScheduleScreen({
    Key? key,
    required this.classId,
    required this.className,
  }) : super(key: key);

  @override
  State<CreateScheduleScreen> createState() => _CreateScheduleScreenState();
}

class _CreateScheduleScreenState extends State<CreateScheduleScreen> {
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  TimeOfDay _startTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 0);

  // Danh sách thứ: 2, 3, 4, 5, 6, 7, 8 (CN)
  final List<int> _selectedDays = [];
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FF), // Màu nền sáng nhẹ
      appBar: AppBar(
        title: const Text("Tạo Lịch Học Tự Động", style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5B8DEF), Color(0xFFB06AB3)], // Gradient đẹp
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("1. Thời gian khóa học"),
              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker("Bắt đầu", _startDate, (date) => setState(() => _startDate = date)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDatePicker("Kết thúc", _endDate, (date) => setState(() => _endDate = date)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildSectionTitle("2. Giờ học"),
              Row(
                children: [
                  Expanded(
                    child: _buildTimePicker("Từ giờ", _startTime, (time) => setState(() => _startTime = time)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTimePicker("Đến giờ", _endTime, (time) => setState(() => _endTime = time)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildSectionTitle("3. Chọn ngày học trong tuần"),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: List.generate(7, (index) {
                  int dayValue = index + 1;
                  String label = dayValue == 7 ? "CN" : "T${dayValue + 1}";
                  bool isSelected = _selectedDays.contains(dayValue);

                  return FilterChip(
                    label: Text(label, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF3B4350), fontWeight: FontWeight.w600)),
                    selected: isSelected,
                    backgroundColor: const Color(0xFFF0F3FA),
                    selectedColor: const Color(0xFF5B8DEF),
                    checkmarkColor: Colors.white,
                    shape: StadiumBorder(side: BorderSide(color: isSelected ? const Color(0xFF5B8DEF) : const Color(0xFFE1E6F0))),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedDays.add(dayValue);
                        } else {
                          _selectedDays.remove(dayValue);
                        }
                      });
                    },
                  );
                }),
              ),

              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E9F2)),
                ),
                child: const Text(
                  "Mẹo: Chọn nhiều ngày để tự động sinh lịch cho cả khóa học. Hệ thống sẽ tự động kiểm tra trùng lịch.",
                  style: TextStyle(color: Color(0xFF5A6270), height: 1.4, fontSize: 13),
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isCreating ? null : _generateSchedule,
                  icon: _isCreating
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    _isCreating ? "Đang kiểm tra & tạo..." : "Tạo Lịch Học",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF5B8DEF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                    disabledBackgroundColor: const Color(0xFF5B8DEF).withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- LOGIC XỬ LÝ: CHECK TRÙNG LỊCH & TẠO ---
  Future<void> _generateSchedule() async {
    if (_selectedDays.isEmpty) {
      _showError("Vui lòng chọn ít nhất 1 ngày học!");
      return;
    }

    // Kiểm tra giờ hợp lệ
    final int newStartMinutes = _startTime.hour * 60 + _startTime.minute;
    final int newEndMinutes = _endTime.hour * 60 + _endTime.minute;
    if (newStartMinutes >= newEndMinutes) {
      _showError("Giờ kết thúc phải sau giờ bắt đầu!");
      return;
    }

    setState(() => _isCreating = true);

    try {
      // BƯỚC 1: Lấy danh sách lịch đã có trong khoảng thời gian này
      // Để tránh tạo trùng đè lên lịch cũ
      final existingLessonsQuery = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('lessons')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(_startDate.year, _startDate.month, _startDate.day)))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59)))
          .get();

      final existingLessons = existingLessonsQuery.docs.map((doc) => doc.data()).toList();

      // BƯỚC 2: Kiểm tra trùng lịch
      DateTime current = _startDate;
      String? conflictError;

      while (current.isBefore(_endDate) || current.isAtSameMomentAs(_endDate)) {
        if (_selectedDays.contains(current.weekday)) {
          // Check trùng
          for (var existing in existingLessons) {
            DateTime existingDate = (existing['date'] as Timestamp).toDate();
            if (DateUtils.isSameDay(current, existingDate)) {
              int exStart = _parseTimeString(existing['startTime']);
              int exEnd = _parseTimeString(existing['endTime']);

              // Công thức trùng: (StartA < EndB) && (StartB < EndA)
              if (newStartMinutes < exEnd && exStart < newEndMinutes) {
                conflictError = "Đã có lịch ngày ${DateFormat('dd/MM').format(current)} (${existing['startTime']}-${existing['endTime']})";
                break;
              }
            }
          }
        }
        if (conflictError != null) break;
        current = current.add(const Duration(days: 1));
      }

      if (conflictError != null) {
        _showError("Lỗi: $conflictError");
        setState(() => _isCreating = false);
        return;
      }

      // BƯỚC 3: Ghi dữ liệu nếu không trùng
      final batch = FirebaseFirestore.instance.batch();
      final classRef = FirebaseFirestore.instance.collection('classes').doc(widget.classId);

      current = _startDate; // Reset ngày để chạy vòng lặp ghi
      int count = 0;

      while (current.isBefore(_endDate) || current.isAtSameMomentAs(_endDate)) {
        if (_selectedDays.contains(current.weekday)) {
          final lessonRef = classRef.collection('lessons').doc();
          final startDateTime = DateTime(current.year, current.month, current.day, _startTime.hour, _startTime.minute);

          batch.set(lessonRef, {
            'date': Timestamp.fromDate(DateTime(current.year, current.month, current.day)),
            'startAt': Timestamp.fromDate(startDateTime),
            'startTime': "${_startTime.hour}:${_startTime.minute.toString().padLeft(2, '0')}",
            'endTime': "${_endTime.hour}:${_endTime.minute.toString().padLeft(2, '0')}",
            'topic': widget.className,
            'type': 'lesson',
          });
          count++;
        }
        current = current.add(const Duration(days: 1));
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Thành công! Đã tạo $count buổi học."), backgroundColor: Colors.green));
        Navigator.pop(context);
      }

    } catch (e) {
      _showError("Lỗi hệ thống: $e");
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  // Helper
  int _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } catch (e) {
      return 0;
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // --- UI WIDGETS CON ---
  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFF5B8DEF),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF1C2D50)),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime date, Function(DateTime) onSelect) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context, initialDate: date,
          firstDate: DateTime(2024), lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(primary: Color(0xFF5B8DEF)),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onSelect(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF6A7280)),
          filled: true,
          fillColor: const Color(0xFFF7F9FF),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E8F1))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E8F1))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF5B8DEF), width: 1.4)),
        ),
        child: Text(DateFormat('dd/MM/yyyy').format(date), style: const TextStyle(fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay time, Function(TimeOfDay) onSelect) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context, initialTime: time,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(primary: Color(0xFF5B8DEF)),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onSelect(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF6A7280)),
          filled: true,
          fillColor: const Color(0xFFF7F9FF),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E8F1))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E8F1))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF5B8DEF), width: 1.4)),
        ),
        child: Text("${time.hour}:${time.minute.toString().padLeft(2, '0')}", style: const TextStyle(fontWeight: FontWeight.w500)),
      ),
    );
  }
}