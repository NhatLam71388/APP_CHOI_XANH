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

  const ItemCart({
    super.key,
    required this.isSelected,
    required this.item,
    this.onTap,
    this.onSelectedChanged,
    required this.cartitemCount,
    required this.userId,
    this.OnChanged,
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
    // Trigger scale animation
    _scaleController.forward().then((_) => _scaleController.reverse());

    if (widget.OnChanged != null) widget.OnChanged!();

    final total = await APICartService.getCartItemCountFromApi(Global.email);
    widget.cartitemCount.value = total;
  }

  Future<void> _removeItem() async {
    // Start fade out animation
    await _fadeController.forward();
    
    await APICartService.removeCartItem(
      context: context,
      cartitemCount: widget.cartitemCount,
      emailAddress: widget.userId,
      productId: widget.item.id.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isSelected 
                    ? const Color(0xFF198754).withOpacity(0.3)
                    : const Color(0xFF198754).withOpacity(0.1),
                  width: 1.5,
                ),
            boxShadow: [
              BoxShadow(
                    color: const Color(0xFF198754).withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(20),
                  splashColor: const Color(0xFF198754).withOpacity(0.1),
                  highlightColor: const Color(0xFF198754).withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image container với border và shadow + checkbox
                        Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF198754).withOpacity(0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF198754).withOpacity(0.05),
                                  ),
                                  child: Image.network(
                                    widget.item.image,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF198754).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 40,
                                        color: const Color(0xFF198754).withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Checkbox dưới hình ảnh
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => widget.onSelectedChanged?.call(!widget.isSelected),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: widget.isSelected 
                                      ? const Color(0xFF198754) 
                                      : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: widget.isSelected 
                                        ? const Color(0xFF198754) 
                                        : Colors.grey.withOpacity(0.5),
                                      width: 2,
                                    ),
                                  ),
                                  child: widget.isSelected
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                    const SizedBox(width: 16),
                    
                        // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                              // Title
                          Text(
                            widget.item.name ?? 'Không có tên',
                            style: const TextStyle(
                              fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1a1a1a),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          
                              // Price
                          Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                  color: const Color(0xFF198754).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF198754).withOpacity(0.3),
                                    width: 1,
                                  ),
                            ),
                            child: Text(
                              '${formatCurrency(widget.item.price)}₫',
                              style: const TextStyle(
                                    color: Color(0xFF198754),
                                    fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                              // Action buttons
                          Row(
                            children: [
                                  // Quantity controls button
                                  Expanded(
                                    child: Container(
                                height: 36,
                                decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            const Color(0xFF198754),
                                            const Color(0xFF20C997),
                                          ],
                                        ),
                                  borderRadius: BorderRadius.circular(18),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF198754).withOpacity(0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                child: Row(
                                  children: [
                                    // Decrease Button
                                            Expanded(
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
                                          height: 36,
                                          child: Icon(
                                            Icons.remove,
                                                    size: 16,
                                            color: widget.item.quantity > 1 
                                                      ? Colors.white 
                                                      : Colors.white.withOpacity(0.5),
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
                                                        fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                        color: Colors.white,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    
                                    // Increase Button
                                            Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          _updateQuantity(widget.item.quantity + 1);
                                        },
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(18),
                                          bottomRight: Radius.circular(18),
                                        ),
                                        child: Container(
                                          height: 36,
                                          child: const Icon(
                                            Icons.add,
                                                    size: 16,
                                                    color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Remove button
                                  Container(
                                    height: 36,
                                    width: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: Colors.red.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _removeItem,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Colors.red,
                                        elevation: 0,
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: Colors.red,
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
          ],
        ),
      ),
    );
  }
}
