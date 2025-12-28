import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:baocaocuoiky/screens/onboding/onboding_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../model/menu.dart';
import '../../../utils/rive_utils.dart';
import 'info_card.dart';
import 'package:baocaocuoiky/screens/admin/admin_dashboard_screen.dart';
import 'package:baocaocuoiky/screens/home/profile/profile_home.dart';
import 'side_menu.dart';
class SideBar extends StatefulWidget {
  const SideBar({super.key});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  Menu selectedSideMenu = sidebarMenus.first;

  Future<void> _handleMenuTap(BuildContext context, Menu menu) async {
    // chạy animation
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

    // Logout
    if (menu.title == "Logout") {
      await FirebaseAuth.instance.signOut();

      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnbodingScreen()),
            (route) => false,
      );
      return;
    }

    // các menu khác
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
          child: SingleChildScrollView( // 1. Thêm widget này bao bên ngoài
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .snapshots(),
                  builder: (context, snap) {
                    final data = snap.data?.data() as Map<String, dynamic>?;
                    final name = data?['fullName']?.toString() ?? 'User';
                    final email = FirebaseAuth.instance.currentUser?.email ?? '';

                    return InfoCard(
                      name: name,
                      bio: email,
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 24, top: 32, bottom: 16),
                  child: Text(
                    "Browse".toUpperCase(),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium!
                        .copyWith(color: Colors.white70),
                  ),
                ),

                ...sidebarMenus.map((menu) => SideMenu(
                  menu: menu,
                  selectedMenu: selectedSideMenu,
                  press: _handleMenuTap,
                  riveOnInit: (artboard) {
                    menu.rive.status = RiveUtils.getRiveInput(
                      artboard,
                      stateMachineName: menu.rive.stateMachineName,
                    );
                  },
                )),

                Padding(
                  padding: const EdgeInsets.only(left: 24, top: 40, bottom: 16),
                  child: Text(
                    "History".toUpperCase(),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium!
                        .copyWith(color: Colors.white70),
                  ),
                ),

                ...sidebarMenus2.map((menu) => SideMenu(
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
                )),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
