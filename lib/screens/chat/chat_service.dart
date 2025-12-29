import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String conversationId(String userA, String userB) {
    final sorted = [userA, userB]..sort();
    return '${sorted.first}_${sorted.last}';
  }

  /// Đảm bảo tồn tại phòng chat 1-1
  Future<String> ensureConversation({
    required String userId,
    required String peerId,
    required String classId,
    String? userName,
    String? peerName,
  }) async {
    final convId = conversationId(userId, peerId);
    final ref = _db.collection('conversations').doc(convId);
    final snap = await ref.get();
    
    if (!snap.exists) {
      await ref.set({
        'participants': [userId, peerId],
        'classId': classId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
        'lastSenderId': null,
        'unreadCounts': {userId: 0, peerId: 0},
        'names': {
          userId: userName ?? '',
          peerId: peerName ?? '',
        },
      });
    }
    return convId;
  }

  // --- MỚI: Lấy Stream của 1 cuộc hội thoại để hiện Unread Realtime ---
  Stream<DocumentSnapshot> getConversationStream(String userA, String userB) {
    final convId = conversationId(userA, userB);
    return _db.collection('conversations').doc(convId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamMessages(String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
    required List<String> participants,
  }) async {
    if (text.trim().isEmpty) return;
    final convRef = _db.collection('conversations').doc(conversationId);
    final msgRef = convRef.collection('messages').doc();
    final now = FieldValue.serverTimestamp();

    await _db.runTransaction((txn) async {
      txn.set(msgRef, {
        'text': text.trim(),
        'senderId': senderId,
        'createdAt': now,
      });

      // Cập nhật conversation: lastMessage + unreadCount
      // Đọc doc hiện tại để lấy unread cũ (nếu cần chính xác tuyệt đối), 
      // hoặc dùng FieldValue.increment (nhanh gọn)
      
      final unreadUpdates = <String, dynamic>{};
      for (final uid in participants) {
        if (uid != senderId) {
           unreadUpdates['unreadCounts.$uid'] = FieldValue.increment(1);
        }
      }

      txn.set(convRef, {
        'lastMessage': text.trim(),
        'lastSenderId': senderId,
        'updatedAt': now,
        ...unreadUpdates,
      }, SetOptions(merge: true));
    });
  }

  Future<void> markConversationRead(String conversationId, String userId) async {
    final ref = _db.collection('conversations').doc(conversationId);
    await ref.update({
      'unreadCounts.$userId': 0,
    });
  }
}