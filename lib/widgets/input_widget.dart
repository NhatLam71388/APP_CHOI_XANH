import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isPassword;
  final TextEditingController? controller;
  final int? maxline;
  final bool readOnly;
  final bool enable;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final String? hintText;
  final bool autofocus;
  final bool expands;
  final EdgeInsetsGeometry? contentPadding;

  const CustomTextField({
    Key? key,
    required this.label,
    this.icon,
    this.isPassword = false,
    this.controller,
    this.maxline,
    this.readOnly = false,
    this.enable = true,
    this.focusNode,
    this.nextFocusNode,
    this.onTap,
    this.validator,
    this.keyboardType,
    this.hintText,
    this.autofocus = false,
    this.expands = false,
    this.contentPadding,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField>
    with SingleTickerProviderStateMixin {
  bool _obscureText = true;
  bool _isFocused = false;
  bool _hasError = false;
  String? _errorText;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _borderColorAnimation;
  late Animation<Color?> _backgroundColorAnimation;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _borderColorAnimation = ColorTween(
      begin: const Color(0xFFE8F5E8),
      end: const Color(0xFF4CAF50),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _backgroundColorAnimation = ColorTween(
      begin: const Color(0xFFF1F8E9),
      end: const Color(0xFFE8F5E8),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Add focus listener
    widget.focusNode?.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (widget.focusNode?.hasFocus == true) {
      _animationController.forward();
      setState(() {
        _isFocused = true;
        _hasError = false;
        _errorText = null;
      });
    } else {
      _animationController.reverse();
      setState(() {
        _isFocused = false;
      });
      _validateField();
    }
  }

  void _validateField() {
    if (widget.validator != null && widget.controller?.text != null) {
      final validationResult = widget.validator!(widget.controller!.text);
      setState(() {
        _hasError = validationResult != null;
        _errorText = validationResult;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    widget.focusNode?.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final widthScreen = MediaQuery.of(context).size.width;
    double fontSize = widthScreen * 0.036;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: TextFormField(
              enabled: widget.enable,
              readOnly: widget.readOnly,
              controller: widget.controller,
              focusNode: widget.focusNode,
              maxLines: widget.maxline ?? 1,
              expands: widget.expands,
              autofocus: widget.autofocus,
              keyboardType: widget.keyboardType,
              textInputAction: widget.nextFocusNode != null
                  ? TextInputAction.next
                  : TextInputAction.done,
              onFieldSubmitted: (_) {
                if (widget.nextFocusNode != null) {
                  FocusScope.of(context).requestFocus(widget.nextFocusNode);
                } else {
                  FocusScope.of(context).unfocus();
                }
              },
              onChanged: (value) {
                if (_hasError) {
                  _validateField();
                }
              },
              obscureText: widget.isPassword ? _obscureText : false,
              validator: widget.validator,
              decoration: InputDecoration(
                hintText: widget.hintText ?? widget.label,
                hintStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: fontSize,
                  fontWeight: FontWeight.w400,
                ),
                labelText: widget.label,
                labelStyle: TextStyle(
                  color: _isFocused 
                      ? const Color(0xFF4CAF50)
                      : _hasError 
                          ? const Color(0xFFE57373)
                          : Colors.grey[600],
                  fontSize: fontSize * 0.9,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: widget.icon != null
                    ? AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          widget.icon,
                          color: _isFocused 
                              ? const Color(0xFF4CAF50)
                              : _hasError 
                                  ? const Color(0xFFE57373)
                                  : Colors.grey[600],
                          size: 22,
                        ),
                      )
                    : null,
                suffixIcon: widget.isPassword
                    ? IconButton(
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            _obscureText ? Icons.visibility_off : Icons.visibility,
                            key: ValueKey(_obscureText),
                            color: _isFocused 
                                ? const Color(0xFF4CAF50)
                                : Colors.grey[600],
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      )
                    : null,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: _hasError 
                        ? const Color(0xFFE57373)
                        : const Color(0xFFE8F5E8),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF4CAF50),
                    width: 3,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFE57373),
                    width: 2,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFE57373),
                    width: 3,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: _backgroundColorAnimation.value,
                contentPadding: widget.contentPadding ??
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                errorStyle: TextStyle(
                  color: const Color(0xFFE57373),
                  fontSize: fontSize * 0.8,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextStyle(
                color: widget.enable ? Colors.black87 : Colors.grey,
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: const Color(0xFF4CAF50),
              cursorWidth: 2,
              cursorRadius: const Radius.circular(2),
            ),
          ),
        );
      },
    );
  }
}

// Widget hiển thị lỗi validation
class ValidationErrorWidget extends StatelessWidget {
  final String errorText;
  final double fontSize;

  const ValidationErrorWidget({
    Key? key,
    required this.errorText,
    required this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: errorText.isNotEmpty ? 20 : 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: errorText.isNotEmpty ? 1.0 : 0.0,
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              size: fontSize * 0.8,
              color: const Color(0xFFE57373),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                errorText,
                style: TextStyle(
                  color: const Color(0xFFE57373),
                  fontSize: fontSize * 0.8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
