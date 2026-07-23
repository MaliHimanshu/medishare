import 'package:flutter/material.dart';

/// Production-grade animated shimmer skeleton loader.
/// Uses a horizontal sweep gradient for a premium loading effect.
class MsSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape shape;

  const MsSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  const MsSkeleton.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = null,
        shape = BoxShape.circle;

  @override
  State<MsSkeleton> createState() => _MsSkeletonState();
}

class _MsSkeletonState extends State<MsSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();

    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8);
    final shimmerColor = isDark ? const Color(0xFF3D3D3D) : const Color(0xFFF5F5F5);

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.circle
                ? null
                : (widget.borderRadius ?? BorderRadius.circular(12)),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.0, 0.5, 1.0],
              colors: [baseColor, shimmerColor, baseColor],
              transform: _SlidingGradientTransform(_shimmer.value),
            ),
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

/// Convenience widget for a full card-shaped skeleton
class MsCardSkeleton extends StatelessWidget {
  final double height;
  final double? width;

  const MsCardSkeleton({
    super.key,
    this.height = 120,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return MsSkeleton(
      width: width ?? double.infinity,
      height: height,
      borderRadius: BorderRadius.circular(16),
    );
  }
}

/// Skeleton for a list tile row (icon + two lines of text)
class MsListTileSkeleton extends StatelessWidget {
  const MsListTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          const MsSkeleton.circle(size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MsSkeleton(
                  width: double.infinity,
                  height: 14,
                  borderRadius: BorderRadius.circular(7),
                ),
                const SizedBox(height: 8),
                MsSkeleton(
                  width: 160,
                  height: 11,
                  borderRadius: BorderRadius.circular(5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
