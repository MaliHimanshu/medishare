import 'package:flutter/material.dart';

/// Reusable Material 3 Status Chip for Equipment, Donations, Requests, and Hospitals
class MSStatusChip extends StatelessWidget {
  final String status;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const MSStatusChip({
    super.key,
    required this.status,
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
  });

  Color _getStatusColor(String st) {
    switch (st.toUpperCase()) {
      case 'APPROVED':
      case 'AVAILABLE':
        return Colors.green;
      case 'COMPLETED':
      case 'DONATED':
        return Colors.blue;
      case 'REJECTED':
      case 'CANCELLED':
      case 'UNAVAILABLE':
        return Colors.red;
      case 'REQUESTED':
      case 'PENDING':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    final formattedText = status.toUpperCase();

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(80), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: fontSize * 0.3,
            backgroundColor: color,
          ),
          const SizedBox(width: 5),
          Text(
            formattedText,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
