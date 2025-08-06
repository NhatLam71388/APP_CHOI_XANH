import 'package:flutter/material.dart';
import 'package:flutter_application_1/view/search/search_page.dart';

class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final void Function(String)? onSearch;
  final TextEditingController controller;

  const SearchAppBar({
    super.key,
    required this.onSearch,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AppBar(
        backgroundColor: Color(0xFF198754),
        elevation: 0,
        leading: Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              Scaffold.of(context).openDrawer();
            },
            child: Container(
              margin: const EdgeInsets.only(
                  left: 20, top: 12, bottom: 12, right: 0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.menu, color: Colors.white),
            ),
          ),
        ),
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: TextField(
            controller: controller, // 👈 gắn controller
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                onSearch?.call(value);
              }
            },
            textAlignVertical: TextAlignVertical.center,
            decoration: const InputDecoration(
              hintText: 'Tìm kiếm sản phẩm...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
