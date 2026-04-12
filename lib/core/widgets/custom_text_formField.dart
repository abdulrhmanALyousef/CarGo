import 'package:flutter/material.dart';

class CustomTextFormField extends StatefulWidget {
  const CustomTextFormField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.title,
    this.validator,
    this.maxLines = 1,
    this.suffix,
    this.suffixIcon,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController controller;
  final String title;
  final String hintText;
  final String? Function(String?)? validator;
  final int? maxLines;
  final Widget? suffix;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    final resolvedSuffixIcon = widget.suffixIcon ??
        (widget.obscureText
            ? IconButton(
                onPressed: () => setState(() => _isVisible = !_isVisible),
                icon: Icon(
                  _isVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFFAAAAAA),
                ),
              )
            : widget.suffix);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF222222),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          style: const TextStyle(fontSize: 14, color: Color(0xFF222222)),
          maxLines: widget.maxLines,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          obscureText: widget.obscureText && !_isVisible,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
            prefixIcon: widget.prefixIcon,
            filled: true,
            fillColor: const Color(0xFFF2F2F2),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF222222), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            suffixIcon: resolvedSuffixIcon,
          ),
        ),
      ],
    );
  }
}