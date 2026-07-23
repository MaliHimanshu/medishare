import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Reusable themed text field for MediShare
class MsTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputAction? textInputAction;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool readOnly;
  final bool autofocus;
  final int? maxLines;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;

  const MsTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.errorText,
    this.prefixIcon,
    this.suffix,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.validator,
    this.focusNode,
  });

  @override
  State<MsTextField> createState() => _MsTextFieldState();
}

class _MsTextFieldState extends State<MsTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller:         widget.controller,
          obscureText:        widget.isPassword ? _obscure : false,
          keyboardType:       widget.keyboardType,
          textInputAction:    widget.textInputAction,
          readOnly:           widget.readOnly,
          autofocus:          widget.autofocus,
          maxLines:           widget.isPassword ? 1 : widget.maxLines,
          focusNode:          widget.focusNode,
          onChanged:          widget.onChanged,
          onFieldSubmitted:   widget.onSubmitted,
          validator:          widget.validator,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.textPrimaryColor,
          ),
          decoration: InputDecoration(
            hintText:     widget.hint,
            errorText:    widget.errorText,
            prefixIcon:   widget.prefixIcon != null
                ? Icon(widget.prefixIcon, size: 20, color: context.textSecondaryColor)
                : null,
            suffixIcon:   widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20,
                      color: context.textSecondaryColor,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : widget.suffix,
          ),
        ),
      ],
    );
  }
}
