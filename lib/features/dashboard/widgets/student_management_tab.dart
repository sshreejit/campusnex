import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ─────────────────────────────────────────────────────────
/// STUDENT MANAGEMENT TAB (EXTRACTED)
/// ─────────────────────────────────────────────────────────
class StudentManagementTab extends ConsumerWidget {
  const StudentManagementTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: const Color(0xFFE2E6EA), // ✅ consistent background

      child: const Center(
        child: Text(
          'Student List',
          style: TextStyle(color: Colors.black87),
        ),
      ),
    );
  }
}