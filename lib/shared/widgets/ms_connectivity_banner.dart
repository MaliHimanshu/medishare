import 'package:flutter/material.dart';
/// Animated connectivity banner that slides in from the top when internet is lost.
/// Automatically handles show/hide based on a `isConnected` flag.
class MsConnectivityBanner extends StatefulWidget {
  final bool isConnected;
  final Widget child;

  const MsConnectivityBanner({
    super.key,
    required this.isConnected,
    required this.child,
  });

  @override
  State<MsConnectivityBanner> createState() => _MsConnectivityBannerState();
}

class _MsConnectivityBannerState extends State<MsConnectivityBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    if (!widget.isConnected) _ctrl.forward();
  }

  @override
  void didUpdateWidget(MsConnectivityBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isConnected && !_ctrl.isCompleted) {
      _ctrl.forward();
    } else if (widget.isConnected && _ctrl.isCompleted) {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _fade,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    bottom: 10,
                    left: 16,
                    right: 16,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_rounded,
                          color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'No internet connection',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
