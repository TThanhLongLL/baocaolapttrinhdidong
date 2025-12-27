import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String? id;
  final String hocSinhId;        // ID học sinh (tự động tạo)
  final String fullName;         // Họ tên
  final String maHocSinh;        // Mã học sinh
  final String email;            // Email
  final String? accountId;       // ID tài khoản (liên kết từ users)
  final DateTime? ngaySinh;      // Ngày sinh
  final String? gioiTinh;        // Giới tính (Nam/Nữ/Khác)
  final String? className;       // Tên lớp
  final String? lopId;           // ID lớp (liên kết với SchoolClass)
  final DateTime? createdAt;

  Student({
    this.id,
    required this.hocSinhId,
    required this.fullName,
    required this.maHocSinh,
    required this.email,
    this.accountId,
    this.ngaySinh,
    this.gioiTinh,
    this.className,
    this.lopId,
    this.createdAt,
  });

  factory Student.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Student(
      id: doc.id,
      hocSinhId: data['hocSinhId'] ?? '',
      fullName: data['fullName'] ?? '',
      maHocSinh: data['maHocSinh'] ?? '',
      email: data['email'] ?? '',
      accountId: data['accountId'],
      ngaySinh: data['ngaySinh'] != null ? (data['ngaySinh'] as Timestamp).toDate() : null,
      gioiTinh: data['gioiTinh'],
      className: data['className'],
      lopId: data['lopId'],
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'hocSinhId': hocSinhId,
      'fullName': fullName,
      'maHocSinh': maHocSinh,
      'email': email,
      if (accountId != null) 'accountId': accountId,
      if (ngaySinh != null) 'ngaySinh': Timestamp.fromDate(ngaySinh!),
      if (gioiTinh != null) 'gioiTinh': gioiTinh,
      if (className != null) 'className': className,
      if (lopId != null) 'lopId': lopId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  Student copyWith({
    String? id,
    String? hocSinhId,
    String? fullName,
    String? maHocSinh,
    String? email,
    String? accountId,
    DateTime? ngaySinh,
    String? gioiTinh,
    String? className,
    String? lopId,
    DateTime? createdAt,
  }) {
    return Student(
      id: id ?? this.id,
      hocSinhId: hocSinhId ?? this.hocSinhId,
      fullName: fullName ?? this.fullName,
      maHocSinh: maHocSinh ?? this.maHocSinh,
      email: email ?? this.email,
      accountId: accountId ?? this.accountId,
      ngaySinh: ngaySinh ?? this.ngaySinh,
      gioiTinh: gioiTinh ?? this.gioiTinh,
      className: className ?? this.className,
      lopId: lopId ?? this.lopId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}