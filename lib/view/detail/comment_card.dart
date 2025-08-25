import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;

import '../../services/api_service.dart';

// Color scheme - Green theme
class CommentColors {
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color darkGreen = Color(0xFF388E3C);
  static const Color accentGreen = Color(0xFF66BB6A);
  static const Color backgroundGreen = Color(0xFFE8F5E8);
  static const Color surfaceGreen = Color(0xFFF1F8E9);
}

class CommentCard extends StatefulWidget {
  final String nguoidang;
  final String ngaydang;
  final String rating;
  final String soluongthich;
  final String noidung;
  final String hinhdaidien;
  final List<dynamic> replies;
  final String productId;
  final String commentId;
  final Function(String newLikeCount)? onLikeUpdated;
  final Function()? onReplySubmitted;

  const CommentCard({
    super.key,
    required this.nguoidang,
    required this.ngaydang,
    required this.rating,
    required this.soluongthich,
    required this.noidung,
    this.hinhdaidien = '',
    this.replies = const [],
    required this.productId,
    required this.commentId,
    this.onLikeUpdated,
    this.onReplySubmitted,
  });

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard>
    with TickerProviderStateMixin {
  bool _showReplyForm = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSubmittingReply = false;
  bool _isLiked = true;
  bool _showReplies = false;

  // Animation controllers
  late AnimationController _cardAnimationController;
  late AnimationController _formAnimationController;
  late AnimationController _likeAnimationController;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _formHeightAnimation;
  late Animation<double> _likeScaleAnimation;
  late Animation<Color?> _likeColorAnimation;

  // Color scheme - Green theme
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color darkGreen = Color(0xFF388E3C);
  static const Color accentGreen = Color(0xFF66BB6A);
  static const Color backgroundGreen = Color(0xFFE8F5E8);
  static const Color surfaceGreen = Color(0xFFF1F8E9);

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Setup animations
    _cardScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.elasticOut,
    ));

    _formHeightAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _formAnimationController,
      curve: Curves.easeInOut,
    ));

    _likeScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _likeAnimationController,
      curve: Curves.elasticOut,
    ));

    _likeColorAnimation = ColorTween(
      begin: Colors.grey[400],
      end: Colors.red,
    ).animate(CurvedAnimation(
      parent: _likeAnimationController,
      curve: Curves.easeInOut,
    ));

    // Start card entrance animation
    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _formAnimationController.dispose();
    _likeAnimationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // Hàm xử lý like comment với animation
  Future<void> _handleLikeComment() async {
    // Trigger like animation
    _likeAnimationController.forward().then((_) {
      _likeAnimationController.reverse();
    });

    try {
      final response = await http.get(
        Uri.parse('https://demochung.125.atoz.vn/ww1/save.binhluan.thich.asp?id=${widget.productId}&id2=${widget.commentId}'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse.isNotEmpty && jsonResponse[0] is Map) {
          final result = jsonResponse[0] as Map<String, dynamic>;
          
          if (result['maloi'] == '1') {
            final newLikeCount = result['soluongthich'] ?? widget.soluongthich;
            if (widget.onLikeUpdated != null) {
              widget.onLikeUpdated!(newLikeCount.toString());
            }
            print('✅ Like thành công! Số lượng thích mới: $newLikeCount');
          } else {
            print('❌ Like thất bại: ${result['ThongBao']}');
          }
        }
      } else {
        print('❌ Lỗi HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Lỗi khi like comment: $e');
    }
  }

  // Hàm xử lý gửi reply
  Future<void> _handleSubmitReply() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng nhập nội dung phản hồi'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingReply = true;
    });

    try {
      final formData = {
        'tenkh': _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : '',
        'txtemail': _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : '',
        'txtdienthoai': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : '',
        'noidungtxt': _contentController.text.trim(),
        'id2': '5',
        'id3': '/dist/images/user.jpg',
        'l': widget.commentId,
      };

      final response = await http.post(
        Uri.parse('https://demochung.125.atoz.vn/ww1/save.binhluan.asp'),
        body: formData,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse.isNotEmpty && jsonResponse[0] is Map) {
          final result = jsonResponse[0] as Map<String, dynamic>;
          
          if (result['maloi'] == '1') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Gửi phản hồi thành công!'),
                backgroundColor: primaryGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );

            setState(() {
              _showReplyForm = false;
              _nameController.clear();
              _emailController.clear();
              _phoneController.clear();
              _contentController.clear();
            });
            
            if (widget.onReplySubmitted != null) {
              widget.onReplySubmitted!();
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gửi phản hồi thất bại: ${result['ThongBao']}'),
                backgroundColor: Colors.red[400],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Lỗi kết nối, vui lòng thử lại'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      print('❌ Lỗi khi gửi reply: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lỗi kết nối, vui lòng thử lại'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      setState(() {
        _isSubmittingReply = false;
      });
    }
  }

  // Hàm toggle hiển thị replies
  void _toggleReplies() {
    setState(() {
      _showReplies = !_showReplies;
    });
  }

  // Hàm toggle hiển thị form reply với animation
  void _toggleReplyForm() {
    setState(() {
      _showReplyForm = !_showReplyForm;
      if (_showReplyForm) {
        _formAnimationController.forward();
      } else {
        _formAnimationController.reverse();
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _contentController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _cardScaleAnimation,
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, surfaceGreen],
            ),
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Phần bình luận chính
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    // Ảnh đại diện với border gradient
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [primaryGreen, accentGreen],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryGreen.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(2),
                      child: CircleAvatar(
                        radius: 24,
                    backgroundImage: widget.hinhdaidien.isNotEmpty
                            ? NetworkImage('${APIService.baseUrl}${widget.hinhdaidien}')
                        : null,
                        backgroundColor: backgroundGreen,
                    child: widget.hinhdaidien.isEmpty
                            ? Icon(Icons.person, size: 24, color: primaryGreen)
                        : null,
                  ),
                    ),
                    const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tên người đăng và ngày đăng
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [primaryGreen, accentGreen],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                              widget.nguoidang.isNotEmpty ? widget.nguoidang : 'Khách',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                              widget.ngaydang,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                              ),
                            ),
                          ],
                        ),
                          const SizedBox(height: 12),
                          // Đánh giá với animation
                        RatingBarIndicator(
                            rating: double.tryParse(widget.rating) ?? 0 / 20,
                          itemBuilder: (context, _) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          itemCount: 5,
                            itemSize: 22.0,
                          direction: Axis.horizontal,
                        ),
                          const SizedBox(height: 12),
                          // Nội dung bình luận - chỉ hiển thị khi có nội dung
                          if (widget.noidung.trim().isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: lightGreen.withOpacity(0.3)),
                                boxShadow: [
                                  BoxShadow(
                                    color: lightGreen.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                          widget.noidung,
                          style: const TextStyle(
                                  fontSize: 15,
                            color: Colors.black87,
                                  height: 1.4,
                          ),
                        ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        // Lượt thích và nút trả lời
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                              // Nút like với animation
                              AnimatedBuilder(
                                animation: _likeAnimationController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _likeScaleAnimation.value,
                                    child: GestureDetector(
                              onTap: () async {
                                await _handleLikeComment();
                              },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.red[50],
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.red[300]!,
                                            width: 1.5,
                                          ),
                                        ),
                              child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                children: [
                                            Icon(
                                              Icons.favorite,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 6),
                                  Text(
                                    widget.soluongthich,
                                              style: TextStyle(
                                      fontSize: 14,
                                                color: Colors.red[700],
                                                fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                                    ),
                                  );
                                },
                              ),
                              // Nút trả lời với gradient
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _showReplyForm
                                        ? [Colors.red[400]!, Colors.red[600]!]
                                        : [primaryGreen, accentGreen],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_showReplyForm ? Colors.red : primaryGreen).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _toggleReplyForm,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                _showReplyForm ? Icons.close : Icons.reply,
                                            size: 18,
                                            color: Colors.white,
                              ),
                                          const SizedBox(width: 6),
                                          Text(
                                _showReplyForm ? 'Đóng' : 'Trả lời',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
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
                      ],
                    ),
                  ),
                ],
              ),
              
              // Phần hiển thị replies nếu có
              if (widget.replies.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, lightGreen.withOpacity(0.5), Colors.transparent],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                  // Header cho replies với nút toggle
                  GestureDetector(
                    onTap: _toggleReplies,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [backgroundGreen, surfaceGreen],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: lightGreen.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                  children: [
                          Icon(
                            _showReplies ? Icons.expand_less : Icons.expand_more,
                            size: 18,
                            color: primaryGreen,
                          ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.replies.length} phản hồi',
                            style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                              color: primaryGreen,
                      ),
                    ),
                  ],
                ),
                    ),
                  ),
                  // Danh sách replies - chỉ hiển thị khi _showReplies = true
                  if (_showReplies) ...[
                    const SizedBox(height: 16),
                ...widget.replies.map((reply) => ReplyCard(
                  nguoidang: reply['nguoidang'] ?? 'Khách',
                  ngaydang: reply['ngaydang'] ?? '',
                  rating: reply['rating'] ?? '0',
                  soluongthich: reply['soluongthich'] ?? '0',
                  noidung: reply['noidung'] ?? '',
                  hinhdaidien: reply['hinhdaidien'] ?? '',
                      productId: widget.productId,
                      replyId: reply['id'] ?? '',
                  onLikeUpdated: (String newLikeCount) {
                    reply['soluongthich'] = newLikeCount;
                    if (widget.onLikeUpdated != null) {
                          widget.onLikeUpdated!(widget.soluongthich);
                    }
                  },
                )),
                  ],
                ],

                // Form reply với animation
                AnimatedBuilder(
                  animation: _formAnimationController,
                  builder: (context, child) {
                    return SizeTransition(
                      sizeFactor: _formHeightAnimation,
                      child: _showReplyForm
                          ? Container(
                              margin: const EdgeInsets.only(top: 20),
                              padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [backgroundGreen, surfaceGreen],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: lightGreen.withOpacity(0.5)),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryGreen.withOpacity(0.1),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: primaryGreen,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.reply,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                            const Text(
                              'Trả lời bình luận',
                              style: TextStyle(
                                          fontSize: 16,
                                fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                                  const SizedBox(height: 20),
                                  // Form fields với thiết kế đẹp
                        Row(
                          children: [
                            Expanded(
                                        child: _buildFormField(
                                controller: _nameController,
                                          label: 'Tên',
                                          hint: 'Nhập tên của bạn',
                                          icon: Icons.person,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                            Expanded(
                                        child: _buildFormField(
                                controller: _emailController,
                                          label: 'Email',
                                          hint: 'Nhập email của bạn',
                                          icon: Icons.email,
                              ),
                            ),
                          ],
                        ),
                                  const SizedBox(height: 16),
                                  _buildFormField(
                          controller: _phoneController,
                                    label: 'Số điện thoại',
                                    hint: 'Nhập số điện thoại của bạn',
                                    icon: Icons.phone,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildFormField(
                          controller: _contentController,
                                    label: 'Nội dung phản hồi',
                                    hint: 'Nhập nội dung phản hồi...',
                                    icon: Icons.comment,
                          maxLines: 3,
                        ),
                                  const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _isSubmittingReply ? null : _toggleReplyForm,
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.grey[600],
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        ),
                              child: const Text('Hủy'),
                            ),
                                      const SizedBox(width: 12),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [primaryGreen, accentGreen],
                                          ),
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: primaryGreen.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                              onPressed: _isSubmittingReply ? null : _handleSubmitReply,
                              style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                              ),
                              child: _isSubmittingReply
                                  ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                              : const Text(
                                                  'Gửi phản hồi',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                        ),
                            ),
                          ],
                        ),
                      ],
                    ),
                            )
                          : const SizedBox.shrink(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lightGreen.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: lightGreen.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: primaryGreen, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: TextStyle(color: primaryGreen),
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
      ),
    );
  }
}

// Widget ReplyCard với thiết kế mới
class ReplyCard extends StatefulWidget {
  final String nguoidang;
  final String ngaydang;
  final String rating;
  final String soluongthich;
  final String noidung;
  final String hinhdaidien;
  final String productId;
  final String replyId;
  final Function(String newLikeCount)? onLikeUpdated;

  const ReplyCard({
    super.key,
    required this.nguoidang,
    required this.ngaydang,
    required this.rating,
    required this.soluongthich,
    required this.noidung,
    this.hinhdaidien = '',
    required this.productId,
    required this.replyId,
    this.onLikeUpdated,
  });

  @override
  State<ReplyCard> createState() => _ReplyCardState();
}

class _ReplyCardState extends State<ReplyCard>
    with SingleTickerProviderStateMixin {
  bool _isLiked = true;
  late AnimationController _likeController;
  late Animation<double> _likeScaleAnimation;

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _likeScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _likeController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  Future<void> _handleLikeReply() async {
    _likeController.forward().then((_) {
      _likeController.reverse();
    });

    try {
      final response = await http.get(
        Uri.parse('https://demochung.125.atoz.vn/ww1/save.binhluan.thich.asp?id=${widget.productId}&id2=${widget.replyId}'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse.isNotEmpty && jsonResponse[0] is Map) {
          final result = jsonResponse[0] as Map<String, dynamic>;
          
          if (result['maloi'] == '1') {
            final newLikeCount = result['soluongthich'] ?? widget.soluongthich;
            if (widget.onLikeUpdated != null) {
              widget.onLikeUpdated!(newLikeCount.toString());
            }
            print('✅ Like reply thành công! Số lượng thích mới: $newLikeCount');
          } else {
            print('❌ Like reply thất bại: ${result['ThongBao']}');
          }
        }
      } else {
        print('❌ Lỗi HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Lỗi khi like reply: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 40, top: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, CommentColors.surfaceGreen.withOpacity(0.3)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CommentColors.lightGreen.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: CommentColors.primaryGreen.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [CommentColors.accentGreen, CommentColors.lightGreen],
                ),
              ),
              padding: const EdgeInsets.all(1.5),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: widget.hinhdaidien.isNotEmpty
                    ? NetworkImage('${APIService.baseUrl}${widget.hinhdaidien}')
                : null,
                backgroundColor: CommentColors.backgroundGreen,
                child: widget.hinhdaidien.isEmpty
                    ? Icon(Icons.person, size: 18, color: CommentColors.primaryGreen)
                : null,
          ),
            ),
            const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: CommentColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.nguoidang.isNotEmpty ? widget.nguoidang : 'Khách',
                          style: TextStyle(
                        fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: CommentColors.primaryGreen,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.ngaydang,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                      ),
                    ),
                  ],
                ),
                  const SizedBox(height: 8),
                RatingBarIndicator(
                    rating: double.tryParse(widget.rating) ?? 0 / 20,
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  itemCount: 5,
                  itemSize: 16.0,
                  direction: Axis.horizontal,
                ),
                  const SizedBox(height: 8),
                  // Nội dung reply - chỉ hiển thị khi có nội dung
                  if (widget.noidung.trim().isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: CommentColors.lightGreen.withOpacity(0.2)),
                      ),
                      child: Text(
                        widget.noidung,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  AnimatedBuilder(
                    animation: _likeController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _likeScaleAnimation.value,
                        child: GestureDetector(
                  onTap: () async {
                    await _handleLikeReply();
                  },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.red[300]!,
                                width: 1,
                              ),
                            ),
                  child: Row(
                              mainAxisSize: MainAxisSize.min,
                    children: [
                                Icon(
                                  Icons.favorite,
                                  color: Colors.red,
                                  size: 16,
                                ),
                      const SizedBox(width: 4),
                      Text(
                                  widget.soluongthich,
                                  style: TextStyle(
                          fontSize: 12,
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                          ),
                        ),
                      );
                    },
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}