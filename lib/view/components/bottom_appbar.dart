import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int cartitemCount;
  final int wishlistItemCount;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.cartitemCount,
    required this.wishlistItemCount,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: Color(0xff0066FF),
      unselectedItemColor: Color(0xff0066FF),
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700),
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: ImageIcon(
            currentIndex == 0 ? AssetImage('asset/homesl.png') : AssetImage('asset/home.png'),
            size: 24,
          ),
          label: 'Trang chủ',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: 26,
                height: 26,
                child: ImageIcon(
                  currentIndex == 1 ? AssetImage('asset/favouritesl.png') : AssetImage('asset/favourite.png'),
                  size: 24,
                ),
              ),
              if (wishlistItemCount > 0)
                Positioned(
                  right: -8,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$wishlistItemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          label: 'Yêu thích',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: 26,
                height: 26,
                child: ImageIcon(
                  currentIndex == 2 ? AssetImage('asset/cartsl.png') : AssetImage('asset/shopping-cart.png'),
                  size: 26,
                ),
              ),
              if (cartitemCount > 0)
                Positioned(
                  right: -8,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$cartitemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          label: 'Giỏ hàng',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(
            currentIndex == 3 ? AssetImage('asset/usersl.png') : AssetImage('asset/user.png'),
            size: 24,
          ),
          label: 'Tài khoản',
        ),
      ],
    );
  }
}