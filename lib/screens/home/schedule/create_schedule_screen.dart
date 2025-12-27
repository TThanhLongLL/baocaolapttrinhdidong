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
  // Flutter: Monday = 1, ..., Sunday = 7
  final List<int> _selectedDays = [];
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tạo Lịch Học Tự Động")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
              children: List.generate(7, (index) {
                // index 0 -> Thứ 2 (value 1)
                int dayValue = index + 1; 
                String label = dayValue == 7 ? "CN" : "T${dayValue + 1}";
                bool isSelected = _selectedDays.contains(dayValue);

                return FilterChip(
                  label: Text(label),
                  selected: isSelected,
                  selectedColor: const Color(0xFF7553F6).withOpacity(0.2),
                  checkmarkColor: const Color(0xFF7553F6),
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
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isCreating ? null : _generateSchedule,
                icon: _isCreating 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Icon(Icons.calendar_month),
                label: Text(_isCreating ? "Đang tạo lịch..." : "Tạo Lịch Học"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7553F6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- LOGIC SINH LỊCH TỰ ĐỘNG ---
  Future<void> _generateSchedule() async {
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng chọn ít nhất 1 ngày học!")));
      return;
    }

    setState(() => _isCreating = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      final classRef = FirebaseFirestore.instance.collection('classes').doc(widget.classId);
      
      // Duyệt từng ngày từ Start đến End
      DateTime current = _startDate;
      int count = 0;

      while (current.isBefore(_endDate) || current.isAtSameMomentAs(_endDate)) {
        // Kiểm tra nếu thứ của ngày hiện tại (weekday) nằm trong danh sách đã chọn
        if (_selectedDays.contains(current.weekday)) {
          // Tạo document buổi học
          final lessonRef = classRef.collection('lessons').doc();
          
          // Tạo DateTime đầy đủ cho thời gian bắt đầu
          final startDateTime = DateTime(current.year, current.month, current.day, _startTime.hour, _startTime.minute);
          
          batch.set(lessonRef, {
            'date': Timestamp.fromDate(DateTime(current.year, current.month, current.day)), // Chỉ lưu ngày để dễ query
            'startAt': Timestamp.fromDate(startDateTime), // Lưu thời gian bắt đầu cụ thể để sắp xếp
            'startTime': "${_startTime.hour}:${_startTime.minute.toString().padLeft(2, '0')}",
            'endTime': "${_endTime.hour}:${_endTime.minute.toString().padLeft(2, '0')}",
            'topic': widget.className, // Mặc định là tên môn, sau này GV sửa tên bài sau
            'type': 'lesson', // Phân biệt với bài kiểm tra
          });
          count++;
        }
        // Tăng thêm 1 ngày
        current = current.add(const Duration(days: 1));
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã tạo thành công $count buổi học!"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  // Widget con UI
  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildDatePicker(String label, DateTime date, Function(DateTime) onSelect) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context, initialDate: date, 
          firstDate: DateTime(2024), lastDate: DateTime(2030)
        );
        if (picked != null) onSelect(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        child: Text(DateFormat('dd/MM/yyyy').format(date)),
      ),
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay time, Function(TimeOfDay) onSelect) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: time);
        if (picked != null) onSelect(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        child: Text("${time.hour}:${time.minute.toString().padLeft(2, '0')}"),
      ),
    );
  }
}