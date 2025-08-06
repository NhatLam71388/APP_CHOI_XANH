import 'package:flutter/material.dart';

class GlowingCard extends StatefulWidget {
  final Widget child;

  const GlowingCard({super.key, required this.child});

  @override
  State<GlowingCard> createState() => _GlowingCardState();
}

class _GlowingCardState extends State<GlowingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 5).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  LinearGradient _buildAnimatedGradient() {
    final start = Alignment.lerp(
      Alignment.topLeft,
      Alignment.bottomRight,
      _animation.value,
    );
    final end = Alignment.lerp(
      Alignment.topRight,
      Alignment.bottomLeft,
      _animation.value,
    );

    return LinearGradient(
      begin: start!,
      end: end!,
      colors: [
        Colors.red.withOpacity(0.2),
        Colors.transparent,
        Colors.red.withOpacity(0.2),
      ],
      stops: [0.0, 0.5, 1.0],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(3), // tạo khoảng viền nhỏ
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: _buildAnimatedGradient(),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10), // nhỏ hơn 1 cấp
              color: Colors.white, // nền trong
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}
