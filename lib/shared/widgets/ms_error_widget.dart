import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Error type for context-aware error display
enum MsErrorType { general, noInternet, timeout, serverError, unauthorized }

/// Production-grade animated error widget with error-type awareness.
class MSErrorWidget extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;
  final MsErrorType errorType;

  const MSErrorWidget({
    super.key,
    this.title = 'Something Went Wrong',
    required this.message,
    required this.onRetry,
    this.errorType = MsErrorType.general,
  });

  /// Named constructor for no internet
  const MSErrorWidget.noInternet({
    super.key,
    required this.onRetry,
  })  : title = 'No Internet Connection',
        message = 'Please check your network and try again.',
        errorType = MsErrorType.noInternet;

  /// Named constructor for server error
  const MSErrorWidget.serverError({
    super.key,
    required this.onRetry,
    this.message = 'Server is temporarily unavailable.',
  })  : title = 'Server Error',
        errorType = MsErrorType.serverError;

  @override
  State<MSErrorWidget> createState() => _MSErrorWidgetState();
}

class _MSErrorWidgetState extends State<MSErrorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  IconData get _icon {
    switch (widget.errorType) {
      case MsErrorType.noInternet:
        return Icons.wifi_off_rounded;
      case MsErrorType.timeout:
        return Icons.timer_off_outlined;
      case MsErrorType.serverError:
        return Icons.cloud_off_rounded;
      case MsErrorType.unauthorized:
        return Icons.lock_outline_rounded;
      case MsErrorType.general:
        return Icons.error_outline_rounded;
    }
  }

  Color get _iconColor {
    switch (widget.errorType) {
      case MsErrorType.noInternet:
        return AppColors.warning;
      case MsErrorType.timeout:
        return AppColors.info;
      case MsErrorType.serverError:
        return AppColors.primary;
      case MsErrorType.unauthorized:
        return AppColors.error;
      case MsErrorType.general:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _iconColor.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_icon, size: 40, color: _iconColor),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.message,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textSecondaryColor,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: widget.onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try Again',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
