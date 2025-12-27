import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolClass {
  final String? id;
  final String lopId;           // Mã lớp (tự động tạo)
  final String className;       // Tên lớp (VD: 12A1)
  final String khoaHoc;         // Khóa học (VD: Tin học, Toán)
  final String classCode;       // Mã lớp (VD: TC-2024-001)
  final DateTime dateStart;     // Ngày bắt đầu
  final DateTime dateEnd;       // Ngày kết thúc
  final bool allowJoin;         // Cho phép học sinh tự yêu cầu tham gia hay không
  final String namHoc;          // Năm học (VD: 2024-2025)
  final int memberCount;        // Số lượng thành viên (mặc định 0)
  final int maxMembers;         // Số lượng tối đa
  final DateTime? createdAt;
  final String teacherId;   // Mã giáo viên (accountId hoặc ID từ bảng teachers)
  final String teacherName;

  SchoolClass({
    this.id,
    required this.lopId,
    required this.className,
    required this.khoaHoc,
    required this.classCode,
    required this.dateStart,
    required this.dateEnd,
    this.allowJoin = true,
    required this.namHoc,
    this.memberCount = 0,
    required this.maxMembers,
    this.createdAt,
    required this.teacherId,
    required this.teacherName,
  });

  factory SchoolClass.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SchoolClass(
      id: doc.id,
      lopId: data['lopId'] ?? '',
      className: data['className'] ?? '',
      khoaHoc: data['khoaHoc'] ?? '',
      classCode: data['classCode'] ?? '',
      dateStart: (data['dateStart'] as Timestamp).toDate(),
      dateEnd: (data['dateEnd'] as Timestamp).toDate(),
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? 'Chưa phân công',
      allowJoin: data['allowJoin'] ?? true,
      namHoc: data['namHoc'] ?? '',
      memberCount: data['memberCount'] ?? 0,
      maxMembers: data['maxMembers'] ?? 30,
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'lopId': lopId,
      'className': className,
      'khoaHoc': khoaHoc,
      'classCode': classCode,
      'dateStart': Timestamp.fromDate(dateStart),
      'dateEnd': Timestamp.fromDate(dateEnd),
      'teacherId': teacherId,
      'teacherName': teacherName,
      'allowJoin': allowJoin,
      'namHoc': namHoc,
      'memberCount': memberCount,
      'maxMembers': maxMembers,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  SchoolClass copyWith({
    String? id,
    String? lopId,
    String? className,
    String? khoaHoc,
    String? classCode,
    DateTime? dateStart,
    DateTime? dateEnd,
    String? teacherId,       
    String? teacherName, 
    bool? allowJoin,
    String? namHoc,
    int? memberCount,
    int? maxMembers,
    DateTime? createdAt,
  }) {
    return SchoolClass(
      id: id ?? this.id,
      lopId: lopId ?? this.lopId,
      className: className ?? this.className,
      khoaHoc: khoaHoc ?? this.khoaHoc,
      classCode: classCode ?? this.classCode,
      dateStart: dateStart ?? this.dateStart,
      dateEnd: dateEnd ?? this.dateEnd,
      teacherId: teacherId ?? this.teacherId,      
      teacherName: teacherName ?? this.teacherName,
      allowJoin: allowJoin ?? this.allowJoin,
      namHoc: namHoc ?? this.namHoc,
      memberCount: memberCount ?? this.memberCount,
      maxMembers: maxMembers ?? this.maxMembers,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
