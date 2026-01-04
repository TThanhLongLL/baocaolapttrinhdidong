import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../model/menu.dart';
import '../../../utils/rive_utils.dart';
import 'info_card.dart';
import 'package:baocaocuoiky/screens/admin/admin_dashboard_screen.dart';
import 'package:baocaocuoiky/screens/onboding/onboding_screen.dart'; 
import 'side_menu.dart';

class SideBar extends StatefulWidget {
  const SideBar({super.key});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  Menu selectedSideMenu = sidebarMenus.first;

  Future<void> _handleMenuTap(BuildContext context, Menu menu) async {
    final status = menu.rive.status;
    if (status != null) {
      RiveUtils.chnageSMIBoolState(status);
    }

    if (menu.title == "Admin") {
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
      return;
    }

    if (menu.title == "Logout") {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnbodingScreen()),
        (route) => false,
      );
      return;
    }

    setState(() {
      selectedSideMenu = menu;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: 288,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF17203A),
          borderRadius: BorderRadius.all(Radius.circular(30)),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final String role = data?['role'] ?? 'student';
                final String name = data?['fullName']?.toString() ?? 'User';
                final String email = FirebaseAuth.instance.currentUser?.email ?? '';

                // [QUAN TRỌNG] Tính isAdmin một lần duy nhất ở đây
                final bool isAdmin = role.toLowerCase().trim() == "admin";

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoCard(name: name, bio: email),
                    
                    Padding(
                      padding: const EdgeInsets.only(left: 24, top: 32, bottom: 16),
                      child: Text(
                        "Trang Chính".toUpperCase(),
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.white70),
                      ),
                    ),

                    // --- VÒNG LẶP 1 (TRANG CHÍNH) ---
                    ...sidebarMenus.map((menu) {
                      // Nếu muốn ẩn menu nào đó ở nhóm 1 thì check tại đây
                      // Ví dụ: if (menu.title == "Quản lý" && !isAdmin) return const SizedBox.shrink();
                      
                      return SideMenu(
                        menu: menu,
                        selectedMenu: selectedSideMenu,
                        press: _handleMenuTap,
                        riveOnInit: (artboard) {
                          menu.rive.status = RiveUtils.getRiveInput(
                            artboard,
                            stateMachineName: menu.rive.stateMachineName,
                          );
                        },
                      );
                    }),

                    Padding(
                      padding: const EdgeInsets.only(left: 24, top: 40, bottom: 16),
                      child: Text(
                        "Phần sau".toUpperCase(),
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.white70),
                      ),
                    ),

                    // --- VÒNG LẶP 2 (PHẦN SAU - CHỨA ADMIN) ---
                    ...sidebarMenus2.map((menu) {
                      // [SỬA LỖI TẠI ĐÂY]
                      // Kiểm tra nếu là menu Admin VÀ user KHÔNG phải admin thì ẩn đi
                      if (menu.title == "Admin" && !isAdmin) {
                        return const SizedBox.shrink(); 
                      }

                      return SideMenu(
                        menu: menu,
                        selectedMenu: selectedSideMenu,
                        press: _handleMenuTap,
                        riveOnInit: (artboard) {
                          final riveInput = RiveUtils.getRiveInput(
                            artboard,
                            stateMachineName: menu.rive.stateMachineName,
                          );
                          if (riveInput != null) {
                            menu.rive.status = riveInput;
                          }
                        },
                      );
                    }),
                    const SizedBox(height: 50),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}