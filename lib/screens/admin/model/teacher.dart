import 'package:cloud_firestore/cloud_firestore.dart';

class Teacher {
  final String? id;
  final String giaoVienId;      // ID giáo viên (tự động tạo)
  final String maGiaoVien;      // Mã giáo viên
  final String hoTen;           // Họ tên
  final DateTime? ngaySinh;     // Ngày sinh
  final String? gioiTinh;       // Giới tính (Nam/Nữ/Khác)
  final String? boMonId;        // ID bộ môn
  final String? accountId;      // ID tài khoản
  final List<String> lopDangDay; // Danh sách lớp đang dạy
  final DateTime? createdAt;

  Teacher({
    this.id,
    required this.giaoVienId,
    required this.maGiaoVien,
    required this.hoTen,
    this.ngaySinh,
    this.gioiTinh,
    this.boMonId,
    this.accountId,
    this.lopDangDay = const [],
    this.createdAt,
  });

  factory Teacher.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Teacher(
      id: doc.id,
      giaoVienId: data['giaoVienId'] ?? '',
      maGiaoVien: data['maGiaoVien'] ?? '',
      hoTen: data['hoTen'] ?? '',
      ngaySinh: data['ngaySinh'] != null ? (data['ngaySinh'] as Timestamp).toDate() : null,
      gioiTinh: data['gioiTinh'],
      boMonId: data['boMonId'],
      accountId: data['accountId'],
      lopDangDay: List<String>.from(data['lopDangDay'] ?? []),
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'giaoVienId': giaoVienId,
      'maGiaoVien': maGiaoVien,
      'hoTen': hoTen,
      if (ngaySinh != null) 'ngaySinh': Timestamp.fromDate(ngaySinh!),
      if (gioiTinh != null) 'gioiTinh': gioiTinh,
      if (boMonId != null) 'boMonId': boMonId,
      if (accountId != null) 'accountId': accountId,
      'lopDangDay': lopDangDay,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  Teacher copyWith({
    String? id,
    String? giaoVienId,
    String? maGiaoVien,
    String? hoTen,
    DateTime? ngaySinh,
    String? gioiTinh,
    String? boMonId,
    String? accountId,
    List<String>? lopDangDay,
    DateTime? createdAt,
  }) {
    return Teacher(
      id: id ?? this.id,
      giaoVienId: giaoVienId ?? this.giaoVienId,
      maGiaoVien: maGiaoVien ?? this.maGiaoVien,
      hoTen: hoTen ?? this.hoTen,
      ngaySinh: ngaySinh ?? this.ngaySinh,
      gioiTinh: gioiTinh ?? this.gioiTinh,
      boMonId: boMonId ?? this.boMonId,
      accountId: accountId ?? this.accountId,
      lopDangDay: lopDangDay ?? this.lopDangDay,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}