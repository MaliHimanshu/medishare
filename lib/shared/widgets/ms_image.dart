import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class MsImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData placeholderIcon;

  const MsImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderIcon = Icons.volunteer_activism,
  });

  @override
  Widget build(BuildContext context) {
    final border = borderRadius ?? BorderRadius.circular(12);

    Widget imageWidget;

    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      imageWidget = _buildPlaceholder();
    } else {
      final url = imageUrl!.trim();

      if (url.startsWith('http://') || url.startsWith('https://')) {
        imageWidget = Image.network(
          url,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: width,
              height: height,
              color: AppColors.primary.withAlpha(15),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            );
          },
        );
      } else if (url.startsWith('data:image')) {
        try {
          final base64Str = url.split(',').last;
          final bytes = base64Decode(base64Str);
          imageWidget = Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          );
        } catch (_) {
          imageWidget = _buildPlaceholder();
        }
      } else {
        // Local File Path
        final file = File(url.replaceFirst('file://', ''));
        if (file.existsSync()) {
          imageWidget = Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          );
        } else {
          imageWidget = _buildPlaceholder();
        }
      }
    }

    return ClipRRect(
      borderRadius: border,
      child: SizedBox(
        width: width,
        height: height,
        child: imageWidget,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.primary.withAlpha(20),
      child: Center(
        child: Icon(
          placeholderIcon,
          color: AppColors.primary,
          size: (height != null && height! < 60) ? 24 : 40,
        ),
      ),
    );
  }
}
