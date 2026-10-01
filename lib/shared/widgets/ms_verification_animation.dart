import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class MsVerificationAnimation extends StatefulWidget {
  final bool isSuccess;

  const MsVerificationAnimation({super.key, this.isSuccess = false});

  @override
  State<MsVerificationAnimation> createState() =>
      _MsVerificationAnimationState();
}

class _MsVerificationAnimationState extends State<MsVerificationAnimation>
    with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late AnimationController _successCtrl;

  late Animation<double> _iconScale;
  late Animation<double> _iconFade;
  late Animation<double> _ringSweep;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseFade;

  late Animation<double> _successScale;
  late Animation<double> _successFade;

  @override
  void initState() {
    super.initState();

    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // 0–400ms: Icon fades and scales in
    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.266, curve: Curves.easeOutBack), // 0-400ms
      ),
    );
    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.266, curve: Curves.easeIn), // 0-400ms
      ),
    );

    // 400–1000ms: Security/verification ring animates around the icon
    _ringSweep = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(
          0.266,
          0.666,
          curve: Curves.easeInOutCubic,
        ), // 400-1000ms
      ),
    );

    // 1000–1500ms: OTP/verification indicator pulses
    _pulseScale = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(
          0.666,
          1.0,
          curve: Curves.easeInOutSine,
        ), // 1000-1500ms
      ),
    );
    _pulseFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.666, 1.0, curve: Curves.easeOut), // 1000-1500ms
      ),
    );

    // Success animation
    _successScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut));
    _successFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _successCtrl, curve: Curves.easeIn));

    _mainCtrl.forward();
  }

  @override
  void didUpdateWidget(covariant MsVerificationAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSuccess && !oldWidget.isSuccess) {
      _successCtrl.forward();
    } else if (!widget.isSuccess && oldWidget.isSuccess) {
      _successCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainCtrl, _successCtrl]),
      builder: (context, child) {
        return SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulse Effect
              if (!widget.isSuccess)
                Transform.scale(
                  scale: _pulseScale.value,
                  child: Opacity(
                    opacity: _pulseFade.value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withAlpha(40),
                      ),
                    ),
                  ),
                ),

              // Ring Drawer
              if (!widget.isSuccess)
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CustomPaint(
                    painter: _RingPainter(
                      sweepAngle: _ringSweep.value,
                      color: AppColors.accent,
                    ),
                  ),
                ),

              // Main Icon
              if (!widget.isSuccess)
                Transform.scale(
                  scale: _iconScale.value,
                  child: Opacity(
                    opacity: _iconFade.value,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons
                            .admin_panel_settings_outlined, // medical/security feel
                        size: 32,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),

              // Success Overlay
              if (_successCtrl.value > 0)
                Transform.scale(
                  scale: _successScale.value,
                  child: Opacity(
                    opacity: _successFade.value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double sweepAngle;
  final Color color;

  _RingPainter({required this.sweepAngle, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (sweepAngle <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    // Draw the arc starting from top (-pi/2)
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle || oldDelegate.color != color;
  }
}
