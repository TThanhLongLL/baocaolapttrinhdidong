import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';

class GeminiService {
  // TODO: điền API key thật
  static const String apiKey = 'AIzaSyCqoAThpbwQBdZguEDvW1A-vceclJp7pzM';

  late final GenerativeModel _model;
  bool _isConnected = false;

  // Keywords gốc (có thể có/không dấu đều được)
  final List<String> _studyKeywords = [
    // học tập chung
    'hoc', 'hoc tap', 'bai tap', 'bai giang', 'mon hoc', 'khoa hoc', 'on tap',
    'bai thi', 'de thi', 'kiem tra', 'thi', 'quiz', 'exam', 'lesson', 'study',
    'homework', 'assignment',

    // kiến thức - giải thích
    'giai thich',
    'giải thích',
    'cong thuc',
    'công thức',
    'dinh nghia',
    'định nghĩa',
    'vi du', 'ví dụ', 'tom tat', 'tóm tắt',

    // môn học phổ biến
    'toan',
    'toán',
    'ly',
    'lý',
    'hoa',
    'hóa',
    'sinh',
    'van',
    'văn',
    'anh',
    'tiếng anh',

    // lập trình
    'lap trinh',
    'lập trình',
    'code',
    'programming',
    'flutter',
    'dart',
    'python',
    'java', 'c++', 'c#', 'javascript', 'js', 'sql', 'oop',
    'vong lap', 'vòng lặp', 'for', 'while', 'if', 'else', 'ham', 'hàm',
    'thuat toan',
    'thuật toán',
    'algorithm',
    'data structure',
    'cau truc du lieu',
    'cấu trúc dữ liệu',
    'ai', 'ml', 'machine learning',

    // lịch học - hoạt động học tập
    'thoi khoa bieu',
    'thời khóa biểu',
    'lich hoc',
    'lịch học',
    'buoi hoc',
    'buổi học',
    'tiet hoc', 'tiết học', 'phong hoc', 'phòng học',
    'hom nay', 'hôm nay', 'ngay mai', 'ngày mai', 'tuan nay', 'tuần này',
    'han nop', 'hạn nộp', 'deadline', 'hoat dong hoc tap', 'hoạt động học tập',
  ];

  // Danh sách keyword đã normalize (tối ưu)
  late final List<String> _normalizedKeywords;

  // Thông điệp từ chối chuẩn khi ngoài phạm vi học tập
  final String _studyGuardMessage =
      'Trợ lý học tập chỉ hỗ trợ các câu hỏi liên quan đến bài học, bài tập và lịch học.\nVui lòng đặt câu hỏi đúng phạm vi học tập.';

  // Prompt hệ thống yêu cầu phạm vi hỗ trợ
  final String _studySystemPrompt = '''
Ban la tro ly hoc tap trong ung dung quan ly hoc tap.
Muc tieu: ho tro nguoi dung trong cac van de HOC TAP (kien thuc mon hoc, noi dung bai hoc, huong dan lam bai/on tap, phuong phap va ky nang hoc, cac cau hoi ve lich/thoi khoa bieu/so buoi/han nop bai/hoat dong hoc tap).
KHONG tra loi noi dung ngoai hoc tap (giai tri, doi song ca nhan, chinh tri, ton giao, noi dung nhay cam).
Neu ngu canh cung cap lich hoc, hay tra loi truc tiep noi dung lich do; KHONG hoi them nguoi dung. Neu khong co lich trong ngu canh, noi ro: "Chua tim thay lich hoc trong he thong cho tai khoan nay".''';

  GeminiService() {
    _model = GenerativeModel(
      model: 'models/gemini-flash-latest',
      apiKey: apiKey,
    );

    // Tạo sẵn keyword đã normalize để dùng lại
    _normalizedKeywords = _studyKeywords.map(_normalizeVietnamese).toList();
  }

  // Kiểm tra kết nối
  Future<bool> checkConnection() async {
    try {
      final content = [Content.text('Xin chào')];
      final response = await _model.generateContent(content);
      _isConnected = response.text != null;
      return _isConnected;
    } catch (e) {
      _isConnected = false;
      // ignore: avoid_print
      print('Lỗi kết nối: $e');
      return false;
    }
  }

  // Lấy trạng thái kết nối
  bool get isConnected => _isConnected;

  Future<String> sendMessage(String message) async {
    // Guard: chỉ cho phép câu hỏi trong phạm vi học tập
    if (!_isStudyQuestion(message)) {
      return _studyGuardMessage;
    }

    final String scheduleContext = await _buildScheduleContext();

    try {
      final content = [
        // Lưu ý: package này không có "system" role riêng,
        // nên ta đưa prompt hệ thống vào đầu ngữ cảnh.
        Content.text(_studySystemPrompt),
        if (scheduleContext.isNotEmpty) Content.text(scheduleContext),
        Content.text(message),
      ];

      final response = await _model.generateContent(content);
      return response.text ?? 'Không có phản hồi';
    } catch (e) {
      return 'Lỗi: ${e.toString()}';
    }
  }

  bool _isStudyQuestion(String message) {
    final normalizedMessage = _normalizeVietnamese(message);

    // Chỉ cần match 1 keyword là cho qua
    for (final kw in _normalizedKeywords) {
      if (normalizedMessage.contains(kw)) return true;
    }
    return false;
  }

  Future<String> _buildScheduleContext() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "Chua tim thay lich hoc trong he thong cho tai khoan nay.";

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = userDoc.data() ?? {};
    final role = (data['role'] ?? 'student') as String;
    final accountId = data['accountId'] as String?;
    final teacherId = data['teacherId'] ?? data['giaoVienId'] ?? accountId ?? user.uid;

    final classIds = await _getClassIds(user, role, accountId, teacherId);
    if (classIds.isEmpty) return "Chua tim thay lich hoc trong he thong cho tai khoan nay.";

    final buffer = StringBuffer();
    buffer.writeln('Lich hoc sap toi (tu hom nay):');
    bool hasLesson = false;

    final DateTime now = DateTime.now();
    final Timestamp today = Timestamp.fromDate(DateTime(now.year, now.month, now.day));
    final DateFormat dfDay = DateFormat('dd/MM');

    for (final classId in classIds) {
      final classDoc = await FirebaseFirestore.instance.collection('classes').doc(classId).get();
      final className = (classDoc.data() ?? {})['className'] ?? classId;

      final lessonsSnap = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('lessons')
          .where('date', isGreaterThanOrEqualTo: today)
          .orderBy('date')
          .limit(5)
          .get();

      if (lessonsSnap.docs.isEmpty) continue;

      hasLesson = true;
      buffer.writeln('- Lop $className:');
      for (final doc in lessonsSnap.docs) {
        final data = doc.data();
        final dateTs = data['date'] as Timestamp?;
        final String day = dateTs != null ? dfDay.format(dateTs.toDate()) : '?';
        final String timeRange = _formatTimeRange(data);
        final String topic = data['topic'] ?? 'Buoi hoc';
        buffer.writeln('  - $day $timeRange - $topic');
      }
    }

    if (!hasLesson) {
      return "Chua tim thay lich hoc trong he thong cho tai khoan nay.";
    }

    return buffer.toString();
  } catch (_) {
    return "Chua tim thay lich hoc trong he thong cho tai khoan nay.";
  }
}

  Future<List<String>> _getClassIds(User user, String role, String? accountId, dynamic teacherIdField) async {
    if (role == 'teacher' || role == 'admin') {
      final teacherId = teacherIdField ?? accountId ?? user.uid;
      final q = await FirebaseFirestore.instance
          .collection('classes')
          .where('teacherId', isEqualTo: teacherId)
          .get();
      return q.docs.map((e) => e.id).toList();
    } else {
      final enrolled = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('enrolledClasses')
          .get();
      return enrolled.docs.map((e) {
        final data = e.data();
        if (data is Map<String, dynamic>) {
          return (data['classId'] as String?) ?? e.id;
        }
        return e.id;
      }).toList();
    }
  }

  String _formatTimeRange(Map<String, dynamic> data) {
    final startTime = data['startTime'] as String?;
    final endTime = data['endTime'] as String?;

    if (startTime != null && endTime != null) {
      return '$startTime-$endTime';
    }

    final startAt = data['startAt'] as Timestamp?;
    if (startAt != null) {
      final t = startAt.toDate();
      final h = t.hour.toString().padLeft(2, '0');
      final m = t.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

    return '---';
  }

  /// Chuẩn hóa tiếng Việt để so khớp keyword:
  /// - lower case
  /// - bỏ dấu tiếng Việt
  /// - chuẩn hóa khoảng trắng
  String _normalizeVietnamese(String input) {
    var s = input.toLowerCase().trim();

    const withDiacritics =
        'àáạảãâầấậẩẫăằắặẳẵ'
        'èéẹẻẽêềếệểễ'
        'ìíịỉĩ'
        'òóọỏõôồốộổỗơờớợởỡ'
        'ùúụủũưừứựửữ'
        'ỳýỵỷỹ'
        'đ'
        'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ'
        'ÈÉẸẺẼÊỀẾỆỂỄ'
        'ÌÍỊỈĨ'
        'ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ'
        'ÙÚỤỦŨƯỪỨỰỬỮ'
        'ỲÝỴỶỸ'
        'Đ';

    const withoutDiacritics =
        'aaaaaaaaaaaaaaaaa'
        'eeeeeeeeeee'
        'iiiii'
        'oooooooooooooooooo'
        'uuuuuuuuuuu'
        'yyyyy'
        'd'
        'AAAAAAAAAAAAAAAAA'
        'EEEEEEEEEEE'
        'IIIII'
        'OOOOOOOOOOOOOOOOOO'
        'UUUUUUUUUUU'
        'YYYYY'
        'D';

    for (int i = 0; i < withDiacritics.length; i++) {
      s = s.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }

    // Chuẩn hóa khoảng trắng
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s;
  }
}



