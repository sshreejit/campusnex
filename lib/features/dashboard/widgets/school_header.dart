import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campusnex/core/repositories/user_repository.dart';
import 'package:campusnex/core/theme/app_colors.dart';
import 'package:campusnex/features/auth/auth_notifier.dart';
import 'package:campusnex/features/dashboard/providers/dashboard_providers.dart';
import 'dart:ui';

Widget _buildActionMenu(WidgetRef ref) {
  return PopupMenuButton<String>(
    icon: const Icon(Icons.more_vert, color: Colors.white),
    onSelected: (value) =>
    value == 'logout'
        ? ref.read(authNotifierProvider.notifier).signOut()
        : null,
    itemBuilder: (context) => [
      const PopupMenuItem(
        value: 'logout',
        child: Row(
          children: [
            Icon(Icons.logout, size: 18, color: AppColors.error),
            SizedBox(width: 12),
            Text('Logout'),
          ],
        ),
      ),
    ],
  );
}

Widget _buildAdminBadge(bool isManager) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isManager) ...[
          const Icon(Icons.star, size: 12, color: AppColors.warning),
          const SizedBox(width: 4),
        ],
        const Text(
          'ADMIN',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class SchoolHeader extends ConsumerWidget {
  const SchoolHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;
    if (user == null) return const SizedBox();
    final school = ref.watch(currentSchoolProvider).value;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.charcoalSteel,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          /// 🔹 LOGO
          SizedBox(
            width: 52,
            child: (school?.logoUrl ?? '').isNotEmpty
                ? Image.network(
              school!.logoUrl!,
              width: 52,
              height: 52,
              fit: BoxFit.contain,
            )
                : const Icon(Icons.school, size: 36, color: Colors.white),
          ),

          const SizedBox(width: 12),

          /// 🔹 TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// School Name
                if ((school?.name ?? '').isNotEmpty)
                  Text(
                    school!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                const SizedBox(height: 4),

                /// Welcome + Badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Welcome, ${user.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    _buildAdminBadge(true),
                  ],
                ),
              ],
            ),
          ),

          /// 🔹 MENU
          _buildActionMenu(ref),
        ],
      ),
    );
  }
}