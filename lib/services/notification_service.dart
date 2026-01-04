import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();
  final CollectionReference _col =
      FirebaseFirestore.instance.collection('notifications');

  // Lấy tất cả (dùng cho Admin quản lý)
  Stream<QuerySnapshot> streamAllNotifications() {
    return _col.orderBy('createdAt', descending: true).snapshots();
  }


  Stream<QuerySnapshot> streamActiveNotifications() {
    return _col.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> createGlobalNotification({
    required String title,
    String subtitle = '',
    Color color = const Color(0xFF80A4FF),
    DateTime? expirationDate, // [MỚI] Ngày hết hạn
  }) async {
    await _col.add({
      'title': title,
      'subtitle': subtitle,
      'color': color.value,
      'createdAt': FieldValue.serverTimestamp(),
      'expirationDate': expirationDate != null ? Timestamp.fromDate(expirationDate) : null, // [MỚI]
      'type': 'global',
    });
  }

  // [MỚI] Hàm xóa thông báo
  Future<void> deleteNotification(String id) async {
    await _col.doc(id).delete();
  }
}