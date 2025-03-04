import 'package:flutter/cupertino.dart';

class BottomNavItem {
  final IconData icon;
  final String label;

  const BottomNavItem({required this.icon, required this.label});
}

class BottomNavConfig {
  static const List<BottomNavItem> items = [
    BottomNavItem(icon: CupertinoIcons.map_fill, label: 'Map'),
    BottomNavItem(icon: CupertinoIcons.doc_text_fill, label: 'Projects'),
    BottomNavItem(icon: CupertinoIcons.book_fill, label: 'Learn'),
    BottomNavItem(icon: CupertinoIcons.chart_bar_alt_fill, label: 'Ranks'),
    BottomNavItem(icon: CupertinoIcons.person_fill, label: 'Profile'),
  ];
} 