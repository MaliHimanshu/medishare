import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class MSAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;

  const MSAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 24,
  });

  String get initial {
    if (name.trim().isEmpty) return 'U';
    return name.trim()[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primary.withAlpha(25),
        backgroundImage: NetworkImage(imageUrl!),
        onBackgroundImageError: (_, _) {},
        child: null,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withAlpha(25),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.9,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
