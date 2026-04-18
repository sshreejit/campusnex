import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────
/// ROLE BANNER (REUSABLE)
/// ─────────────────────────────────────────────────────────
class RoleBanner extends StatelessWidget {
  final String label;
  final String userName;
  final Color color;

  const RoleBanner({
    super.key,
    required this.label,
    required this.userName,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            userName,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}