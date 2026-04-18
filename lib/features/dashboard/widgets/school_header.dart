import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campusnex/core/repositories/user_repository.dart';
import 'package:campusnex/core/theme/app_colors.dart';
import 'package:campusnex/features/auth/auth_notifier.dart';
import 'package:campusnex/features/dashboard/providers/dashboard_providers.dart';

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
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.white30),
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
            letterSpacing: 0.3,
            fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.charcoalSteel,
            AppColors.charcoalSteel.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// 🔥 TOP ROW
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// 🔹 LOGO
              SizedBox(
                width: 75, // match image size
                child: Align(
                  alignment: Alignment.topLeft,
                  child: (school?.logoUrl ?? '').isNotEmpty
                      ? Image.network(
                    school!.logoUrl!,
                    width: 75,
                    height: 75,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.school,
                      size: 40,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(
                    Icons.school,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              /// 🔹 TEXT BLOCK
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
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                    const SizedBox(height: 4), // 🔥 tighter

                    /// Welcome + Badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Welcome, ${user?.name ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
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
        ],
      ),
    );
  }
}