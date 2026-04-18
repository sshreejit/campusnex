import 'package:flutter/material.dart';
import 'package:campusnex/core/widgets/app_fab.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../roles/providers/role_provider.dart';
import '../../../roles/repositories/roles_repository.dart';
import '../../../auth/auth_notifier.dart';
import '../../../auth/auth_state.dart';


class RolesTab extends ConsumerWidget {
  const RolesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(rolesProvider);

    return Stack(
      children: [
        Container(
          color: AppColors.background,
          child: rolesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => Center(
              child: Text('Error: $e'),
            ),
            data: (roles) {
              if (roles.isEmpty) {
                return const Center(
                  child: Text('No roles found'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: roles.length,
                itemBuilder: (_, i) {
                  final r = roles[i];

                  return Card(
                    color: AppColors.surface,
                    child: ListTile(
                      title: Text(
                        r.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          /// ✏️ EDIT
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () =>
                                _showEditDialog(context, ref, r),
                          ),

                          /// 🗑 DELETE (WITH CONFIRMATION)
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.error),
                            onPressed: () async {
                              final authState =
                              ref.read(authNotifierProvider);

                              if (authState is! AuthSuccess) return;

                              final isUsed = await ref
                                  .read(rolesRepositoryProvider)
                                  .isRoleAssigned(
                                roleId: r.id,
                                schoolId:
                                authState.user.schoolId,
                              );

                              final confirmed =
                              await showConfirmDialog(
                                context: context,
                                title: 'Delete Role',
                                message: isUsed
                                    ? 'Are you sure you want to delete this role?\n\n'
                                    'This role is already assigned to staff.\n\n'
                                    'Deleting it will affect them.'
                                    : 'Are you sure you want to delete this role?',
                                actionText: 'Delete',
                                isDestructive: true,
                              );

                              if (confirmed != true) return;

                              await ref
                                  .read(rolesRepositoryProvider)
                                  .deleteRole(
                                roleId: r.id,
                                schoolId:
                                authState.user.schoolId,
                              );

                              ref.refresh(rolesProvider);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        /// ➕ ADD ROLE BUTTON
        Positioned(
          bottom: 16,
          right: 16,
          child: AppFab(
            label: 'Add Role',
            icon: Icons.add_circle_outline,
            onTap: () => _showAddDialog(context, ref),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // ADD ROLE
  // ─────────────────────────────────────────────
  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Role'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Role Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;

              final authState = ref.read(authNotifierProvider);
              if (authState is! AuthSuccess) return;

              await ref.read(rolesRepositoryProvider).addRole(
                name: name,
                schoolId: authState.user.schoolId,
                createdBy: authState.user.id,
              );

              ref.refresh(rolesProvider);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // EDIT ROLE (UPDATE WITH CONFIRMATION)
  // ─────────────────────────────────────────────
  void _showEditDialog(
      BuildContext context, WidgetRef ref, dynamic role) {
    final controller = TextEditingController(text: role.name);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Role'),
        content: TextField(
          controller: controller,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final authState = ref.read(authNotifierProvider);
              if (authState is! AuthSuccess) return;

              final isUsed = await ref
                  .read(rolesRepositoryProvider)
                  .isRoleAssigned(
                roleId: role.id,
                schoolId: authState.user.schoolId,
              );

              final confirmed =
              await showConfirmDialog(
                context: context,
                title: 'Update Role',
                message: isUsed
                    ? 'This role is already assigned to staff.\n\n'
                    'Updating it will affect them.\n\n'
                    'Continue?'
                    : 'Are you sure you want to update this role?',
                actionText: 'Continue',
              );

              if (confirmed != true) return;

              await ref.read(rolesRepositoryProvider).updateRole(
                roleId: role.id,
                schoolId: authState.user.schoolId,
                name: controller.text.trim(),
              );

              ref.refresh(rolesProvider);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}