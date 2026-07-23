import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Production-grade animated empty state widget.
/// Features a fade+slide entrance animation and gradient icon background.
class MSEmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double height;
  final bool compact;

  const MSEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.height = 200,
    this.compact = false,
  });

  @override
  State<MSEmptyState> createState() => _MSEmptyStateState();
}

class _MSEmptyStateState extends State<MSEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasAction = widget.actionLabel != null && widget.onAction != null;
    final iconRadius = widget.compact ? 28.0 : 38.0;
    final iconSize = widget.compact ? 26.0 : 34.0;
    final titleSize = widget.compact ? 14.0 : 16.0;
    final subtitleSize = widget.compact ? 11.0 : 12.5;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 16 : 24,
            vertical: widget.compact ? 16 : 24,
          ),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.borderColor, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Gradient icon container
              Container(
                width: iconRadius * 2,
                height: iconRadius * 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withAlpha(30),
                      AppColors.accent.withAlpha(20),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: AppColors.primary, size: iconSize),
              ),

              SizedBox(height: widget.compact ? 10 : 14),

              Text(
                widget.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: titleSize,
                  color: context.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontSize: subtitleSize,
                  color: context.textSecondaryColor,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              if (hasAction) ...[
                SizedBox(height: widget.compact ? 12 : 18),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  onPressed: widget.onAction,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    widget.actionLabel!,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
