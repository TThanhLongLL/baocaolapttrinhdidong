// lib/screens/home/components/secondary_course_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SecondaryCourseCard extends StatelessWidget {
  final String title;
  final String subtitle; // Ví dụ: "Watch video - 15 mins"
  final String iconSrc;
  final Color color;

  const SecondaryCourseCard({
    Key? key,
    this.title = "Tiêu đề thông báo",
    this.subtitle = "Xem chi tiết",
    this.iconSrc = "assets/icons/code.svg", // Đảm bảo bạn có icon này hoặc đổi tên
    this.color = const Color(0xFF7553F6), // Màu mặc định
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 16,
                  ),
                )
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Đường kẻ dọc
          SizedBox(
            height: 40,
            child: VerticalDivider(
              color: Colors.white70,
              thickness: 1,
            ),
          ),
          const SizedBox(width: 10),
          // Icon bên phải
          SvgPicture.asset(iconSrc, height: 40, width: 40, color: Colors.white), 
          // Nếu icon của bạn có màu sẵn thì bỏ thuộc tính color ở trên đi
        ],
      ),
    );
  }
}