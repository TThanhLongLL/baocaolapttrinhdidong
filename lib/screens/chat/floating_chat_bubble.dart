import 'package:flutter/material.dart';
import 'package:baocaocuoiky/screens/chat/chat_screen.dart';
import 'package:baocaocuoiky/constants.dart'; 

class FloatingChatBubble extends StatefulWidget {
  const FloatingChatBubble({Key? key}) : super(key: key);

  @override
  State<FloatingChatBubble> createState() => _FloatingChatBubbleState();
}

class _FloatingChatBubbleState extends State<FloatingChatBubble>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleChat() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng Column để xếp chồng nút bấm và khung chat theo chiều dọc
    return Column(
      mainAxisSize: MainAxisSize.min, // Chỉ chiếm không gian tối thiểu cần thiết
      crossAxisAlignment: CrossAxisAlignment.end, // Căn phải
      children: [
        // --- Phần khung chat mở rộng ---
        ScaleTransition(
          scale: _scaleAnimation,
          alignment: Alignment.bottomRight,
          child: Container(
            // Kích thước của khung chat nổi
            height: 450, 
            width: 320,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            // ClipRRect để bo tròn góc cho nội dung bên trong (ChatScreen)
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              // Nhúng màn hình ChatScreen vào đây
              child: Scaffold(
                // Tùy chỉnh lại AppBar của ChatScreen cho gọn khi ở chế độ nổi
                appBar: AppBar(
                   backgroundColor: Colors.white,
                   elevation: 0,
                   title: const Text("Trợ lý AI", style: TextStyle(color: Colors.black, fontSize: 18)),
                   leading: IconButton(
                     icon: const Icon(Icons.close, color: Colors.grey),
                     onPressed: _toggleChat, // Nút đóng ở góc trên khung chat
                   ),
                ),
                // Phần thân vẫn là ChatScreen cũ của bạn
                body: const ChatScreen(isFloatingMode: true), 
              ),
            ),
          ),
        ),

        // --- Nút bấm tròn nổi (Floating Action Button) ---
        FloatingActionButton(
          onPressed: _toggleChat,
          backgroundColor: const Color(0xFF6F5DE8), // Màu tím giống giao diện của bạn
          child: Icon(
            _isOpen ? Icons.close : Icons.chat_bubble_outline,
            color: Colors.white,
            size: 28,
          ),
        ),
      ],
    );
  }
}