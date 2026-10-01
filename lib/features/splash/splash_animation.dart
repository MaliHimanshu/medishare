import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class MediShareSplashAnimation extends StatelessWidget {
  final AnimationController controller;
  final bool isDark;

  const MediShareSplashAnimation({
    super.key,
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = controller.value; // 0.0 to 1.0 (9s duration)

        // --- TIMINGS & SMOOTH INTERPOLATION ---

        // 1. ECG Phase (0.0s - 2.5s)
        final ecgDrawProgress = (t / 0.20).clamp(0.0, 1.0);
        final ecgOpacity = 1.0 - ((t - 0.20) / 0.07).clamp(0.0, 1.0);

        // 2. Pill Appearance Phase (2.5s - 3.5s)
        final pillProgress = ((t - 0.25) / 0.11).clamp(0.0, 1.0);
        final curvedPillScale = Curves.easeOutCubic.transform(pillProgress);

        // 3. Pill Split & Cross Phase (3.5s - 5.0s)
        final splitProgress = ((t - 0.38) / 0.16).clamp(0.0, 1.0);
        final curvedSplit = Curves.easeInOutCubic.transform(splitProgress);
        final verticalOffset = curvedSplit * 24.0; // Distance to separate

        // Crossbar expands horizontally ONLY after split begins (around 4.0s)
        final crossbarProgress = ((t - 0.44) / 0.11).clamp(0.0, 1.0);
        final curvedCrossbar = Curves.easeOutCubic.transform(crossbarProgress);
        final crossbarWidth = 36.0 + (curvedCrossbar * 52.0);
        final crossbarOpacity = curvedCrossbar > 0 ? 1.0 : 0.0;

        // Center Dot appears precisely when crossbar is fully expanded (4.8s - 5.0s)
        final dotProgress = ((t - 0.53) / 0.05).clamp(0.0, 1.0);
        final dotOpacity = Curves.easeIn.transform(dotProgress);

        // 4. Ripple Phase (5.0s - 6.5s)
        final rippleProgress = ((t - 0.55) / 0.16).clamp(0.0, 1.0);

        // 5. Text & Slide Phase (6.5s - 8.0s)
        final slideProgress = ((t - 0.72) / 0.16).clamp(0.0, 1.0);
        final curvedSlide = Curves.easeInOutCubic.transform(slideProgress);
        final globalOffsetX =
            curvedSlide * -85.0; // Slide left exactly 85 points
        final textOpacity = Curves.easeIn.transform(slideProgress);

        // 6. Text Shimmer Phase (8.0s - 9.0s)
        final shimmerProgress = ((t - 0.88) / 0.12).clamp(0.0, 1.0);

        // Colors
        final topPillColor = const Color(0xFF0C2340); // Dark Blue
        final bottomPillColor = AppColors.primary; // Bright Blue
        final tealColor = AppColors.accent;

        return LayoutBuilder(
          builder: (context, constraints) {
            final centerX = constraints.maxWidth / 2;
            final centerY = constraints.maxHeight / 2;

            // Base positions based on center and globalOffsetX
            final baseLogoX = centerX + globalOffsetX;

            // Text exact position
            final textX = baseLogoX + 45 + (1 - curvedSlide) * 30;
            final textY = centerY - 28;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. ECG Line
                if (ecgDrawProgress > 0 && ecgOpacity > 0)
                  Positioned.fill(
                    child: Opacity(
                      opacity: ecgOpacity,
                      child: CustomPaint(
                        painter: _EcgPainter(
                          progress: ecgDrawProgress,
                          color: const Color(0xFF00E5FF),
                        ),
                      ),
                    ),
                  ),

                // 2. BLUE PILL COMPONENTS
                if (curvedPillScale > 0) ...[
                  // Top Half
                  Positioned(
                    left: baseLogoX - (18 * curvedPillScale),
                    top: centerY - (52 * curvedPillScale) - verticalOffset,
                    width: 36 * curvedPillScale,
                    height: 52 * curvedPillScale,
                    child: Container(
                      decoration: BoxDecoration(
                        color: topPillColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(18 * curvedPillScale),
                          topRight: Radius.circular(18 * curvedPillScale),
                        ),
                      ),
                    ),
                  ),
                  // Bottom Half
                  Positioned(
                    left: baseLogoX - (18 * curvedPillScale),
                    top: centerY + verticalOffset,
                    width: 36 * curvedPillScale,
                    height: 52 * curvedPillScale,
                    child: Container(
                      decoration: BoxDecoration(
                        color: bottomPillColor,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(18 * curvedPillScale),
                          bottomRight: Radius.circular(18 * curvedPillScale),
                        ),
                      ),
                    ),
                  ),
                ],

                // 3. TEAL CROSSBAR
                if (crossbarOpacity > 0)
                  Positioned(
                    left: baseLogoX - (crossbarWidth / 2),
                    top: centerY - 18,
                    width: crossbarWidth,
                    height: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        color: tealColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),

                // 4. CENTER DOT
                if (dotOpacity > 0)
                  Positioned(
                    left: baseLogoX - 4,
                    top: centerY - 4,
                    width: 8,
                    height: 8,
                    child: Opacity(
                      opacity: dotOpacity,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF111827),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),

                // 5. RIPPLE
                if (rippleProgress > 0 && rippleProgress < 1.0)
                  ...List.generate(3, (index) {
                    final delay = index * 0.2;
                    final rProgress =
                        (rippleProgress - delay).clamp(0.0, 1.0) /
                        (1.0 - delay);
                    if (rProgress <= 0 || rProgress >= 1)
                      return const SizedBox.shrink();

                    final currentScale = 1.0 + rProgress * 6.0;
                    final rippleSize = 60 * currentScale;

                    return Positioned(
                      left: baseLogoX - (rippleSize / 2),
                      top: centerY - (rippleSize / 2),
                      width: rippleSize,
                      height: rippleSize,
                      child: Opacity(
                        opacity: (1.0 - rProgress) * 0.5,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: tealColor, width: 2),
                          ),
                        ),
                      ),
                    );
                  }),

                // 6. MEDISHARE TEXT & 7. TEXT SHIMMER
                if (textOpacity > 0)
                  Positioned(
                    left: textX,
                    top: textY,
                    child: Opacity(
                      opacity: textOpacity,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 70.0),
                        child: _buildShimmerText(shimmerProgress),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildShimmerText(double shimmerProgress) {
    final textColor = isDark ? Colors.white : AppColors.textPrimary;

    final textWidget = RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Medi',
            style: TextStyle(
              color: textColor,
              fontSize: 46,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
          ),
          TextSpan(
            text: 'Share',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 46,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
          ),
        ],
      ),
    );

    if (shimmerProgress <= 0.0 || shimmerProgress >= 1.0) {
      return textWidget;
    }

    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        if (bounds.width == 0 || bounds.height == 0) {
          return const LinearGradient(
            colors: [Colors.transparent, Colors.transparent],
          ).createShader(bounds);
        }
        return LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withAlpha(200),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment(-2.0 + (shimmerProgress * 4.0), 0.0),
          end: Alignment(-1.0 + (shimmerProgress * 4.0), 0.0),
        ).createShader(bounds);
      },
      child: textWidget,
    );
  }
}

class _EcgPainter extends CustomPainter {
  final double progress;
  final Color color;

  _EcgPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final glowPaint = Paint()
      ..color = color.withAlpha(120)
      ..strokeWidth = 10.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);

    final path = Path();
    final startY = size.height / 2;
    final width = size.width;

    final currentX = progress * width;

    path.moveTo(0, startY);

    final center = width / 2;

    final p1 = center - 80;
    final p2 = center - 60;
    final p3 = center - 40;
    final p4 = center - 15;
    final p5 = center + 15;
    final p6 = center + 40;
    final p7 = center + 80;

    if (currentX < p1) {
      path.lineTo(currentX, startY);
    } else {
      path.lineTo(p1, startY);

      if (currentX < p2) {
        path.lineTo(currentX, startY - ((currentX - p1) / (p2 - p1)) * 15);
      } else {
        path.lineTo(p2, startY - 15);

        if (currentX < p3) {
          path.lineTo(
            currentX,
            startY - 15 + ((currentX - p2) / (p3 - p2)) * 30,
          );
        } else {
          path.lineTo(p3, startY + 15);

          if (currentX < p4) {
            path.lineTo(
              currentX,
              startY + 15 - ((currentX - p3) / (p4 - p3)) * 90,
            );
          } else {
            path.lineTo(p4, startY - 75);

            if (currentX < p5) {
              path.lineTo(
                currentX,
                startY - 75 + ((currentX - p4) / (p5 - p4)) * 135,
              );
            } else {
              path.lineTo(p5, startY + 60);

              if (currentX < p6) {
                path.lineTo(
                  currentX,
                  startY + 60 - ((currentX - p5) / (p6 - p5)) * 60,
                );
              } else {
                path.lineTo(p6, startY);
                if (currentX < p7) {
                  path.lineTo(currentX, startY);
                } else {
                  path.lineTo(p7, startY);
                  path.lineTo(currentX, startY);
                }
              }
            }
          }
        }
      }
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _EcgPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
