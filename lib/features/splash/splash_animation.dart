import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class MediShareSplashAnimation extends StatefulWidget {
  final AnimationController controller;
  final bool isDark;

  const MediShareSplashAnimation({
    super.key,
    required this.controller,
    required this.isDark,
  });

  @override
  State<MediShareSplashAnimation> createState() =>
      _MediShareSplashAnimationState();
}

class _MediShareSplashAnimationState extends State<MediShareSplashAnimation> {
  late final Animation<double> _ecgDraw;
  late final Animation<double> _ecgFade;
  
  late final Animation<double> _pillScale;
  late final Animation<double> _splitFrac;
  late final Animation<double> _crossFrac;
  late final Animation<double> _rippleFrac;
  
  late final Animation<double> _slideFrac;
  late final Animation<double> _textAlpha;
  late final Animation<double> _shimmerFrac;

  @override
  void initState() {
    super.initState();
    _buildAnimations();
  }

  void _buildAnimations() {
    final c = widget.controller;

    // ECG slowly draws from 0.0s to 2.5s
    _ecgDraw = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: c, curve: const Interval(0.00, 0.25, curve: Curves.easeInOutCubic)),
    );
    // ECG fades slowly while Pill fades in from 3.5s to 4.5s
    _ecgFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: c, curve: const Interval(0.35, 0.45, curve: Curves.easeOut)),
    );
    
    // Pill scales from 0 to 1 at 3.5s to 4.5s (overlapping ECG fade)
    _pillScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: c, curve: const Interval(0.35, 0.45, curve: Curves.easeOutBack)),
    );
    
    // Pill splits smoothly 5.0s to 6.5s
    _splitFrac = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: c, curve: const Interval(0.50, 0.65, curve: Curves.easeInOutCubic)),
    );
    
    // Crossbar forms along with the split
    _crossFrac = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: c, curve: const Interval(0.50, 0.65, curve: Curves.easeOutCubic)),
    );
    
    // Ripple 6.5s to 7.5s
    _rippleFrac = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: c, curve: const Interval(0.65, 0.75, curve: Curves.easeOutCubic)),
    );
    
    // Logo slides and text enters 7.5s to 8.5s
    _slideFrac = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: c, curve: const Interval(0.75, 0.85, curve: Curves.easeInOutCubic)),
    );
    _textAlpha = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: c, curve: const Interval(0.75, 0.85, curve: Curves.easeOutCubic)),
    );
    
    // Final shimmer 8.5s to 10.0s
    _shimmerFrac = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: c, curve: const Interval(0.85, 1.00, curve: Curves.easeInOut)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RepaintBoundary(
          child: AnimatedBuilder(
            animation: widget.controller,
            builder: (context, _) {
              if (widget.controller.value == 0.0) {
                 debugPrint('SPLASH ECG START');
              }
              return CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _SplashPainter(
                  isDark: widget.isDark,
                  ecgDraw: _ecgDraw.value,
                  ecgFade: _ecgFade.value,
                  pillScale: _pillScale.value,
                  splitFrac: _splitFrac.value,
                  crossFrac: _crossFrac.value,
                  rippleFrac: _rippleFrac.value,
                  slideFrac: _slideFrac.value,
                  textAlpha: _textAlpha.value,
                  shimmerFrac: _shimmerFrac.value,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SplashPainter extends CustomPainter {
  final bool isDark;
  final double ecgDraw, ecgFade;
  final double pillScale, splitFrac, crossFrac, rippleFrac;
  final double slideFrac, textAlpha, shimmerFrac;

  const _SplashPainter({
    required this.isDark,
    required this.ecgDraw, required this.ecgFade,
    required this.pillScale, required this.splitFrac,
    required this.crossFrac, required this.rippleFrac,
    required this.slideFrac, required this.textAlpha,
    required this.shimmerFrac,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double sw = size.width;
    final double cy = size.height / 2.0;

    // 1. Final Composition Math (75% of screen width)
    final double targetWidth = sw * 0.75;
    
    const double rawPillHW = 24.0; 
    const double rawPillHH = 62.0; 
    const double rawCrossHH = 24.0; 
    const double rawCrossMaxHW = 62.0;
    const double rawGap = 20.0;
    const double rawDotR = 6.0;
    const double rawFontSize = 54.0;

    final Color mediColor = isDark ? Colors.white : AppColors.textPrimary;
    final Color shareColor = AppColors.accent;

    final tpMediBase = _layoutText('Medi', mediColor, rawFontSize, 1.0);
    final tpShareBase = _layoutText('Share', shareColor, rawFontSize, 1.0);
    final double rawTextW = tpMediBase.width + tpShareBase.width;
    
    final double rawSymbolW = rawCrossMaxHW * 2.0;
    final double rawTotalW = rawSymbolW + rawGap + rawTextW;

    final double effK = targetWidth / rawTotalW;
    
    final double fs = rawFontSize * effK;
    final tpMedi = _layoutText('Medi', mediColor, fs, textAlpha);
    final tpShare = _layoutText('Share', shareColor, fs, textAlpha);
    final double textWidth = tpMedi.width + tpShare.width;
    
    final double symbolWidth = rawSymbolW * effK;
    final double symbolTextGap = rawGap * effK;
    final double totalWidth = symbolWidth + symbolTextGap + textWidth;

    // Center the complete group
    final double groupLeft = (sw - totalWidth) / 2.0;
    final double finalSymbolLeft = groupLeft;
    final double finalTextX = finalSymbolLeft + symbolWidth + symbolTextGap;
    
    final double startSymbolCx = sw / 2.0;
    final double finalSymbolCx = finalSymbolLeft + (symbolWidth / 2.0);
    
    // Smooth transition from center to final position
    final double logoCx = startSymbolCx + (finalSymbolCx - startSymbolCx) * slideFrac;

    // Text slides gracefully behind the symbol
    final double textStartOffset = 40.0 * effK;
    final double textX = finalTextX + (textStartOffset * (1.0 - textAlpha));

    // Colors
    final Paint pillPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final Paint crossFullPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: crossFrac)
      ..style = PaintingStyle.fill;

    final Paint dotFullPaint = Paint()
      ..color = isDark ? const Color(0xFF111827) : Colors.white
      ..style = PaintingStyle.fill;

    // ECG setup
    if (ecgDraw > 0.0 && ecgFade > 0.0) {
      _drawEcg(canvas, size, effK);
    }
    
    if (pillScale > 0.0) {
      _drawPill(canvas, logoCx, cy, effK, rawPillHW, rawPillHH, rawCrossHH, pillPaint);
      if (crossFrac > 0.0) {
        _drawCrossbar(canvas, logoCx, cy, effK, rawPillHW, rawCrossMaxHW, rawCrossHH, crossFullPaint);
        _drawDot(canvas, logoCx, cy, effK, rawDotR, dotFullPaint);
      }
      if (rippleFrac > 0.0 && rippleFrac < 1.0) {
        _drawRipples(canvas, logoCx, cy, effK, rawCrossHH);
      }
    }
    
    if (textAlpha > 0.0) {
      _drawText(canvas, textX, cy, tpMedi, tpShare, textWidth);
    }
  }

  TextPainter _layoutText(String text, Color color, double fs, double alphaFrac) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withValues(alpha: alphaFrac.clamp(0.0, 1.0)),
          fontSize: fs,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  void _drawEcg(Canvas canvas, Size size, double effK) {
    final double midY = size.height * 0.5;
    final double sw = size.width;

    // ECG spans 70% of the screen logically
    final double startX = sw * 0.15;
    final double endX = sw * 0.85;
    final double w = endX - startX;

    final path = Path()..moveTo(startX, midY);
    path.lineTo(startX + w * 0.35, midY); // flat
    path.lineTo(startX + w * 0.40, midY - (40.0 * effK)); // small dip/rise
    path.lineTo(startX + w * 0.45, midY + (40.0 * effK));
    path.lineTo(startX + w * 0.50, midY - (120.0 * effK)); // BIG SPIKE
    path.lineTo(startX + w * 0.55, midY + (90.0 * effK)); // BIG DROP
    path.lineTo(startX + w * 0.60, midY - (20.0 * effK)); // small rebound
    path.lineTo(startX + w * 0.65, midY);
    path.lineTo(endX, midY);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    // Animate the path extraction
    final extracted = metric.extractPath(0.0, metric.length * ecgDraw);

    final double ecgLineW = 6.0 * effK;
    final double ecgGlowW = 14.0 * effK;

    final Paint ecgLinePaint = Paint()
      ..color = AppColors.accent.withValues(alpha: ecgFade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = ecgLineW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint ecgGlowPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: ecgFade * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = ecgGlowW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);

    canvas.drawPath(extracted, ecgGlowPaint);
    canvas.drawPath(extracted, ecgLinePaint);
  }

  void _drawPill(Canvas canvas, double logoCx, double cy, double effK, double rawHW, double rawHH, double rawCrossHH, Paint p) {
    final double hw  = rawHW * effK * pillScale;
    final double hh  = rawHH * effK * pillScale;
    final double r   = hw;
    
    final double maxOffset = rawCrossHH * effK;
    final double offset = maxOffset * splitFrac;

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(logoCx - hw, cy - offset - hh, hw * 2.0, hh),
        topLeft: Radius.circular(r),
        topRight: Radius.circular(r),
      ),
      p,
    );

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(logoCx - hw, cy + offset, hw * 2.0, hh),
        bottomLeft: Radius.circular(r),
        bottomRight: Radius.circular(r),
      ),
      p,
    );
  }

  void _drawCrossbar(Canvas canvas, double logoCx, double cy, double effK, double rawPillHW, double rawCrossMaxHW, double rawCrossHH, Paint p) {
    final double halfW = (rawPillHW + (rawCrossMaxHW - rawPillHW) * crossFrac) * effK;
    final double halfH = rawCrossHH * effK;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(logoCx - halfW, cy - halfH, halfW * 2.0, halfH * 2.0),
        Radius.circular(halfH),
      ),
      p,
    );
  }

  void _drawDot(Canvas canvas, double logoCx, double cy, double effK, double rawDotR, Paint fullPaint) {
    final Paint p = Paint()
      ..color = fullPaint.color.withValues(alpha: crossFrac)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(logoCx, cy), rawDotR * effK, p);
  }

  void _drawRipples(Canvas canvas, double logoCx, double cy, double effK, double rawCrossHH) {
    final double baseHH = rawCrossHH * effK;
    for (int i = 0; i < 3; i++) {
      final double delay = i * 0.28;
      if (rippleFrac <= delay) continue;
      final double progress = ((rippleFrac - delay) / (1.0 - delay)).clamp(0.0, 1.0);
      if (progress >= 1.0) continue;
      final double radius = baseHH * (1.2 + progress * 5.0);
      final double alpha = (1.0 - progress) * 0.55;
      canvas.drawCircle(
        Offset(logoCx, cy),
        radius,
        Paint()
          ..color = AppColors.accent.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0 * effK,
      );
    }
  }

  void _drawText(Canvas canvas, double textX, double cy, TextPainter tpMedi, TextPainter tpShare, double totalW) {
    final double textY = cy - tpMedi.height / 2.0;

    if (shimmerFrac > 0.0 && shimmerFrac < 1.0) {
      final Rect bounds = Rect.fromLTWH(textX, textY, totalW, tpMedi.height);
      canvas.saveLayer(bounds, Paint());
      tpMedi.paint(canvas, Offset(textX, textY));
      tpShare.paint(canvas, Offset(textX + tpMedi.width, textY));
      
      final double shimX = bounds.left - totalW + shimmerFrac * totalW * 3.0;
      canvas.drawRect(
        bounds,
        Paint()
          ..blendMode = BlendMode.srcATop
          ..shader = LinearGradient(
            colors: const [Colors.transparent, Colors.white, Colors.transparent],
            stops: const [0.0, 0.5, 1.0],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(Rect.fromLTWH(shimX, textY, totalW, tpMedi.height)),
      );
      canvas.restore();
    } else {
      tpMedi.paint(canvas, Offset(textX, textY));
      tpShare.paint(canvas, Offset(textX + tpMedi.width, textY));
    }
  }

  @override
  bool shouldRepaint(covariant _SplashPainter old) =>
      old.ecgDraw    != ecgDraw    || old.ecgFade    != ecgFade    ||
      old.pillScale  != pillScale  || old.splitFrac  != splitFrac  ||
      old.crossFrac  != crossFrac  || old.rippleFrac != rippleFrac ||
      old.slideFrac  != slideFrac  || old.textAlpha  != textAlpha  ||
      old.shimmerFrac != shimmerFrac || old.isDark   != isDark;
}
