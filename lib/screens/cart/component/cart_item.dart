import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/product_model.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/services/cart_service.dart';
import 'package:flutter_application_1/widgets/until.dart';

import '../../../Controller/home.dart';

class ItemCart extends StatefulWidget {
  final bool isSelected;
  final CartItemModel item;
  final VoidCallback? onTap;
  final ValueChanged<bool?>? onSelectedChanged;
  final ValueNotifier<int> cartitemCount;
  final String userId;
  final VoidCallback? OnChanged;
  final Function(String)? onItemRemoved;

  const ItemCart({
    super.key,
    required this.isSelected,
    required this.item,
    this.onTap,
    this.onSelectedChanged,
    required this.cartitemCount,
    required this.userId,
    this.OnChanged,
    this.onItemRemoved,
    required Future<Null> Function() onDecrease,
    required Future<Null> Function() onIncrease,
  });

  @override
  State<ItemCart> createState() => _ItemCartState();
}

class _ItemCartState extends State<ItemCart> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    
    // Scale animation for quantity changes
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Fade animation for item removal
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Slide animation for item entry
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _slideController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _updateQuantity(int newQuantity) async {
    try {
      // Trigger scale animation
      _scaleController.forward().then((_) {
        if (mounted) _scaleController.reverse();
      });

      // Update local quantity immediately for smooth UI
      widget.item.quantity = newQuantity;

      // Update cart count from server
      final total = await APICartService.getCartItemCountFromApi(Global.email);
      widget.cartitemCount.value = total;
      
      // Note: Số lượng chỉ được lưu trên server khi đặt hàng
      // Hiện tại chỉ cập nhật local state để UI mượt hơn
      
    } catch (e) {
      showToast('Lỗi khi cập nhật: $e', backgroundColor: Colors.red);
    }
  }

  Future<void> _removeItem() async {
    try {
      // Show confirmation dialog first
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Xác nhận'),
            content: const Text('Bạn có chắc chắn muốn xóa sản phẩm này khỏi giỏ hàng?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      );

      if (confirmed != true) return;

      // Start fade out animation
      _fadeController.forward();
      
      final success = await APICartService.removeCartItem(
        context: context,
        cartitemCount: widget.cartitemCount,
        emailAddress: widget.userId,
        productId: widget.item.id.toString(),
      );

      if (success) {
        showToast('Đã xóa sản phẩm khỏi giỏ hàng', backgroundColor: Colors.green);
        
        // Xóa item khỏi UI ngay lập tức để tránh animation conflict
        if (widget.onItemRemoved != null && mounted) {
          widget.onItemRemoved!(widget.item.id.toString());
        }
        
        // Delay callback to allow animation to complete
        await Future.delayed(const Duration(milliseconds: 300));
        if (widget.OnChanged != null && mounted) {
          widget.OnChanged!();
        }
      } else {
        showToast('Xóa sản phẩm thất bại', backgroundColor: Colors.red);
        // Reverse animation if removal failed
        if (mounted) {
          _fadeController.reverse();
        }
      }
    } catch (e) {
      showToast('Lỗi khi xóa sản phẩm: $e', backgroundColor: Colors.red);
      if (mounted) {
        _fadeController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.green.withOpacity(0.05),
                blurRadius: 1,
                offset: const Offset(0, 1),
                spreadRadius: 0,
              ),
            ],
            border: Border.all(
              color: widget.isSelected 
                ? Colors.green.withOpacity(0.3) 
                : Colors.grey.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enhanced Checkbox with green theme
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isSelected 
                          ? Colors.green.withOpacity(0.1) 
                          : Colors.transparent,
                      ),
                      child: Checkbox(
                        value: widget.isSelected,
                        onChanged: widget.onSelectedChanged,
                        activeColor: Colors.green,
                        checkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: BorderSide(
                          color: widget.isSelected 
                            ? Colors.green 
                            : Colors.grey.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Enhanced Product Image
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.item.image,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey.withOpacity(0.5),
                                size: 30,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Enhanced Product Title
                          Text(
                            widget.item.name ?? 'Không có tên',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Enhanced Price Display
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${formatCurrency(widget.item.price)}₫',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Enhanced Quantity Controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Quantity Controls
                              Container(
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Decrease Button
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          if (widget.item.quantity > 1) {
                                            _updateQuantity(widget.item.quantity - 1);
                                          }
                                        },
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(18),
                                          bottomLeft: Radius.circular(18),
                                        ),
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: widget.item.quantity > 1 
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.grey.withOpacity(0.1),
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(18),
                                              bottomLeft: Radius.circular(18),
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.remove,
                                            size: 18,
                                            color: widget.item.quantity > 1 
                                              ? Colors.green 
                                              : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    // Quantity Display
                                    Container(
                                      width: 40,
                                      height: 36,
                                      alignment: Alignment.center,
                                      child: AnimatedBuilder(
                                        animation: _scaleAnimation,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: _scaleAnimation.value,
                                            child: Text(
                                              '${widget.item.quantity}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1A1A1A),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    
                                    // Increase Button
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          _updateQuantity(widget.item.quantity + 1);
                                        },
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(18),
                                          bottomRight: Radius.circular(18),
                                        ),
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.1),
                                            borderRadius: const BorderRadius.only(
                                              topRight: Radius.circular(18),
                                              bottomRight: Radius.circular(18),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            size: 18,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Remove Button
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _removeItem,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.red.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.delete_outline,
                                          size: 16,
                                          color: Colors.red.withOpacity(0.8),

                                        ),
                                        const SizedBox(width: 4),

                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
