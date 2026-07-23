import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class MSSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final int debounceMs;

  const MSSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Search equipment, hospitals, requests...',
    required this.onChanged,
    this.onClear,
    this.debounceMs = 300,
  });

  @override
  State<MSSearchBar> createState() => _MSSearchBarState();
}

class _MSSearchBarState extends State<MSSearchBar> {
  Timer? _debounceTimer;

  void _handleChanged(String value) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(Duration(milliseconds: widget.debounceMs), () {
      widget.onChanged(value);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      onChanged: _handleChanged,
      style: TextStyle(color: context.textPrimaryColor),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(color: context.textHintColor),
        prefixIcon: const Icon(Icons.search, color: AppColors.primary),
        suffixIcon: widget.controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  widget.controller.clear();
                  if (widget.onClear != null) {
                    widget.onClear!();
                  } else {
                    widget.onChanged('');
                  }
                },
              )
            : null,
        filled: true,
        fillColor: context.inputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: context.borderColor, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: context.borderColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
        ),
      ),
    );
  }
}
