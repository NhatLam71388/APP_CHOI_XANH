import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatefulWidget {
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
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar>
    with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _bounceAnimations;

  // Màu xanh lá chủ đạo
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color accentGreen = Color(0xFF66BB6A);
  static const Color darkGreen = Color(0xFF1B5E20);

  @override
  void initState() {
    super.initState();
    _animationControllers = List.generate(4, (index) => 
      AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      )
    );

    _scaleAnimations = _animationControllers.map((controller) =>
      Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut)
      )
    ).toList();

    _bounceAnimations = _animationControllers.map((controller) =>
      Tween<double>(begin: 0.0, end: -8.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut)
      )
    ).toList();

    // Trigger animation for current index
    if (widget.currentIndex < _animationControllers.length) {
      _animationControllers[widget.currentIndex].forward();
    }
  }

  @override
  void didUpdateWidget(CustomBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      // Reset old animation
      if (oldWidget.currentIndex < _animationControllers.length) {
        _animationControllers[oldWidget.currentIndex].reverse();
      }
      // Start new animation
      if (widget.currentIndex < _animationControllers.length) {
        _animationControllers[widget.currentIndex].forward();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildAnimatedIcon({
    required int index,
    required String selectedAsset,
    required String unselectedAsset,
    required double size,
  }) {
    return AnimatedBuilder(
      animation: _animationControllers[index],
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimations[index].value),
          child: Transform.scale(
            scale: _scaleAnimations[index].value,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.currentIndex == index 
                    ? lightGreen.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: widget.currentIndex == index
                    ? Border.all(color: lightGreen.withOpacity(0.3), width: 1)
                    : null,
              ),
              child: ImageIcon(
                widget.currentIndex == index 
                    ? AssetImage(selectedAsset) 
                    : AssetImage(unselectedAsset),
                size: size,
                color: widget.currentIndex == index ? primaryGreen : Colors.grey[600],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge({
    required int count,
    required Color badgeColor,
  }) {
    return count > 0 
        ? AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.elasticOut,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: badgeColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(
              minWidth: 18,
              minHeight: 18,
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          )
        : const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          currentIndex: widget.currentIndex,
          onTap: (index) {
            widget.onTap(index);
            // Trigger haptic feedback
            // HapticFeedback.lightImpact();
          },
          selectedItemColor: primaryGreen,
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(
                index: 0,
                selectedAsset: 'asset/homesl.png',
                unselectedAsset: 'asset/home.png',
                size: 24,
              ),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildAnimatedIcon(
                    index: 1,
                    selectedAsset: 'asset/favouritesl.png',
                    unselectedAsset: 'asset/favourite.png',
                    size: 24,
                  ),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: _buildBadge(
                      count: widget.wishlistItemCount,
                      badgeColor: const Color(0xFFE91E63),
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
                  _buildAnimatedIcon(
                    index: 2,
                    selectedAsset: 'asset/cartsl.png',
                    unselectedAsset: 'asset/shopping-cart.png',
                    size: 26,
                  ),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: _buildBadge(
                      count: widget.cartitemCount,
                      badgeColor: const Color(0xFFFF5722),
                    ),
                  ),
                ],
              ),
              label: 'Giỏ hàng',
            ),
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(
                index: 3,
                selectedAsset: 'asset/usersl.png',
                unselectedAsset: 'asset/user.png',
                size: 24,
              ),
              label: 'Tài khoản',
            ),
          ],
        ),
      ),
    );
  }
}