import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/dashboard_providers.dart';

/// ─────────────────────────────────────────────────────────
/// SCHOOL OVERVIEW TAB
/// ─────────────────────────────────────────────────────────
class SchoolOverviewTab extends ConsumerWidget {
  const SchoolOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(schoolOverviewProvider);

    return Container(
      color: AppColors.background,

      child: overviewAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),

        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppColors.error),
          ),
        ),

        data: (overview) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [

              /// 🔹 SUMMARY CARDS
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Students',
                      value: overview.totalStudents.toString(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Staff',
                      value: overview.totalStaff.toString(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Admins',
                      value: overview.totalAdmins.toString(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox()),
                ],
              ),

              const SizedBox(height: 20),

              /// 🔹 STUDENTS PER CLASS
              const Text(
                'Students per Class',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Card(
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(12),

                  child: Column(
                    children: overview.studentsPerClass.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),

                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              entry.value.toString(),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────
/// STAT CARD
/// ─────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      elevation: 2,

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}