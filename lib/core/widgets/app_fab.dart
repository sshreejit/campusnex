import 'package:flutter/material.dart';

class AppFab extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const AppFab({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 20, bottom: 20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 26, // 🔥 more width (key difference)
            vertical: 16,   // 🔥 taller (premium feel)
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFD6EAF8), // same as designation
            borderRadius: BorderRadius.circular(40), // 🔥 more pill shape
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,   // 🔥 softer shadow
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22, // slightly bigger
                color: Colors.black87,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15.5, // 🔥 slightly bigger text
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}