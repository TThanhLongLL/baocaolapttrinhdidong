import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'chat_service.dart';

class ChatRoomScreen extends StatefulWidget {
  final String conversationId;
  final String peerId;
  final String peerName;
  final List<String> participants;

  const ChatRoomScreen({
    super.key,
    required this.conversationId,
    required this.peerId,
    required this.peerName,
    required this.participants,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _controller = TextEditingController();
  final _chatService = ChatService();
  final _auth = FirebaseAuth.instance;
  final _scrollController = ScrollController();

  bool _markedInitialRead = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _chatService.sendMessage(
      conversationId: widget.conversationId,
      senderId: user.uid,
      text: _controller.text,
      participants: widget.participants,
    );
      _controller.clear();
      Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        0.0, 
        duration: const Duration(milliseconds: 300), 
        curve: Curves.easeOut
      );
    });
  }

  Future<void> _markRead() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _chatService.markConversationRead(widget.conversationId, user.uid);
    _markedInitialRead = true;
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Vui long dang nhap de chat')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.peerName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _chatService.streamMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isNotEmpty && !_markedInitialRead) {
                  _markRead();
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final isMe = data['senderId'] == user.uid;
                    final text = data['text'] ?? '';
                    final ts = data['createdAt'] as Timestamp?;
                    final dateTime = ts != null ? ts.toDate() : DateTime.now(); 
                    final time = DateFormat('HH:mm').format(dateTime);

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(maxWidth: 280),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF5B8DEF) : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              text,
                              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              time,
                              style: TextStyle(
                                  color: isMe ? Colors.white70 : Colors.grey,
                                  fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  
                );
              
              },
              
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Nhap tin nhan...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF5B8DEF)),
                    onPressed: _send,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
